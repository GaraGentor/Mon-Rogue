extends RewardDialog

## Debug-Menü der Karte (nur in Debug-Builds, siehe world_map.gd add_debug_button): öffnet mit dem
## aktuellen Team jeden Ort des Spiels, unabhängig von der Position auf der Karte. Die Orte laufen über
## ihre normalen Abläufe, Fortschritt zählt also wie im echten Spiel. Texte nur auf Deutsch, Spieler sehen sie nie.

const ACCENT := Color(0.85, 0.3, 0.3)
const COLUMNS := 6
const BUTTON_SIZE := Vector2(170, 44)
const BUTTON_FONT_SIZE := 16
const HEADER_FONT_SIZE := 18
const MON_COLUMNS := 8
const MON_BUTTON_SIZE := Vector2(130, 120)
const MON_ICON_SIZE := 72
const UNPICKED_COLOR := Color(0.65, 0.65, 0.65)
const EGG_LABEL_WIDTH := 170
const EGG_BUTTON_SIZE := Vector2(300, 44)
const STAT_NAMES := {"hp": "KP", "atk": "Angriff", "def": "Verteidigung", "s_atk": "Sp. Angriff", "s_def": "Sp. Verteidigung", "speed": "Initiative"}
const STAT_VALUE_WIDTH := 70
const STAT_STEP_SIZE := Vector2(60, 40)
const STATS_EXAMPLE_BST := 200
const DEBUG_ESSENCE := 500
const DEBUG_SHARDS := 5
const DEBUG_KEYS := 5
## So viel Edelstein-Bonus trägt das gefallene Test-Monster, damit Edelsteine vererbt werden können
const FALLEN_GEM_BONUS := 20
## Mit so vielen K.O.s startet der Level-Up-Bildschirm (2 K.O.s = +1 Stufe)
const LEVEL_UP_KILLS := 2
## So viele Gegner-Slots hat der Kampf (battle.tscn)
const MAX_ENEMIES := 3

const BATTLE_PATH := "res://script/scenes/battle/battle.tscn"
const JUDGEMENT_PATH := "res://script/scenes/judgment/judgement.tscn"
const LEVEL_UP_PATH := "res://script/scenes/level_up/level_up.tscn"
const BOSS_REWARD_PATH := "res://script/scenes/boss_reward/boss_reward.tscn"
const RUN_END_PATH := "res://script/scenes/run_end/run_end.tscn"
const WORLD_MAP_PATH := "res://script/scenes/world_map/world_map.tscn"
const RELIC_REWARD_SCENE := preload("res://script/scenes/relic_reward/relic_reward.tscn")

## Die Karte (world_map.gd), über die die Felder geöffnet werden
var map: Control

var _main: VBoxContainer
var _fight_page: VBoxContainer
## Startet den Kampf, für den gerade die Gegnerzahl gewählt wird
var _fight_start: Callable
var _picker: VBoxContainer
## Arten, die im Judgement als Fänge bereitliegen
var _picked: Array[String] = []
var _fallen_check: CheckBox
var _start_button: Button
var _rotten_eggs_button: Button
var _egg_page: VBoxContainer
var _egg_rows: VBoxContainer
## Art, deren Ei-Attacken gerade angezeigt werden
var _egg_species: String
var _stats_page: VBoxContainer
var _stats_summary: Label
## Wert -> Label mit dem reservierten Anteil
var _stat_values := {}

func _ready() -> void:
	set_accent(ACCENT)
	set_title("DEBUG")
	# keine Preise und Ziele, nur Buttons
	_columns.visible = false
	_build_main()
	_build_fight_page()
	_build_picker()
	_build_egg_page()
	_build_stats_page()
	_show_page(_main)

func _build_main() -> void:
	_main = VBoxContainer.new()
	_main.add_theme_constant_override("separation", 8)
	add_footer(_main)

	var is_last_biome: bool = State.map_level == Map.map_settings.size() - 1
	_add_section(_main, "Kämpfe", [
		[tr(Map.type_label(Map.PATH_TYPE.COMBAT)) + " ...", _open_fight_page.bind(_change_scene.bind(BATTLE_PATH))],
		["BOSS-FELD ...", _open_fight_page.bind(_start_map_boss)],
		["ENDBOSS ..." if is_last_biome else "BIOM-BOSS ...", _open_fight_page.bind(map.start_biome_boss)],
	])

	var fields := []
	for type in [Map.PATH_TYPE.CAMP, Map.PATH_TYPE.HUB, Map.PATH_TYPE.SHOP, Map.PATH_TYPE.TRAINER, Map.PATH_TYPE.JAILER, Map.PATH_TYPE.GEM, Map.PATH_TYPE.TREASURE]:
		fields.append([tr(Map.type_label(type)), _open_field.bind(type)])
	fields.append(["SCHATZ AUTOMATISCH", _collect_treasure])
	fields.append(["GLÜCKSRAD", _open_wheel])
	_add_section(_main, "Felder", fields)

	_add_section(_main, "Nach dem Kampf", [
		["JUDGEMENT ...", func(): _show_page(_picker)],
		["LEVEL-UP", _open_level_up],
		["RELIC-AUSWAHL", _open_relic_reward],
		["FÄHIGKEITEN-AUSWAHL", _open_skill_reward],
		["BOSS-BELOHNUNG", _open_boss_reward],
		["RUN-ENDE SIEG", _end_run.bind(true)],
		["RUN-ENDE NIEDERL.", _end_run.bind(false)],
	])

	var biomes := []
	for depth in State.biome_path.size():
		biomes.append(["%d %s" % [depth + 1, tr(ColorMap.get_combo(State.biome_path[depth]).label)], _switch_biome.bind(depth)])
	_add_section(_main, "Biom wechseln (neue Karte)", biomes)

	var extras := _add_section(_main, "Ressourcen und nächster Run", [
		["+%d ESSENZ" % DEBUG_ESSENCE, _add_essence],
		["+%d BOSS TRÄNEN" % DEBUG_SHARDS, _add_shards],
		["+%d SCHLÜSSEL" % DEBUG_KEYS, _add_keys],
		["+1 GUTSCHEIN", _add_coupon],
	])
	_rotten_eggs_button = _make_button(_rotten_eggs_text(), _toggle_rotten_eggs)
	extras.add_child(_rotten_eggs_button)
	extras.add_child(_make_button("EI-ATTACKEN ...", func(): _show_page(_egg_page)))
	extras.add_child(_make_button("WERTE-VERTEILUNG ...", func(): _show_page(_stats_page)))

	var close_button := _make_button("SCHLIESSEN", close)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_main.add_child(close_button)

## Gegnerzahl vor dem Kampfstart. WIE IM SPIEL lässt das Biom bzw. den Boss entscheiden.
func _build_fight_page() -> void:
	_fight_page = VBoxContainer.new()
	_fight_page.add_theme_constant_override("separation", 12)
	add_footer(_fight_page)

	var entries := [["WIE IM SPIEL", _start_fight.bind(0)]]
	for count in range(1, MAX_ENEMIES + 1):
		entries.append([str(count), _start_fight.bind(count)])
	_add_section(_fight_page, "Gegen wie viele Monster?", entries)

	var back_button := _make_button("ZURÜCK", _show_page.bind(_main))
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_fight_page.add_child(back_button)

## Judgement-Auswahl: beliebig viele Arten als Fänge, die dort bereitliegen
func _build_picker() -> void:
	_picker = VBoxContainer.new()
	_picker.add_theme_constant_override("separation", 12)
	add_footer(_picker)

	_picker.add_child(_make_header("Judgement: Welche Monster liegen als neue Fänge bereit?"))
	var grid := GridContainer.new()
	grid.columns = MON_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_picker.add_child(grid)
	for meta in Monmap.mons:
		var button := _make_mon_button(meta.name)
		button.toggled.connect(func(on: bool):
			if on:
				_picked.append(meta.name)
			else:
				_picked.erase(meta.name)
			_refresh_start())
		grid.add_child(button)

	_fallen_check = CheckBox.new()
	_fallen_check.text = "Zusätzlich ein gefallenes Monster (Wiederbelebung und Letzter Wille)"
	_fallen_check.add_theme_color_override("font_color", IronPlate.TEXT_COLOR)
	_fallen_check.toggled.connect(func(_on): _refresh_start())
	_picker.add_child(_fallen_check)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(_make_button("ZURÜCK", _show_page.bind(_main)))
	_start_button = _make_button("JUDGEMENT STARTEN", _start_judgement)
	row.add_child(_start_button)
	_picker.add_child(row)
	_refresh_start()

## Ei-Attacken: oben die Art, darunter ihre freischaltbaren Attacken als Schalter
func _build_egg_page() -> void:
	_egg_page = VBoxContainer.new()
	_egg_page.add_theme_constant_override("separation", 12)
	add_footer(_egg_page)

	_egg_page.add_child(_make_header("Ei-Attacken (dauerhaft im Spielstand, Gold = freigeschaltet)"))
	var grid := GridContainer.new()
	grid.columns = MON_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_egg_page.add_child(grid)
	_egg_rows = VBoxContainer.new()
	_egg_rows.add_theme_constant_override("separation", 8)
	var species_group := ButtonGroup.new()
	var first: Button
	for meta in Monmap.mons:
		var button := _make_mon_button(meta.name)
		button.button_group = species_group
		button.toggled.connect(func(on: bool):
			if on:
				_show_egg_skills(meta.name))
		grid.add_child(button)
		if first == null:
			first = button
	_egg_page.add_child(_egg_rows)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(_make_button("ZURÜCK", _show_page.bind(_main)))
	row.add_child(_make_button("ALLE DIESER ART", func(): _set_species_unlocked(true)))
	row.add_child(_make_button("KEINE DIESER ART", func(): _set_species_unlocked(false)))
	row.add_child(_make_button("ALLE ARTEN", _unlock_all_species))
	_egg_page.add_child(row)
	first.button_pressed = true

func _show_page(page: VBoxContainer) -> void:
	for other in [_main, _fight_page, _picker, _egg_page, _stats_page]:
		other.visible = other == page

func _refresh_start() -> void:
	# ohne Fang und Gefallenen würde das Judgement sofort zurück zur Karte springen
	_start_button.disabled = _picked.is_empty() and not _fallen_check.button_pressed

func _add_section(parent: Control, title: String, entries: Array) -> GridContainer:
	parent.add_child(_make_header(title))
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)
	for entry in entries:
		grid.add_child(_make_button(entry[0], entry[1]))
	return grid

func _make_header(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	label.add_theme_color_override("font_color", SkillDetailPopup.GOLD)
	return label

func _make_button(text: String, on_pressed: Callable) -> Button:
	var button := plate_button(text)
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	button.custom_minimum_size = BUTTON_SIZE
	button.pressed.connect(on_pressed)
	return button

## Schalter: eingeschaltet hell mit goldener Schrift, sonst abgedunkelt
func _make_toggle_button(text: String) -> Button:
	var button := plate_button(text)
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	button.add_theme_color_override("font_hover_pressed_color", SkillDetailPopup.GOLD)
	button.toggle_mode = true
	button.modulate = UNPICKED_COLOR
	button.toggled.connect(func(on: bool): button.modulate = Color.WHITE if on else UNPICKED_COLOR)
	return button

func _make_mon_button(mon_species: String) -> Button:
	var button := _make_toggle_button(Helper.mon_display_name(mon_species))
	button.custom_minimum_size = MON_BUTTON_SIZE
	button.icon = Monmap.texture(mon_species, Monmap.ICON)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_constant_override("icon_max_width", MON_ICON_SIZE)
	return button

# ─────────────────────────
# Orte

func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func _open_fight_page(start: Callable) -> void:
	_fight_start = start
	_show_page(_fight_page)

func _start_fight(enemy_count: int) -> void:
	DebugSettings.next_enemy_count = enemy_count
	_fight_start.call()

func _start_map_boss() -> void:
	State.is_map_boss = true
	_change_scene(BATTLE_PATH)

func _open_field(type: Map.PATH_TYPE) -> void:
	close()
	map.call_event_by_type(type)

func _open_wheel() -> void:
	close()
	map.open_wheel_event()

## Öffnet den Schatz ohne Auswahl: Essenz und Bonus-Preis kommen direkt an
func _collect_treasure() -> void:
	close()
	var treasure: RewardDialog = map.treasure_scene.instantiate()
	map.view_container.add_child(treasure)
	Helper.show_unlock_message("Schatz: " + ", ".join(treasure.take_all()))

func _open_level_up() -> void:
	State.killed_monsters = LEVEL_UP_KILLS
	State.pending_ep = DEBUG_ESSENCE
	State.pending_keys = 1
	State.pending_gems = 1
	State.pending_coupons = 1
	State.pending_relic_chest = not Relics.get_unowned().is_empty()
	State.pending_skill_envelope = not Skills.reward_offers().is_empty()
	_change_scene(LEVEL_UP_PATH)

func _open_relic_reward() -> void:
	if Relics.get_unowned().is_empty():
		Helper.show_unlock_message("Alle Relics sind schon gesammelt")
		return
	close()
	map.view_container.add_child(RELIC_REWARD_SCENE.instantiate())

func _open_skill_reward() -> void:
	if Skills.reward_offers().is_empty():
		Helper.show_unlock_message("Alle einzigartigen Skills sind schon gelernt")
		return
	close()
	var dialog: Control = map.skill_reward_dialog()
	map.view_container.add_child(dialog)
	dialog.visible = true

## Wie nach einem Biom-Boss: die Belohnung führt ins nächste Biom, nach dem letzten endet der Run
func _open_boss_reward() -> void:
	State.current_map_position = State.NO_MAP_POSITION
	_change_scene(BOSS_REWARD_PATH)

func _end_run(won: bool) -> void:
	State.end_run(won)
	_change_scene(RUN_END_PATH)

func _switch_biome(depth: int) -> void:
	State.map_level = depth
	State.biome_fight_index = 0
	State.current_map_position = State.NO_MAP_POSITION
	Map.generate_starting_points()
	_change_scene(WORLD_MAP_PATH)

func _add_essence() -> void:
	State.ep += DEBUG_ESSENCE
	Helper.show_unlock_message("+%d Essenz" % DEBUG_ESSENCE)

func _add_shards() -> void:
	# wie beim Boss-Sieg auch im Spielstand, der Kerkermeister zieht sie dort wieder ab
	SaveManager.add_boss_shard(DEBUG_SHARDS)
	State.boss_shards += DEBUG_SHARDS
	Helper.show_unlock_message("+%d Boss Tränen" % DEBUG_SHARDS)

func _add_keys() -> void:
	State.keys += DEBUG_KEYS
	Helper.show_unlock_message("+%d Schlüssel" % DEBUG_KEYS)

func _add_coupon() -> void:
	State.coupons += 1
	Helper.show_unlock_message("+1 Gutschein")

func _rotten_eggs_text() -> String:
	return "FAULE EIER: " + ("AN" if SaveManager.has_full_reroll_charges() else "AUS")

## Volle Ladungen zeigen in der nächsten Ei-Auswahl den Button "Faule Eier", AUS leert sie
func _toggle_rotten_eggs() -> void:
	SaveManager.set_reroll_charges(0 if SaveManager.has_full_reroll_charges() else SaveManager.REROLL_CHARGES_NEEDED)
	_rotten_eggs_button.text = _rotten_eggs_text()

# ─────────────────────────
# Werte-Verteilung

## Reserve pro Wert
func _build_stats_page() -> void:
	_stats_page = VBoxContainer.new()
	_stats_page.add_theme_constant_override("separation", 10)
	add_footer(_stats_page)

	_stats_page.add_child(_make_header("Werte-Verteilung: fester Anteil der BST pro Wert"))
	for stat in DebugSettings.STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := _make_header(STAT_NAMES[stat])
		label.custom_minimum_size.x = EGG_LABEL_WIDTH
		row.add_child(label)
		for step in [-5, -1]:
			row.add_child(_make_step_button(stat, step))
		var value := _make_header("")
		value.custom_minimum_size.x = STAT_VALUE_WIDTH
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(value)
		_stat_values[stat] = value
		for step in [1, 5]:
			row.add_child(_make_step_button(stat, step))
		_stats_page.add_child(row)
	_stats_summary = _make_header("")
	_stats_page.add_child(_stats_summary)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(_make_button("ZURÜCK", _show_page.bind(_main)))
	row.add_child(_make_button("STANDARD", func():
		DebugSettings.reset_reserved()
		_refresh_stats_page()))
	_stats_page.add_child(row)
	_refresh_stats_page()

func _make_step_button(stat: String, step: int) -> Button:
	var button := _make_button("%+d" % step, func():
		DebugSettings.set_reserved(stat, DebugSettings.reserved(stat) + step)
		_refresh_stats_page())
	button.custom_minimum_size = STAT_STEP_SIZE
	return button

func _refresh_stats_page() -> void:
	for stat in DebugSettings.STATS:
		_stat_values[stat].text = "%d %%" % DebugSettings.reserved(stat)
	var total := DebugSettings.reserved_total()
	_stats_summary.text = "Reserviert: %d %%, üblicher Weg: %d %%. Bei %d BST: %d fest, %d werden wie gewohnt verteilt. Gilt sofort, auch im laufenden Run." % [
		total, 100 - total, STATS_EXAMPLE_BST, STATS_EXAMPLE_BST * total / 100, STATS_EXAMPLE_BST * (100 - total) / 100]

# ─────────────────────────
# Ei-Attacken

## Freischaltbare Ei-Attacken der Art, nach Herkunft: [[Überschrift, Skill-Namen], ...]
func _egg_skill_groups(mon_species: String) -> Array:
	var meta: Dictionary = Monmap.mon_metainfos_by_name(mon_species)
	return [
		["Fangen & Opfern", meta.get("unlockable_egg_skills", [])],
		["Meilensteine", meta.get("milestone_egg_skills", {}).values()],
		["Kopfgelder", meta.get("bounty_egg_skills", {}).values()],
	]

func _show_egg_skills(mon_species: String) -> void:
	_egg_species = mon_species
	for child in _egg_rows.get_children():
		_egg_rows.remove_child(child)
		child.queue_free()
	for group in _egg_skill_groups(mon_species):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := _make_header(group[0])
		label.custom_minimum_size.x = EGG_LABEL_WIDTH
		row.add_child(label)
		for skill_name in group[1]:
			row.add_child(_make_egg_skill_button(mon_species, skill_name))
		_egg_rows.add_child(row)

func _make_egg_skill_button(mon_species: String, skill_name: String) -> Button:
	var button := _make_toggle_button(tr(skill_name))
	button.custom_minimum_size = EGG_BUTTON_SIZE
	button.tooltip_text = Helper.skill_description(Skills.get_skill(skill_name))
	button.button_pressed = SaveManager.is_egg_skill_unlocked(mon_species, skill_name)
	button.toggled.connect(func(on: bool): _set_egg_skill(mon_species, skill_name, on))
	return button

func _set_egg_skill(mon_species: String, skill_name: String, unlocked: bool) -> void:
	if unlocked:
		SaveManager.unlock_egg_skill(mon_species, skill_name)
	else:
		SaveManager.lock_egg_skill(mon_species, skill_name)

func _set_species_unlocked(unlocked: bool) -> void:
	for group in _egg_skill_groups(_egg_species):
		for skill_name in group[1]:
			_set_egg_skill(_egg_species, skill_name, unlocked)
	_show_egg_skills(_egg_species)

func _unlock_all_species() -> void:
	for meta in Monmap.mons:
		for group in _egg_skill_groups(meta.name):
			for skill_name in group[1]:
				SaveManager.unlock_egg_skill(meta.name, skill_name)
	_show_egg_skills(_egg_species)
	Helper.show_unlock_message("Alle Ei-Attacken freigeschaltet")

# ─────────────────────────
# Judgement

func _start_judgement() -> void:
	var level: int = State.INITIAL_LEVEL
	for mon in State.mons:
		level = maxi(level, mon._level)
	for mon_species in _picked:
		# wie beim Fangen (catch_anim.gd)
		var mon := _wild_mon(mon_species, level)
		mon._initial_moves = Monster.BASE_MOVES
		State.catched_mons.append(mon)
		State.mark_mon_caught(mon_species)
	if _fallen_check.button_pressed:
		# ein neues Monster statt eines aus dem Team, das aktuelle Team bleibt unangetastet
		var fallen := _wild_mon(Monmap.mons.pick_random().name, level)
		fallen.add_gem("atk", FALLEN_GEM_BONUS)
		State.fainted_own_mons.append(fallen)
	_change_scene(JUDGEMENT_PATH)

## Wildes Monster einer bestimmten Art, immer mit Ei-Attacke (falls noch eine offen ist), damit Opfern möglich ist
func _wild_mon(mon_species: String, level: int) -> Monster:
	var meta: Dictionary = Monmap.mon_metainfos_by_name(mon_species)
	var mon := Monster.new(level, meta)
	mon._bounty = meta.get("bounty_target", "")
	Helper.add_biome_element(mon)
	Helper.roll_wild_skills(mon, meta)
	Helper.add_egg_skill(mon)
	mon.unlock_skills()
	return mon

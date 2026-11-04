extends HBoxContainer

## Aktuelles Team im Header der Karte: Bild, Name, Stufe und KP jedes eigenen Monsters.

const PORTRAIT_SIZE := Vector2(40, 40)
const BAR_SIZE := Vector2(150, 8)
const FONT_SIZE := 16
const HP_COLOR := Color(0.35, 0.8, 0.35)
const LOW_HP_COLOR := Color(0.9, 0.3, 0.25)
## darunter wird der Balken rot
const LOW_HP_SHARE := 0.3

## refresh ist schon für das Ende des Frames vorgemerkt (beim Heilen ändern sich die KP jeden Frame)
var _refresh_queued := false

func _ready() -> void:
	add_theme_constant_override("separation", 24)
	# KP ändern sich auch auf der Karte (Lager, Ereignisse), Elemente im Shop
	Events.deal_damage_to_monster.connect(_on_monster_changed)
	Events.refresh_ui_for_monster.connect(refresh)
	refresh()

func _exit_tree() -> void:
	Events.deal_damage_to_monster.disconnect(_on_monster_changed)
	Events.refresh_ui_for_monster.disconnect(refresh)

func _on_monster_changed(_mon) -> void:
	if not _refresh_queued:
		_refresh_queued = true
		refresh.call_deferred()

func refresh() -> void:
	_refresh_queued = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var title := Label.new()
	title.text = tr("MAP_HEADER_TEAM")
	title.add_theme_font_size_override("font_size", FONT_SIZE)
	add_child(title)
	for mon: Monster in State.mons:
		add_child(_entry(mon))

func _entry(mon: Monster) -> Control:
	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", 8)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = PORTRAIT_SIZE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = Monmap.texture(mon._name, PORTRAIT_SIZE.x)
	portrait.material = Monmap.LIVING_MATERIAL
	entry.add_child(portrait)

	var info := VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	entry.add_child(info)

	var name_label := Label.new()
	name_label.text = tr("MAP_TEAM_ENTRY").format({"name": Helper.mon_battle_name(mon), "level": mon._level})
	name_label.add_theme_font_size_override("font_size", FONT_SIZE)
	name_label.add_theme_color_override("font_color", Helper.color_by_mon(mon).lightened(0.4))
	info.add_child(name_label)

	var max_hp: float = mon.hp()
	var hp := clampf(max_hp - mon._lost_hp, 0.0, max_hp)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = BAR_SIZE
	bar.show_percentage = false
	bar.max_value = max_hp
	bar.value = hp
	var fill := StyleBoxFlat.new()
	fill.bg_color = LOW_HP_COLOR if hp < max_hp * LOW_HP_SHARE else HP_COLOR
	bar.add_theme_stylebox_override("fill", fill)
	info.add_child(bar)

	var hp_label := Label.new()
	hp_label.text = tr("MAP_TEAM_HP").format({"hp": roundi(hp), "max": roundi(max_hp)})
	hp_label.add_theme_font_size_override("font_size", FONT_SIZE - 3)
	info.add_child(hp_label)
	return entry

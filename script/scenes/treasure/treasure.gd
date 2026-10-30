extends Control

## Schatz: Gold oder ein Bonus-Preis, einer davon darf genommen werden.
## Der Bonus ist meist ein Edelstein, sonst ein Element-Trank oder selten ein gewöhnliches Relic.
## Edelstein und Trank werden danach einem eigenen Monster gegeben.

const GemField = preload("res://script/scenes/gems/gems.gd")

const CARD_SIZE := Vector2(240, 300)

## Gold: Grundbetrag plus Zuschlag pro Biom-Tiefe (State.map_level)
const GOLD_MIN := 20
const GOLD_MAX := 50
const GOLD_PER_DEPTH := 10

## Gewichte für den Bonus-Preis
const BONUS_WEIGHTS := {"gem": 60, "potion": 30, "relic": 10}

const ELEMENTS := [Enums.MON_TYPES.EARTH, Enums.MON_TYPES.AIR, Enums.MON_TYPES.WATER, Enums.MON_TYPES.FIRE]

var label_theme = preload("res://script/ui/materials/battle_labels.tres")
var card_box = preload("res://script/ui/materials/monster_widget_boxes.tres")
var gold_icon = preload("res://assets/ui/boss_shard/ChatGPT Image 26. Dez. 2025, 16_38_12.png")
var gem_icon = preload("res://assets/ui/boss_shard/a_rare_crystal_with_some_spark.jpeg")
var element_pill = preload("res://script/scenes/shop/element_pill.tscn")

@export var title: Label
@export var card_row: HBoxContainer

var _depth: int

func _ready() -> void:
	_depth = clampi(State.map_level, 0, GemField.BONUS_BY_DEPTH.size() - 1)
	var gold := randi_range(GOLD_MIN, GOLD_MAX) + _depth * GOLD_PER_DEPTH
	_add_card(tr("TREASURE_GOLD"), "$ " + str(gold), _texture_icon(gold_icon), tr("TREASURE_TAKE_GOLD"), _on_gold_chosen.bind(gold))
	_add_bonus_card()

func _on_gold_chosen(gold: int) -> void:
	State.ep += gold
	queue_free()

func _add_bonus_card() -> void:
	if State.mons.is_empty():
		return
	match _roll_bonus():
		"relic":
			var commons = Relics.get_unowned(Relics.Rarity.COMMON)
			if not commons.is_empty():
				_add_relic_card(commons.pick_random())
				return
		"potion":
			# nur Elemente, die noch mindestens einem Monster fehlen
			var elements = ELEMENTS.filter(func(e): return _mons_without(e).size() > 0)
			if not elements.is_empty():
				_add_potion_card(elements.pick_random())
				return
	# Fallback, falls kein passendes Relic oder Element übrig ist
	_add_gem_card(GemField.STATS.keys().pick_random())

func _roll_bonus() -> String:
	var total := 0
	for w in BONUS_WEIGHTS.values():
		total += w
	var roll := randi_range(1, total)
	for kind in BONUS_WEIGHTS:
		roll -= BONUS_WEIGHTS[kind]
		if roll <= 0:
			return kind
	return "gem"

# ── Edelstein ─────────────────────────

func _add_gem_card(stat: String) -> void:
	var bonus: float = GemField.BONUS_BY_DEPTH[_depth]
	var info: Dictionary = GemField.STATS[stat]
	var text = tr("GEM_DESC").format({"stat": tr(info.stat).trim_suffix(":"), "value": roundi(bonus * 100)})
	_add_card(tr(info.name), text, _texture_icon(gem_icon, info.color), tr("TREASURE_TAKE"), _on_gem_chosen.bind(stat, bonus))

func _on_gem_chosen(stat: String, bonus: float) -> void:
	_show_step(tr("GEM_CHOOSE_MON"))
	var info: Dictionary = GemField.STATS[stat]
	for mon: Monster in State.mons:
		var stat_name = tr(info.stat).trim_suffix(":")
		var text = "%s +%d%%\n%s" % [stat_name, roundi(bonus * 100), tr("GEM_CURRENT").format({"value": roundi((mon.gem_factor(stat) - 1.0) * 100)})]
		_add_card(Helper.mon_display_name(mon._name), text, _texture_icon(gem_icon, info.color), tr("GEM_GIVE"), _on_gem_given.bind(mon, stat, bonus))

func _on_gem_given(mon: Monster, stat: String, bonus: float) -> void:
	mon.add_gem(stat, bonus)
	queue_free()

# ── Element-Trank ─────────────────────────

func _add_potion_card(element: int) -> void:
	var element_name = tr(ColorMap.get_combo(element).label)
	var text = tr("TREASURE_POTION_DESC").format({"element": element_name})
	_add_card(tr("TREASURE_POTION").format({"element": element_name}), text, _potion_icon(element), tr("TREASURE_TAKE"), _on_potion_chosen.bind(element))

func _on_potion_chosen(element: int) -> void:
	_show_step(tr("TREASURE_POTION_CHOOSE_MON"))
	for mon: Monster in _mons_without(element):
		var new_type = ColorMap.add_element(mon._type, element)
		var text = "%s\n%s %s" % [tr(ColorMap.get_combo(mon._type).label), tr("SHOP_CHANGES_TO"), tr(ColorMap.get_combo(new_type).label)]
		_add_card(Helper.mon_display_name(mon._name), text, _potion_icon(new_type), tr("GEM_GIVE"), _on_potion_given.bind(mon, element))

func _on_potion_given(mon: Monster, element: int) -> void:
	mon._type = ColorMap.add_element(mon._type, element)
	queue_free()

func _mons_without(element: int) -> Array:
	return State.mons.filter(func(mon): return not ColorMap.has_element(mon._type, element))

# ── Relic ─────────────────────────

func _add_relic_card(id: String) -> void:
	var relic = Relics.get_relic(id)
	_add_card(tr(relic.name), tr(relic.description), _texture_icon(load(relic.icon)), tr("TREASURE_TAKE"), _on_relic_chosen.bind(id))

func _on_relic_chosen(id: String) -> void:
	Relics.add_relic(id)
	queue_free()

# ── Karten ─────────────────────────

## Schritt 2: Karten leeren, neue Überschrift
func _show_step(text: String) -> void:
	title.text = text
	for child in card_row.get_children():
		card_row.remove_child(child)
		child.queue_free()

func _texture_icon(texture: Texture2D, color: Color = Color.WHITE) -> Control:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.modulate = color
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

## Trank-Kugel aus dem Shop, ohne Preis und nicht ziehbar
func _potion_icon(type: int) -> Control:
	var pill = element_pill.instantiate()
	pill._init_pill(type)
	pill.money_label.visible = false
	pill.element_label.visible = false
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in pill.find_children("*", "Control", true, false):
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pill

func _add_card(card_title: String, text: String, icon: Control, button_text: String, on_pressed: Callable) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override("panel", card_box)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var label := Label.new()
	label.theme = label_theme
	label.text = card_title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)

	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(icon)

	var description := Label.new()
	description.text = text
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(description)

	var button := Button.new()
	button.theme = label_theme
	button.text = button_text
	button.pressed.connect(on_pressed)
	box.add_child(button)
	card_row.add_child(card)

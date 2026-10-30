extends Control

## Edelstein-Feld: drei Edelsteine zur Wahl, der gewählte erhöht einen Wert eines eigenen
## Monsters prozentual für den restlichen Run. Pro Biom-Tiefe werden die Steine stärker.

const GEM_CHOICES := 3
const CARD_SIZE := Vector2(240, 300)

## Stat-Key (siehe Monster.gem_factor) -> Anzeige
const STATS := {
	"hp": {"name": "GEM_HP", "stat": "STAT_HP", "color": Color(0.85, 0.25, 0.3)},
	"atk": {"name": "GEM_ATK", "stat": "STAT_ATK", "color": Color(0.95, 0.55, 0.2)},
	"def": {"name": "GEM_DEF", "stat": "STAT_DEF", "color": Color(0.6, 0.6, 0.65)},
	"s_atk": {"name": "GEM_S_ATK", "stat": "STAT_SPA", "color": Color(0.7, 0.35, 0.9)},
	"s_def": {"name": "GEM_S_DEF", "stat": "STAT_SPD", "color": Color(0.3, 0.55, 0.95)},
	"speed": {"name": "GEM_SPEED", "stat": "STAT_SPE", "color": Color(0.35, 0.85, 0.45)},
}

## Bonus pro Biom-Tiefe (State.map_level), 0.06 = +6 %
const BONUS_BY_DEPTH := [0.06, 0.08, 0.10, 0.12, 0.15]

var label_theme = preload("res://script/ui/materials/battle_labels.tres")
var card_box = preload("res://script/ui/materials/monster_widget_boxes.tres")
var gem_icon = preload("res://assets/ui/boss_shard/a_rare_crystal_with_some_spark.jpeg")

@export var title: Label
@export var card_row: HBoxContainer

var _bonus: float
var _chosen_stat := ""

func _ready() -> void:
	_bonus = BONUS_BY_DEPTH[clampi(State.map_level, 0, BONUS_BY_DEPTH.size() - 1)]
	var stats = STATS.keys()
	stats.shuffle()
	for stat in stats.slice(0, GEM_CHOICES):
		var info: Dictionary = STATS[stat]
		var text = tr("GEM_DESC").format({"stat": tr(info.stat).trim_suffix(":"), "value": roundi(_bonus * 100)})
		_add_card(tr(info.name), text, info.color, tr("GEM_TAKE"), _on_gem_chosen.bind(stat))

## Schritt 2: Monster wählen, das den Edelstein bekommt
func _on_gem_chosen(stat: String) -> void:
	_chosen_stat = stat
	title.text = tr("GEM_CHOOSE_MON")
	for child in card_row.get_children():
		card_row.remove_child(child)
		child.queue_free()
	for mon: Monster in State.mons:
		var stat_name = tr(STATS[stat].stat).trim_suffix(":")
		var text = "%s +%d%%\n%s" % [stat_name, roundi(_bonus * 100), tr("GEM_CURRENT").format({"value": roundi((mon.gem_factor(stat) - 1.0) * 100)})]
		_add_card(Helper.mon_display_name(mon._name), text, STATS[stat].color, tr("GEM_GIVE"), _on_mon_chosen.bind(mon))

func _on_mon_chosen(mon: Monster) -> void:
	mon.add_gem(_chosen_stat, _bonus)
	queue_free()

func _add_card(card_title: String, text: String, color: Color, button_text: String, on_pressed: Callable) -> void:
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

	var icon := TextureRect.new()
	icon.texture = gem_icon
	# Steine teilen sich ein Bild, die Farbe zeigt den Wert
	icon.modulate = color
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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

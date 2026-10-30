extends Control

## Relic-Auswahl nach einem Boss-Sieg (Boss-Feld oder Biom-Boss): bis zu RELIC_CHOICES
## noch nicht gesammelte Relics, eins davon darf genommen werden.

const RELIC_CHOICES := 3
const CARD_SIZE := Vector2(260, 340)

var label_theme = preload("res://script/ui/materials/battle_labels.tres")
var card_box = preload("res://script/ui/materials/monster_widget_boxes.tres")

@export var card_row: HBoxContainer

func _ready() -> void:
	State.pending_relic_reward = false
	var offered = Relics.get_unowned()
	offered.shuffle()
	for id in offered.slice(0, RELIC_CHOICES):
		card_row.add_child(_create_card(id))

func _create_card(id: String) -> Control:
	var relic = Relics.get_relic(id)
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

	var title := Label.new()
	title.theme = label_theme
	title.text = tr(relic.name)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var icon := TextureRect.new()
	icon.texture = load(relic.icon)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(icon)

	var description := Label.new()
	description.text = tr(relic.description)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(description)

	var button := Button.new()
	button.theme = label_theme
	button.text = tr("RELIC_REWARD_TAKE")
	button.pressed.connect(_on_relic_chosen.bind(id))
	box.add_child(button)
	return card

func _on_relic_chosen(id: String) -> void:
	Relics.add_relic(id)
	queue_free()

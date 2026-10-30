class_name RewardDialog
extends Control

## Gemeinsamer Belohnungs-Dialog über der Karte (Schatz, Edelstein-Feld, Relic-Belohnung):
## abgedunkelter Hintergrund, mittiges Panel mit Überschrift und einer Reihe Karten.
## Unterklassen setzen Titel und Karten, mehrstufige Auswahl läuft über clear_cards().
## Der Aufbau passiert in _init(), damit Unterklassen in _ready() direkt Karten anlegen können.

const CARD_SIZE := Vector2(230, 300)
const ICON_MIN_HEIGHT := 90
const BOX = preload("res://script/ui/materials/monster_widget_boxes.tres")
const LABEL_THEME = preload("res://script/ui/materials/battle_labels.tres")

var _panel: PanelContainer
var _title: Label
var _card_row: HBoxContainer

func _init() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	center.add_child(_panel)
	set_accent(BOX.border_color)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	_panel.add_child(box)
	_title = Label.new()
	_title.theme = LABEL_THEME
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_card_row = HBoxContainer.new()
	_card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_row.add_theme_constant_override("separation", 16)
	box.add_child(_card_row)

func set_title(text: String) -> void:
	_title.text = text

## Rahmenfarbe des Panels, unterscheidet die Belohnungsarten
func set_accent(color: Color) -> void:
	var style := BOX.duplicate() as StyleBoxFlat
	style.border_color = color
	style.set_content_margin_all(24)
	_panel.add_theme_stylebox_override("panel", style)

## Für den nächsten Schritt (z. B. Monster wählen): Karten leeren und neue Überschrift
func next_step(text: String) -> void:
	set_title(text)
	for child in _card_row.get_children():
		_card_row.remove_child(child)
		child.queue_free()

func close() -> void:
	queue_free()

static func texture_icon(texture: Texture2D, color: Color = Color.WHITE) -> Control:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.modulate = color
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

## Bild eines eigenen Monsters, für den Schritt "welches Monster bekommt es?"
static func mon_icon(mon: Monster) -> Control:
	return texture_icon(Monmap.mon_metainfos_by_name(mon._name).texture_front)

func add_card(card_title: String, text: String, icon: Control, button_text: String, on_pressed: Callable) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override("panel", BOX)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var label := Label.new()
	label.theme = LABEL_THEME
	label.text = card_title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# lange Namen nur an Wortgrenzen umbrechen
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(label)

	icon.custom_minimum_size.y = maxf(icon.custom_minimum_size.y, ICON_MIN_HEIGHT)
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(icon)

	var description := Label.new()
	description.text = text
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(description)

	var button := Button.new()
	button.theme = LABEL_THEME
	button.text = button_text
	button.pressed.connect(on_pressed)
	box.add_child(button)
	_card_row.add_child(card)

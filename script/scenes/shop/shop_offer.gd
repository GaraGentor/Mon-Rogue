extends PanelContainer

## Angebot im Shop (Edelstein oder Relic). Mit drag_data lässt es sich wie ein Element
## auf ein Monster ziehen (drop_panel.gd), sonst wird es über den Button gekauft.

signal buy_pressed

var label_theme = preload("res://script/ui/materials/battle_labels.tres")
var card_box = preload("res://script/ui/materials/monster_widget_boxes.tres")

var drag_data := {}
var _button: Button

func setup(title: String, text: String, icon: Texture2D, color: Color, cost: int, buyable_by_button: bool) -> void:
	custom_minimum_size = Vector2(150, 0)
	add_theme_stylebox_override("panel", card_box)
	tooltip_text = "%s\n%s" % [title, text]

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(box)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title_label)

	var texture := TextureRect.new()
	texture.texture = icon
	texture.modulate = color
	texture.custom_minimum_size = Vector2(0, 64)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Drag soll am Angebot selbst starten
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(texture)

	var text_label := Label.new()
	text_label.text = text
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text_label)

	var price := Label.new()
	price.theme = label_theme
	price.text = "$ " + str(cost)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(price)

	if buyable_by_button:
		_button = Button.new()
		_button.theme = label_theme
		_button.text = tr("SHOP_BUY")
		_button.pressed.connect(buy_pressed.emit)
		box.add_child(_button)

## Verkauft: ausgegraut, nicht mehr zieh- oder kaufbar
func mark_sold() -> void:
	drag_data = {}
	modulate = Color(1, 1, 1, 0.35)
	tooltip_text = tr("SHOP_SOLD")
	if _button:
		_button.disabled = true
		_button.text = tr("SHOP_SOLD")

func _get_drag_data(_at_position: Vector2):
	if drag_data.is_empty():
		return null
	var preview := Label.new()
	preview.text = tooltip_text
	set_drag_preview(preview)
	return drag_data

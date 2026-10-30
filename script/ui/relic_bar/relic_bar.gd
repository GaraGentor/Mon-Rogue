extends HBoxContainer

## Zeigt die gesammelten Relics als Icons, ein Klick öffnet ein Popup mit Name und Beschreibung.

const ICON_SIZE := Vector2(40, 40)

var _popup: PopupPanel
var _popup_label: RichTextLabel

func _ready() -> void:
	_popup = PopupPanel.new()
	_popup_label = RichTextLabel.new()
	_popup_label.bbcode_enabled = true
	_popup_label.fit_content = true
	_popup_label.custom_minimum_size = Vector2(260, 0)
	_popup.add_child(_popup_label)
	add_child(_popup)

	Relics.relics_changed.connect(refresh)
	refresh()

func _exit_tree() -> void:
	Relics.relics_changed.disconnect(refresh)

func refresh() -> void:
	for child in get_children():
		if child is Button:
			remove_child(child)
			child.queue_free()
	for id in State.relics:
		var relic = Relics.get_relic(id)
		var button := Button.new()
		button.custom_minimum_size = ICON_SIZE
		button.icon = load(relic.icon)
		button.expand_icon = true
		button.pressed.connect(_show_info.bind(button, relic))
		add_child(button)

func _show_info(button: Button, relic: Dictionary) -> void:
	_popup_label.text = "[b]%s[/b]\n%s" % [tr(relic.name), tr(relic.description)]
	var pos := Vector2i(button.get_screen_position() + Vector2(0, button.size.y + 4))
	_popup.popup(Rect2i(pos, Vector2i.ZERO))

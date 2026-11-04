extends Control

## Legende der Kartenfelder am rechten Rand. Ein Klick auf den Reiter fährt sie von rechts herein
## (und wieder hinaus), ein Klick auf einen Eintrag klappt darunter die ausführliche Beschreibung auf.

const PANEL_STYLE = preload("res://script/ui/materials/monster_widget_boxes.tres")
const LABEL_THEME = preload("res://script/ui/materials/battle_labels.tres")
const INFO_ICON = preload("res://assets/ui/icons/info.svg")

const PANEL_WIDTH := 340.0
## Abstand oben (unter dem Header der Karte) und unten
const TOP_OFFSET := 170.0
const BOTTOM_OFFSET := 16.0
const TAB_SIZE := Vector2(150, 48)
const ICON_SIZE := 36
const SLIDE_TIME := 0.35
const TITLE_SIZE := 28
const ENTRY_SIZE := 20
const DESCRIPTION_SIZE := 16
const OPEN_COLOR := Color(1.0, 0.85, 0.45)

## Panel samt Reiter, wird über die Offsets seitlich verschoben
var _slider: Control
var _open := false
var _tween: Tween
## Feldtyp -> {"button": Button, "description": Label}
var _entries := {}

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = LABEL_THEME

	_slider = Control.new()
	_slider.mouse_filter = MOUSE_FILTER_IGNORE
	_slider.anchor_left = 1.0
	_slider.anchor_right = 1.0
	_slider.anchor_bottom = 1.0
	_slider.offset_top = TOP_OFFSET
	_slider.offset_bottom = -BOTTOM_OFFSET
	add_child(_slider)
	_set_shift(0.0)

	var tab := Button.new()
	tab.text = tr("MAP_LEGEND")
	tab.icon = INFO_ICON
	tab.expand_icon = true
	tab.add_theme_constant_override("icon_max_width", 24)
	tab.add_theme_font_size_override("font_size", ENTRY_SIZE)
	tab.position = Vector2(-TAB_SIZE.x, 0)
	tab.size = TAB_SIZE
	# deckend, sonst scheinen die Pfadlinien der Karte durch
	var hover_style: StyleBoxFlat = PANEL_STYLE.duplicate()
	hover_style.border_color = OPEN_COLOR
	for state in ["normal", "pressed"]:
		tab.add_theme_stylebox_override(state, PANEL_STYLE)
	tab.add_theme_stylebox_override("hover", hover_style)
	tab.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	tab.pressed.connect(toggle)
	_slider.add_child(tab)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", PANEL_STYLE)
	panel.set_anchors_preset(PRESET_FULL_RECT)
	_slider.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = tr("MAP_LEGEND")
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	box.add_child(title)

	var hint := Label.new()
	hint.text = tr("MAP_LEGEND_HINT")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(1, 1, 1, 0.6)
	hint.add_theme_font_size_override("font_size", DESCRIPTION_SIZE)
	box.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	for type in Map.ICONS:
		_add_entry(list, type)

func _add_entry(list: VBoxContainer, type: Map.PATH_TYPE) -> void:
	var button := Button.new()
	button.flat = true
	button.text = tr(Map.type_label(type))
	button.icon = Map.icon(type)
	button.expand_icon = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, ICON_SIZE + 8)
	button.add_theme_constant_override("icon_max_width", ICON_SIZE)
	button.add_theme_constant_override("h_separation", 12)
	button.add_theme_font_size_override("font_size", ENTRY_SIZE)
	button.pressed.connect(_toggle_entry.bind(type))
	list.add_child(button)

	var description := Label.new()
	description.text = tr(Map.type_label(type) + "_DESC")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", DESCRIPTION_SIZE)
	description.size_flags_horizontal = SIZE_EXPAND_FILL

	var indent := MarginContainer.new()
	indent.add_theme_constant_override("margin_left", ICON_SIZE + 16)
	indent.add_theme_constant_override("margin_bottom", 8)
	indent.add_child(description)
	indent.visible = false
	list.add_child(indent)

	_entries[type] = {"button": button, "description": indent}

## Klappt die Beschreibung eines Eintrags auf, alle anderen zu (ein zweiter Klick schließt sie wieder)
func _toggle_entry(type: Map.PATH_TYPE) -> void:
	for other in _entries:
		var expand: bool = other == type and not _entries[other].description.visible
		_entries[other].description.visible = expand
		if expand:
			_entries[other].button.add_theme_color_override("font_color", OPEN_COLOR)
		else:
			_entries[other].button.remove_theme_color_override("font_color")

func toggle() -> void:
	_open = not _open
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_shift, _slider.offset_left, -PANEL_WIDTH if _open else 0.0, SLIDE_TIME)

## shift = 0: Panel ganz rechts außerhalb, nur der Reiter schaut heraus; -PANEL_WIDTH: ganz sichtbar
func _set_shift(shift: float) -> void:
	_slider.offset_left = shift
	_slider.offset_right = shift + PANEL_WIDTH

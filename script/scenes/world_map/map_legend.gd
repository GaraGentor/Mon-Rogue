extends Control

## Legende der Kartenfelder am rechten Rand. Der Pergament-Button im Header ruft toggle() auf und fährt
## sie von rechts herein (und wieder hinaus), ein Klick auf einen Eintrag klappt darunter die ausführliche Beschreibung auf.

const PAPER_SHADER := preload("res://script/scenes/world_map/map_paper.gdshader")
const LABEL_THEME = preload("res://script/ui/materials/battle_labels.tres")

const PANEL_WIDTH := 400.0
## Abstand der Papierkante zum Panelrand (im Shader Platz für den Schlagschatten)
const PAPER_MARGIN := 10.0
## Abstand des Inhalts zum Panelrand, damit er innerhalb des gezeichneten Doppelrahmens bleibt
const CONTENT_MARGIN := 46
## Eine Faltkante in der Mitte des Panels
const FOLD_SPACING := Vector2(PANEL_WIDTH / 2.0, 560.0)
const CONTOUR_AMOUNT := 0.3
## Abstand oben (unter dem Header der Karte) und unten
const TOP_OFFSET := 190.0
const BOTTOM_OFFSET := 16.0
const ICON_SIZE := 36
const SLIDE_TIME := 0.35
const TITLE_SIZE := 28
const ENTRY_SIZE := 20
const DESCRIPTION_SIZE := 16
## Immer das neutrale Pergament (MapBiomeTheme.FALLBACK), unabhängig vom aktuellen Biom
const INK_COLOR := Color(MapBiomeTheme.FALLBACK.ink)
const OPEN_COLOR := Color(0.62, 0.16, 0.07)
const HINT_ALPHA := 0.75

## Panel, wird über die Offsets seitlich verschoben
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

	_slider.add_child(_create_paper())

	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, CONTENT_MARGIN)
	_slider.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = tr("MAP_LEGEND")
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	title.add_theme_color_override("font_color", INK_COLOR)
	box.add_child(title)

	var hint := Label.new()
	hint.text = tr("MAP_LEGEND_HINT")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(INK_COLOR, HINT_ALPHA))
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

## Derselbe Shader wie das Kartenpapier, aber ohne Biom-Farben und Risse
func _create_paper() -> ColorRect:
	var look := MapBiomeTheme.FALLBACK
	var paper_material := ShaderMaterial.new()
	paper_material.shader = PAPER_SHADER
	paper_material.set_shader_parameter("paper_light", Color(look.paper_light))
	paper_material.set_shader_parameter("paper_dark", Color(look.paper_dark))
	paper_material.set_shader_parameter("ink", INK_COLOR)
	paper_material.set_shader_parameter("contour_amount", CONTOUR_AMOUNT)
	paper_material.set_shader_parameter("margin", PAPER_MARGIN)
	paper_material.set_shader_parameter("fold_spacing", FOLD_SPACING)

	var paper := ColorRect.new()
	paper.material = paper_material
	paper.mouse_filter = MOUSE_FILTER_STOP
	paper.set_anchors_preset(PRESET_FULL_RECT)
	paper.resized.connect(func(): paper_material.set_shader_parameter("rect_size", paper.size))
	return paper

func _set_button_color(button: Button, color: Color) -> void:
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, color)

func _add_entry(list: VBoxContainer, type: Map.PATH_TYPE) -> void:
	var button := Button.new()
	button.flat = true
	button.text = tr(Map.type_label(type))
	button.icon = Map.ICONS[type]
	button.expand_icon = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, ICON_SIZE + 8)
	button.add_theme_constant_override("icon_max_width", ICON_SIZE)
	button.add_theme_constant_override("h_separation", 12)
	button.add_theme_font_size_override("font_size", ENTRY_SIZE)
	_set_button_color(button, INK_COLOR)
	button.pressed.connect(_toggle_entry.bind(type))
	list.add_child(button)

	var description := Label.new()
	description.text = tr(Map.type_label(type) + "_DESC")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", DESCRIPTION_SIZE)
	description.add_theme_color_override("font_color", INK_COLOR)
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
		_set_button_color(_entries[other].button, OPEN_COLOR if expand else INK_COLOR)

func toggle() -> void:
	_open = not _open
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_shift, _slider.offset_left, -PANEL_WIDTH if _open else 0.0, SLIDE_TIME)

## shift = 0: Panel ganz rechts außerhalb; -PANEL_WIDTH: ganz sichtbar
func _set_shift(shift: float) -> void:
	_slider.offset_left = shift
	_slider.offset_right = shift + PANEL_WIDTH

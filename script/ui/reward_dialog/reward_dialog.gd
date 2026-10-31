class_name RewardDialog
extends Control

## Gemeinsamer Belohnungs-Dialog über der Karte (Schatz, Edelstein-Feld, Relic-Belohnung):
## abgedunkelter Hintergrund, mittiges Panel mit Überschrift. Links stehen die Preise untereinander,
## rechts erscheinen beim Ziehen eines Preises die Ziele: eigene Monster oder die Tasche.
## Ablegen auf einem Ziel bestätigt die Wahl, Fallenlassen woanders bricht ab.
## Der Aufbau passiert in _init(), damit Unterklassen in _ready() direkt Karten anlegen können.

const CARD_SIZE := Vector2(340, 110)
const ICON_SIZE := Vector2(90, 90)
const TARGET_SIZE := Vector2(120, 150)
const TARGET_COLUMNS := 3
const BOX = preload("res://script/ui/materials/monster_widget_boxes.tres")
const LABEL_THEME = preload("res://script/ui/materials/battle_labels.tres")
const BAG_ICON = preload("res://assets/ui/icons/bag.svg")
const HOVER_COLOR := Color(1.3, 1.3, 1.0)

## Preis auf der linken Seite, lässt sich auf die Ziele ziehen
class RewardCard extends PanelContainer:
	var dialog: RewardDialog
	var drag: Dictionary

	func _get_drag_data(_at_position: Vector2):
		var preview := PanelContainer.new()
		preview.add_theme_stylebox_override("panel", BOX)
		var label := Label.new()
		label.theme = LABEL_THEME
		label.text = drag.title
		preview.add_child(label)
		set_drag_preview(preview)
		dialog._show_targets(self)
		return drag

## Ziel auf der rechten Seite: ein Monster oder (mon == null) die Tasche
class DropTarget extends PanelContainer:
	var dialog: RewardDialog
	var mon: Monster

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return dialog._dragged != null and is_same(data, dialog._dragged.drag)

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if mon:
			data.on_drop.call(mon)
		else:
			data.on_drop.call()

var _panel: PanelContainer
var _title: Label
var _card_column: VBoxContainer
var _target_header: Label
var _target_grid: GridContainer
var _tooltip: PanelContainer
var _tooltip_label: Label
## gerade gezogene Karte, null wenn nichts gezogen wird
var _dragged: RewardCard

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

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 30)
	box.add_child(columns)
	_card_column = VBoxContainer.new()
	_card_column.add_theme_constant_override("separation", 12)
	columns.add_child(_card_column)

	# Breite für TARGET_COLUMNS Ziele freihalten, damit das Panel beim Ziehen nicht springt
	var target_side := VBoxContainer.new()
	target_side.add_theme_constant_override("separation", 12)
	target_side.custom_minimum_size.x = TARGET_COLUMNS * TARGET_SIZE.x + (TARGET_COLUMNS - 1) * 12
	columns.add_child(target_side)
	_target_header = Label.new()
	_target_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_side.add_child(_target_header)
	_target_grid = GridContainer.new()
	_target_grid.add_theme_constant_override("h_separation", 12)
	_target_grid.add_theme_constant_override("v_separation", 12)
	_target_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	target_side.add_child(_target_grid)

	# eigener Tooltip, weil Godot während eines Drags keine Tooltips zeigt
	_tooltip = PanelContainer.new()
	var tooltip_style := BOX.duplicate() as StyleBoxFlat
	tooltip_style.set_content_margin_all(10)
	_tooltip.add_theme_stylebox_override("panel", tooltip_style)
	_tooltip.top_level = true
	_tooltip.mouse_filter = MOUSE_FILTER_IGNORE
	_tooltip.visible = false
	_tooltip_label = Label.new()
	_tooltip.add_child(_tooltip_label)
	add_child(_tooltip)
	_hide_targets()

func set_title(text: String) -> void:
	_title.text = text

## Rahmenfarbe des Panels, unterscheidet die Belohnungsarten
func set_accent(color: Color) -> void:
	var style := BOX.duplicate() as StyleBoxFlat
	style.border_color = color
	style.set_content_margin_all(24)
	_panel.add_theme_stylebox_override("panel", style)

func close() -> void:
	queue_free()

static func texture_icon(texture: Texture2D, color: Color = Color.WHITE) -> Control:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.modulate = color
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

## Bild eines eigenen Monsters, als Ziel für Edelsteine und Tränke
static func mon_icon(mon: Monster) -> Control:
	return texture_icon(Monmap.mon_metainfos_by_name(mon._name).texture_front)

## Preis, der in die Tasche gezogen wird (Gold, Relic)
func add_bag_card(card_title: String, text: String, icon: Control, on_taken: Callable) -> void:
	_add_card(card_title, text, icon, {"header": tr("REWARD_BAG_HEADER"), "mons": [], "on_drop": on_taken})

## Preis, der auf eins der mons gezogen wird. on_given(mon) vergibt ihn,
## tooltip(mon) liefert den Text, der beim Drüberziehen erscheint.
func add_mon_card(card_title: String, text: String, icon: Control, header: String, mons: Array, on_given: Callable, tooltip: Callable) -> void:
	_add_card(card_title, text, icon, {"header": header, "mons": mons, "on_drop": on_given, "tooltip": tooltip})

func _add_card(card_title: String, text: String, icon: Control, drag: Dictionary) -> void:
	var card := RewardCard.new()
	card.dialog = self
	drag.title = card_title
	card.drag = drag
	card.custom_minimum_size = CARD_SIZE
	card.mouse_default_cursor_shape = Control.CURSOR_DRAG
	card.add_theme_stylebox_override("panel", BOX)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	icon.custom_minimum_size = ICON_SIZE
	row.add_child(icon)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(box)
	var label := Label.new()
	label.theme = LABEL_THEME
	label.text = card_title
	# lange Namen nur an Wortgrenzen umbrechen
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(label)
	var description := Label.new()
	description.text = text
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)

	_ignore_mouse_below(card)
	_card_column.add_child(card)

func _add_target(target_title: String, icon: Control, mon: Monster) -> void:
	var target := DropTarget.new()
	target.dialog = self
	target.mon = mon
	target.custom_minimum_size = TARGET_SIZE
	target.add_theme_stylebox_override("panel", BOX)

	var box := VBoxContainer.new()
	target.add_child(box)
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(icon)
	var label := Label.new()
	label.text = target_title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(label)

	_ignore_mouse_below(target)
	_target_grid.add_child(target)

## Kinder sollen weder Drag noch Drop abfangen, das macht die Karte bzw. das Ziel selbst
static func _ignore_mouse_below(control: Control) -> void:
	for child in control.find_children("*", "Control", true, false):
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _show_targets(card: RewardCard) -> void:
	_clear_targets()
	_dragged = card
	card.modulate.a = 0.4
	_target_header.text = card.drag.header
	if card.drag.mons.is_empty():
		_target_grid.columns = 1
		_add_target(tr("REWARD_BAG"), texture_icon(BAG_ICON), null)
		return
	_target_grid.columns = mini(card.drag.mons.size(), TARGET_COLUMNS)
	for mon: Monster in card.drag.mons:
		_add_target(Helper.mon_display_name(mon._name), mon_icon(mon), mon)

func _hide_targets() -> void:
	_clear_targets()
	_target_header.text = tr("REWARD_DRAG_HINT")
	_tooltip.visible = false
	if _dragged:
		_dragged.modulate.a = 1.0
		_dragged = null

func _clear_targets() -> void:
	for child in _target_grid.get_children():
		_target_grid.remove_child(child)
		child.queue_free()

func _notification(what: int) -> void:
	# Drop auf ein Ziel oder Fallenlassen woanders (= Abbruch)
	if what == NOTIFICATION_DRAG_END and is_node_ready():
		_hide_targets()

func _process(_delta: float) -> void:
	if _dragged == null:
		return
	# Ziel unter dem gezogenen Preis hervorheben und seinen Tooltip zeigen
	var mouse := get_global_mouse_position()
	var hovered: DropTarget = null
	for target: DropTarget in _target_grid.get_children():
		var over := target.get_global_rect().has_point(mouse)
		target.modulate = HOVER_COLOR if over else Color.WHITE
		if over:
			hovered = target
	var tooltip: Callable = _dragged.drag.get("tooltip", Callable())
	_tooltip.visible = hovered != null and hovered.mon != null and tooltip.is_valid()
	if _tooltip.visible:
		_tooltip_label.text = tooltip.call(hovered.mon)
		_tooltip.reset_size()
		var rect := hovered.get_global_rect()
		var pos := Vector2(rect.get_center().x - _tooltip.size.x / 2, rect.end.y + 8)
		_tooltip.global_position = pos.clamp(Vector2.ZERO, get_viewport_rect().size - _tooltip.size)

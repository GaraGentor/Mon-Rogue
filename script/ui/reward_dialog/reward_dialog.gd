class_name RewardDialog
extends Control

## Gemeinsamer Belohnungs-Dialog über der Karte (Schatz, Edelstein-Feld, Relic-Belohnung, Shop):
## abgedunkelter Hintergrund, mittiges Panel mit Überschrift. Links stehen die Preise,
## rechts erscheinen beim Ziehen eines Preises die Ziele: eigene Monster oder die Tasche.
## Ablegen auf einem Ziel bestätigt die Wahl, Fallenlassen woanders bricht ab.
## Standardmäßig schließt der Dialog nach der ersten Wahl, Unterklassen (Shop) können das über
## _taken() und _drag_blocked() ändern.
## Der Aufbau passiert in _init(), damit Unterklassen in _ready() direkt Karten anlegen können.

const CARD_SIZE := Vector2(340, 110)
const ICON_SIZE := Vector2(90, 90)
## vertikale Karten: kleineres Bild und Titel, damit zwei Reihen auf den Bildschirm passen
const VERTICAL_ICON_SIZE := Vector2(72, 72)
const VERTICAL_TITLE_FONT_SIZE := 22
const TARGET_SIZE := Vector2(120, 150)
## so viele Monster passen ins Team (judgement.gd MAX_TEAM)
const TARGET_COLUMNS := 2
## Tasche im Szenen-Layout (use_scene_layout)
const BAG_FILL_SIZE := Vector2(220, 260)
const BOX = preload("res://script/ui/materials/monster_widget_boxes.tres")
const LABEL_THEME = preload("res://script/ui/materials/battle_labels.tres")
const BAG_ICON = preload("res://assets/ui/icons/bag.svg")
const HOVER_COLOR := Color(1.3, 1.3, 1.0)
const SOLD_ALPHA := 0.35

## Preis auf der linken Seite, lässt sich auf die Ziele ziehen
class RewardCard extends PanelContainer:
	var dialog: RewardDialog
	var drag: Dictionary
	## Icon und Text, nebeneinander oder (vertikale Karten) untereinander
	var row: BoxContainer
	## Titel und Beschreibung, Unterklassen können dazwischen etwas einfügen (insert_detail)
	var info: VBoxContainer
	var sold := false

	## Zeile direkt unter dem Titel, z. B. der Preis im Shop
	func insert_detail(control: Control) -> void:
		info.add_child(control)
		info.move_child(control, 1)

	func _get_drag_data(_at_position: Vector2):
		if sold:
			return null
		var reason := dialog._drag_blocked(self)
		if reason != "":
			dialog._target_header.text = reason
			return null
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
		var card := dialog._dragged
		if mon:
			data.on_drop.call(mon)
		else:
			data.on_drop.call()
		dialog._taken(card)

var _dim: ColorRect
var _center: CenterContainer
var _panel: PanelContainer
var _title: Label
var _content: VBoxContainer
var _columns: HBoxContainer
## Spalte mit den Kartengruppen, neue Karten landen immer in der letzten Gruppe
var _card_groups: VBoxContainer
var _card_grid: GridContainer
var _card_columns := 1
var _target_side: VBoxContainer
var _target_header: Label
var _target_grid: GridContainer
var _tooltip: PanelContainer
var _tooltip_label: Label
## gerade gezogene Karte, null wenn nichts gezogen wird
var _dragged: RewardCard
var _drag_hint := "REWARD_DRAG_HINT"
var _card_size := CARD_SIZE
## Bild oben, Text darunter statt Bild links (Shop)
var _vertical_cards := false
## Szenen-Layout (Shop): Ziele füllen die ganze rechte Seite statt fester Kästchen
var _fill_targets := false

func _init() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.7)
	_dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_dim)
	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_center)
	_panel = PanelContainer.new()
	_center.add_child(_panel)
	set_accent(BOX.border_color)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 20)
	_panel.add_child(_content)
	_title = Label.new()
	_title.theme = LABEL_THEME
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_title)

	_columns = HBoxContainer.new()
	_columns.add_theme_constant_override("separation", 30)
	_content.add_child(_columns)
	_card_groups = VBoxContainer.new()
	_card_groups.add_theme_constant_override("separation", 30)
	_columns.add_child(_card_groups)
	new_card_group()

	# Breite für TARGET_COLUMNS Ziele freihalten, damit das Panel beim Ziehen nicht springt
	_target_side = VBoxContainer.new()
	_target_side.add_theme_constant_override("separation", 12)
	_target_side.custom_minimum_size.x = TARGET_COLUMNS * TARGET_SIZE.x + (TARGET_COLUMNS - 1) * 12
	_columns.add_child(_target_side)
	_target_header = Label.new()
	_target_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_target_side.add_child(_target_header)
	_target_grid = GridContainer.new()
	_target_grid.add_theme_constant_override("h_separation", 12)
	_target_grid.add_theme_constant_override("v_separation", 12)
	_target_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_target_side.add_child(_target_grid)

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

## Wie viele Preise nebeneinander stehen (der Shop hat mehr Ware, als in eine Spalte passt).
## vertical: Bild oben, Text darunter. Gilt für Karten, die danach angelegt werden.
func set_card_layout(columns: int, card_size: Vector2, vertical := false) -> void:
	_card_columns = columns
	_card_grid.columns = columns
	_card_size = card_size
	_vertical_cards = vertical

## Neue Kartengruppe (eigenes Grid mit Abstand), z. B. eine pro Warenart im Shop
func new_card_group() -> void:
	_card_grid = GridContainer.new()
	_card_grid.columns = _card_columns
	_card_grid.add_theme_constant_override("h_separation", 12)
	_card_grid.add_theme_constant_override("v_separation", 12)
	_card_groups.add_child(_card_grid)

## Eigene Szene statt Overlay über der Karte: background ersetzt die Abdunklung, das Panel füllt
## den Bildschirm ohne Rahmen und die Ziele nehmen den ganzen Platz rechts ein
func use_scene_layout(background: Control) -> void:
	_dim.queue_free()
	move_child(background, 0)
	_center.remove_child(_panel)
	_center.queue_free()
	add_child(_panel)
	move_child(_panel, 1)
	_panel.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var style := StyleBoxEmpty.new()
	style.set_content_margin_all(24)
	_panel.add_theme_stylebox_override("panel", style)
	_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_target_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fill_targets = true

## Text rechts, solange nichts gezogen wird (Übersetzungs-Key)
func set_drag_hint(key: String) -> void:
	_drag_hint = key
	if _dragged == null:
		_target_header.text = tr(key)

## Zeile unter Preisen und Zielen, z. B. Geld und Fertig-Button im Shop
func add_footer(control: Control) -> void:
	_content.add_child(control)

func close() -> void:
	queue_free()

## Nach einer Wahl: standardmäßig ist der Dialog damit fertig
func _taken(_card: RewardCard) -> void:
	close()

## Grund, warum die Karte gerade nicht gezogen werden darf ("" = darf gezogen werden)
func _drag_blocked(_card: RewardCard) -> String:
	return ""

## Ausgegraut und nicht mehr ziehbar
func mark_sold(card: RewardCard) -> void:
	card.sold = true
	card.modulate.a = SOLD_ALPHA
	card.mouse_default_cursor_shape = Control.CURSOR_ARROW

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
func add_bag_card(card_title: String, text: String, icon: Control, on_taken: Callable) -> RewardCard:
	return _add_card(card_title, text, icon, {"header": tr("REWARD_BAG_HEADER"), "bag": true, "on_drop": on_taken})

## Preis, der auf eins der mons gezogen wird. on_given(mon) vergibt ihn,
## tooltip(mon) liefert den Text, der beim Drüberziehen erscheint.
## mons darf auch ein Callable sein, dann wird die Liste erst beim Ziehen bestimmt
## (im Shop ändert sich nach einem Kauf, wer einen Trank noch trinken kann).
func add_mon_card(card_title: String, text: String, icon: Control, header: String, mons: Variant, on_given: Callable, tooltip: Callable) -> RewardCard:
	return _add_card(card_title, text, icon, {"header": header, "mons": mons, "on_drop": on_given, "tooltip": tooltip})

func _add_card(card_title: String, text: String, icon: Control, drag: Dictionary) -> RewardCard:
	var card := RewardCard.new()
	card.dialog = self
	drag.title = card_title
	card.drag = drag
	card.custom_minimum_size = _card_size
	card.mouse_default_cursor_shape = Control.CURSOR_DRAG
	card.add_theme_stylebox_override("panel", BOX)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	card.add_child(margin)

	card.row = VBoxContainer.new() if _vertical_cards else HBoxContainer.new()
	card.row.add_theme_constant_override("separation", 8 if _vertical_cards else 12)
	margin.add_child(card.row)
	icon.custom_minimum_size = VERTICAL_ICON_SIZE if _vertical_cards else ICON_SIZE
	card.row.add_child(icon)

	card.info = VBoxContainer.new()
	card.info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.info.alignment = BoxContainer.ALIGNMENT_BEGIN if _vertical_cards else BoxContainer.ALIGNMENT_CENTER
	card.row.add_child(card.info)
	var label := Label.new()
	label.theme = LABEL_THEME
	label.text = card_title
	# lange Namen nur an Wortgrenzen umbrechen
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.info.add_child(label)
	var description := Label.new()
	description.text = text
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.info.add_child(description)
	if _vertical_cards:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", VERTICAL_TITLE_FONT_SIZE)
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	ignore_mouse_below(card)
	_card_grid.add_child(card)
	return card

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

	ignore_mouse_below(target)
	_target_grid.add_child(target)

## Kinder sollen weder Drag noch Drop abfangen, das macht die Karte bzw. das Ziel selbst
static func ignore_mouse_below(control: Control) -> void:
	for child in control.find_children("*", "Control", true, false):
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _show_targets(card: RewardCard) -> void:
	_clear_targets()
	_dragged = card
	card.modulate.a = 0.4
	_target_header.text = card.drag.header
	if card.drag.get("bag", false):
		_target_grid.columns = 1
		_add_target(tr("REWARD_BAG"), texture_icon(BAG_ICON), null)
		if _fill_targets:
			# Tasche mittig im Platz unter der Überschrift, nicht gestreckt
			_target_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			_target_grid.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
			_target_grid.get_child(0).custom_minimum_size = BAG_FILL_SIZE
		return
	var mons: Array = card.drag.mons.call() if card.drag.mons is Callable else card.drag.mons
	if mons.is_empty():
		_target_header.text = tr("REWARD_NO_TARGET")
		return
	_target_grid.columns = 1 if _fill_targets else mini(mons.size(), TARGET_COLUMNS)
	for mon: Monster in mons:
		_add_target(Helper.mon_display_name(mon._name), mon_icon(mon), mon)
	if _fill_targets:
		# Monster übereinander, zusammen so groß wie die ganze rechte Seite
		_target_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_target_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		for target: Control in _target_grid.get_children():
			target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			target.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _hide_targets() -> void:
	_clear_targets()
	_target_header.text = tr(_drag_hint)
	_tooltip.visible = false
	if _dragged:
		_dragged.modulate.a = SOLD_ALPHA if _dragged.sold else 1.0
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

extends Control

## Nach dem Kampf: links die Monster untereinander mit ihrem Level-Up, rechts das Schlachtfeld mit der Tasche
## und der zufällig verstreuten Beute. Beute gibt es nur, wenn man sie in die Tasche zieht; was liegen bleibt, ist beim Weitergehen weg.

const ESSENCE_ICON = preload("res://assets/ui/icons/monster_essence.svg")
const KEY_ICON = preload("res://assets/ui/icons/key.svg")
const CHEST_ICON = preload("res://assets/ui/rewards/reward_chest.png")
const BAG_SIZE := Vector2(208, 196)
const BAG_FONT_SIZE := 19
const FIELD_MARGIN := 16
## so weit bleibt die Beute vom Bildrand weg, dort liegt der Wolkenrand
const LOOT_EDGE_MARGIN := 60.0
## Abstand der Beute zu allem, was schon auf dem Feld liegt
const LOOT_GAP := 16.0
const LOOT_PLACE_TRIES := 60

## Stück Beute auf dem Schlachtfeld, lässt sich in die Tasche ziehen
class LootIcon extends VBoxContainer:
	const ICON_SIZE := Vector2(84, 84)
	const FONT_SIZE := 20

	signal drag_started

	## wird beim Ablegen in der Tasche aufgerufen
	var on_taken: Callable
	var _art: TextureRect

	func _init(texture: Texture2D, text: String) -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_DRAG
		# die Mitte sitzt auf dem Ankerpunkt, den _scatter_loot setzt
		grow_horizontal = Control.GROW_DIRECTION_BOTH
		grow_vertical = Control.GROW_DIRECTION_BOTH
		_art = RewardDialog.texture_icon(texture) as TextureRect
		_art.custom_minimum_size = ICON_SIZE
		var art_material: ShaderMaterial = RewardDialog.ICON_BUTTON_MATERIAL.duplicate()
		art_material.set_shader_parameter("outline_color", SkillDetailPopup.GOLD)
		_art.material = art_material
		add_child(_art)
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.add_theme_color_override("font_color", SkillDetailPopup.GOLD)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 6)
		add_child(label)
		RewardDialog.ignore_mouse_below(self)

	func _get_drag_data(_at_position: Vector2):
		var art: Control = _art.duplicate(0)
		art.size = ICON_SIZE
		art.position = -ICON_SIZE / 2
		var holder := Control.new()
		holder.add_child(art)
		set_drag_preview(holder)
		modulate.a = 0.4
		drag_started.emit()
		return self

## Tasche auf dem Schlachtfeld, Ablegeziel für die Beute. Auf der Plakette steht das Geld.
class LootBag extends Control:
	var art: OpenBag
	var _pop: Tween

	func _init() -> void:
		custom_minimum_size = BAG_SIZE
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		size_flags_vertical = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
		pivot_offset = Vector2(BAG_SIZE.x / 2, BAG_SIZE.y)
		art = OpenBag.new(BAG_SIZE, null, Vector2.ZERO, BAG_FONT_SIZE)
		add_child(art)

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is LootIcon

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		data.on_taken.call()
		if _pop:
			_pop.kill()
		scale = Vector2(1.15, 0.85)
		_pop = create_tween()
		_pop.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

var debug=false
var debug_mons=2

@export var monster_scene1: Control
@export var monster_scene2: Control
## hält bei nur einem Monster den Platz des zweiten frei, damit die Karte nur die halbe Höhe nimmt
@export var empty_slot: Control

@export var go_button: Button
## Bild des Schlachtfelds aus der Szene, darauf liegen Tasche und Beute
@export var battlefield: Control
@export var battlefield_image: TextureRect

var _bag: LootBag
var _hint_panel: PanelContainer
## freie Fläche über dem ganzen Bild, darauf liegt die Beute verstreut
var _loot_field: Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if State.killed_monsters == 0:
	#	get_tree().change_scene_to_file("res://script/scenes/world_map/world_map.tscn")
	#	return
	if debug:
		for dm in debug_mons:
			var mon:Monster = Helper.generate_mons({"count": 1, "level": randi_range(10,30)})[0]
			mon._level_progress = randi_range(0,1)
			State.mons.append(mon)
			State.killed_monsters = 5
	monster_scene1.init_with_mon(State.mons[0])
	if State.mons.size() == 2:
		monster_scene2.init_with_mon(State.mons[1])
		monster_scene2.visible = true
	empty_slot.visible = not monster_scene2.visible
	battlefield_image.resized.connect(_update_cloud_size)
	_update_cloud_size()
	_build_battlefield()
	_start()

## Der Wolkenrand rechnet in Pixeln und braucht dafür die Größe des Bildes
func _update_cloud_size() -> void:
	battlefield_image.material.set_shader_parameter("rect_size", battlefield_image.size)

func _start() -> void:
	for killed in State.killed_monsters:
		State.killed_monsters -= 1
		if monster_scene1.mon:
			await monster_scene1._play()
		if monster_scene2.mon:
			await monster_scene2._play()
	go_button.disabled = false

## Oben der Hinweis, unten die Tasche, darüber die verstreute Beute
func _build_battlefield() -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, FIELD_MARGIN)
	battlefield.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)

	_hint_panel = PanelContainer.new()
	_hint_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint := Label.new()
	hint.text = tr("LEVEL_UP_LOOT_HINT")
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", IronPlate.TEXT_COLOR)
	IronPlate.frame(_hint_panel, hint, 12, 8)
	column.add_child(_hint_panel)

	_loot_field = Control.new()
	_loot_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loot_field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battlefield.add_child(_loot_field)

	_bag = LootBag.new()
	column.add_child(_bag)
	State.ep_changed.connect(_show_money)
	_show_money(State.ep)

	if State.pending_ep > 0:
		_add_loot(ESSENCE_ICON, Helper.me_text(State.pending_ep), _take_essence)
	if State.pending_keys > 0:
		_add_loot(KEY_ICON, tr("KEY_LOOT_AMOUNT").format({"amount": State.pending_keys}), _take_keys)
	if State.pending_relic_chest:
		_add_loot(CHEST_ICON, tr("RELIC_CHEST_LOOT"), _take_relic_chest)
	_hint_panel.visible = _loot_field.get_child_count() > 0
	_scatter_loot()

func _add_loot(texture: Texture2D, text: String, on_taken: Callable) -> void:
	var loot := LootIcon.new(texture, text)
	loot.on_taken = func():
		on_taken.call()
		_loot_field.remove_child(loot)
		loot.queue_free()
		_hint_panel.visible = _loot_field.get_child_count() > 0
	loot.drag_started.connect(_bag.art.set_gold.bind(true))
	_loot_field.add_child(loot)

## Verteilt die Beute zufällig auf dem Bild, frei von Hinweis, Tasche und anderer Beute.
## Bis dahin unsichtbar, denn deren Größen stehen erst nach dem ersten Layout fest.
func _scatter_loot() -> void:
	_loot_field.modulate.a = 0.0
	await get_tree().process_frame
	var area := Rect2(Vector2.ZERO, _loot_field.size).grow(-LOOT_EDGE_MARGIN)
	var taken: Array[Rect2] = []
	for blocker: Control in [_hint_panel, _bag]:
		taken.append(Rect2(blocker.global_position - _loot_field.global_position, blocker.size).grow(LOOT_GAP))
	for loot: LootIcon in _loot_field.get_children():
		var rect := _free_spot(area, loot.get_combined_minimum_size(), taken)
		taken.append(rect.grow(LOOT_GAP))
		# Anteil statt Pixel: bleibt passend, wenn sich die Fläche ändert
		var center := rect.get_center() / _loot_field.size
		for side in [SIDE_LEFT, SIDE_RIGHT]:
			loot.set_anchor_and_offset(side, center.x, 0.0, true)
		for side in [SIDE_TOP, SIDE_BOTTOM]:
			loot.set_anchor_and_offset(side, center.y, 0.0, true)
	_loot_field.modulate.a = 1.0

## Zufällige Stelle ohne Überschneidung; ist nach allen Versuchen keine frei, bleibt es beim letzten
func _free_spot(area: Rect2, spot_size: Vector2, taken: Array[Rect2]) -> Rect2:
	var rect := Rect2(area.position, spot_size)
	for i in LOOT_PLACE_TRIES:
		rect.position = Vector2(
			randf_range(area.position.x, area.end.x - spot_size.x),
			randf_range(area.position.y, area.end.y - spot_size.y))
		if not taken.any(func(other: Rect2): return other.intersects(rect)):
			break
	return rect

func _take_essence() -> void:
	State.ep += State.pending_ep
	State.pending_ep = 0

func _take_keys() -> void:
	State.keys += State.pending_keys
	State.pending_keys = 0

## Die Relic-Auswahl erscheint beim nächsten Betreten der Karte (world_map.gd)
func _take_relic_chest() -> void:
	State.pending_relic_chest = false
	State.pending_relic_reward = true

func _show_money(ep: int) -> void:
	_bag.art.label.text = str(ep)

## Ablegen in der Tasche oder Fallenlassen woanders (dann bleibt die Beute liegen)
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _bag != null:
		_bag.art.set_gold(false)
		for loot in _loot_field.get_children():
			loot.modulate.a = 1.0

func _on_button_pressed() -> void:
	# was nicht in der Tasche liegt, bleibt auf dem Schlachtfeld
	State.pending_ep = 0
	State.pending_keys = 0
	State.pending_relic_chest = false
	get_tree().change_scene_to_file("res://script/scenes/world_map/world_map.tscn")

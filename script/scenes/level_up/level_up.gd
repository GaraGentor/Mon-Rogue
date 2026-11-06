extends Control

## Nach dem Kampf: links die Monster untereinander mit ihrem Level-Up, rechts das Schlachtfeld mit der Tasche
## und der Beute. Beute gibt es nur, wenn man sie in die Tasche zieht; was liegen bleibt, ist beim Weitergehen weg.

const ESSENCE_ICON = preload("res://assets/ui/icons/monster_essence.svg")
const BAG_SIZE := Vector2(208, 196)
const BAG_FONT_SIZE := 19
const FIELD_MARGIN := 16

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
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
		size_flags_vertical = Control.SIZE_SHRINK_END
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

@export var go_button: Button
## Bild des Schlachtfelds aus der Szene, darauf liegen Tasche und Beute
@export var battlefield: Control

var _bag: LootBag
var _hint_panel: PanelContainer
var _loot_row: HBoxContainer

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
	_build_battlefield()
	_start()

func _start() -> void:
	for killed in State.killed_monsters:
		State.killed_monsters -= 1
		if monster_scene1.mon:
			await monster_scene1._play()
		if monster_scene2.mon:
			await monster_scene2._play()
	go_button.disabled = false

## Von oben nach unten: Hinweis, Beute, Tasche
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

	_loot_row = HBoxContainer.new()
	_loot_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_loot_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_loot_row)

	_bag = LootBag.new()
	column.add_child(_bag)
	State.ep_changed.connect(_show_money)
	_show_money(State.ep)

	if State.pending_ep > 0:
		_add_loot(ESSENCE_ICON, Helper.me_text(State.pending_ep), _take_essence)
	_hint_panel.visible = _loot_row.get_child_count() > 0

func _add_loot(texture: Texture2D, text: String, on_taken: Callable) -> void:
	var loot := LootIcon.new(texture, text)
	loot.on_taken = func():
		on_taken.call()
		_loot_row.remove_child(loot)
		loot.queue_free()
		_hint_panel.visible = _loot_row.get_child_count() > 0
	loot.drag_started.connect(_bag.art.set_gold.bind(true))
	_loot_row.add_child(loot)

func _take_essence() -> void:
	State.ep += State.pending_ep
	State.pending_ep = 0

func _show_money(ep: int) -> void:
	_bag.art.label.text = str(ep)

## Ablegen in der Tasche oder Fallenlassen woanders (dann bleibt die Beute liegen)
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _bag != null:
		_bag.art.set_gold(false)
		for loot in _loot_row.get_children():
			loot.modulate.a = 1.0

func _on_button_pressed() -> void:
	# was nicht in der Tasche liegt, bleibt auf dem Schlachtfeld
	State.pending_ep = 0
	get_tree().change_scene_to_file("res://script/scenes/world_map/world_map.tscn")

extends Control

## Heilungs-Camp: in der Mitte das Lagerfeuer, links und rechts davon die eigenen Monster.
## Vor dem Ausruhen kann man Essenz aus der Tasche vor dem Feuer in die Flammen ziehen, das heilt zusätzlich.
## Beim Ausruhen steht die Szene kurz still, dann steigen die Lebensanzeigen auf den geheilten Stand,
## während kleine Herzen in einem großen Bogen aus dem Feuer auf die Monster fliegen.

## Stapel Essenz neben der Tasche, lässt sich ins Feuer ziehen
class GoldStack extends VBoxContainer:
	const ART_SIZE := Vector2(64, 64)
	const COIN_SIZE := Vector2(40, 40)
	const FONT_SIZE := 20

	var camp: Node
	var amount: int
	var _art: Control

	func _init(owner_camp: Node, gold: int, coins: int) -> void:
		camp = owner_camp
		amount = gold
		alignment = BoxContainer.ALIGNMENT_END
		add_theme_constant_override("separation", 0)
		_art = Control.new()
		_art.custom_minimum_size = ART_SIZE
		for i in coins:
			var coin := RewardDialog.texture_icon(ESSENCE_ICON)
			coin.material = PROPS_MATERIAL
			coin.size = COIN_SIZE
			# Münzen türmen sich von unten nach oben auf
			coin.position = Vector2((ART_SIZE.x - COIN_SIZE.x) / 2 + (i % 2) * 6.0 - 3.0, ART_SIZE.y - COIN_SIZE.y - i * 6.0)
			_art.add_child(coin)
		add_child(_art)
		var label := Label.new()
		label.text = Helper.me_text(gold)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.add_theme_color_override("font_color", SkillDetailPopup.GOLD)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 6)
		add_child(label)
		RewardDialog.ignore_mouse_below(self)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _get_drag_data(_at_position: Vector2):
		var reason: String = camp.feed_blocked(amount)
		if reason != "":
			camp.show_hint(reason)
			return null
		var art: Control = _art.duplicate()
		art.position = -ART_SIZE / 2
		var holder := Control.new()
		holder.add_child(art)
		set_drag_preview(holder)
		return self

## Fläche über dem Feuer, Ablegeziel für die Essenz
class FeedTarget extends Control:
	var camp: Node

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is GoldStack

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		camp.feed(data.amount)

const CAMP_MONSTER = preload("res://script/scenes/heal_camp/camp_monster.tscn")
const HEART_TEXTURE = preload("res://assets/ui/icons/heart.svg")
const PROPS_MATERIAL = preload("res://script/scenes/jailer/jailer_props_material.tres")
const ESSENCE_ICON = preload("res://assets/ui/icons/monster_essence.svg")
## Lebenspunkte pro Monster, die eine Essenz im Feuer bringt
const HP_PER_GOLD := 5
## Größe der Stapel neben der Tasche -> so viele Münzen zeigt der Stapel
const GOLD_STACKS := {1: 1, 5: 3, 10: 5}
const BAG_SIZE := Vector2(150, 142)
const BAG_ITEM_SIZE := Vector2(40, 40)
const BAG_FONT_SIZE := 22
## so viel Essenz steht für ein sichtbares Stück in der Tasche
const ESSENCE_PER_ITEM := 25
const FEED_POP_SECONDS := 0.4
const FEED_FADE_SECONDS := 0.3
const HINT_FONT_SIZE := 18
## so lange sieht man den Stand vor der Heilung
const HEAL_DELAY := 0.8
const HEAL_SECONDS := 2.0
const BUTTON_MARGIN := 24
const HEART_SIZE := Vector2(26, 26)
const HEART_INTERVAL := 0.14
const HEART_FLIGHT_SECONDS := 1.1
## so hoch steigen die Herzen über den höheren der beiden Endpunkte
const HEART_ARC_HEIGHT := Vector2(170.0, 260.0)
## Austrittspunkt im Feuer, Anteile seiner Fläche
const FIRE_MOUTH := Vector2(0.5, 0.72)

@export var left_slot: Control
@export var right_slot: Control
## Lagerfeuer, aus ihm kommen die Herzen
@export var fire: Control
## Reihe vor dem Feuer: Tasche und Essenz-Stapel
@export var feed_row: Control

var debug = false
var _button: Button
var _rest_button: Button
var _camp_monsters: Array[Control] = []
var _bag: OpenBag
var _stacks: Array[GoldStack] = []
var _hint_panel: PanelContainer
var _hint: Label
## zusätzliche Lebenspunkte pro Monster durch verfütterte Essenz
var _bonus_hp := 0
var _pop: Tween

func _enter_tree() -> void:
	if debug:
		var mon1:Monster = Helper.generate_mons({"count": 1, "level": randi_range(10,30)})[0]
		mon1._lost_hp = mon1.hp() / 1.5
		State.mons.append(mon1)
		#var mon2:Monster = Helper.generate_mons({"count": 1, "level": randi_range(10,30)})[0]
		#mon2._lost_hp = mon2.hp() / 1.5
		#State.mons.append(mon2)

func _ready() -> void:
	_button = RewardDialog.icon_button(ShopDialog.EXIT_ICON)
	_button.tooltip_text = tr("COMMON_OK")
	_button.visible = false
	_button.pressed.connect(queue_free)
	add_child(_button)
	_button.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT, PRESET_MODE_KEEP_SIZE, BUTTON_MARGIN)
	_rest_button = RewardDialog.plate_button(tr("HUB_REST"))
	_rest_button.pressed.connect(_rest)
	add_child(_rest_button)
	_rest_button.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT, PRESET_MODE_MINSIZE, BUTTON_MARGIN)
	_rest_button.grow_horizontal = GROW_DIRECTION_BEGIN
	# das Team hat höchstens zwei Monster (judgement.gd MAX_TEAM)
	var slots: Array[Control] = [left_slot, right_slot]
	for i in State.mons.size():
		var camp_monster := CAMP_MONSTER.instantiate()
		camp_monster.mon = State.mons[i]
		slots[i % slots.size()].add_child(camp_monster)
		_camp_monsters.append(camp_monster)
	_build_feeding()

## Tasche und Stapel vor dem Feuer, darüber der Hinweis; das Feuer selbst nimmt die Essenz an
func _build_feeding() -> void:
	var target := FeedTarget.new()
	target.camp = self
	target.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	fire.add_child(target)
	# gleich breite Seiten links und rechts halten die Tasche mittig vor dem Feuer
	var left_side := Control.new()
	left_side.size_flags_horizontal = SIZE_EXPAND_FILL
	left_side.mouse_filter = MOUSE_FILTER_IGNORE
	feed_row.add_child(left_side)
	_bag = OpenBag.new(BAG_SIZE, ESSENCE_ICON, BAG_ITEM_SIZE, BAG_FONT_SIZE)
	feed_row.add_child(_bag)
	var right_side := HBoxContainer.new()
	right_side.size_flags_horizontal = SIZE_EXPAND_FILL
	right_side.add_theme_constant_override("separation", 12)
	feed_row.add_child(right_side)
	for amount: int in GOLD_STACKS:
		var stack := GoldStack.new(self, amount, GOLD_STACKS[amount])
		_stacks.append(stack)
		right_side.add_child(stack)

	_hint_panel = PanelContainer.new()
	_hint_panel.mouse_filter = MOUSE_FILTER_IGNORE
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", HINT_FONT_SIZE)
	_hint.add_theme_color_override("font_color", IronPlate.TEXT_COLOR)
	IronPlate.frame(_hint_panel, _hint, 12, 8)
	add_child(_hint_panel)
	_hint_panel.set_anchors_and_offsets_preset(PRESET_CENTER_TOP, PRESET_MODE_MINSIZE, BUTTON_MARGIN)
	_hint_panel.grow_horizontal = GROW_DIRECTION_BOTH
	show_hint(tr("CAMP_FEED_HINT").format({"hp": HP_PER_GOLD}))

	State.ep_changed.connect(_show_money)
	_show_money(State.ep)

func show_hint(text: String) -> void:
	_hint.text = text

## Grund, warum der Stapel gerade nicht ins Feuer darf ("" = darf)
func feed_blocked(amount: int) -> String:
	if State.ep < amount:
		return tr("CAMP_FEED_POOR")
	if not State.mons.any(func(mon: Monster): return _healed_lost_hp(mon) > 0.0):
		return tr("CAMP_FEED_FULL")
	return ""

## So viel fehlt dem Monster noch nach dem Ausruhen
func _healed_lost_hp(mon: Monster) -> float:
	return clampf(mon._lost_hp - mon.hp() / 2 - _bonus_hp, 0, mon.hp())

func feed(amount: int) -> void:
	_bonus_hp += amount * HP_PER_GOLD
	State.ep -= amount
	show_hint(tr("CAMP_FEED_BONUS").format({"hp": _bonus_hp}))
	fire.pivot_offset = Vector2(fire.size.x / 2, fire.size.y)
	if _pop:
		_pop.kill()
	fire.scale = Vector2(1.12, 1.18)
	_pop = create_tween()
	_pop.tween_property(fire, "scale", Vector2.ONE, FEED_POP_SECONDS).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _show_money(ep: int) -> void:
	_bag.label.text = str(ep)
	_bag.show_items(ceili(ep / float(ESSENCE_PER_ITEM)))
	# Stapel, die gerade nicht ins Feuer dürfen, sind ausgegraut
	for stack in _stacks:
		var blocked := feed_blocked(stack.amount) != ""
		stack.modulate = RewardDialog.LOCKED_COLOR if blocked else Color.WHITE
		stack.mouse_default_cursor_shape = CURSOR_ARROW if blocked else CURSOR_DRAG

## Das Feuer leuchtet auf, solange die Essenz darüber schwebt
func _process(_delta: float) -> void:
	var over := get_viewport().gui_is_dragging() and fire.get_global_rect().has_point(get_global_mouse_position())
	fire.modulate = RewardDialog.HOVER_COLOR if over else Color.WHITE

## Ab hier wird nicht mehr gefüttert: Tasche und Stapel blenden aus, ihr Platz bleibt, damit nichts springt
func _rest() -> void:
	_rest_button.visible = false
	_hint_panel.visible = false
	for stack in _stacks:
		stack.mouse_filter = MOUSE_FILTER_IGNORE
	create_tween().tween_property(feed_row, "modulate:a", 0.0, FEED_FADE_SECONDS)
	_button.visible = true
	_button.disabled = true
	_play()

func _play() -> void:
	var tween := create_tween().set_parallel()
	# hält den Tween auch ohne Monster am Leben, damit der Button immer freigeschaltet wird
	tween.tween_interval(HEAL_DELAY)
	for mon: Monster in State.mons:
		tween.tween_property(mon, "_lost_hp", _healed_lost_hp(mon), HEAL_SECONDS).set_delay(HEAL_DELAY)
	if not _camp_monsters.is_empty():
		_send_hearts()
	await tween.finished
	_button.disabled = false

## Während der Heilung abwechselnd ein Herz zu jedem Monster
func _send_hearts() -> void:
	var count := int(HEAL_SECONDS / HEART_INTERVAL)
	var hearts := create_tween()
	hearts.tween_interval(HEAL_DELAY)
	for i in count:
		hearts.tween_callback(_fly_heart.bind(_camp_monsters[i % _camp_monsters.size()]))
		hearts.tween_interval(HEART_INTERVAL)

func _fly_heart(camp_monster: Control) -> void:
	var heart := TextureRect.new()
	heart.texture = HEART_TEXTURE
	heart.material = PROPS_MATERIAL
	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart.mouse_filter = MOUSE_FILTER_IGNORE
	heart.size = HEART_SIZE
	heart.pivot_offset = HEART_SIZE / 2
	heart.z_index = 5
	add_child(heart)
	var start := fire.get_global_rect().position + fire.size * FIRE_MOUTH - global_position - HEART_SIZE / 2
	var texture_rect: Control = camp_monster.texture_rect
	var end := texture_rect.get_global_rect().get_center() - global_position - HEART_SIZE / 2
	end += Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0))
	var peak := Vector2((start.x + end.x) / 2, minf(start.y, end.y) - randf_range(HEART_ARC_HEIGHT.x, HEART_ARC_HEIGHT.y))
	# Bézierkurve mit drei Punkten: steil aus dem Feuer heraus, in großem Bogen zum Monster
	var along_arc := func(t: float) -> void:
		heart.position = start.lerp(peak, t).lerp(peak.lerp(end, t), t)
	heart.position = start
	heart.scale = Vector2.ONE * 0.4
	var tween := heart.create_tween().set_parallel()
	tween.tween_method(along_arc, 0.0, 1.0, HEART_FLIGHT_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(heart, "scale", Vector2.ONE, HEART_FLIGHT_SECONDS * 0.4)
	tween.tween_property(heart, "modulate:a", 0.0, 0.2).set_delay(HEART_FLIGHT_SECONDS - 0.2)
	tween.chain().tween_callback(heart.queue_free)

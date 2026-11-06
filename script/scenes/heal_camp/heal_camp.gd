extends Control

## Heilungs-Camp: in der Mitte das Lagerfeuer, links und rechts davon die eigenen Monster.
## Erst steht die Szene kurz still, dann steigen die Lebensanzeigen auf den geheilten Stand,
## während kleine Herzen in einem großen Bogen aus dem Feuer auf die Monster fliegen.

const CAMP_MONSTER = preload("res://script/scenes/heal_camp/camp_monster.tscn")
const HEART_TEXTURE = preload("res://assets/ui/icons/heart.svg")
const PROPS_MATERIAL = preload("res://script/scenes/jailer/jailer_props_material.tres")
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

var debug = false
var _button: Button
var _camp_monsters: Array[Control] = []

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
	_button.disabled = true
	_button.pressed.connect(queue_free)
	add_child(_button)
	_button.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT, PRESET_MODE_KEEP_SIZE, BUTTON_MARGIN)
	# das Team hat höchstens zwei Monster (judgement.gd MAX_TEAM)
	var slots: Array[Control] = [left_slot, right_slot]
	for i in State.mons.size():
		var camp_monster := CAMP_MONSTER.instantiate()
		camp_monster.mon = State.mons[i]
		slots[i % slots.size()].add_child(camp_monster)
		_camp_monsters.append(camp_monster)
	_play()

func _play() -> void:
	var tween := create_tween().set_parallel()
	# hält den Tween auch ohne Monster am Leben, damit der Button immer freigeschaltet wird
	tween.tween_interval(HEAL_DELAY)
	for mon: Monster in State.mons:
		var healed_lost_hp: float = clampf(mon._lost_hp - mon.hp() / 2, 0, mon.hp())
		tween.tween_property(mon, "_lost_hp", healed_lost_hp, HEAL_SECONDS).set_delay(HEAL_DELAY)
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

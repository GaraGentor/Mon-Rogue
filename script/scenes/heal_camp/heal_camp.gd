extends Control

## Heilungs-Camp: in der Mitte das Lagerfeuer, links und rechts davon die eigenen Monster.
## Erst steht die Szene kurz still, dann steigen die Lebensanzeigen auf den geheilten Stand.

const CAMP_MONSTER = preload("res://script/scenes/heal_camp/camp_monster.tscn")
## so lange sieht man den Stand vor der Heilung
const HEAL_DELAY := 0.8
const HEAL_SECONDS := 2.0

@export var left_slot: Control
@export var right_slot: Control
## hierhin kommt der OK-Button
@export var content: Control

var debug = false
var _button: Button

func _enter_tree() -> void:
	if debug:
		var mon1:Monster = Helper.generate_mons({"count": 1, "level": randi_range(10,30)})[0]
		mon1._lost_hp = mon1.hp() / 1.5
		State.mons.append(mon1)
		#var mon2:Monster = Helper.generate_mons({"count": 1, "level": randi_range(10,30)})[0]
		#mon2._lost_hp = mon2.hp() / 1.5
		#State.mons.append(mon2)

func _ready() -> void:
	_button = RewardDialog.plate_button(tr("COMMON_OK"))
	_button.custom_minimum_size = Vector2(220, 50)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.disabled = true
	_button.pressed.connect(queue_free)
	content.add_child(_button)
	# das Team hat höchstens zwei Monster (judgement.gd MAX_TEAM)
	var slots: Array[Control] = [left_slot, right_slot]
	for i in State.mons.size():
		var camp_monster := CAMP_MONSTER.instantiate()
		camp_monster.mon = State.mons[i]
		slots[i % slots.size()].add_child(camp_monster)
	_play()

func _play() -> void:
	var tween := create_tween().set_parallel()
	# hält den Tween auch ohne Monster am Leben, damit der Button immer freigeschaltet wird
	tween.tween_interval(HEAL_DELAY)
	for mon: Monster in State.mons:
		var healed_lost_hp: float = clampf(mon._lost_hp - mon.hp() / 2, 0, mon.hp())
		tween.tween_property(mon, "_lost_hp", healed_lost_hp, HEAL_SECONDS).set_delay(HEAL_DELAY)
	await tween.finished
	_button.disabled = false

extends Control

@export var ms1: Control
@export var ms2: Control

@export var button: Button

@export var second_monster_panel: Panel

var debug = false

func _enter_tree() -> void:
	if debug:
		var mon1:Monster = Helper.generate_mons({"count": 1, "level": randi_range(10,30)})[0]
		mon1._lost_hp = mon1.hp() / 1.5
		State.mons.append(mon1)
		#var mon2:Monster = Helper.generate_mons({"count": 1, "level": randi_range(10,30)})[0]
		#mon2._lost_hp = mon2.hp() / 1.5
		#State.mons.append(mon2)
	if State.mons.size() == 1:
		second_monster_panel.visible = false

func _play() -> void:
	_heal_mon(State.mons[0])
	if State.mons.size() > 1:
		_heal_mon(State.mons[1])

func _heal_mon(mon: Monster) -> void:
	var h_to_heal = mon.hp() / 2
	var to_heal = clamp(mon._lost_hp - h_to_heal, 0, mon.hp())
	await get_tree().create_tween().tween_property(mon, "_lost_hp", to_heal, 2).finished
	button.disabled = false

func _ready() -> void:
	visible = true

func _on_ok_button_pressed() -> void:
	visible = false
	queue_free()

func _on_visibility_changed() -> void:
	if visible:
		_play()

extends Control

@export var mw1: Control
@export var mw2: Control
@export var mw3: Control

@export var next_button: Button

@export var placeholder_panel: Panel

@export var learning_screen: Panel
@export var leaving_screen: Panel

var _index = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.learn_skill.connect(_learn_skill)
	_start()
	pass # Replace with function body.

func _start(index:int = 0):
	State.mons = State.mons
	print(State.mons)
	var new_mons = State.catched_mons
	mw2.monster = State.mons[0]
	if State.mons.size() == 2:
		placeholder_panel.visible = false
		mw3.visible = true
		mw3.monster = State.mons[1]
	print("nm:?", new_mons)
	if new_mons.size() >= 1:
		mw1.monster = new_mons[index]
	else:
		get_tree().change_scene_to_file("res://script/scenes/world_map/world_map.tscn")
		return
	set_strings(new_mons)

func _on_recruit_button_pressed() -> void:
	if State.mons.size() == 2:
		leaving_screen.visible = true
	if State.mons.size() == 1:
		var nm: Monster = State.catched_mons[_index]
		State.mons.append(nm)
		State.catched_mons.remove_at(_index)
		_index = 0
		_start()
	

func _on_release_pressed() -> void:
	State.catched_mons.remove_at(_index)
	_index = 0
	_start()

func set_strings(_mons):
	next_button.text = "{a}/{b}\n\n\n{next}".format({"a":str(_index+1), "b":str(_mons.size()), "next": tr("JUDGEMENT_NEXT")})

func _on_next_pressed() -> void:
	var new_mons = State.catched_mons
	if (_index + 1 >= new_mons.size()):
		_index = 0
	else: _index = _index + 1
	_start(_index)

func _learn_skill(skill) -> void:
	learning_screen.skill = skill
	learning_screen.visible = true

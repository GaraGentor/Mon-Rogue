extends Control

var debug=false
var debug_mons=2

@export var monster_scene1: Control
@export var monster_scene2: Control

@export var killed_monsters_label: Label

@export var go_button: Button

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
	killed_monsters_label.text = tr("LEVEL_UP_KILLED").format({"count": State.killed_monsters})
	_start()

func _start() -> void:
	for killed in State.killed_monsters:
		State.killed_monsters -= 1
		if monster_scene1.mon:
			await monster_scene1._play()
		if monster_scene2.mon:
			await monster_scene2._play()
	go_button.disabled = false


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://script/scenes/world_map/world_map.tscn")

extends Control

var select_egg_material = preload("res://script/scenes/battle/selected_monster_material.tres")

var mons = []
var egg_picked_index = 1
var selected: int:
	set(value):
		selected = value
		Events.select_initial_mon.emit(value)

var common_egg = preload("res://assets/ui/eggs/common_1.png")
var common_egg_crack = preload("res://assets/ui/eggs/common_2.png")

@export var title_label: Label
@export var go_button: Button

@export var monster_widget: Control

var selected_egg: int = 0

func _ready() -> void:
	mons = Helper.generate_mons({"count": 3, "initial": true})
	# display_mons()
	Events.select_initial_mon.connect(select_egg)
	# Events.select_initial_mon.emit(0)

func select_egg(index):
	go_button.disabled = false
	$Selection.get_node("HBoxContainer/ColorRect1/TextureRect1").material = null
	$Selection.get_node("HBoxContainer/ColorRect2/TextureRect2").material = null
	$Selection.get_node("HBoxContainer/ColorRect3/TextureRect3").material = null
	$Selection.get_node("HBoxContainer/ColorRect"+str(index+1)+"/TextureRect" + str(index+1)).material = select_egg_material

	selected_egg = index
	monster_widget.monster = mons[index]

func select_mon(mon):
	State.mons = [mon]

func _on_button_pressed() -> void:
	select_mon(mons[selected_egg])
	get_tree().change_scene_to_file("res://script/scenes/world_map/world_map.tscn")

func on_select_egg(event: InputEvent, index):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Events.select_initial_mon.emit(index)

func _on_gui_input1(event: InputEvent) -> void:
	on_select_egg(event, 0)
func _on_gui_input2(event: InputEvent) -> void:
	on_select_egg(event, 1)
func _on_gui_input3(event: InputEvent) -> void:
	on_select_egg(event, 2)


func _on_pick_egg_button_pressed() -> void:
	if egg_picked_index < 4:
		title_label.text = tr("SELECTION_PICK_WARRIOR")
		var eggi: TextureRect = $Selection.get_node("HBoxContainer/ColorRect"+str(egg_picked_index)+"/TextureRect"+str(egg_picked_index))
		var transition = get_tree().create_tween().tween_method(eggi.set_position,Vector2(0,-450),Vector2(0,0), 0.3)
		var cr: Panel = $Selection.get_node("HBoxContainer/ColorRect"+str(egg_picked_index))
		var transition2 = get_tree().create_tween().tween_method(cr.set_self_modulate,Color(1,1,1,0),Color(1,1,1,1), 0.3)
		cr.set_self_modulate(Color(1,1,1,1))
	if egg_picked_index == 3:
		title_label.text = tr("SELECTION_TIME_TO_GO")
	if egg_picked_index == 4:
		title_label.text = tr("SELECTION_NO_MORE_EGGS")
	egg_picked_index += 1

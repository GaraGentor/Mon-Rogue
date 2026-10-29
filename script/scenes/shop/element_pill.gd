extends Control

@export var dragging: bool
@export var money_label: Label
@export var element_label: Label
@export var mat: ColorRect

var drag_data = {"type": 0, "cost": 20}

signal dragging_start(type, cost)

func _init_pill(type, cost:int = 0) -> void:
	var mat: ShaderMaterial = mat.material
	var d = ColorMap.get_combo(type)
	mat.set_shader_parameter("water_color", Color(d.color))
	element_label.text = tr(d.label)
	element_label.self_modulate = d.color
	money_label.text = "$ " + str(cost)
	drag_data = {"type": type, "cost": cost}

func _can_drop_data(pos, data):
	print(data)
	return true

func _get_drag_data(at_position: Vector2):
	print("willd rag?", at_position)
	var t = self.duplicate()
	t.anchor_left = 0
	t.anchor_top = 0
	t.anchor_right = 0
	t.anchor_bottom = 0

	t.offset_left = 0
	t.offset_top = 0
	t.offset_right = 64
	t.offset_bottom = 64

	t.custom_minimum_size = Vector2(64, 64)
	t.size = Vector2(128, 256)
	set_drag_preview(t)
	return drag_data

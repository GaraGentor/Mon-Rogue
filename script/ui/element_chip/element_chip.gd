extends Control

@export var label: Label

func _ready() -> void:
	pass
	#_init_label("")
# Called when the node enters the scene tree for the first time.
func _init_color(mon: Monster) -> void:
	label.text = tr(Helper.type_name_by_mon(mon))
	var styleBox: StyleBoxFlat = label.get_theme_stylebox("normal").duplicate()
	styleBox.bg_color = Helper.color_by_mon(mon)
	label.add_theme_stylebox_override("normal", styleBox)
	pass

func _init_with_element(data) -> void:
	label.text = tr(data.label)
	var styleBox: StyleBoxFlat = label.get_theme_stylebox("normal").duplicate()
	styleBox.bg_color = data.color
	label.add_theme_stylebox_override("normal", styleBox)

func _init_label(text: String) -> void:
	label.text = "FIRE"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

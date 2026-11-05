extends Control

const DARK_TEXT := Color(0.1, 0.1, 0.12)
const LIGHT_BACKGROUND := 0.6

@export var label: Label

func _ready() -> void:
	pass
	#_init_label("")
# Called when the node enters the scene tree for the first time.
func _init_color(mon: Monster) -> void:
	label.text = tr(Helper.type_name_by_mon(mon))
	_set_background(Helper.color_by_mon(mon))

func _init_with_element(data) -> void:
	label.text = tr(data.label)
	_set_background(data.color)

func _set_background(color: Color) -> void:
	var styleBox: StyleBoxFlat = label.get_theme_stylebox("normal").duplicate()
	styleBox.bg_color = color
	label.add_theme_stylebox_override("normal", styleBox)
	# auf hellen Farben (Luft) ist weißer Text nicht lesbar
	label.add_theme_color_override("font_color", DARK_TEXT if color.get_luminance() > LIGHT_BACKGROUND else Color.WHITE)

func _init_label(text: String) -> void:
	label.text = "FIRE"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

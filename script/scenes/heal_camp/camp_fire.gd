extends Control

## Lagerfeuer in der Mitte des Heilungs-Camps: die Flammen flackern um ihren Fußpunkt, der Schein pulsiert mit.

@export var outer_flame: Control
@export var inner_flame: Control
@export var glow: Control

const OUTER_FLICKER := 0.09
const INNER_FLICKER := 0.14
const MAX_LEAN_DEGREES := 3.0
const FLICKER_SECONDS := Vector2(0.09, 0.18)
const GLOW_ALPHA := Vector2(0.65, 1.0)

func _ready() -> void:
	_flicker(outer_flame, OUTER_FLICKER)
	_flicker(inner_flame, INNER_FLICKER)
	_pulse_glow()

func _flicker(flame: Control, amount: float) -> void:
	var seconds := randf_range(FLICKER_SECONDS.x, FLICKER_SECONDS.y)
	var stretch := randf_range(-amount, amount)
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	# wird die Flamme höher, wird sie auch schmaler
	tween.tween_property(flame, "scale", Vector2(1.0 - stretch * 0.6, 1.0 + stretch), seconds)
	tween.tween_property(flame, "rotation_degrees", randf_range(-MAX_LEAN_DEGREES, MAX_LEAN_DEGREES), seconds)
	tween.chain().tween_callback(_flicker.bind(flame, amount))

func _pulse_glow() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(glow, "modulate:a", randf_range(GLOW_ALPHA.x, GLOW_ALPHA.y), randf_range(0.2, 0.4))
	tween.tween_callback(_pulse_glow)

class_name UILine
extends Control

## Verbindungspunkte
@export var from_node: Control
@export var to_node: Control

## Basisfarben der Linie (abhängig von is_premium)
@export var color := Color.WHITE
@export var color2 := Color.DARK_GOLDENROD
@export var width := 4.0

@export_group("Wellen-Effekt")
## Farbe des Glow-/Wellen-Effekts
@export var wave_color := Color(0.4, 0.9, 1.0):
	set(value):
		wave_color = value
		_update_shader_params()
## Intensität der Welle (steuert sowohl die geometrische Auslenkung als auch die Leuchtkraft)
@export_range(0.0, 5.0, 0.05) var wave_intensity := 1.0:
	set(value):
		wave_intensity = value
		_update_shader_params()
## Geschwindigkeit der wandernden Welle
@export_range(0.0, 10.0, 0.05) var wave_speed := 2.0:
	set(value):
		wave_speed = value
		_update_shader_params()

@export_group("Feinabstimmung")
## Anzahl der Wellenberge über die gesamte Linienlänge
@export var wave_frequency := 3.0
## Auflösung der Linie (mehr Segmente = glattere Welle, aber etwas teurer)
@export_range(4, 128, 1) var segments := 32

var is_premium: bool

var _time := 0.0
var _shader_material: ShaderMaterial

# Pfad ggf. anpassen, falls du die .gdshader Datei woanders ablegst
const WAVE_SHADER: Shader = preload("res://script/scenes/world_map/ui_line_wave.gdshader")


func _ready() -> void:
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = WAVE_SHADER
	material = _shader_material
	_update_shader_params()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _update_shader_params() -> void:
	if not _shader_material:
		return
	_shader_material.set_shader_parameter("glow_color", wave_color)
	_shader_material.set_shader_parameter("glow_intensity", wave_intensity * 1.5)
	_shader_material.set_shader_parameter("glow_speed", wave_speed)


func _draw() -> void:
	if not from_node or not to_node:
		return

	var origin := get_global_rect().position
	var a := rect_center_top(from_node._path._ui_item.get_global_rect()) - origin
	var b := rect_center_bottom(to_node._path._ui_item.get_global_rect()) - origin

	var diff := b - a
	var length := diff.length()
	if length < 0.01:
		return

	var dir := diff / length
	var perp := Vector2(-dir.y, dir.x)
	var line_color := color if is_premium else color2
	var half_width := width * 0.5
	var amplitude := wave_intensity * 8.0

	var left_points := PackedVector2Array()
	var right_points := PackedVector2Array()
	var uvs_left := PackedVector2Array()
	var uvs_right := PackedVector2Array()

	for i in segments + 1:
		var t := float(i) / float(segments)
		var base_point := a.lerp(b, t)
		# Sinus-Welle, an beiden Enden ausgeblendet, damit sie exakt an den Nodes andockt
		var fade := sin(t * PI)
		var offset := sin(t * wave_frequency * TAU - _time * wave_speed) * amplitude * fade
		var center := base_point + perp * offset

		left_points.append(center - perp * half_width)
		right_points.append(center + perp * half_width)
		uvs_left.append(Vector2(t, 0.0))
		uvs_right.append(Vector2(t, 1.0))

	# Linke Seite hin, rechte Seite zurück -> ergibt ein geschlossenes Band (Ribbon)
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	points.append_array(left_points)
	uvs.append_array(uvs_left)
	for i in range(right_points.size() - 1, -1, -1):
		points.append(right_points[i])
		uvs.append(uvs_right[i])

	draw_polygon(points, PackedColorArray([line_color]), uvs)


func rect_center_top(r: Rect2) -> Vector2:
	return Vector2(
		r.position.x + r.size.x * 0.5,
		r.position.y
	)


func rect_center_bottom(r: Rect2) -> Vector2:
	return Vector2(
		r.position.x + r.size.x * 0.5,
		r.position.y + r.size.y
	)

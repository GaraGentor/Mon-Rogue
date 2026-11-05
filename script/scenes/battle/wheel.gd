extends Control

## Ordnet alle Kinder gleichmäßig auf einem Kreis an.
## Bei angle_offset = 0 steht das erste Kind oben (12 Uhr), die weiteren folgen im Uhrzeigersinn.
## Die Kinder werden nur verschoben, nicht gedreht, damit die Monster aufrecht bleiben.
## Der Platz auf dem Kreis kommt aus dem Meta-Wert "slot", nicht aus der Reihenfolge der Kinder.
## So kann ein Kind zum Zeichnen nach vorne geholt werden, ohne seinen Platz zu verlieren.

@export var icon_size := 50.0
@export var margin := 8.0

@export_group("Linien")
@export var line_width := 4.0
## Wie weit die Linien maximal vom Kreis abweichen.
@export var line_amplitude := 9.0
## Gewünschte Länge eines Bogens zwischen zwei Kreuzungen in Pixeln.
@export var lobe_length := 45.0
## Kleine Unregelmäßigkeit in Pixeln, damit die Linien handgezogen wirken.
@export var line_wobble := 1.2
@export var line_color := Color("#8c2a24")
## Farbe, zu der die Linien beim Glimmen hin wandern.
@export var pulse_color := Color("#c8503a")
## Maximale Stärke des Glimmens (0 = aus, 1 = volle pulse_color).
@export var glow_max := 0.3
## Geschwindigkeit des Glimmens im Bogenmaß pro Sekunde.
@export var pulse_speed := 1.2

const TwinedLine := preload("res://script/scenes/battle/twined_line.gd")

## Drehung des Rads im Bogenmaß. Wird vom TurnWheel getweent.
var angle_offset := 0.0:
	set(value):
		angle_offset = value
		layout_circle()

var _pulse_phase := 0.0
var _line := TwinedLine.new()

func _ready() -> void:
	_line.width = line_width
	_line.amplitude = line_amplitude
	_line.wobble = line_wobble
	_line.color = line_color
	_line.pulse_color = pulse_color

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		layout_circle()

func _process(delta: float) -> void:
	_pulse_phase = wrapf(_pulse_phase + pulse_speed * delta, 0.0, TAU)
	queue_redraw()

## Eine geflochtene Kordel aus zwei Wellenlinien zwischen je zwei Icons.
## Sie drehen sich mit dem Rad mit und glimmen nur schwach.
## Die Linien enden am Icon-Rand, damit sie nicht durch die halbtransparenten Icons scheinen.
func _draw() -> void:
	var count := get_child_count()
	var r := radius()
	if count == 0 or r <= 0.0:
		return
	draw_set_transform(size / 2, -angle_offset)
	var step := angle_step()
	var lobes_per_gap := maxi(roundi(step * r / lobe_length), 1)
	# Winkel, den jedes Icon auf dem Kreis verdeckt; das aktive Icon ist größer skaliert
	var icon_angles: Array[float] = []
	icon_angles.resize(count)
	for child: Control in get_children():
		icon_angles[child.get_meta("slot", child.get_index())] = child.scale.x * icon_size / 2.0 / r
	for slot in range(count):
		var from_angle := slot * step + icon_angles[slot]
		var to_angle := (slot + 1) * step - icon_angles[(slot + 1) % count]
		if from_angle >= to_angle:
			continue
		_line.draw_braid(self, r, from_angle, to_angle, lobes_per_gap / step * PI, _pulse_phase, 0.0, glow_max)

func radius() -> float:
	# Platz für das vergrößerte aktive Icon lassen
	return max(0.0, min(size.x, size.y) / 2.0 - icon_size * 0.7 - margin)

func angle_step() -> float:
	var count := get_child_count()
	return TAU / float(count) if count > 0 else 0.0

func layout_circle():
	queue_redraw()
	var center := size / 2
	var step := angle_step()
	var r := radius()
	var children := get_children()
	for i in range(children.size()):
		var child: Control = children[i]
		var slot: int = child.get_meta("slot", i)
		var angle := -PI / 2 + float(slot) * step - angle_offset
		child.position = center + Vector2(cos(angle), sin(angle)) * r - child.size / 2

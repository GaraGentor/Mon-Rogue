extends RefCounted

## Zeichnet eine geflochtene Kordel aus zwei Wellenlinien auf einem Kreis um den Ursprung des aktuellen Zeichen-Transforms.
## An den Kreuzungen läuft abwechselnd die eine und die andere Linie oben, eine dunkle Kontur trennt sie.
## Stil wie die Risse auf den Skill-Karten: kein Glanz, sondern langsames Glühen in der eigenen Farbe.

const SEGMENT_LENGTH := 2.0
const GLOW_WIDTH_FACTOR := 2.5
## Wie stark das Glühen entlang der Linie zeitversetzt ist.
const PULSE_LAG := 0.8
const OUTLINE_COLOR := Color("#120e0b")
## Halbe Länge des oben liegenden Stücks an einer Kreuzung, in Linienbreiten.
const CROSSING_REACH := 2.0
## So viel länger ist die Linie als ihre Kontur, damit sie die Enden der Kontur überdeckt (in Pixeln).
const CROSSING_CORE_EXTRA := 1.5

var width := 3.0
var amplitude := 9.0
## Kontur je Seite in Pixeln.
var outline := 1.0
## Kleine, feste Unregelmäßigkeit in Pixeln, damit die Linie handgezogen wirkt.
var wobble := 0.0
var color := Color.RED
var pulse_color := Color.WHITE
var glow_alpha := 0.35

var _canvas: CanvasItem
var _radius := 0.0
var _wave_factor := 1.0
var _pulse_phase := 0.0
var _glow_min := 0.0
var _glow_max := 0.0

## Muss aus dem _draw() von canvas aufgerufen werden.
## wave_factor legt die Wellenanzahl fest: Bei den Winkeln k * PI / wave_factor kreuzen sich die Linien.
## Die Helligkeit pendelt mit pulse_phase zwischen glow_min und glow_max (0 = color, 1 = pulse_color).
func draw_braid(canvas: CanvasItem, r: float, from_angle: float, to_angle: float, wave_factor: float, pulse_phase: float, glow_min: float, glow_max: float) -> void:
	_canvas = canvas
	_radius = r
	_wave_factor = wave_factor
	_pulse_phase = pulse_phase
	_glow_min = glow_min
	_glow_max = glow_max
	for strand_sign: float in [1.0, -1.0]:
		var strand := _build(from_angle, to_angle, strand_sign)
		var glow_colors := PackedColorArray()
		for i in range(strand.colors.size()):
			glow_colors.append(Color(strand.colors[i], glow_alpha * strand.glows[i]))
		canvas.draw_polyline_colors(strand.points, glow_colors, width * GLOW_WIDTH_FACTOR, true)
		_draw_outline(strand.points)
		canvas.draw_polyline_colors(strand.points, strand.colors, width, true)
	_draw_crossings(from_angle, to_angle)

## Zeichnet an jeder Kreuzung die obere Linie samt Kontur noch einmal über die untere.
func _draw_crossings(from_angle: float, to_angle: float) -> void:
	var half_lobe := PI / _wave_factor / 2.0
	var reach := minf(CROSSING_REACH * width / _radius, half_lobe * 0.8)
	var core_reach := minf(reach + CROSSING_CORE_EXTRA / _radius, half_lobe * 0.95)
	var first := ceili(from_angle * _wave_factor / PI)
	var last := floori(to_angle * _wave_factor / PI)
	for k in range(first, last + 1):
		var theta := k * PI / _wave_factor
		var strand_sign := 1.0 if k % 2 == 0 else -1.0
		_draw_outline(_build(maxf(theta - reach, from_angle), minf(theta + reach, to_angle), strand_sign).points)
		var core := _build(maxf(theta - core_reach, from_angle), minf(theta + core_reach, to_angle), strand_sign)
		_canvas.draw_polyline_colors(core.points, core.colors, width, true)

func _draw_outline(points: PackedVector2Array) -> void:
	_canvas.draw_polyline(points, OUTLINE_COLOR, width + outline * 2.0, true)

## Berechnet ein Stück einer Linie. Liefert points, colors und glows.
func _build(from_angle: float, to_angle: float, strand_sign: float) -> Dictionary:
	var segments := maxi(ceili(_radius * (to_angle - from_angle) / SEGMENT_LENGTH), 1)
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var glows := PackedFloat32Array()
	for i in range(segments + 1):
		var theta := lerpf(from_angle, to_angle, float(i) / segments)
		var wave := amplitude * strand_sign * sin(_wave_factor * theta)
		# ganzzahlige Frequenzen, damit sich die Unregelmäßigkeit auf einem vollen Kreis schließt
		var uneven := wobble * (sin(5.0 * theta + strand_sign * 1.3) + 0.5 * sin(11.0 * theta + strand_sign * 2.6))
		# Winkel 0 liegt auf 12 Uhr
		points.append(Vector2.from_angle(theta - PI / 2) * (_radius + wave + uneven))
		var pulse := 0.5 + 0.5 * sin(_pulse_phase + sin(3.0 * theta + strand_sign) * PULSE_LAG)
		var glow := lerpf(_glow_min, _glow_max, pulse)
		colors.append(color.lerp(pulse_color, glow))
		glows.append(glow)
	return {"points": points, "colors": colors, "glows": glows}

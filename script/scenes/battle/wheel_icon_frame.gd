extends Control

## Verzierter Rahmen eines Monster-Icons auf dem Rad: eine geflochtene Kordel.
## Ruhig, solange das Monster nicht am Zug ist, sonst pulsiert der Rahmen deutlich.

const TwinedLine := preload("res://script/scenes/battle/twined_line.gd")

## Gerade Zahl, damit das Über und Unter der Kordel am Kreis aufgeht.
const LOBES := 10
const PULSE_SPEED := 2.2
const IDLE_GLOW_MAX := 0.08
const ACTIVE_GLOW_MIN := 0.25
const ACTIVE_GLOW_MAX := 1.0

## 0 = nicht am Zug, 1 = am Zug. Wird vom TurnWheel getweent.
var active_amount := 0.0

var _line := TwinedLine.new()
var _pulse_phase := 0.0

func setup(color: Color, pulse_color: Color) -> void:
	_line.width = 2.5
	_line.amplitude = 3.0
	_line.outline = 0.7
	_line.wobble = 0.3
	_line.color = color
	_line.pulse_color = pulse_color

func _process(delta: float) -> void:
	_pulse_phase = wrapf(_pulse_phase + PULSE_SPEED * delta, 0.0, TAU)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(size / 2)
	var r := minf(size.x, size.y) / 2.0
	var glow_min := lerpf(0.0, ACTIVE_GLOW_MIN, active_amount)
	var glow_max := lerpf(IDLE_GLOW_MAX, ACTIVE_GLOW_MAX, active_amount)
	_line.draw_braid(self, r, 0.0, TAU, LOBES / 2.0, _pulse_phase, glow_min, glow_max)

extends Control

## Kreisförmige HP-Anzeige: grauer Ring als Hintergrund, farbiger Bogen für die restlichen HP (im Uhrzeigersinn ab 12 Uhr).

@export var ring_width := 7.0
@export var back_color := Color(0, 0, 0, 0.75)
@export var fill_color := Color(0.75, 0.1, 0.1)
@export var low_color := Color(0.95, 0.55, 0.1)

var max_value := 1.0:
	set(val):
		max_value = maxf(val, 1.0)
		queue_redraw()
var value := 1.0:
	set(val):
		value = clampf(val, 0.0, max_value)
		queue_redraw()

func _draw() -> void:
	var center := size / 2
	var radius := minf(size.x, size.y) / 2 - ring_width / 2
	draw_arc(center, radius, 0, TAU, 48, back_color, ring_width, true)
	var ratio := value / max_value
	if ratio <= 0:
		return
	var start := -PI / 2
	draw_arc(center, radius, start, start + TAU * ratio, maxi(4, int(48 * ratio)), low_color if ratio < 0.3 else fill_color, ring_width - 2, true)

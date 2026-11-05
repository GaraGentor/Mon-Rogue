class_name SpeechBubble
extends PanelContainer

## Sprechblase eines NPCs: say() blendet den Text ein, nach einer Weile verschwindet er von selbst.
## Der Zipfel zeigt nach rechts zum NPC, der Host legt die Blase links neben dessen Kopf.

const WIDTH := 250.0
const PAPER := Color(0.95, 0.91, 0.8)
const INK := Color(0.16, 0.12, 0.08)
const FONT_SIZE := 18
## Anzeigedauer: Grundzeit plus etwas Lesezeit pro Zeichen
const BASE_SECONDS := 2.5
const SECONDS_PER_CHAR := 0.04
const FADE_SECONDS := 0.2
## Zipfel, bezogen auf die obere rechte Ecke der Blase
const TAIL := [Vector2(-1, 18), Vector2(18, 28), Vector2(-1, 40)]

var _label: Label
var _tween: Tween

func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_corner_radius_all(14)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)
	_label = Label.new()
	_label.custom_minimum_size.x = WIDTH - 24
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_color_override("font_color", INK)
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	add_child(_label)
	var tail := Polygon2D.new()
	tail.color = PAPER
	tail.polygon = PackedVector2Array(TAIL)
	tail.position.x = WIDTH
	add_child(tail)

func say(text: String) -> void:
	_label.text = text
	reset_size()
	visible = true
	pivot_offset = Vector2(WIDTH, 0)
	if _tween:
		_tween.kill()
	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)
	_tween = create_tween()
	_tween.set_parallel()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_SECONDS)
	_tween.tween_property(self, "scale", Vector2.ONE, FADE_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_interval(BASE_SECONDS + text.length() * SECONDS_PER_CHAR)
	_tween.chain().tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	_tween.chain().tween_callback(hide)

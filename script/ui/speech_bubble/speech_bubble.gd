class_name SpeechBubble
extends PanelContainer

## Sprechblase eines NPCs: say() blendet den Text ein, nach einer Weile verschwindet er von selbst.
## Der Zipfel zeigt nach rechts zum NPC, der Host legt die Blase links neben dessen Kopf.
## Mit dark ist sie eine Eisenplatte im Pixel-Look (Kerkermeister) statt heller Blase aus Papier.

const WIDTH := 250.0
const PAPER := Color(0.95, 0.91, 0.8)
const INK := Color(0.16, 0.12, 0.08)
const FONT_SIZE := 18
const DARK_FONT_SIZE := 22
const DARK_MARGIN := 16
const DARK_TAIL_TEXTURE = preload("res://assets/ui/jailer/bubble_tail.svg")
const DARK_TAIL_MATERIAL = preload("res://script/scenes/jailer/jailer_props_material.tres")
const DARK_FONT = preload("res://script/ui/fonts/pxelfont/PixelifySans-VariableFont_wght.ttf")
## der dunkle Zipfel überdeckt den Rand der Platte und sitzt auf Höhe des Texts
const DARK_TAIL_POSITION := Vector2(-6, 12)
const DARK_TAIL_SIZE := Vector2(24, 28)
## Anzeigedauer: Grundzeit plus etwas Lesezeit pro Zeichen
const BASE_SECONDS := 2.5
const SECONDS_PER_CHAR := 0.04
const FADE_SECONDS := 0.2
## Zipfel, bezogen auf die obere rechte Ecke der Blase
const TAIL := [Vector2(-1, 18), Vector2(18, 28), Vector2(-1, 40)]

var _label: Label
var _tween: Tween
var _width: float
## bleibt stehen, bis der nächste Text kommt
var _stays: bool

func _init(width := WIDTH, stays := false, dark := false) -> void:
	_width = width
	_stays = stays
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if dark:
		_build_dark()
	else:
		_build_paper()

func _build_paper() -> void:
	add_child(_label)
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_corner_radius_all(14)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)
	_label.custom_minimum_size.x = _width - 24
	_label.add_theme_color_override("font_color", INK)
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	var tail := Polygon2D.new()
	tail.color = PAPER
	tail.polygon = PackedVector2Array(TAIL)
	tail.position.x = _width
	add_child(tail)

func _build_dark() -> void:
	IronPlate.frame(self, _label, DARK_MARGIN, DARK_MARGIN)
	_label.custom_minimum_size.x = _width - 2 * DARK_MARGIN
	_label.add_theme_color_override("font_color", IronPlate.TEXT_COLOR)
	_label.add_theme_font_override("font", DARK_FONT)
	_label.add_theme_font_size_override("font_size", DARK_FONT_SIZE)
	# Node2D, damit der Container den Zipfel nicht in die Fläche zieht
	var holder := Node2D.new()
	holder.position = Vector2(_width, 0) + DARK_TAIL_POSITION
	add_child(holder)
	var tail := TextureRect.new()
	tail.texture = DARK_TAIL_TEXTURE
	tail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tail.size = DARK_TAIL_SIZE
	tail.material = DARK_TAIL_MATERIAL
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(tail)

func say(text: String) -> void:
	_label.text = text
	reset_size()
	visible = true
	pivot_offset = Vector2(_width, 0)
	if _tween:
		_tween.kill()
	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)
	_tween = create_tween()
	_tween.set_parallel()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_SECONDS)
	_tween.tween_property(self, "scale", Vector2.ONE, FADE_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _stays:
		return
	_tween.chain().tween_interval(BASE_SECONDS + text.length() * SECONDS_PER_CHAR)
	_tween.chain().tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	_tween.chain().tween_callback(hide)

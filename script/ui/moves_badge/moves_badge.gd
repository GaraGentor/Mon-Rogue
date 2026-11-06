extends Control

## Züge-Zahl mit den gleichen Partikeln wie über eigenen Monstern im Kampf (monster_scene).

@export var label: Label
@export var particles: MovesParticlesView

func _ready() -> void:
	resized.connect(_center)
	_center()

func set_moves(moves: int, max_moves: int) -> void:
	_show_value(moves, "%s %d/%d" % [tr("BATTLE_MON_MOVES"), moves, max_moves])

## Modus "3 Aktionen": Stufe der Passive statt Aktionen
func set_passive_level(level: int, description: String) -> void:
	_show_value(level, description)

func _show_value(value: int, description: String) -> void:
	label.text = str(value)
	tooltip_text = description
	particles.restart()
	particles.emitting = value > 0
	pivot_offset = size / 2
	scale = Vector2.ONE * 1.6
	modulate = Color(2, 2, 2)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.35)

func _center() -> void:
	particles.center_on(size / 2)

extends Control

func _on_gold_button_pressed() -> void:
	State.ep += randi_range(20,50)
	queue_free()

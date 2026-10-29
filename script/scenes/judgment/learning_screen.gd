extends Panel

@export var mw1: Control
@export var mw2: Control

@export var lean_mon_2_button: Button

@export var skill: Dictionary

@export var jug: Control

func _on_visibility_changed() -> void:
	if visible:
		mw1.monster = State.mons[0]
		if State.mons.size() >= 2:
			mw2.monster = State.mons[1]
			mw2.visible = true
			lean_mon_2_button.visible = true
	else:
		mw1.visible = true
		mw2.visible = false
		lean_mon_2_button.visible = false

func _on_button_mon1_pressed() -> void:
	State.mons[0]._skills.append(skill)
	visible = false
	jug._on_release_pressed()

func _on_button_mon2_pressed() -> void:
	State.mons[1]._skills.append(skill)
	visible = false
	jug._on_release_pressed()

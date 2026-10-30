extends Panel

@export var mw1: Control
@export var mw2: Control

@export var lean_mon_1_button: Button
@export var lean_mon_2_button: Button

# Hier erscheint die Auswahl, welcher Skill ersetzt wird, wenn alle Slots voll sind
@export var replace_container: Control

@export var skill: Dictionary

@export var jug: Control

func _on_visibility_changed() -> void:
	if visible:
		mw1.monster = State.mons[0]
		Skills.setup_learn_button(lean_mon_1_button, State.mons[0], skill, "JUDGEMENT_LEARN_1")
		if State.mons.size() >= 2:
			mw2.monster = State.mons[1]
			mw2.visible = true
			lean_mon_2_button.visible = true
			Skills.setup_learn_button(lean_mon_2_button, State.mons[1], skill, "JUDGEMENT_LEARN_2")
	else:
		mw1.visible = true
		mw2.visible = false
		lean_mon_2_button.visible = false
		_clear_replace_options()

func _on_button_mon1_pressed() -> void:
	_learn(State.mons[0])

func _on_button_mon2_pressed() -> void:
	_learn(State.mons[1])

func _learn(mon: Monster) -> void:
	var learned = Skills.learnable_copy(skill)
	if mon._skills.size() < Skills.MAX_SKILLS:
		mon._skills.append(learned)
		_finish()
		return
	_clear_replace_options()
	var picker := SkillReplacePicker.new(mon)
	picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	replace_container.add_child(picker)
	var index = await picker.picked
	if index == -1:
		return
	mon._skills[index] = learned
	_finish()

func _clear_replace_options() -> void:
	for child in replace_container.get_children():
		child.queue_free()

func _finish() -> void:
	visible = false
	jug._on_release_pressed()

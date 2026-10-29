extends Panel

@export var mw1: Control
@export var mw2: Control

@export var exit_panel: Panel

@export var jugment: Control

func _start(index: int) -> bool:
	exit_panel.monster_rect.texture = Monmap.mon_metainfos_by_name(State.mons[index]._name).texture_back
	mw1.visible = false
	mw2.visible = false
	exit_panel.visible = true
	await exit_panel._start_animation()
	return true


func _on_visibility_changed() -> void:
	if visible:
		mw1.monster = State.mons[0]
		mw2.monster = State.mons[1]
	else:
		mw1.visible = true
		mw2.visible = true
		exit_panel.visible = false
		exit_panel.reset_animation()

func _on_first_mon_pressed() -> void:
	await _start(0)
	State.mons.remove_at(0)
	visible = false
	jugment._start()
	jugment._on_recruit_button_pressed()

func _on_second_mon_pressed() -> void:
	await _start(1)
	State.mons.remove_at(1)
	visible = false
	jugment._start()
	jugment._on_recruit_button_pressed()

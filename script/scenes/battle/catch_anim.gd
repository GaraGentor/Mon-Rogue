extends Control

var catched: bool = false

@export var msg: Label

func _catch_animation(mon: Monster) -> void:
	print(mon)
	print(mon._name)
	print(Monmap.mon_metainfos_by_name(mon._name).texture_front)
	$TextureRect/MonTexture.texture = Monmap.mon_metainfos_by_name(mon._name).texture_front
	visible = true
	# create timer and decide catch.
	await get_tree().create_timer(3.0).timeout
	catch_mon(mon)
	display_progress(mon)

func catch_mon(mon: Monster) -> void:
	catched = Helper.will_catch_mon(mon)
	if catched:
		Events.mon_is_catched.emit(mon)
		mon.unlock_skills()
		State.catched_mons.append(mon)
		State.run_catches += 1
		State.enemy_mons.remove_at(State.enemy_mons.find(mon))

func display_progress(mon: Monster) -> void:
	if catched:
		msg.text = tr("BATTLE_CATCH_SUCCESS")
	else:
		msg.text = tr("BATTLE_CATCH_FAILED")
	msg.visible = true
	await get_tree().create_timer(3.0).timeout
	visible = false
	msg.visible = false
	Events.finish_catching.emit(catched, mon)

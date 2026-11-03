extends Control

var catched: bool = false

@export var msg: Label

func _catch_animation(mon: Monster) -> void:
	print(mon)
	print(mon._name)
	Monmap.show_on($TextureRect/MonTexture, mon._name, Monmap.LARGE)
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
		# Zusatzaktionen gibt es für eigene Monster nur über den Kerkermeister
		mon._initial_moves = Monster.BASE_MOVES
		State.catched_mons.append(mon)
		State.mark_mon_caught(mon._name)
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

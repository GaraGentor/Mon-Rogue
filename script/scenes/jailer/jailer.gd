extends Control

@export var hbox_container: HBoxContainer
@export var mon_scene: PackedScene

@export var refresh_button: Button

var debug = false

func _ready():
	if (debug):
		State.ep = 250
	refresh_button.text = tr("JAILER_REROLL").format({"cost": 25, "money": State.ep})
	_refresh()

func _refresh():
	var all_mons = Helper.get_all_owned_monster_names().duplicate(true)
	var all_saved_monsers = SaveManager.save_data.monsters.keys()
	var upgraded_mons = all_saved_monsers
	var combined_mons: Array = []
	#combined_mons.append_array(all_mons)
	combined_mons.append_array(upgraded_mons)
	#combined_mons.append_array(State.TEST_INITIAL_MONS.duplicate())
	for mon in State.TEST_INITIAL_MONS:
		if not combined_mons.has(mon):
			combined_mons.append(mon)
		
	var random_mons = []
	
	for i in 3:
		if combined_mons.size() >= 1:
			var picked = combined_mons.pick_random()
			random_mons.append(picked)
			combined_mons.erase(picked)
			print(combined_mons)

	
	for child in hbox_container.get_children():
		child.queue_free()
	
	for rand_mon in random_mons:
		var mon_scene = mon_scene.instantiate()
		mon_scene._init_with_mon(rand_mon)
		hbox_container.add_child(mon_scene)
		mon_scene.buy_button.pressed.connect( func(): upgrade_mon(rand_mon, mon_scene) )

func upgrade_mon(mon, scene) -> void:
	print("ye?")
	if (scene.current_upgrade_level * 2 + 1) <= State.boss_shards:
		scene.sold()
		bought(mon, scene.current_upgrade_level * 2 + 1)
		scene._init_with_mon(mon)

func upgrade_cost(current_level: int) -> int:
	return current_level + 1

func bought(mon_id, cost) -> void:
	State.boss_shards -= cost
	SaveManager.subtract_boss_shard(cost)
	SaveManager.add_mon_upgrade(mon_id)
	Events.mon_upgraded.emit(mon_id)
	pass

func _on_reroll_pressed() -> void:
	if State.ep >= 25:
		State.ep -= 25
		refresh_button.text = tr("JAILER_REROLL").format({"cost": 25, "money": State.ep})
		_refresh()
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	queue_free()
	pass # Replace with function body.

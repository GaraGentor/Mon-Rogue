extends Control

@export var mon_reward: Panel
@export var more_label: Label

@export var thanks_panel: Panel

var missing_mon_egg = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var catched_mons = SaveManager.save_data.catched_monsters.duplicate(true)
	catched_mons.append_array(State.INITIAL_MONS)
	var missing_mon = false
	for mon in State.mons:
		var has_mon = catched_mons.has(mon._name)
		if not has_mon:
			missing_mon_egg.append(mon)
			show_mon_reward()
			more_label.text = tr("BOSS_REWARD_CHOOSE_ONE")

func show_mon_reward() -> void:
	mon_reward.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_ok_button_pressed() -> void:
	pass

func finish() -> void:
	State.map_level += 1
	State.biome_fight_index = 0
	if State.map_level == Map.map_settings.size():
		thanks_panel.visible = true
		return
	Map.generate_starting_points()
	get_tree().change_scene_to_file("res://script/scenes/world_map/world_map.tscn")

func _on_shard_button_pressed() -> void:
	SaveManager.add_boss_shard(1)
	State.boss_shards += 1
	finish()
	pass # Replace with function body.


func _on_egg_button_pressed() -> void:
	var mon_to_save = missing_mon_egg.pick_random()
	SaveManager.add_catched_monster_mon(mon_to_save._name)
	finish()
	pass # Replace with function body.


func _on_start_new_run_pressed() -> void:
	State.reset()
	get_tree().change_scene_to_file("res://script/scenes/selection/selection.tscn")

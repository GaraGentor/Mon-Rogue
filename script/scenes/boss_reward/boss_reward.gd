extends Control

@export var mon_reward: Panel
@export var more_label: Label

@export var thanks_panel: Panel
# Hinweis auf neu freigeschaltete Meilenstein-Ei-Attacken (Boss-Bildschirm / Spielende)
@export var unlock_label: Label
@export var win_unlock_label: Label

var missing_mon_egg = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# hier landet man nur nach Biom-Bossen, Boss-Felder auf der Karte zählen nicht
	show_unlocks(unlock_label, Skills.add_milestone_progress(State.starter_name, "biome_boss_kills"))
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

func show_unlocks(label: Label, skill_names: Array) -> void:
	if skill_names.is_empty():
		return
	var names = skill_names.map(func(skill_name): return tr(skill_name))
	label.text = tr("MILESTONE_UNLOCKED").format({
		"mon": Helper.mon_display_name(State.starter_name),
		"skills": ", ".join(PackedStringArray(names)),
	})
	label.visible = true

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
		show_unlocks(win_unlock_label, Skills.add_milestone_progress(State.starter_name, "game_wins"))
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

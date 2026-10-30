extends Control

# Endbildschirm eines Runs, für Sieg (boss_reward.gd) und Niederlage (battle.gd). Werte stehen in State.run_*.

const WIN_COLOR := Color(0.858824, 0.717647, 0.45098, 1)
const LOSE_COLOR := Color(0.75, 0.22, 0.2, 1)

@export var background: TextureRect
@export var title_label: Label
@export var subtitle_label: Label
@export var biome_path: Control
@export var stats_grid: GridContainer
@export var team_label: Label
@export var unlock_label: Label

func _ready() -> void:
	var color = WIN_COLOR if State.run_won else LOSE_COLOR
	background.material.set_shader_parameter("top_color", color)
	title_label.text = tr("RUN_END_WIN" if State.run_won else "RUN_END_LOSE")
	# Hintergrund hat dieselbe Farbe, daher heller Text mit dunkler Kontur
	title_label.add_theme_color_override("font_color", color.lightened(0.6))
	title_label.add_theme_color_override("font_outline_color", color.darkened(0.6))
	title_label.add_theme_constant_override("outline_size", 10)
	subtitle_label.text = tr("RUN_END_WIN_SUB" if State.run_won else "RUN_END_LOSE_SUB")

	# map_level ist der Index des aktuellen Bioms, nach dem Sieg steht er auf map_settings.size()
	var total_depth = Map.map_settings.size()
	var reached = mini(State.map_level + 1, total_depth)
	if not State.biome_path.is_empty():
		biome_path.show_path(State.biome_path, reached)

	_add_stat("RUN_END_DEPTH", "%d / %d" % [reached, total_depth])
	_add_stat("RUN_END_FIGHTS", str(State.overall_progress_level))
	_add_stat("RUN_END_KILLS", str(State.run_kills))
	_add_stat("RUN_END_CATCHES", str(State.run_catches))
	_add_stat("RUN_END_EP", str(State.run_ep_earned))

	var names = State.run_team.map(func(mon_name): return Helper.mon_display_name(mon_name))
	team_label.text = tr("RUN_END_TEAM").format({"team": ", ".join(PackedStringArray(names))})
	team_label.visible = not names.is_empty()

	if State.run_won:
		_show_unlocks(Skills.add_milestone_progress(State.starter_name, "game_wins"))

func _add_stat(key: String, value: String) -> void:
	var name_label = Label.new()
	name_label.text = tr(key)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	stats_grid.add_child(name_label)
	var value_label = Label.new()
	value_label.text = value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_grid.add_child(value_label)

func _show_unlocks(skill_names: Array) -> void:
	if skill_names.is_empty():
		return
	var names = skill_names.map(func(skill_name): return tr(skill_name))
	unlock_label.text = tr("MILESTONE_UNLOCKED").format({
		"mon": Helper.mon_display_name(State.starter_name),
		"skills": ", ".join(PackedStringArray(names)),
	})
	unlock_label.visible = true

func _on_new_run_pressed() -> void:
	State.reset()
	get_tree().change_scene_to_file("res://script/scenes/selection/selection.tscn")

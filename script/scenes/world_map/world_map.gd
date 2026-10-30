extends Control

@export var scroll_container: ScrollContainer

@export var map_layout: ColorRect

@export var battle_c: TextureRect
@export var camp_c: ColorRect

# new logic
@export var grid_container: GridContainer
@export var boss_button: Button
@export var node_container: Panel
@export var node_name: Button
@export var line_node: UILine

@export var boss_shard_label: Label
@export var money_label: Label
@export var depth_level: Label

@export var heal_camp_scene: PackedScene
@export var shop_scene: PackedScene
# gogogo
@export var jailer_scene: PackedScene
@export var trainer_scene: PackedScene
@export var treasure_scene: PackedScene

@export var view_container: Panel

var tweens = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	State.ep_changed.connect(change_ep_text)
	State.boss_shards_changed.connect(monster_shard_changed)
	State.pos_changed.connect(change_position)

	depth_level.text = str(State.map_level)
	boss_shard_label.text = str(State.boss_shards)
	money_label.text = str(State.ep)

	await get_tree().process_frame
	if State.killed_monsters >= 1:
		get_tree().change_scene_to_file("res://script/scenes/level_up/level_up.tscn")
		return 
	if State.is_boss_fight:
		get_tree().change_scene_to_file("res://script/scenes/boss_reward/boss_reward.tscn")
		State.is_boss_fight = false
		return
	#Events.map_event_pressed.connect(_call_map_event)
	if not State.current_map:
		Map.generate_starting_points()
	set_map()
	# direct from movement...
	scroll_container_to_bottom()
	if State.current_map_position == State.NO_MAP_POSITION:
		change_position(Vector3.ZERO, true)
	else:
		change_position(State.current_map_position)
	change_ep_text(State.ep)

#func _enter_tree() -> void:
#	Events.map_event_pressed.disconnect(_call_map_event)

func _exit_tree() -> void:
	State.ep_changed.disconnect(change_ep_text)
	State.pos_changed.disconnect(change_position)

func set_map():
	var _to_clear_children = grid_container.get_children()
	for child in _to_clear_children:
		grid_container.remove_child(child)
		child.queue_free()
	
	var screen_width = grid_container.size.x
	var gap = 100
	var map_y_height = State.current_map[0].size()
	for i in 8:
		for j in map_y_height:
			var new_container = node_container.duplicate()
			new_container.visible = true
			grid_container.add_child(new_container)
	# set map
	var grid_children = grid_container.get_children()
	for x_path_index in State.current_map.size():
		var x_path = State.current_map[x_path_index]
		for y_path_index in x_path.size():
			var y_path = x_path[y_path_index]
			var g_container = grid_children[y_path_index * State.current_map.size() + x_path_index]
			var d: Button = node_name.duplicate()
			if y_path != null:
				d.text = tr("MAP_NODE_" + y_path.get_name())
				d.text += "\n" + str(y_path._pos.z)
				d.pressed.connect(func(): call_map_event(y_path))
				d.visible = true
				y_path._ui_item = d
				g_container._path = y_path
				# if is below current path, reset all to done...
				# todo
				if State.current_map_position.y >= y_path._pos.y:
					reset_animation_state(y_path)
			g_container.add_child(d)
	# reverse...
	var children = grid_container.get_children()
	children.reverse()
	draw_lines()

	for child in children:
		grid_container.remove_child(child)

	for child in children:
		grid_container.add_child(child)

func draw_lines() -> void:
	var all_items = grid_container.get_children()
	for i in grid_container.columns:
		#path i
		var ally_nodes = all_items.filter(func(n): 
			if n != null and n._path != null:
				print(n._path._pos.z == i)
				return n._path._pos.z == i
			)
		for y_node in ally_nodes:
			print("gen line", ally_nodes.filter(func(n): return y_node._path._pos.y + 1 == n._path._pos.y).size())
			# get all next nodes
			var allnext_nodes = ally_nodes.filter(func(n): return y_node._path._pos.y + 1 == n._path._pos.y)
			for next_node in allnext_nodes:
				print("will draw")
				var line = line_node.duplicate(DUPLICATE_SCRIPTS | DUPLICATE_USE_INSTANTIATION)
				line.from_node = y_node
				line.to_node = next_node
				map_layout.add_child(line)
			pass
		pass
	pass

func _on_button_pressed() -> void:
	print("Map.gen_map()", State.current_map)
	Map.generate_starting_points()
	set_map()
	change_position(Vector3.ZERO, true)
	

func _call_map_event(map_node) -> void:
	if map_node._pos.y == State.map_progress_level:
		print("same level, go!")
		get_tree().change_scene_to_file("res://script/scenes/battle/battle.tscn")

func scroll_container_to_bottom() -> void:
	var cur_pos = State.current_map_position
	var map_height = grid_container.get_child_count() / grid_container.columns
	var damn_bro = scroll_container.get_v_scroll_bar().max_value - scroll_container.size.y
	grid_container.get_combined_minimum_size().y
	var scroll_pos = damn_bro - ((damn_bro / map_height) * cur_pos.y)
	var tween = get_tree().create_tween()
	var max_scroll = damn_bro
	tween.tween_property(
		scroll_container, "scroll_vertical",
		scroll_pos, map_height * .1 + 1
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func call_map_event(path_type) -> void:
	if path_type:
		if State.current_map_position == State.NO_MAP_POSITION and path_type._pos.y == 0:
			call_event_by_type(path_type._type)
			State.current_map_position = path_type._pos
			#reset_animation_state(path_type)
		if path_type._pos.y - 1 == State.current_map_position.y and path_type._pos.z == State.current_map_position.z:
			call_event_by_type(path_type._type)
			State.current_map_position = path_type._pos
			#reset_animation_state(path_type)

func call_event_by_type(type) -> void:
	if type == Map.PATH_TYPE.COMBAT:
		get_tree().change_scene_to_file("res://script/scenes/battle/battle.tscn")
		pass
	if type == Map.PATH_TYPE.BOSS:
		State.is_map_boss = true
		get_tree().change_scene_to_file("res://script/scenes/battle/battle.tscn")
	if type == Map.PATH_TYPE.CAMP:
		var hcs = heal_camp_scene.instantiate()
		view_container.add_child(hcs)
		hcs.visible = true
		pass
	if type == Map.PATH_TYPE.SHOP:
		var shops = shop_scene.instantiate()
		view_container.add_child(shops)
		shops.visible = true
		pass
	if type == Map.PATH_TYPE.TRAINER:
		var trainer = trainer_scene.instantiate()
		view_container.add_child(trainer)
		trainer.visible = true
		pass
	if type == Map.PATH_TYPE.TREASURE:
		var treasure = treasure_scene.instantiate()
		view_container.add_child(treasure)
		treasure.visible = true
		pass
	if type == Map.PATH_TYPE.JAILER:
		var jailer = jailer_scene.instantiate()
		view_container.add_child(jailer)
		jailer.visible = true
		pass
	print("call event", type)


func _on_boss_button_pressed() -> void:
	if State.current_map.size() > 0:
		if State.current_map_position.y + 1 == State.current_map[0].size():
			State.is_boss_fight = true
			if State.map_level == Map.map_settings.size() - 1:
				State.is_final_boss = true
			get_tree().change_scene_to_file("res://script/scenes/battle/battle.tscn")
			State.current_map_position = State.NO_MAP_POSITION

func change_position(pos, initial = false) -> void:
	for tween: Tween in tweens:
		tween.kill()
	tweens = []
	var all_nodes = []
	for i in State.current_map.size():
		all_nodes.append_array(State.current_map[i])
	
	var possible_walkable_nodes = all_nodes.filter(func(node): return node != null).filter(func(node): return node._pos.y == pos.y + 1 and node._pos.z == pos.z) if initial == false else all_nodes.filter(func(node): return node != null).filter(func(node): return node._pos.y == pos.y)
	# reset all positions here...
	var walked_ndoes = all_nodes.filter(func(node): return node != null).filter(func(node): return node._pos.y == pos.y)
	for walked_nodes in walked_ndoes:
		reset_animation_state(walked_nodes)

	for walkable_node in possible_walkable_nodes:
		if (walkable_node._ui_item):
			print("animate pos:", walkable_node._pos, State.current_map_position)
			var ub: Button = walkable_node._ui_item
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(ub, "scale", Vector2(1.2, 1.2), 3)
			tween.tween_property(ub, "scale", Vector2(1, 1), 3)
			tweens.append(tween)
			ub.add_theme_color_override("font_color", Color.DARK_GREEN)

func monster_shard_changed(ep) -> void:
	boss_shard_label.text = tr("WORLDMAP_BOSS_SHARDS").format({"amount": ep})

func change_ep_text(ep) -> void:
	money_label.text = tr("WORLDMAP_MONEY").format({"amount": ep})
	print("ep", str(ep))

func reset_animation_state(ele) -> void:
	ele._ui_item.scale = Vector2(1,1)
	ele._ui_item.add_theme_color_override("font_color", Color.DARK_CYAN)

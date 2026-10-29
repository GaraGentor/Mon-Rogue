extends Node

enum PATH_TYPE {
	COMBAT = 0,
	BOSS,
	CAMP,
	SHOP,
	TRAINER,
	JAILER,
	EVENT,
	TREASURE,
}

class path:
	var _type = PATH_TYPE.COMBAT
	var _pos = Vector3.ZERO
	var _path = []
	var _ui_item = null
	var _name_map = {
		0: "COMBAT",
		1: "BOSS",
		2: "CAMP",
		3: "SHOP",
		4: "TRAINER",
		5: "JAILER",
		6: "EVENT",
		7: "TREASURE",
	}

	func _init(pos: Vector3):
		_pos = pos
	
	func get_name() -> String:
		return _name_map[_type]

var max_rows = 8
var max_cols = 3
#var path = 

var map_settings = {
	0: {"paths":6, "special_nodes": 1, "bosses": [], "lines": 1, "tresures": [1], "shops": [], "trainers": [], "jailer": []},
	1: {"paths":8, "special_nodes": 2, "bosses": [3], "lines": 2, "tresures": [1], "shops": [], "trainers": [5], "jailer": []},
	2: {"paths":11, "special_nodes": 3, "bosses": [5], "lines": 2, "tresures": [2], "shops": [6], "trainers": [], "jailer": [0]},
	3: {"paths":14, "special_nodes": 4, "bosses": [7], "lines": 3, "tresures": [7], "shops": [5], "trainers": [8], "jailer": [2]},
	4: {"paths":17, "special_nodes": 6, "bosses": [6,12], "lines": 3, "tresures": [2,8], "shops": [9], "trainers": [], "jailer": []},
}

var all_nodes = []
var starting_nodes = []

func generate_starting_points():
	all_nodes = []
	starting_nodes = []
	var map_setting = map_settings[State.map_level]
	var lines = map_setting["lines"]
	var paths = map_setting["paths"]
	var y_grid = []
	for i in paths:
		y_grid.append(null)
	var grid = [y_grid.duplicate(),y_grid.duplicate(),y_grid.duplicate(),y_grid.duplicate(),y_grid.duplicate(),y_grid.duplicate(),y_grid.duplicate(),y_grid.duplicate()]
	var pick_starting_points = [0,1,2,3,4,5,6,7]
	for i in lines:
		var rand_pick = pick_starting_points.pick_random()
		var index_to_remove = pick_starting_points.find(rand_pick)
		var nn = path.new(Vector3(rand_pick, 0, i))
		grid[rand_pick][0] = nn
		all_nodes.append(nn)
		pick_starting_points.remove_at(index_to_remove)
		starting_nodes.append(rand_pick)
	generate_grid(grid)

func generate_grid(grid: Array):
	var map_setting = map_settings[State.map_level]
	var paths = map_setting["paths"]
	#for sp in starting_points:
	for x_path in grid.size():
		if grid[x_path][0] != null:
			for y_path in paths:
				var nn = path.new(Vector3(x_path,y_path,x_path))
				grid[x_path][y_path] = nn
				all_nodes.append(nn)
				
	generate_additional_nodes_per_path(grid)
	generate_last_fire_camps(grid)
	generate_hard_node_tiles(grid, "bosses", PATH_TYPE.BOSS)
	generate_hard_node_tiles(grid, "tresures", PATH_TYPE.TREASURE)
	generate_hard_node_tiles(grid, "shops", PATH_TYPE.SHOP)
	generate_hard_node_tiles(grid, "trainers", PATH_TYPE.TRAINER)
	generate_specials(grid)
	print_new_map(grid)
	State.current_map = grid

func generate_additional_nodes_per_path(grid: Array):
	var y_start_row = 0
	
	for i in starting_nodes:
		print("start_row:::", i)
		var y_row_size = grid[i].size()
		for y_row in y_row_size:
			if y_start_row == 0:
				y_start_row+= 1
				continue
			var r = randi_range(-1, 1)
			print("r:::", i + r)
			if i + r == -1:
				continue
			if i + r == 8:
				continue
			# check if there is already another path in it.
			if starting_nodes.has(i + r):
				continue
			var np = path.new(Vector3(i + r,y_row,i))
			grid[i + r][y_row] = np
			all_nodes.append(np)


func generate_specials(grid: Array):
	var map_setting = map_settings[State.map_level]
	var special_nodes = map_setting["special_nodes"]
	for i in starting_nodes:
		for j in special_nodes:
			var all_nodes_that_can_be_transformed = all_nodes.filter(func(_path: path): return _path._pos.z == i and _path._type == PATH_TYPE.COMBAT)
			if all_nodes_that_can_be_transformed.size() >= 1:
				var what_special_node = randi_range(1,7)
				var np = all_nodes_that_can_be_transformed.pick_random()
				np._type = what_special_node

func generate_hard_node_tiles(grid: Array, key, type):
	var map_setting = map_settings[State.map_level]
	var hard_node_positions = map_setting[key]
	for hard_node_position in hard_node_positions:
		var filtered_nodes = all_nodes.filter(func(_path:path): return _path._pos.y == hard_node_position)
		for hard_to_set_node: path in filtered_nodes:
			hard_to_set_node._type = type

func generate_last_fire_camps(grid: Array):
	for x_paths in grid:
		var index = grid.find(x_paths)
		var camp_node = path.new(Vector3(index,x_paths.size(),index))
		camp_node._type = PATH_TYPE.CAMP
		if starting_nodes.has(index):
			x_paths.append(camp_node)
			all_nodes.append(camp_node)
		else:
			x_paths.append(null)

func print_new_map(map) -> void:
	print("> > > > > > > > > > > > > > > > > > >")
	var print_y = []
	for x in map.size():
		var y_results = []
		for y in map[x].size():
			if map[x][y] != null:
				y_results.append(str(map[x][y]._type))
			else:
				y_results.append("-")
		print_y.append(y_results)
	for i in print_y.size():
		print(print_y[i])
	print("> > > > > > > > > > > > > > > > > > >")

func gen_map():
	var map = []
	# every 2 map levels + 1 max_rows
	var comp_max_rows = max_rows + State.map_level
	var comp_max_cols = max_cols + State.map_level
	var min_cols = State.map_level + 1
	
	var latest_cols = randi_range(min_cols, comp_max_cols)
	var max_generated_cols = 0
	for i in comp_max_rows:
		for j in latest_cols:
			var new_path = path.new(Vector3(j,i, 0))
			map.append(new_path)
		latest_cols += randi_range(-1, 1)
		latest_cols = clamp(latest_cols, min_cols, comp_max_cols)
		if max_generated_cols < latest_cols:
			max_generated_cols = latest_cols
			
	gen_paths(map)
	
	State.current_map = map

func gen_paths(map):
	for i in map:
		var can_move_to = map.filter(func(map_node): return map_node._pos.y == map_node._pos.y + 1)
		i._path = can_move_to

func get_highest_path_node(map: Array):
	var node_map = map.map(func(node): return node._position.y)
	return node_map.unique().max()
	

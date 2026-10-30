extends Node

var current_map: Array = []

# settings
var SETTING_LEVEL = 35
# 500 / State.SETTING_LEVEL
var INITIAL_LEVEL = 1
var INITIAL_MONS = ["1", "2", "1"]
# until more than 3 exist.
var TEST_INITIAL_MONS = ["1", "2"]

var mons: Array[Monster] = []
# Art des Start-Monsters (Ei), sammelt den Meilenstein-Fortschritt
var starter_name := ""
# Das Start-Monster selbst: Meilensteine zählen nur, solange genau dieses Exemplar noch im Team ist
var starter: Monster
var enemy_mons: Array[Monster] = []
var catched_mons: Array[Monster] = []
var fainted_own_mons: Array[Monster] = []
var fainted_enemy_mons: Array[Monster] = []
var relics := []
var overall_progress_level := 0
var map_progress_level := 0
var map_level := 0
# normale Kämpfe im aktuellen Biom, bestimmt Stufe und Anzahl der Gegner (siehe battle.gd ENCOUNTERS)
var biome_fight_index := 0
# Element-Masken der Biome pro Tiefe, einmal pro Run gewürfelt (siehe Map.generate_biome_path)
var biome_path: Array[int] = []

var shopped: Array = []

# Stats pro Monster-Art, einmal pro Run gewürfelt: name -> {"best_points": int, "growth": Growth}
var rolled_mon_stats: Dictionary = {}

# Monster-Arten, die in diesem Run schon besiegt wurden (deren Stats sind im Kampf sichtbar)
var defeated_mon_names: Array[String] = []

var is_boss_fight: bool = false
var is_final_boss: bool = false
# Boss-Feld mitten auf der Karte: Kampf in Boss-Stärke, beendet das Biom aber nicht
var is_map_boss: bool = false

# money
signal ep_changed(ep)
var ep: int = 0:
	set(val):
		ep = val
		ep_changed.emit(ep)

# shards to perma upgrade mons
signal boss_shards_changed(ep)
var boss_shards: int = 0:
	set(val):
		boss_shards = val
		boss_shards_changed.emit(boss_shards)


var killed_monsters: int = 0
signal pos_changed(pos)
# Linie 0 / Zeile 0 hat die Position (0,0,0), daher braucht "noch nicht gestartet" einen eigenen Wert
const NO_MAP_POSITION := Vector3(-1, -1, -1)
var current_map_position: Vector3 = NO_MAP_POSITION:
	set(vec3):
		current_map_position = vec3
		pos_changed.emit(vec3)

var map_progress_elements = []

func _ready() -> void:
	boss_shards = SaveManager.save_data["boss_shards"]

func reset() -> void:
	ep = 0
	map_level = 0
	biome_fight_index = 0
	biome_path = []
	map_progress_level = 0
	overall_progress_level = 0
	relics = []
	mons = []
	starter_name = ""
	starter = null
	enemy_mons = []
	catched_mons = []
	current_map = []
	fainted_own_mons = []
	fainted_enemy_mons = []
	killed_monsters = 0
	current_map_position = NO_MAP_POSITION
	shopped = []
	is_boss_fight = false
	is_final_boss = false
	is_map_boss = false
	rolled_mon_stats = {}
	defeated_mon_names = []

# Element-Maske des aktuellen Bioms, 0 wenn kein Biom-Pfad gewürfelt wurde.
func current_biome() -> int:
	return biome_path[map_level] if map_level < biome_path.size() else 0

# Würfelt die Stats für alle Monster-Arten neu.
func roll_mon_stats() -> void:
	rolled_mon_stats = {}
	for meta_data in Monmap.mons:
		rolled_mon_stats[meta_data.name] = {
			"best_points": randi_range(meta_data["stats"][0], meta_data["stats"][1]),
			"growth": Growth.new(),
		}

# Liefert die für diesen Run festen Stats einer Monster-Art (würfelt beim ersten Zugriff).
func get_mon_stats(mon_name: String) -> Dictionary:
	if rolled_mon_stats.is_empty():
		roll_mon_stats()
	return rolled_mon_stats[mon_name]

# Ist das Start-Monster noch im Team? K.O. gegangene (battle.gd _clear_fainted_mons) und abgegebene Monster
# (leaving_screen.gd) stehen nicht mehr in mons.
func is_starter_in_team() -> bool:
	return starter != null and mons.has(starter)

func mark_mon_defeated(mon_name: String) -> void:
	if not defeated_mon_names.has(mon_name):
		defeated_mon_names.append(mon_name)

func is_mon_defeated(mon_name: String) -> bool:
	return defeated_mon_names.has(mon_name)

func stage_clear(progress: int = 1) -> void:
	#for mon in mons:
	#	mon.upgrade_by_level(progress)
	map_progress_level += progress
	overall_progress_level += progress

extends Node

const SAVE_PATH := "user://savegame.json"

var save_data := {
	"version": 1,
	"boss_shards": 0,
	"monsters": {},
	"skills": {},
	"catched_monsters": [],
	"seen_monsters": [],
	# freigeschaltete Ei-Attacken: Monster-Name -> [Skill-Namen]
	"egg_skills": {},
}

# Called when the node enters the scene tree for the first time.
func _ready():
	load_game()

func save_game():
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	
	var parsed: Dictionary = JSON.parse_string(content)
	if typeof(parsed) == TYPE_DICTIONARY:
		# neue Felder in alten Spielständen ergänzen
		parsed.merge(save_data)
		save_data = parsed

func add_boss_shard(amount := 1):
	save_data["boss_shards"] += amount
	save_game()

func subtract_boss_shard(amount:=1):
	save_data["boss_shards"] -= amount
	save_game()

func add_mon_upgrade(monster_name = "1"):
	if not save_data["monsters"].has(monster_name):
		save_data["monsters"][monster_name] = {
			"upgrade": 1,
		}
	else:
		save_data["monsters"][monster_name] = {
			"upgrade": save_data["monsters"][monster_name]["upgrade"] + 1
		}
	save_game()

func add_seen_mon(monster_name = "1"):
	if not save_data["seen_monsters"].has(monster_name):
		save_data["seen_monsters"].append(monster_name)
	save_game()

func unlock_egg_skill(monster_name: String, skill_name: String):
	if not save_data["egg_skills"].has(monster_name):
		save_data["egg_skills"][monster_name] = []
	if not save_data["egg_skills"][monster_name].has(skill_name):
		save_data["egg_skills"][monster_name].append(skill_name)
	save_game()

func is_egg_skill_unlocked(monster_name: String, skill_name: String) -> bool:
	return save_data["egg_skills"].get(monster_name, []).has(skill_name)

func add_catched_monster_mon(monster_name = "1"):
	if not save_data["catched_monsters"].has(monster_name):
		save_data["catched_monsters"].append(monster_name)
	save_game()

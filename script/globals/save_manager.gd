extends Node

# Slot 1 behält den bisherigen Dateinamen, damit bestehende Spielstände einfach weiterlaufen
const SLOT_COUNT := 3
const SAVE_PATH := "user://savegame.json"
const SLOT_SAVE_PATH := "user://savegame_%d.json"
# Merkt sich nur, welcher Slot aktiv ist
const ACTIVE_SLOT_PATH := "user://save_slots.json"
# Kampfmodus: gehört fest zum Spielstand, damit sich der Fortschritt der Modi nicht vermischt
const MODE_CLASSIC := "classic"
const MODE_THREE_ACTIONS := "three_actions"
# Biom-Boss-Siege, bis in der Ei-Auswahl der Neu-Würfeln-Button erscheint (für Spieler unsichtbar)
const REROLL_CHARGES_NEEDED := 3

var active_slot := 1
var save_data := _new_save_data()

func _new_save_data() -> Dictionary:
	return {
		"version": 1,
		# alte Spielstände ohne dieses Feld sind klassisch
		"combat_mode": MODE_CLASSIC,
		"boss_shards": 0,
		"monsters": {},
		"skills": {},
		"catched_monsters": [],
		"seen_monsters": [],
		# freigeschaltete Ei-Attacken: Monster-Name -> [Skill-Namen]
		"egg_skills": {},
		# Meilenstein-Fortschritt pro Art als Start-Monster: Monster-Name -> {Zähler -> Anzahl} (siehe Skills.MILESTONES)
		# freigeschaltete Meilenstein-Ei-Attacken landen wie die anderen in egg_skills
		"milestones": {},
		"reroll_charges": 0,
		# wurden die gespeicherten Eier neu gewürfelt? Dann verbraucht der nächste Aufbruch die Ladungen
		"eggs_rerolled": false,
		# Eier der Start-Auswahl (Helper.egg_to_save), bleiben bis zum nächsten Run-Ende gleich
		"starter_eggs": [],
		# Biom-Pfad und Monster-Pools pro Tiefe (Map.load_biome_path), bleiben ebenfalls bis zum nächsten Run-Ende gleich
		"biome_path": [],
		"biome_pools": [],
	}

# Called when the node enters the scene tree for the first time.
func _ready():
	_load_active_slot()
	load_game()

func slot_path(slot: int) -> String:
	return SAVE_PATH if slot == 1 else SLOT_SAVE_PATH % slot

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

# Kampfmodus eines vorhandenen Slots, ohne ihn zu laden
func slot_mode(slot: int) -> String:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	return parsed.get("combat_mode", MODE_CLASSIC) if parsed is Dictionary else MODE_CLASSIC

# Wechselt den Slot. new_mode legt einen noch leeren Slot in diesem Modus an, bei vorhandenen zählt der gespeicherte.
# Der Aufrufer setzt danach State zurück und lädt die Szene neu.
func switch_slot(slot: int, new_mode := MODE_CLASSIC) -> void:
	active_slot = slot
	save_data = _new_save_data()
	save_data["combat_mode"] = new_mode
	load_game()
	var file := FileAccess.open(ACTIVE_SLOT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"active": slot}))

func combat_mode() -> String:
	return save_data["combat_mode"]

func is_three_actions() -> bool:
	return combat_mode() == MODE_THREE_ACTIONS

func _load_active_slot() -> void:
	if not FileAccess.file_exists(ACTIVE_SLOT_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ACTIVE_SLOT_PATH))
	if parsed is Dictionary:
		var slot := int(parsed.get("active", 1))
		# gelöschte Slot-Datei: zurück auf Slot 1, statt den Slot still als klassisch neu anzulegen
		if slot >= 1 and slot <= SLOT_COUNT and slot_exists(slot):
			active_slot = slot

func save_game():
	var file := FileAccess.open(slot_path(active_slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_game():
	if not slot_exists(active_slot):
		save_game()
		return

	var file := FileAccess.open(slot_path(active_slot), FileAccess.READ)
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

func lock_egg_skill(monster_name: String, skill_name: String):
	save_data["egg_skills"].get(monster_name, []).erase(skill_name)
	save_game()

func is_egg_skill_unlocked(monster_name: String, skill_name: String) -> bool:
	return save_data["egg_skills"].get(monster_name, []).has(skill_name)

func add_milestone_progress(monster_name: String, stat: String, amount := 1):
	if not save_data["milestones"].has(monster_name):
		save_data["milestones"][monster_name] = {}
	save_data["milestones"][monster_name][stat] = get_milestone_progress(monster_name, stat) + amount
	save_game()

func get_milestone_progress(monster_name: String, stat: String) -> int:
	return int(save_data["milestones"].get(monster_name, {}).get(stat, 0))

func add_reroll_charge():
	save_data["reroll_charges"] = mini(int(save_data["reroll_charges"]) + 1, REROLL_CHARGES_NEEDED)
	save_game()

func has_full_reroll_charges() -> bool:
	return int(save_data["reroll_charges"]) >= REROLL_CHARGES_NEEDED

func spend_reroll_charges():
	save_data["reroll_charges"] = 0
	save_data["eggs_rerolled"] = false
	save_game()

func set_starter_eggs(eggs: Array):
	save_data["starter_eggs"] = eggs
	save_game()

func set_biome_path(path: Array, pools: Array):
	save_data["biome_path"] = path
	save_data["biome_pools"] = pools
	save_game()

# Nach Sieg oder Niederlage: der nächste Run würfelt Eier und Biom-Pfad neu
func clear_run_start():
	save_data["starter_eggs"] = []
	save_data["biome_path"] = []
	save_data["biome_pools"] = []
	save_game()

func add_catched_monster_mon(monster_name = "1"):
	if not save_data["catched_monsters"].has(monster_name):
		save_data["catched_monsters"].append(monster_name)
	save_game()

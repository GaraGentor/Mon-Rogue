class_name Monster

var _name: String
var _type: int
var _sub_type: int

var _best_points: int = 500

var _growth: Growth

var _level: int
var _level_progress: int = 0
var _ep: int = 5
var _upgrades: int = 0
# Key aus Skills.BOUNTIES, wenn dieses wilde Monster ein Kopfgeld-Monster ist, sonst ""
var _bounty: String = ""
# Monster, das zuletzt Schaden verursacht hat (entscheidet, wer ein Kopfgeld bekommt)
var _last_hit_by: Monster
var _lost_hp: float = 0:
	set(value):
		_lost_hp = value
		#if _lost_hp < 0:
		#	_lost_hp = -0.1
		#if _lost_hp > hp():
		#	_lost_hp = hp()
		Events.deal_damage_to_monster.emit(self)
		await Events.damage_animation_done
		if not is_alive():
			Events.monster_faints.emit(self)

var _skills: Array
var _initial_moves: int = 1
var _computed_moves: int = 1:
	set(value):
		_computed_moves = value
		Events.refresh_ui_for_monster.emit()

func _init(level: int, meta_data: Dictionary) -> void:
	## get saved data and apply.
	Events.mon_upgraded.connect(mon_upgraded)

	_name = meta_data.name
	_type = meta_data.initial_type
	var rolled_stats = State.get_mon_stats(_name)
	_best_points = rolled_stats.best_points
	_growth = rolled_stats.growth
	_level = level + State.INITIAL_LEVEL
	upgrade_by_level(level)
	if SaveManager.save_data.monsters.has(_name):
		var filtered = SaveManager.save_data.monsters[_name]
		_upgrades = filtered.upgrade

func mon_upgraded(mon_name):
	if SaveManager.save_data.monsters.has(mon_name):
		var filtered = SaveManager.save_data.monsters[mon_name]
		_upgrades = filtered.upgrades

func upgrade_by_level(level: int = 0):
	_level += level
	upgrade_all_skills_by_level(level)
	pass
# TODO: skill klasse erstellen?
func upgrade_all_skills_by_level(level):
	pass
	#for skill in _skills:
	#	skill.value += skill.growth

func upgrade_skill(skill, level):
	pass

func reset_to_new_round():
	Events.refresh_ui_for_monster.emit()
	print("_upgrades", _upgrades, "_initial_moves", _initial_moves)
	_computed_moves = Relics.modify("moves", _initial_moves + _upgrades, self)

func unlock_skills():
	for skill in _skills:
		skill.scouted = true

# Ei-Attacke, die durch Opfern dieses Monsters freigeschaltet werden kann, sonst {}
func get_unlockable_egg_skill() -> Dictionary:
	for skill in _skills:
		if Skills.is_unlockable_egg_skill(self, skill):
			return skill
	return {}

func hp():
	return (_growth.hp * _level) * Helper.points_per_level(_best_points)

func attack():
	return (_growth.atk * _level) * Helper.points_per_level(_best_points)

func defense():
	return (_growth.def * _level) * Helper.points_per_level(_best_points)
	
func s_attack():
	return (_growth.s_atk * _level) * Helper.points_per_level(_best_points)
	
func s_defense():
	return (_growth.s_def * _level) * Helper.points_per_level(_best_points)

func speed():
	return (_growth.speed * _level) * Helper.points_per_level(_best_points)

func best():
	return _best_points

func is_alive() -> bool:
	return _lost_hp <= (_growth.hp * _level) * Helper.points_per_level(_best_points)

extends Node

func mon_metainfos_by_name(name: String) -> Dictionary:
	return mons.filter(func(mon): return mon.name == name)[0]

var mons = [
	{
		"name": "1",
		"rarity": Enums.MON_RARITY.COMMON,
		"initial_type": Enums.MON_TYPES.AIR,
		"stats": [450, 500],
		"max_upgrades": 2,
		# Ei-Attacken, die immer von Beginn an zur Wahl stehen
		"default_egg_skills": ["SKILL_BASIC_ATTACK", "SKILL_BASIC_BLOCK", "SKILL_GUST"],
		# Ei-Attacken, die wilde Monster dieser Art tragen können und durch Opfern freigeschaltet werden
		"unlockable_egg_skills": ["SKILL_PEBBLE_THROW", "SKILL_WIND_BLADE", "SKILL_FLAME_CLAW", "SKILL_THUNDER_STRIKE", "SKILL_ICE_SPEAR", "SKILL_CHAOS_NOVA"],
		"texture_back": preload("res://assets/mons/1/1_back.png"),
		"texture_front": preload("res://assets/mons/1/1_front.png"),
	},
	{
		"name": "2",
		"rarity": Enums.MON_RARITY.COMMON,
		"initial_type": Enums.MON_TYPES.WATER,
		"stats": [450, 500],
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK", "SKILL_BASIC_BLOCK", "SKILL_SPLASH"],
		"unlockable_egg_skills": ["SKILL_EMBER", "SKILL_TIDAL_SLAM", "SKILL_ROCK_CRUSH", "SKILL_MAGMA_BURST", "SKILL_ICE_SPEAR", "SKILL_CHAOS_NOVA"],
		"texture_back": preload("res://assets/mons/2/2_back.png"),
		"texture_front": preload("res://assets/mons/2/2_front.png"),
	}
]

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
		"default_egg_skills": ["SKILL_BASIC_ATTACK_AIR", "SKILL_BASIC_BLOCK_AIR", "SKILL_GUST"],
		# Ei-Attacken, die wilde Monster dieser Art tragen können und durch Opfern freigeschaltet werden
		"unlockable_egg_skills": ["SKILL_PEBBLE_THROW", "SKILL_WIND_BLADE", "SKILL_THUNDER_STRIKE"],
		# Ei-Attacken, die nur über Meilensteine mit dieser Art als Start-Monster freigeschaltet werden (siehe Skills.MILESTONES)
		"milestone_egg_skills": {"boss_1": "SKILL_TAILWIND_STRIKE", "boss_5": "SKILL_CYCLONE", "game_win": "SKILL_NORTHERN_GALE"},
		# Bounty-Hunter-Ei-Attacken: ein Monster dieser Art muss das Kopfgeld-Monster selbst besiegen (siehe Skills.BOUNTIES)
		"bounty_egg_skills": {"alpha_1": "SKILL_RAPTOR_DIVE", "alpha_2": "SKILL_HUNTERS_GALE", "northern_warden": "SKILL_TROPHY_TEMPEST"},
		"texture_back": preload("res://assets/mons/1/1_back.png"),
		"texture_front": preload("res://assets/mons/1/1_front.png"),
	},
	{
		"name": "2",
		"rarity": Enums.MON_RARITY.COMMON,
		"initial_type": Enums.MON_TYPES.WATER,
		"stats": [450, 500],
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_WATER", "SKILL_BASIC_BLOCK_WATER", "SKILL_SPLASH"],
		"unlockable_egg_skills": ["SKILL_EMBER", "SKILL_TIDAL_SLAM", "SKILL_MAGMA_BURST"],
		"milestone_egg_skills": {"boss_1": "SKILL_UNDERTOW", "boss_5": "SKILL_MAELSTROM", "game_win": "SKILL_NORTHERN_TIDE"},
		"bounty_egg_skills": {"alpha_1": "SKILL_SHARK_BITE", "alpha_2": "SKILL_HUNTERS_TIDE", "northern_warden": "SKILL_TROPHY_TSUNAMI"},
		"texture_back": preload("res://assets/mons/2/2_back.png"),
		"texture_front": preload("res://assets/mons/2/2_front.png"),
	}
]

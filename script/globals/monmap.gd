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
		"texture_back": preload("res://assets/mons/1/1_back.png"),
		"texture_front": preload("res://assets/mons/1/1_front.png"),
	},
	{
		"name": "2",
		"rarity": Enums.MON_RARITY.COMMON,
		"initial_type": Enums.MON_TYPES.WATER,
		"stats": [450, 500],
		"max_upgrades": 2,
		"texture_back": preload("res://assets/mons/2/2_back.png"),
		"texture_front": preload("res://assets/mons/2/2_front.png"),
	}
]

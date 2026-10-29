extends Node

func deal_damage(props):
	print("lose:" + str(props.skill.value) + ":" + str(props.from.attack()) + "::" + str(props.from.attack() * ((props.skill.value / 100))))
	props.mon._lost_hp += props.from.attack() * ((props.skill.value / 100))

func add_shield(props):
	pass
	# props.mon._shield += props.skill.value

var attack_skills = [
	{
		"cost": 1,
		"name": "SKILL_BASIC_ATTACK",
		"nature": Enums.MON_TYPES.WATER,
		"value": 20.0,
		"cooldown": 0,
		"damage_type": Enums.SKILL_DAMAGE_TYPE.PHYSICAL,
		"description": "SKILL_BASIC_ATTACK_DESC",
		"target": Enums.CARD_TARGETS.SINGLE_ENEMY,
		"scouted": false,
		"shop_cost": {"min": 5, "max": 15},
		"handle": func(props): deal_damage(props)
	}
]

var defensive_skills = [
	{
		"cost": 1,
		"name": "SKILL_BASIC_BLOCK",
		"nature": Enums.MON_TYPES.FIRE,
		"value": 2.0,
		"cooldown": 0,
		"damage_type": Enums.SKILL_DAMAGE_TYPE.PHYSICAL,
		"description": "SKILL_BASIC_BLOCK_DESC",
		"target": Enums.CARD_TARGETS.SINGLE_ENEMY,
		"scouted": false,
		"shop_cost": {"min": 5, "max": 15},
		"handle": func(props): add_shield(props)
	}
]

var buff_skills = [
	{
		"cost": 1,
		"name": "SKILL_STRENGTH_BLOCK",
		"nature": Enums.MON_TYPES.AIR,
		"damage": 2,
		"cooldown": 0,
		"damage_type": Enums.SKILL_DAMAGE_TYPE.ABILITY,
		"description": "SKILL_STRENGTH_BLOCK_DESC",
		"scouted": false,
		"shop_cost": {"min": 5, "max": 15},
		"target": Enums.CARD_TARGETS.SINGLE_ENEMY,
	}
]

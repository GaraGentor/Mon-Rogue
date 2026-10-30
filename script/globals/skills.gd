extends Node

func deal_damage(props):
	print("lose:" + str(props.skill.value) + ":" + str(props.from.attack()) + "::" + str(props.from.attack() * ((props.skill.value / 100))))
	props.mon._lost_hp += props.from.attack() * ((props.skill.value / 100))

func add_shield(props):
	pass
	# props.mon._shield += props.skill.value

# Stufe eines Skills (1 = schwach, 4 = sehr stark) -> Gewicht beim zufälligen Generieren.
# Je stärker der Skill, desto seltener taucht er auf.
const TIER_WEIGHTS = {1: 50, 2: 25, 3: 10, 4: 3}

# Liefert eine frische Kopie des Skills mit diesem Namen (aus allen Skill-Listen) oder {}.
func get_skill(skill_name: String) -> Dictionary:
	for list in [attack_skills, defensive_skills, buff_skills, egg_skills]:
		for skill in list:
			if skill.name == skill_name:
				var copy = skill.duplicate()
				copy.id = Helper.generate_fake_uuid()
				return copy
	return {}

func get_tier(skill_name: String) -> int:
	return get_skill(skill_name).get("tier", 1)

# Pro Biom-Tiefe werden höhere Stufen wahrscheinlicher (Faktor pro Stufe über 1).
const DEPTH_TIER_BONUS := 0.4

# Maximale Anzahl Skills, die ein Monster gleichzeitig beherrscht.
const MAX_SKILLS := 4

func get_weight(skill_name: String, depth: int = 0) -> float:
	var tier = get_tier(skill_name)
	return TIER_WEIGHTS[tier] * pow(1.0 + DEPTH_TIER_BONUS * depth, tier - 1)

# Zieht einen Skill-Namen gewichtet nach Stufe (und Biom-Tiefe).
func pick_weighted(skill_names: Array, depth: int = 0) -> String:
	if skill_names.is_empty():
		return ""
	var total = 0.0
	for skill_name in skill_names:
		total += get_weight(skill_name, depth)
	var roll = randf() * total
	for skill_name in skill_names:
		roll -= get_weight(skill_name, depth)
		if roll <= 0:
			return skill_name
	return skill_names.back()

# Zieht bis zu count verschiedene Skill-Namen gewichtet nach Stufe (und Biom-Tiefe).
func pick_weighted_unique(skill_names: Array, count: int, depth: int = 0) -> Array:
	var pool = skill_names.duplicate()
	var picked = []
	for i in min(count, pool.size()):
		var skill_name = pick_weighted(pool, depth)
		picked.append(skill_name)
		pool.erase(skill_name)
	return picked

# Ei-Attacken, deren Element zum Biom passt (biome_mask 0 = alle).
func get_biome_skills(biome_mask: int) -> Array:
	return egg_skills.filter(func(skill): return biome_mask == 0 or skill.nature & biome_mask != 0).map(
		func(skill): return skill.name)

# ─────────────────────────
# Lernen von Skills gefangener Monster

func knows_skill(mon: Monster, skill_name: String) -> bool:
	return mon._skills.any(func(skill): return skill.name == skill_name)

# ─────────────────────────
# Element-Regel: Ein Monster kann einen Skill nur einsetzen, wenn sein Typ alle Elemente des Skills enthält
# (Vulkan = Erde+Feuer+Wasser kann z. B. Erde, Feuer, Wasser, Magma, Schlamm, Dampf und Vulkan spielen).

func covers(type_mask: int, nature: int) -> bool:
	return nature & ~type_mask == 0

func can_use(mon: Monster, skill: Dictionary) -> bool:
	return covers(mon._type, skill.nature)

func can_use_name(mon: Monster, skill_name: String) -> bool:
	return covers(mon._type, get_skill(skill_name).nature)

# "Benötigt: Erde, Luft" für die Elemente, die dem Monster für diesen Skill noch fehlen ("" wenn spielbar).
func missing_elements_text(mon: Monster, skill: Dictionary) -> String:
	var missing = Enums.MON_TYPES.values().filter(func(element): return skill.nature & element and not mon._type & element)
	if missing.is_empty():
		return ""
	var labels = missing.map(func(element): return tr(ColorMap.get_combo(element).label))
	return tr("SKILL_NEEDS_ELEMENTS").format({"elements": ", ".join(PackedStringArray(labels))})

# Lern-Buttons: gesperrt, wenn das Monster den Skill schon kennt; fehlende Elemente werden als Hinweis angehängt
# (gelernt werden darf trotzdem, spielbar wird der Skill erst mit den passenden Elementen).
func setup_learn_button(button: Button, mon: Monster, skill: Dictionary, label_key: String) -> void:
	button.disabled = knows_skill(mon, skill.name)
	if button.disabled:
		button.text = tr("JUDGEMENT_LEARN_KNOWN")
	elif not can_use(mon, skill):
		button.text = tr(label_key) + " (" + missing_elements_text(mon, skill) + ")"
	else:
		button.text = tr(label_key)

# Kopie des Skills, wie das Monster ihn lernt.
func learnable_copy(skill: Dictionary) -> Dictionary:
	var copy = skill.duplicate()
	copy.id = Helper.generate_fake_uuid()
	copy.erase("egg_skill")
	return copy

# ─────────────────────────
# Ei-Attacken pro Monster-Art (siehe Monmap: default_egg_skills / unlockable_egg_skills)

# Alle Ei-Attacken, die die Art zu Beginn eines Runs mitnehmen kann (Standard + freigeschaltet).
func get_available_egg_skills(mon_name: String) -> Array:
	var meta = Monmap.mon_metainfos_by_name(mon_name)
	var available = meta.get("default_egg_skills", []).duplicate()
	for skill_name in meta.get("unlockable_egg_skills", []):
		if SaveManager.is_egg_skill_unlocked(mon_name, skill_name):
			available.append(skill_name)
	return available

# Ei-Attacken der Art, die noch freigeschaltet werden können.
func get_locked_egg_skills(mon_name: String) -> Array:
	var meta = Monmap.mon_metainfos_by_name(mon_name)
	return meta.get("unlockable_egg_skills", []).filter(
		func(skill_name): return not SaveManager.is_egg_skill_unlocked(mon_name, skill_name))

# Ist dieser Skill eines Monsters eine Ei-Attacke, die durch Opfern freigeschaltet werden kann?
func is_unlockable_egg_skill(mon: Monster, skill: Dictionary) -> bool:
	return skill.get("egg_skill", false) and get_locked_egg_skills(mon._name).has(skill.name)

# Basis-Angriff und -Block gibt es pro Element. Über die Werte bekommt jedes Element seinen Charakter:
# Feuer greift hart an und blockt kaum, Erde blockt viel und trifft schwächer, Wasser und Luft liegen dazwischen.
var attack_skills = [
	_basic_skill("SKILL_BASIC_ATTACK_EARTH", Enums.MON_TYPES.EARTH, 16.0, "SKILL_BASIC_ATTACK_DESC", func(props): deal_damage(props)),
	_basic_skill("SKILL_BASIC_ATTACK_FIRE", Enums.MON_TYPES.FIRE, 24.0, "SKILL_BASIC_ATTACK_DESC", func(props): deal_damage(props)),
	_basic_skill("SKILL_BASIC_ATTACK_WATER", Enums.MON_TYPES.WATER, 20.0, "SKILL_BASIC_ATTACK_DESC", func(props): deal_damage(props)),
	_basic_skill("SKILL_BASIC_ATTACK_AIR", Enums.MON_TYPES.AIR, 22.0, "SKILL_BASIC_ATTACK_DESC", func(props): deal_damage(props)),
]

var defensive_skills = [
	_basic_skill("SKILL_BASIC_BLOCK_EARTH", Enums.MON_TYPES.EARTH, 4.0, "SKILL_BASIC_BLOCK_DESC", func(props): add_shield(props)),
	_basic_skill("SKILL_BASIC_BLOCK_FIRE", Enums.MON_TYPES.FIRE, 1.0, "SKILL_BASIC_BLOCK_DESC", func(props): add_shield(props)),
	_basic_skill("SKILL_BASIC_BLOCK_WATER", Enums.MON_TYPES.WATER, 3.0, "SKILL_BASIC_BLOCK_DESC", func(props): add_shield(props)),
	_basic_skill("SKILL_BASIC_BLOCK_AIR", Enums.MON_TYPES.AIR, 2.0, "SKILL_BASIC_BLOCK_DESC", func(props): add_shield(props)),
]

func _basic_skill(skill_name: String, nature: int, value: float, description: String, handle: Callable) -> Dictionary:
	return {
		"cost": 1,
		"name": skill_name,
		"nature": nature,
		"value": value,
		"cooldown": 0,
		"damage_type": Enums.SKILL_DAMAGE_TYPE.PHYSICAL,
		"description": description,
		"target": Enums.CARD_TARGETS.SINGLE_ENEMY,
		"scouted": false,
		"tier": 1,
		"shop_cost": {"min": 5, "max": 15},
		"handle": handle
	}

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

# Test-Skills für Ei-Attacken (alle Schaden auf ein Ziel), Stufe 1-4 bestimmt die Seltenheit.
var egg_skills = [
	_egg_skill("SKILL_GUST", Enums.MON_TYPES.AIR, 25.0, 1, Enums.SKILL_DAMAGE_TYPE.ABILITY),
	_egg_skill("SKILL_SPLASH", Enums.MON_TYPES.WATER, 25.0, 1, Enums.SKILL_DAMAGE_TYPE.ABILITY),
	_egg_skill("SKILL_EMBER", Enums.MON_TYPES.FIRE, 25.0, 1, Enums.SKILL_DAMAGE_TYPE.ABILITY),
	_egg_skill("SKILL_PEBBLE_THROW", Enums.MON_TYPES.EARTH, 25.0, 1, Enums.SKILL_DAMAGE_TYPE.PHYSICAL),
	_egg_skill("SKILL_WIND_BLADE", Enums.MON_TYPES.AIR, 40.0, 2, Enums.SKILL_DAMAGE_TYPE.PHYSICAL),
	_egg_skill("SKILL_TIDAL_SLAM", Enums.MON_TYPES.WATER, 40.0, 2, Enums.SKILL_DAMAGE_TYPE.PHYSICAL),
	_egg_skill("SKILL_FLAME_CLAW", Enums.MON_TYPES.FIRE, 40.0, 2, Enums.SKILL_DAMAGE_TYPE.PHYSICAL),
	_egg_skill("SKILL_ROCK_CRUSH", Enums.MON_TYPES.EARTH, 40.0, 2, Enums.SKILL_DAMAGE_TYPE.PHYSICAL),
	_egg_skill("SKILL_THUNDER_STRIKE", Enums.MON_TYPES.AIR | Enums.MON_TYPES.FIRE, 60.0, 3, Enums.SKILL_DAMAGE_TYPE.ABILITY),
	_egg_skill("SKILL_ICE_SPEAR", Enums.MON_TYPES.AIR | Enums.MON_TYPES.WATER, 60.0, 3, Enums.SKILL_DAMAGE_TYPE.PHYSICAL),
	_egg_skill("SKILL_MAGMA_BURST", Enums.MON_TYPES.EARTH | Enums.MON_TYPES.FIRE, 60.0, 3, Enums.SKILL_DAMAGE_TYPE.ABILITY),
	_egg_skill("SKILL_CHAOS_NOVA", Enums.MON_TYPES.AIR | Enums.MON_TYPES.WATER | Enums.MON_TYPES.FIRE | Enums.MON_TYPES.EARTH, 90.0, 4, Enums.SKILL_DAMAGE_TYPE.ABILITY),
]

func _egg_skill(skill_name: String, nature: int, value: float, tier: int, damage_type: int) -> Dictionary:
	return {
		"cost": 1,
		"name": skill_name,
		"nature": nature,
		"value": value,
		"cooldown": tier - 1,
		"damage_type": damage_type,
		"description": "SKILL_DAMAGE_PHYSICAL_DESC" if damage_type == Enums.SKILL_DAMAGE_TYPE.PHYSICAL else "SKILL_DAMAGE_ABILITY_DESC",
		"target": Enums.CARD_TARGETS.SINGLE_ENEMY,
		"scouted": false,
		"tier": tier,
		"shop_cost": {"min": 5 * tier, "max": 15 * tier},
		"handle": func(props): deal_damage(props)
	}

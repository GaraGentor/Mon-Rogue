extends Node

func deal_damage(props):
	# für Kopfgelder: wer zuletzt getroffen hat, hat das Monster besiegt
	props.mon._last_hit_by = props.from
	var damage = calc_damage(props.from, props.mon, props.skill)
	var multiplier = element_multiplier(props.skill.nature, props.mon._type)
	print("lose:" + str(props.skill.value) + ":" + str(damage) + " (Element x" + str(multiplier) + ")")
	Events.monster_hit_with_element.emit(props.mon, damage, multiplier)
	props.mon._lost_hp += damage

# ─────────────────────────
# Schadensformel
# Physisch: Angriff gegen Verteidigung, Magisch: Sp. Angriff gegen Sp. Verteidigung.
# Bei gleichen Werten bleibt der Schaden wie vorher (Faktor 1), mehr Angriff -> bis zu x2, mehr Verteidigung -> gegen 0.

func calc_damage(from: Monster, to: Monster, skill: Dictionary) -> float:
	var physical = skill.get("damage_type", Enums.SKILL_DAMAGE_TYPE.PHYSICAL) == Enums.SKILL_DAMAGE_TYPE.PHYSICAL
	var atk = from.attack() if physical else from.s_attack()
	var def = to.defense() if physical else to.s_defense()
	var stat_factor = 2.0 * atk / max(atk + def, 0.001)
	return atk * (skill.value / 100) * stat_factor * element_multiplier(skill.nature, to._type)

# ─────────────────────────
# Element-Kreis: Wasser > Feuer > Luft > Erde > Wasser
# (Wasser löscht Feuer, Feuer verzehrt Luft, Wind trägt Erde ab, Erde dämmt Wasser ein.)
# Gegenüberliegende Elemente (Wasser/Luft, Feuer/Erde) sind neutral zueinander.
const STRONG_AGAINST = {
	Enums.MON_TYPES.WATER: Enums.MON_TYPES.FIRE,
	Enums.MON_TYPES.FIRE: Enums.MON_TYPES.AIR,
	Enums.MON_TYPES.AIR: Enums.MON_TYPES.EARTH,
	Enums.MON_TYPES.EARTH: Enums.MON_TYPES.WATER,
}
const ELEMENT_BONUS := 0.5

# Jedes Element des Skills wird gegen jedes Element des Ziels verglichen:
# +1 wenn der Skill stark dagegen ist, -1 wenn das Ziel-Element den Skill abwehrt.
# Kombinierte Monster erben damit alle Schwächen und alle Resistenzen ihrer Elemente, die sich gegenseitig aufheben können.
func element_score(skill_nature: int, target_type: int) -> int:
	var score = 0
	for attack_element in STRONG_AGAINST:
		if not skill_nature & attack_element:
			continue
		for defend_element in STRONG_AGAINST:
			if not target_type & defend_element:
				continue
			if STRONG_AGAINST[attack_element] == defend_element:
				score += 1
			elif STRONG_AGAINST[defend_element] == attack_element:
				score -= 1
	return score

# Macht der Skill Schaden? (Block-Skills haben zwar einen Wert und ein Gegner-Ziel, aber keinen Schaden.)
func is_damage_skill(skill: Dictionary) -> bool:
	return skill.has("value") and not defensive_skills.any(func(block): return block.name == skill.name)

# +1 -> x1.5, +2 -> x2.0, ... / -1 -> x0.5, -2 -> x0.25, ...
func element_multiplier(skill_nature: int, target_type: int) -> float:
	var score = element_score(skill_nature, target_type)
	if score >= 0:
		return 1.0 + ELEMENT_BONUS * score
	return pow(1.0 - ELEMENT_BONUS, -score)

func add_shield(props):
	pass
	# props.mon._shield += props.skill.value

# Stufe eines Skills (1 = schwach, 4 = sehr stark) -> Gewicht beim zufälligen Generieren.
# Je stärker der Skill, desto seltener taucht er auf.
const TIER_WEIGHTS = {1: 50, 2: 25, 3: 10, 4: 3}

# Liefert eine frische Kopie des Skills mit diesem Namen (aus allen Skill-Listen) oder {}.
func get_skill(skill_name: String) -> Dictionary:
	for list in [attack_skills, defensive_skills, buff_skills, egg_skills, milestone_skills, bounty_skills]:
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
const MAX_SKILLS := 6

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
	for skill_name in meta.get("milestone_egg_skills", {}).values() + meta.get("bounty_egg_skills", {}).values():
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

# ─────────────────────────
# Meilenstein-Ei-Attacken: feste Freischaltungen pro Art, gezählt wird nur mit der Art als Start-Monster
# und nur, solange das Start-Monster selbst noch im Team ist (ausgetauscht oder K.O. = kein Fortschritt).
# Welcher Skill zu welchem Meilenstein gehört, steht in Monmap (milestone_egg_skills).
# Sie tauchen nie bei wilden Monstern oder im Biom-Pool auf, man bekommt sie nur über den Meilenstein.
# stat ist der Zähler in SaveManager (pro Art), hint der Freischalt-Hinweis im Konfigurator.
const MILESTONES = [
	{"key": "boss_1", "stat": "biome_boss_kills", "count": 1, "hint": "MILESTONE_HINT_BOSS_1"},
	{"key": "boss_5", "stat": "biome_boss_kills", "count": 5, "hint": "MILESTONE_HINT_BOSS_5"},
	{"key": "game_win", "stat": "game_wins", "count": 1, "hint": "MILESTONE_HINT_GAME_WIN"},
]

# Noch gesperrte Meilensteine der Art als [{skill, hint, ...}].
func get_locked_milestones(mon_name: String) -> Array:
	var skills_by_key = Monmap.mon_metainfos_by_name(mon_name).get("milestone_egg_skills", {})
	var locked = []
	for milestone in MILESTONES:
		var skill_name = skills_by_key.get(milestone.key, "")
		if skill_name != "" and not SaveManager.is_egg_skill_unlocked(mon_name, skill_name):
			var entry = milestone.duplicate()
			entry.skill = skill_name
			locked.append(entry)
	return locked

# Zählt einen Meilenstein-Zähler der Art hoch und liefert die Namen der dadurch neu freigeschalteten Skills.
func add_milestone_progress(mon_name: String, stat: String) -> Array:
	if mon_name == "" or not State.is_starter_in_team():
		return []
	SaveManager.add_milestone_progress(mon_name, stat)
	var unlocked = []
	for milestone in get_locked_milestones(mon_name):
		if SaveManager.get_milestone_progress(mon_name, milestone.stat) >= milestone.count:
			SaveManager.unlock_egg_skill(mon_name, milestone.skill)
			unlocked.append(milestone.skill)
	return unlocked

# ─────────────────────────
# Bounty Hunter: besondere Kopfgeld-Monster tauchen selten in normalen Kämpfen auf.
# Nur wenn ein Monster einer Art den letzten Treffer selbst landet, bekommt diese Art die Ei-Attacke aus
# Monmap (bounty_egg_skills). K.O. durch ein anderes Team-Mitglied oder Fangen zählt nicht.
# mon: Art des Kopfgeld-Monsters, level_bonus: Stufen über dem Kampf, min_depth: ab welcher Biom-Tiefe es auftaucht,
# label: Anzeigename (Platzhalter {mon} = Name der Art), hint: Freischalt-Hinweis im Konfigurator.
# Beispiele, bis es eigene Monster für die Kopfgelder gibt. Bekommt ein Kopfgeld eine eigene Art, trägt diese in
# Monmap "bounty_target": "<key>" und kommt in den normalen Spawn-Pool: dann zählt jedes Auftauchen als Kopfgeld-Monster.
const BOUNTIES = [
	{"key": "alpha_1", "mon": "1", "level_bonus": 2, "min_depth": 0, "label": "BOUNTY_ALPHA", "hint": "BOUNTY_HINT_ALPHA_1"},
	{"key": "alpha_2", "mon": "2", "level_bonus": 2, "min_depth": 1, "label": "BOUNTY_ALPHA", "hint": "BOUNTY_HINT_ALPHA_2"},
	{"key": "northern_warden", "mon": "1", "level_bonus": 4, "min_depth": 3, "label": "BOUNTY_NORTHERN_WARDEN", "hint": "BOUNTY_HINT_NORTHERN_WARDEN"},
]

# Chance pro normalem Kampf, dass ein Kopfgeld-Monster eingestreut wird (zusätzlich zu denen, die von selbst kommen).
# Ein ganzer Run hat rund 26 normale Kämpfe: 1 - 0.985^26 ≈ 33 %, also etwa jeder dritte Run.
const BOUNTY_CHANCE := 0.015

func get_bounty(key: String) -> Dictionary:
	for bounty in BOUNTIES:
		if bounty.key == key:
			return bounty
	return {}

# Noch gesperrte Kopfgelder der Art als [{skill, hint, ...}].
func get_locked_bounties(mon_name: String) -> Array:
	var skills_by_key = Monmap.mon_metainfos_by_name(mon_name).get("bounty_egg_skills", {})
	var locked = []
	for bounty in BOUNTIES:
		var skill_name = skills_by_key.get(bounty.key, "")
		if skill_name != "" and not SaveManager.is_egg_skill_unlocked(mon_name, skill_name):
			var entry = bounty.duplicate()
			entry.skill = skill_name
			locked.append(entry)
	return locked

# Kopfgelder, die für mindestens ein Team-Monster noch etwas freischalten und in dieser Biom-Tiefe auftauchen.
func get_open_bounties(team: Array, depth: int) -> Array:
	var keys = []
	for mon in team:
		for bounty in get_locked_bounties(mon._name):
			if bounty.min_depth <= depth and not keys.has(bounty.key):
				keys.append(bounty.key)
	return keys.map(func(key): return get_bounty(key))

# Das Kopfgeld-Monster wurde besiegt: freigeschaltet wird nur für die Art, die den letzten Treffer gelandet hat.
# Liefert den Namen der neu freigeschalteten Ei-Attacke oder "".
func claim_bounty(defeated: Monster) -> String:
	var killer = defeated._last_hit_by
	if defeated._bounty == "" or killer == null or not State.mons.has(killer):
		return ""
	var skill_name = Monmap.mon_metainfos_by_name(killer._name).get("bounty_egg_skills", {}).get(defeated._bounty, "")
	if skill_name == "" or SaveManager.is_egg_skill_unlocked(killer._name, skill_name):
		return ""
	SaveManager.unlock_egg_skill(killer._name, skill_name)
	return skill_name

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

# Meilenstein-Ei-Attacken pro Art, nur im Grund-Element der Art: das Start-Monster kann sie immer einsetzen.
# Stufe 3 liegt etwas unter den Mehr-Element-Skills (60), braucht dafür aber keine weiteren Elemente.
var milestone_skills = [
	# Monster 1 (Luft)
	_egg_skill("SKILL_TAILWIND_STRIKE", Enums.MON_TYPES.AIR, 28.0, 1, Enums.SKILL_DAMAGE_TYPE.PHYSICAL),
	_egg_skill("SKILL_CYCLONE", Enums.MON_TYPES.AIR, 42.0, 2, Enums.SKILL_DAMAGE_TYPE.ABILITY),
	_egg_skill("SKILL_NORTHERN_GALE", Enums.MON_TYPES.AIR, 55.0, 3, Enums.SKILL_DAMAGE_TYPE.ABILITY),
	# Monster 2 (Wasser)
	_egg_skill("SKILL_UNDERTOW", Enums.MON_TYPES.WATER, 28.0, 1, Enums.SKILL_DAMAGE_TYPE.ABILITY),
	_egg_skill("SKILL_MAELSTROM", Enums.MON_TYPES.WATER, 42.0, 2, Enums.SKILL_DAMAGE_TYPE.ABILITY),
	_egg_skill("SKILL_NORTHERN_TIDE", Enums.MON_TYPES.WATER, 55.0, 3, Enums.SKILL_DAMAGE_TYPE.PHYSICAL),
]

# Bounty-Hunter-Ei-Attacken pro Art, wie die Meilenstein-Skills nur im Grund-Element der Art.
# Gibt es nur über Kopfgelder, nie bei wilden Monstern oder im Biom-Pool.
var bounty_skills = [
	# Monster 1 (Luft)
	_egg_skill("SKILL_RAPTOR_DIVE", Enums.MON_TYPES.AIR, 42.0, 2, Enums.SKILL_DAMAGE_TYPE.PHYSICAL),
	_egg_skill("SKILL_HUNTERS_GALE", Enums.MON_TYPES.AIR, 58.0, 3, Enums.SKILL_DAMAGE_TYPE.ABILITY),
	_egg_skill("SKILL_TROPHY_TEMPEST", Enums.MON_TYPES.AIR, 75.0, 4, Enums.SKILL_DAMAGE_TYPE.ABILITY),
	# Monster 2 (Wasser)
	_egg_skill("SKILL_SHARK_BITE", Enums.MON_TYPES.WATER, 42.0, 2, Enums.SKILL_DAMAGE_TYPE.PHYSICAL),
	_egg_skill("SKILL_HUNTERS_TIDE", Enums.MON_TYPES.WATER, 58.0, 3, Enums.SKILL_DAMAGE_TYPE.ABILITY),
	_egg_skill("SKILL_TROPHY_TSUNAMI", Enums.MON_TYPES.WATER, 75.0, 4, Enums.SKILL_DAMAGE_TYPE.PHYSICAL),
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

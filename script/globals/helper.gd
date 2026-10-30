extends Node

func generate_fake_uuid() -> String:
	return "%s-%s" % [str(randi()), str(Time.get_ticks_usec())]

func points_per_level(bst: int) -> float:
	return bst / State.SETTING_LEVEL

## Grund-Fangchance pro Seltenheit (bei 0 HP und gleicher Stufe wie das eigene Team)
const CATCH_RARITY_BASE := {
	Enums.MON_RARITY.COMMON: 0.9,
	Enums.MON_RARITY.UNCOMMON: 0.7,
	Enums.MON_RARITY.RARE: 0.5,
	Enums.MON_RARITY.EPIC: 0.3,
	Enums.MON_RARITY.LEGENDARY: 0.15,
}
## Anteil der Chance, der bei vollen HP wegfällt (0.75 = volle HP ergeben nur 25 % der Grundchance)
const CATCH_HP_WEIGHT := 0.75
## Chance-Abzug pro Stufe, die das Monster über dem eigenen Team liegt (darunter entsprechend Bonus)
const CATCH_LEVEL_STEP := 0.08
const CATCH_LEVEL_FACTOR_RANGE := [0.25, 1.3]
const CATCH_CHANCE_RANGE := [0.02, 0.95]

## Fangchance 0..1: je weniger HP, desto leichter; höhere Stufe und Seltenheit machen es schwerer.
func catch_chance(mon: Monster) -> float:
	var rarity: int = Monmap.mon_metainfos_by_name(mon._name).get("rarity", Enums.MON_RARITY.COMMON)
	# Kopfgeld-Monster sind eine Seltenheitsstufe schwerer zu fangen
	if mon._bounty != "":
		rarity = mini(rarity + 1, Enums.MON_RARITY.LEGENDARY)
	var hp_left = clampf(1.0 - mon._lost_hp / mon.hp(), 0.0, 1.0)
	var hp_factor = 1.0 - CATCH_HP_WEIGHT * hp_left
	var level_factor = clampf(1.0 - CATCH_LEVEL_STEP * (mon._level - _team_level()),
		CATCH_LEVEL_FACTOR_RANGE[0], CATCH_LEVEL_FACTOR_RANGE[1])
	return clampf(CATCH_RARITY_BASE[rarity] * hp_factor * level_factor,
		CATCH_CHANCE_RANGE[0], CATCH_CHANCE_RANGE[1])

## Durchschnittsstufe der noch kämpfenden eigenen Monster
func _team_level() -> float:
	var alive = State.mons.filter(func(m: Monster): return m.is_alive())
	if alive.is_empty():
		return 0.0
	return alive.reduce(func(sum, m: Monster): return sum + m._level, 0) / float(alive.size())

func will_catch_mon(mon) -> bool:
	return randf() < catch_chance(mon)

func generate_mons(props: Dictionary = {
	"count": 1,
	"level": 1,
	"initial": false,
}) -> Array[Monster]:
	
	var default_props = {
		"count": 1,
		"level": 1,
		"initial": false,
	}
	default_props.merge(props, true)
	print(OS.get_user_data_dir())
	var mons_to_pick = ["1", "2"]
	var mons: Array[Monster] = []
	if default_props.initial:
		var initial_mons = []
		var comp_mons = State.INITIAL_MONS.duplicate()
		#print("SaveManager.save_data", SaveManager.save_data)
		comp_mons.append_array(SaveManager.save_data.catched_monsters.duplicate(true))
		for j in 3:
			var rand = comp_mons.pick_random()
			initial_mons.append(comp_mons.pick_random())
			comp_mons.erase(rand)
		for i in initial_mons:
			var mon_meta_data = Monmap.mon_metainfos_by_name(i)
			var newMon = Monster.new(default_props.level, mon_meta_data)
			# Vorschlag aus den verfügbaren Ei-Attacken, im Konfigurator noch änderbar
			# spielbare Attacken zuerst, nicht spielbare nur zum Auffüllen
			var available = Skills.get_available_egg_skills(i)
			var usable = available.filter(func(skill_name): return Skills.can_use_name(newMon, skill_name))
			var proposal = Skills.pick_weighted_unique(usable, 3)
			proposal.append_array(Skills.pick_weighted_unique(available.filter(func(skill_name): return not proposal.has(skill_name)), 3 - proposal.size()))
			for skill_name in proposal:
				var skill = Skills.get_skill(skill_name)
				skill.scouted = true
				newMon._skills.append(skill)
			mons.append(newMon)
		return mons

	# optional ein Kopfgeld-Monster (Eintrag aus Skills.BOUNTIES) als erster Gegner
	var bounty: Dictionary = props.get("bounty", {})
	for i in default_props.count:
		var mon_meta_data = Monmap.mon_metainfos_by_name(bounty.mon if i == 0 and not bounty.is_empty() else mons_to_pick.pick_random())
		var newMon = Monster.new(default_props.level, mon_meta_data)
		# eigene Kopfgeld-Arten (Monmap bounty_target) sind auch bei normalem Auftauchen das Kopfgeld-Monster
		newMon._bounty = bounty.key if i == 0 and not bounty.is_empty() else mon_meta_data.get("bounty_target", "")
		add_biome_element(newMon)
		roll_wild_skills(newMon, mon_meta_data)
		roll_egg_skill(newMon)
		mons.append(newMon)
	return mons

# Ab Biomen mit so vielen Elementen nehmen wilde Monster zwei Biom-Elemente an statt einem.
const DEEP_BIOME_ELEMENTS := 3

# Wilde Monster nehmen Elemente des aktuellen Bioms an, die sie noch nicht haben (Luft im Feuer-Biom -> Blitz).
# In tiefen Biomen zwei, damit auch Skills mit drei oder vier Elementen in freier Wildbahn auftauchen.
func add_biome_element(mon: Monster) -> void:
	var biome = State.current_biome()
	var count = 2 if Map.count_elements(biome) >= DEEP_BIOME_ELEMENTS else 1
	var candidates = Enums.MON_TYPES.values().filter(func(element): return biome & element and not mon._type & element)
	candidates.shuffle()
	for element in candidates.slice(0, count):
		mon._type |= element

const WILD_SKILL_COUNT := 3

# Wilde Monster: ein Skill ihrer Art, der Rest aus dem Pool des aktuellen Bioms (tiefere Biome -> stärkere Skills).
# Gezogen werden nur Skills, die das Monster mit seinem Typ auch einsetzen kann.
func roll_wild_skills(mon: Monster, mon_meta_data: Dictionary) -> void:
	var usable = func(skill_name): return Skills.can_use_name(mon, skill_name)
	var species_pool = mon_meta_data.default_egg_skills.filter(usable)
	var skill_names = [Skills.pick_weighted(species_pool)]
	var not_picked = func(skill_name): return not skill_names.has(skill_name)
	var biome_pool = Skills.get_biome_skills(State.current_biome()).filter(usable).filter(not_picked)
	skill_names.append_array(Skills.pick_weighted_unique(biome_pool, WILD_SKILL_COUNT - skill_names.size(), State.map_level))
	# zu wenig passende Biom-Skills: mit den Skills der Art auffüllen
	skill_names.append_array(Skills.pick_weighted_unique(species_pool.filter(not_picked), WILD_SKILL_COUNT - skill_names.size()))
	for skill_name in skill_names:
		mon._skills.append(Skills.get_skill(skill_name))

const EGG_SKILL_CHANCE := 0.35

# Wilde Monster tragen mit etwas Glück genau eine noch nicht freigeschaltete Ei-Attacke ihrer Art.
func roll_egg_skill(mon: Monster) -> void:
	var locked = Skills.get_locked_egg_skills(mon._name)
	if locked.is_empty() or randf() > EGG_SKILL_CHANCE:
		return
	# bevorzugt Ei-Attacken, die das Monster selbst einsetzen kann
	var usable_locked = locked.filter(func(skill_name): return Skills.can_use_name(mon, skill_name))
	var skill = Skills.get_skill(Skills.pick_weighted(usable_locked if not usable_locked.is_empty() else locked, State.map_level))
	skill.egg_skill = true
	# trägt das Monster den Skill schon (aus dem Biom-Pool), wird genau dieser markiert
	var index = mon._skills.map(func(s): return s.name).find(skill.name)
	mon._skills[index if index != -1 else mon._skills.size() - 1] = skill
	
func color_by_mon(mon: Monster) -> Color:
	return ColorMap.get_combo(mon._type).color

func mon_display_name(mon_name: String) -> String:
	return tr("MONSTER_" + mon_name)

# Anzeigename eines konkreten Monsters, Kopfgeld-Monster tragen ihren Titel ("Alpha 1").
func mon_battle_name(mon: Monster) -> String:
	if mon._bounty == "":
		return mon_display_name(mon._name)
	return tr(Skills.get_bounty(mon._bounty).label).format({"mon": mon_display_name(mon._name)})

# Kurzer Hinweis oben auf dem Bildschirm, der von selbst verblasst (bleibt auch bei Szenenwechseln stehen).
func show_unlock_message(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.858824, 0.717647, 0.45098, 1))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	label.position.y = 40
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.add_child(label)
	label.position.x = (get_tree().root.get_visible_rect().size.x - label.get_minimum_size().x) / 2
	var tween := label.create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func type_name_by_mon(mon: Monster) -> String:
	return ColorMap.get_combo(mon._type).label
	# return Enums.MON_TYPE_MAP[str(mon._type)]

func color_by_type(type: int) -> Color:
	return ColorMap.get_combo(type).color

func between(v, min, max) -> bool:
	return v >= min and v <= max

func get_all_owned_monster_names() -> Array:
	var all_mons = []
	all_mons.append_array(State.INITIAL_MONS.duplicate())
	all_mons.append_array(SaveManager.save_data.catched_monsters)
	return all_mons
#func balance_growth_rate(max_level) -> Dictionary:
	
# send message
# animation helper
# wait timer

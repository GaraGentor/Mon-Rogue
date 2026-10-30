extends Node

func generate_fake_uuid() -> String:
	return "%s-%s" % [str(randi()), str(Time.get_ticks_usec())]

func points_per_level(bst: int) -> float:
	return bst / State.SETTING_LEVEL

func will_catch_mon(mon) -> bool:
	var will_catch = randi_range(0, 100)
	if will_catch < mon._catch_probability:
		return true
	return false

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
			for skill_name in Skills.pick_weighted_unique(Skills.get_available_egg_skills(i), 3):
				var skill = Skills.get_skill(skill_name)
				skill.scouted = true
				newMon._skills.append(skill)
			mons.append(newMon)
		return mons

	for i in default_props.count:
		var mon_meta_data = Monmap.mon_metainfos_by_name(mons_to_pick.pick_random())
		var newMon = Monster.new(default_props.level, mon_meta_data)
		for j in 3:
			newMon._skills.append(Skills.get_skill(Skills.pick_weighted(mon_meta_data.default_egg_skills)))
		roll_egg_skill(newMon)
		mons.append(newMon)
	return mons

const EGG_SKILL_CHANCE := 0.35

# Wilde Monster tragen mit etwas Glück genau eine noch nicht freigeschaltete Ei-Attacke ihrer Art.
func roll_egg_skill(mon: Monster) -> void:
	var locked = Skills.get_locked_egg_skills(mon._name)
	if locked.is_empty() or randf() > EGG_SKILL_CHANCE:
		return
	var skill = Skills.get_skill(Skills.pick_weighted(locked))
	skill.egg_skill = true
	mon._skills[mon._skills.size() - 1] = skill
	
func color_by_mon(mon: Monster) -> Color:
	return ColorMap.get_combo(mon._type).color

func mon_display_name(mon_name: String) -> String:
	return tr("MONSTER_" + mon_name)

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

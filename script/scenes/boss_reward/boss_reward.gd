extends Control

## Nach einem Biom-Boss: immer eine Boss Träne, dazu das Ei, wenn ein Monster im Team noch nicht freigeschaltet ist.
## Es gibt keine Auswahl, sind alle Belohnungen abgeholt, geht es ins nächste Biom.

## Boss Tränen, die man als Belohnung bekommt
const SHARD_REWARD := 1

@export var mon_reward: Control
@export var egg_rect: TextureRect
@export var shard_amount_label: Label
@export var shard_button: Button
@export var egg_button: Button

# Hinweis auf neu freigeschaltete Meilenstein-Ei-Attacken (Spielende: run_end.gd)
@export var unlock_label: Label

var missing_mon_egg = []
# Art im Ei, wird beim Öffnen gelost
var mon_to_save: Monster
# noch nicht abgeholte Belohnungen
var _unclaimed := 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shard_amount_label.text = tr("BOSS_REWARD_SHARD_AMOUNT").format({"amount": SHARD_REWARD})
	# hier landet man nur nach Biom-Bossen, Boss-Felder auf der Karte zählen nicht
	show_unlocks(unlock_label, Skills.add_milestone_progress(State.starter_name, "biome_boss_kills"))
	SaveManager.add_reroll_charge()
	var catched_mons = SaveManager.save_data.catched_monsters.duplicate(true)
	catched_mons.append_array(State.INITIAL_MONS)
	for mon in State.mons:
		if not catched_mons.has(mon._name):
			missing_mon_egg.append(mon)
	if not missing_mon_egg.is_empty():
		mon_reward.visible = true
		_unclaimed += 1
		# Art steht schon fest, damit das Ei nach ihrer Seltenheit eingefärbt werden kann
		mon_to_save = missing_mon_egg.pick_random()
		egg_rect.material = Monmap.egg_material(Monmap.rarity_of(mon_to_save._name))

func show_unlocks(label: Label, skill_names: Array) -> void:
	if skill_names.is_empty():
		return
	var names = skill_names.map(func(skill_name): return tr(skill_name))
	label.text = tr("MILESTONE_UNLOCKED").format({
		"mon": Helper.mon_display_name(State.starter_name),
		"skills": ", ".join(PackedStringArray(names)),
	})
	label.visible = true

func finish() -> void:
	State.map_level += 1
	State.biome_fight_index = 0
	if State.map_level == Map.map_settings.size():
		State.end_run(true)
		get_tree().change_scene_to_file("res://script/scenes/run_end/run_end.tscn")
		return
	Map.generate_starting_points()
	get_tree().change_scene_to_file("res://script/scenes/world_map/world_map.tscn")

func _claimed(button: Button) -> void:
	button.disabled = true
	button.text = tr("BOSS_REWARD_CLAIMED")
	_unclaimed -= 1
	if _unclaimed == 0:
		finish()

func _on_shard_button_pressed() -> void:
	SaveManager.add_boss_shard(SHARD_REWARD)
	State.boss_shards += SHARD_REWARD
	_claimed(shard_button)

func _on_egg_button_pressed() -> void:
	SaveManager.add_catched_monster_mon(mon_to_save._name)
	_claimed(egg_button)

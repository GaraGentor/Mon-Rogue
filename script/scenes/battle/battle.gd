extends Control

var selected_mon_mat = preload("res://script/scenes/battle/selected_monster_material.tres")

const ENEMY_THINK_TIME := 0.6
const ENEMY_ACTION_TIME := 0.9

@export var catch_anim: Control
@export var catch_button: Button
@export var battle_info: Control
@export var card_hand: ScrollContainer

@onready var turn_wheel: Control = battle_info.turn_wheel

var is_playing: bool = true

## auf dem Feld markiertes Monster (eigenes oder gegnerisches), wird im Infobereich angezeigt
var selected_mon: Monster
## zuletzt markierter Gegner: Ziel für Hypnose und Karten ohne eigenes Ziel
var currently_selected_enemy_mon: Monster

var mouse_action = Enums.MOUSE_ACTION.NONE

## Monster, das laut Turn Wheel gerade am Zug ist
var active_mon: Monster

func _enter_tree() -> void:
	_generate_battle()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.mouse_event.connect(_catch_mouse_event)
	Events.monster_faints.connect(_check_game_over)
	Events.finish_catching.connect(_finish_catching)

	_refresh_skill_points()
	Events.mouse_event.emit({"action": Enums.MOUSE_ACTION.SELECT_MONSTER, "mon": State.enemy_mons[0]})

	if State.mons.size() > 1:
		$GameWindow/HBoxContainer2/MonsterScene1.visible = true

	if State.is_final_boss:
		$UI/HBoxContainer/TextureRect/Catch.visible = false

	# unsichtbar, blockiert aber Eingaben während der Gegner am Zug ist
	$UI_Blocker.self_modulate = Color(1, 1, 1, 0)
	turn_wheel.turn_for.connect(_on_turn_for)
	card_hand.show_mon(State.mons[0])
	turn_wheel.start()

func _is_own_turn() -> bool:
	return active_mon != null and State.mons.has(active_mon)

func _on_turn_for(mon: Monster) -> void:
	active_mon = mon
	var own_index = State.mons.find(mon)
	if own_index > -1:
		# Skillpunkte zu Beginn des eigenen Zuges auffüllen
		mon.reset_to_new_round()
		# wer am Zug ist, zeigt das Turn Wheel; die Hand zeigt seine Karten
		card_hand.show_mon(mon)
		catch_button.disabled = false
		$UI_Blocker.visible = false
		return
	$UI_Blocker.visible = true
	await get_tree().create_timer(ENEMY_THINK_TIME).timeout
	if not is_inside_tree():
		return
	_ki_turn(mon)
	# eingesetzte Skills sind jetzt aufgedeckt
	if selected_mon == mon:
		battle_info.refresh()
	await get_tree().create_timer(ENEMY_ACTION_TIME).timeout
	if not is_inside_tree():
		return
	turn_wheel.next_mon()

func _monster_scenes() -> Array:
	return [$GameWindow/HBoxContainer2.get_node("MonsterScene" + str(0)),
		$GameWindow/HBoxContainer2.get_node("MonsterScene" + str(1)),
		$GameWindow/HBoxContainer3.get_node("MonsterScene" + str(0)),
		$GameWindow/HBoxContainer3.get_node("MonsterScene" + str(1)),
		$GameWindow/HBoxContainer3.get_node("MonsterScene" + str(2))]

func _scene_for(mon: Monster) -> Control:
	return _monster_scenes().filter(func(e): return e.mon == mon)[0]

## markiert genau ein Monster auf dem ganzen Feld und zeigt es im Infobereich
func _select_mon(mon: Monster) -> void:
	selected_mon = mon
	if State.enemy_mons.has(mon):
		currently_selected_enemy_mon = mon
	for scene in _monster_scenes():
		scene.texture_rect.material = selected_mon_mat if scene.mon == mon and mon != null else null
	battle_info.monster = mon

## nach einem K.O. oder Fang ein noch kämpfendes Monster markieren
func _reselect_if_gone(gone: Monster) -> void:
	if selected_mon != gone and currently_selected_enemy_mon != gone:
		return
	var alive_enemies = State.enemy_mons.filter(func(mon: Monster): return mon.is_alive() and mon != gone)
	if currently_selected_enemy_mon == gone:
		currently_selected_enemy_mon = alive_enemies[0] if not alive_enemies.is_empty() else null
	if selected_mon != gone:
		return
	var alive = alive_enemies + State.mons.filter(func(mon: Monster): return mon.is_alive())
	if not alive.is_empty():
		_select_mon(alive[0])

func _exit_tree() -> void:
	Events.mouse_event.disconnect(_catch_mouse_event)
	Events.monster_faints.disconnect(_check_game_over)
	Events.finish_catching.disconnect(_finish_catching)

func _catch_mouse_event(event) -> void:
	if event.action == Enums.MOUSE_ACTION.SELECT_MONSTER and event.mon != null:
		_select_mon(event.mon)
	if event.action == Enums.MOUSE_ACTION.PLAY_CARD:
		# nur das Monster, das am Zug ist, darf Skills spielen
		if not _is_own_turn():
			return
		# deal damage
		catch_button.disabled = true

		# per Drag & Drop gespielte Karten bringen ihr Ziel mit
		var target: Monster = event.get("mon", currently_selected_enemy_mon)
		var isOk = subract_skill_points(event.skill, active_mon)
		print("deal damage" + str(isOk))
		if isOk:
			if event.skill.target == Enums.CARD_TARGETS.SINGLE_ENEMY:
				event.skill.handle.call({"from": active_mon, "skill": event.skill, "mon": target})
			Events.monster_hit_monster.emit(_scene_for(active_mon), _scene_for(target))
			Events.call_skill_card.emit(event.skill)
			mouse_action = Enums.MOUSE_ACTION.NONE
	mouse_action = event.action

func subract_skill_points(selected_skill, mon) -> bool:
	if mon._computed_moves >= selected_skill.cost:
		mon._computed_moves -= selected_skill.cost
		return true
	return false

func _refresh_skill_points() -> void:
	for mon in State.mons:
		if mon.is_alive():
			mon.reset_to_new_round()

## Feste Begegnungstabelle pro Biom-Tiefe (map_level), unabhängig vom eigenen Team.
## Werte werden über die Kämpfe im Biom von Anfang bis Ende interpoliert:
## - fights: erwartete normale Kämpfe im Biom (danach bleibt es beim Endwert)
## - level: [Stufe beim ersten Kampf, Stufe beim letzten Kampf]
## - offset: zufällige Abweichung pro Monster [min, max]
## - counts: Gewichte für 1/2/3 Gegner [am Anfang, am Ende]
## Ein Team, das jeden Kampf ausfechtet (2 K.O.s = +1 Stufe), liegt etwa gleichauf;
## wer lieber alles fängt, levelt nicht und fällt zurück.
const ENCOUNTERS := [
	# Biom 1: Einstieg, fast nur Einzelkämpfe auf gleicher oder niedrigerer Stufe
	{"fights": 4, "level": [2, 4], "offset": [-1, 0], "counts": [[100, 0, 0], [70, 30, 0]]},
	# Biom 2: Doppelkämpfe werden normal
	{"fights": 4, "level": [5, 9], "offset": [-1, 1], "counts": [[70, 30, 0], [40, 50, 10]]},
	# Biom 3: erste 3er-Gruppen
	{"fights": 5, "level": [10, 15], "offset": [-1, 1], "counts": [[40, 50, 10], [15, 55, 30]]},
	# Biom 4: gleiche oder höhere Stufe
	{"fights": 6, "level": [16, 23], "offset": [0, 1], "counts": [[15, 55, 30], [5, 40, 55]]},
	# Biom 5: 3 gegen 2 ist die Regel
	{"fights": 7, "level": [24, 33], "offset": [0, 2], "counts": [[5, 35, 60], [0, 20, 80]]},
]

## Bosse pro Biom: Anzahl und Stufen über der Endstufe des Bioms
const BOSS_ENCOUNTERS := [
	{"count": 1, "level_bonus": 2},
	{"count": 2, "level_bonus": 1},
	{"count": 2, "level_bonus": 2},
	{"count": 3, "level_bonus": 1},
	{"count": 3, "level_bonus": 2},
]

func _generate_battle():
	var depth = clampi(State.map_level, 0, ENCOUNTERS.size() - 1)
	var encounter: Dictionary = ENCOUNTERS[depth]
	var count: int
	var level: int
	var t = clampf(float(State.biome_fight_index) / max(encounter.fights - 1, 1), 0.0, 1.0)
	if State.is_boss_fight:
		var boss: Dictionary = BOSS_ENCOUNTERS[depth]
		count = boss.count
		level = encounter.level[1] + boss.level_bonus
	elif State.is_map_boss:
		# Boss-Feld auf der Karte: Boss-Anzahl, aber auf der aktuellen Stufe des Bioms
		var boss: Dictionary = BOSS_ENCOUNTERS[depth]
		count = boss.count
		level = roundi(lerpf(encounter.level[0], encounter.level[1], t)) + boss.level_bonus
		State.is_map_boss = false
	else:
		count = _roll_enemy_count(encounter.counts, t)
		level = roundi(lerpf(encounter.level[0], encounter.level[1], t))
		State.biome_fight_index += 1
	var ms = Helper.generate_mons({"count": count})
	# Stufe direkt setzen: Monster.new(level) ergibt sonst 2 * level + 1
	for mon in ms:
		mon._level = max(1, level + randi_range(encounter.offset[0], encounter.offset[1]))
	print("encounter depth ", depth, " fight ", State.biome_fight_index, ": ", count, "x level ", level)
	State.enemy_mons = ms

## Zieht die Gegneranzahl (1-3) mit zwischen Biom-Anfang und -Ende interpolierten Gewichten.
func _roll_enemy_count(counts: Array, t: float) -> int:
	var weights = []
	for i in 3:
		weights.append(lerpf(counts[0][i], counts[1][i], t))
	var roll = randf() * weights.reduce(func(a, b): return a + b, 0.0)
	for i in 3:
		roll -= weights[i]
		if roll < 0.0:
			return i + 1
	return 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func round_won():
	upgrade_mons()

func upgrade_mons():
	pass

func _check_game_over(last_fainted:Monster) -> void:
	turn_wheel.remove_mon(last_fainted)
	_reselect_if_gone(last_fainted)
	var is_enemy = true if State.enemy_mons.find(last_fainted) > -1 else false
	print("check gameover", State.mons.all(
			func(mon: Monster):
			return not mon.is_alive()
			))
	print("who ded?", str(is_enemy), State.enemy_mons.size(), ":", last_fainted._name)
	if is_enemy:
		State.killed_monsters += 1
		State.mark_mon_defeated(last_fainted._name)
		State.ep += last_fainted._ep
		print("State.mons.all(func(mon: Monster): return mon._hp <= 0 and not mon._new)",
		State.mons.all(
			func(mon: Monster):
			return not mon.is_alive()
			)
	)
	if State.mons.all(
			func(mon: Monster):
			return not mon.is_alive()
			):
		State.reset()
		_clear_fainted_mons()
		print("will go to select")
		get_tree().change_scene_to_file("res://script/scenes/selection/selection.tscn")
		return
	if State.enemy_mons.all(func(mon: Monster): return not mon.is_alive()) or State.enemy_mons.size() == 0:
		print("will close battle")
		State.stage_clear()
		State.ep += State.enemy_mons.map(func(mon): return mon._ep).reduce(func(a, b): return a + b, 0)
		print("state ep", State.ep)
		# clear dead monsters.
		# open stats.
		_clear_fainted_mons()
		if State.catched_mons.size() > 0:
			get_tree().change_scene_to_file("res://script/scenes/judgment/judgement.tscn")
			return
		get_tree().change_scene_to_file("res://script/scenes/world_map/world_map.tscn")

func _clear_fainted_mons():
	var v = State.mons.filter(func(mon:Monster): return not mon.is_alive())
	for item: Monster in v:
		State.mons.erase(item)

## Zug eines Gegners: zufälliger Skill auf ein zufälliges lebendes eigenes Monster
func _ki_turn(emon: Monster) -> void:
	var alive = State.mons.filter(func(mon: Monster): return mon.is_alive())
	if alive.is_empty() or not emon.is_alive():
		return
	# Gegner halten sich an dieselbe Element-Regel wie der Spieler
	var usable = emon._skills.filter(func(skill): return Skills.can_use(emon, skill))
	if usable.is_empty():
		return
	var skill = usable.pick_random()
	var to_hit = alive.pick_random()
	if skill.target == Enums.CARD_TARGETS.SINGLE_ENEMY:
		Events.monster_hit_monster.emit(_scene_for(emon), _scene_for(to_hit))
		skill.handle.call({"from": emon, "skill": skill, "mon": to_hit})
		skill.scouted = true

func _on_end_turn_pressed() -> void:
	if not _is_own_turn():
		return
	$UI_Blocker.visible = true
	Events.mouse_event.emit({"action": Enums.MOUSE_ACTION.NONE})
	turn_wheel.next_mon()

func _finish_catching(catched: bool, mon: Monster) -> void:
	if catched:
		State.mark_mon_defeated(mon._name)
		var index = State.enemy_mons.find(mon)
		if index > -1:
			State.enemy_mons.remove_at(index)
		# catch_anim hat das Monster bereits aus enemy_mons entfernt, daher immer prüfen
		_check_game_over(mon)
		if not is_inside_tree():
			return
	_on_end_turn_pressed()

func _on_catch_pressed() -> void:
	# Events.mouse_event.emit({"action": Enums.MOUSE_ACTION.CATCH_MONSTER})
	print(currently_selected_enemy_mon)
	print(State.enemy_mons)
	var already_catched = State.catched_mons.find(currently_selected_enemy_mon)
	if currently_selected_enemy_mon and currently_selected_enemy_mon.is_alive() and already_catched == -1:
		catch_anim._catch_animation(currently_selected_enemy_mon)

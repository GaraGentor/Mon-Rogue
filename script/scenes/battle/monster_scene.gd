extends Control

@export var mon_slot: int
@export var home_mons: bool

@export var texture_rect: TextureRect

var mon: Monster

@export var hp_label: Label

@export var progress_bar: BoxContainer

@export var is_healing: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.refresh_ui_for_monster.connect(printStuff)
	Events.deal_damage_to_monster.connect(_deal_damage)
	Events.monster_faints.connect(_remove_mon)
	Events.mon_is_catched.connect(_remove_mon)
	var mons = State.mons if home_mons else State.enemy_mons
	if mons.size() > mon_slot:
		mon = mons[mon_slot]
		visible = true
		var meta_info = Monmap.mon_metainfos_by_name(mon._name)
		texture_rect.texture = meta_info.texture_front
		progress_bar.progress_bar.max_value = mon.hp()
		progress_bar.progress_bar.value = mon.hp()
		progress_bar.level_label.text = str(mon._level)
		progress_bar.element_panel.self_modulate = Helper.color_by_mon(mon)
		if home_mons:
			progress_bar.skill_panel.visible = true
		printStuff()

func _deal_damage(_mon: Monster) -> void:
	if mon == _mon:
		printStuff()

func printStuff() -> void:
	if mon:
		hp_label.text = "
		MON LEVEL: {1}
		HP: {0}
		MON_HP_LOST: {3}
		MON ATK: {4}
		MON DEF: {5}
		MON S-ATK: {6}
		MON S-DEF: {7}
		MOVES LEFT: {8}".format([
		mon.hp(),
		mon._level,
		#pb1.max_value,
		mon._lost_hp,
		mon.attack(),
		mon.defense(),
		mon.s_attack(),
		mon.s_defense(),
		mon._computed_moves,
		])
		#if progress_bar.progress_bar:
		if get_tree():
			await get_tree().create_tween().tween_method(progress_bar.progress_bar.set_value, progress_bar.progress_bar.value, mon.hp() - mon._lost_hp, 0.3).finished
		#progress_bar.progress_bar.value = mon.hp() - mon._lost_hp
		progress_bar.skill_points_label.text = str(mon._computed_moves)
		Events.damage_animation_done.emit(mon)
		#pb1.value = mon.hp() - mon._lost_hp

func _remove_mon(_mon) -> void:
	if _mon == mon:
		visible = false


## Drag & Drop: Skill-Karten können auf passende Ziele gezogen werden
func _can_drop_data(_at_position: Vector2, data) -> bool:
	if not visible or mon == null or not mon.is_alive():
		return false
	if not (data is Dictionary and data.get("type") == "skill_card"):
		return false
	match data.skill.get("target", Enums.CARD_TARGETS.SINGLE_ENEMY):
		Enums.CARD_TARGETS.SINGLE_ENEMY, Enums.CARD_TARGETS.TEAM_ENEMY:
			return not home_mons
		Enums.CARD_TARGETS.SINGLE_FRIEND, Enums.CARD_TARGETS.TEAM_FRIEND:
			return home_mons
	return false

func _drop_data(_at_position: Vector2, data) -> void:
	modulate = Color.WHITE
	Events.mouse_event.emit({"action": Enums.MOUSE_ACTION.SELECT_MONSTER, "mon": mon})
	Events.mouse_event.emit({"action": Enums.MOUSE_ACTION.PLAY_CARD, "skill": data.skill, "mon": mon})

func _process(_delta: float) -> void:
	# gültiges Ziel unter einer gezogenen Karte hervorheben
	var drag_data = get_viewport().gui_get_drag_data() if get_viewport().gui_is_dragging() else null
	var hovered = drag_data != null and get_global_rect().has_point(get_global_mouse_position()) \
		and _can_drop_data(Vector2.ZERO, drag_data)
	modulate = Color(1.3, 1.3, 1.0) if hovered else Color.WHITE

func _on_gui_input(event: InputEvent) -> void:
	print(event)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Linke Maustaste losgelassen!")
			# Events.call_skill_card.emit({"action": selected_skill})
			Events.mouse_event.emit({"action": Enums.MOUSE_ACTION.SELECT_MONSTER, "mon": mon})

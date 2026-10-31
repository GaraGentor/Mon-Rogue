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
	Events.monster_hit_with_element.connect(_show_hit_text)
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
		# eigene Monster kann man nicht fangen
		progress_bar.catch_panel.visible = not home_mons
		printStuff()

func _deal_damage(_mon: Monster) -> void:
	if mon == _mon:
		printStuff()

const SUPER_EFFECTIVE_COLOR := Color(1.0, 0.55, 0.2)
const NOT_EFFECTIVE_COLOR := Color(0.6, 0.65, 0.7)

# Schwebender Schadenstext über dem Monster, bei Element-Vorteil/-Nachteil mit Hinweis und Faktor.
func _show_hit_text(_mon: Monster, damage: float, multiplier: float) -> void:
	if mon != _mon:
		return
	var text = str(roundi(damage))
	var color = Color.WHITE
	if multiplier > 1.0:
		text = tr("BATTLE_SUPER_EFFECTIVE") + " x%s\n" % _format_multiplier(multiplier) + text
		color = SUPER_EFFECTIVE_COLOR
	elif multiplier < 1.0:
		text = tr("BATTLE_NOT_EFFECTIVE") + " x%s\n" % _format_multiplier(multiplier) + text
		color = NOT_EFFECTIVE_COLOR
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36 if multiplier > 1.0 else 28)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 10
	add_child(label)
	label.position = _texture_offset() + Vector2((texture_rect.size.x - label.get_minimum_size().x) / 2, texture_rect.size.y * 0.2)
	var tween := label.create_tween()
	tween.set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 60, 1.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.6)
	tween.chain().tween_callback(label.queue_free)

func _format_multiplier(multiplier: float) -> String:
	return String.num(multiplier, 2)

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
		if not home_mons:
			progress_bar.catch_propability_label.text = "%d%%" % roundi(Helper.catch_chance(mon) * 100)
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
	_update_drag_preview(drag_data)

# Während eine Angriffskarte gezogen wird, zeigt jedes mögliche Ziel seinen Element-Faktor an.
var _preview_label: Label

func _update_drag_preview(drag_data) -> void:
	var show_preview = drag_data != null and not home_mons and _can_drop_data(Vector2.ZERO, drag_data) \
		and Skills.is_damage_skill(drag_data.skill)
	if not show_preview:
		if _preview_label:
			_preview_label.visible = false
		return
	var multiplier = Skills.element_multiplier(drag_data.skill.nature, mon._type)
	if _preview_label == null:
		_preview_label = Label.new()
		_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_preview_label.add_theme_font_size_override("font_size", 26)
		_preview_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_preview_label.add_theme_constant_override("outline_size", 8)
		_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_preview_label.z_index = 10
		add_child(_preview_label)
	_preview_label.text = "x" + _format_multiplier(multiplier)
	var color = Color.WHITE
	if multiplier > 1.0:
		color = SUPER_EFFECTIVE_COLOR
	elif multiplier < 1.0:
		color = NOT_EFFECTIVE_COLOR
	_preview_label.add_theme_color_override("font_color", color)
	_preview_label.visible = true
	_preview_label.position = _texture_offset() + Vector2((texture_rect.size.x - _preview_label.get_minimum_size().x) / 2, 0)

func _on_gui_input(event: InputEvent) -> void:
	print(event)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Linke Maustaste losgelassen!")
			# Events.call_skill_card.emit({"action": selected_skill})
			Events.mouse_event.emit({"action": Enums.MOUSE_ACTION.SELECT_MONSTER, "mon": mon})

# Position des Monster-Bilds relativ zu dieser Szene (es liegt in einem VBoxContainer).
func _texture_offset() -> Vector2:
	return texture_rect.global_position - global_position

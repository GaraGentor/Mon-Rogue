extends Control

## Infobereich im Kampf: oben das Turn Wheel, darunter Werte und Skills
## des Monsters, das gerade auf dem Feld ausgewählt ist (eigenes oder gegnerisches).

const SKILL_COLUMNS := ["SKILL_HEADER_SKILL", "SKILL_HEADER_COST", "SKILL_HEADER_CD", "SKILL_HEADER_POWER"]

@export var turn_wheel: Control
@export var name_label: Label
@export var stats_grid: GridContainer
@export var skill_grid: GridContainer
@export var skill_info_container: ScrollContainer

@export var physical_texture: Texture2D
@export var magic_texture: Texture2D

var monster: Monster:
	set(mon):
		monster = mon
		refresh()

func _ready() -> void:
	Events.skill_label_pressed.connect(_show_skill_info)

func _exit_tree() -> void:
	Events.skill_label_pressed.disconnect(_show_skill_info)

func refresh() -> void:
	if monster == null:
		return
	name_label.text = "%s  Lv. %d" % [Helper.mon_display_name(monster._name), monster._level]
	name_label.self_modulate = Helper.color_by_mon(monster)
	# eigene Stats sind bekannt, gegnerische erst nachdem die Art in diesem Run besiegt wurde
	var stats_known := State.mons.has(monster) or State.is_mon_defeated(monster._name)
	stats_grid.init_with_mon(monster, not stats_known)
	_build_skill_list()

func _build_skill_list() -> void:
	for c in skill_grid.get_children():
		c.queue_free()
	skill_grid.add_child(Control.new())
	for header in SKILL_COLUMNS:
		skill_grid.add_child(_label(tr(header), Color(0.7, 0.7, 0.7)))
	# eigene Skills sind bekannt, gegnerische erst nachdem sie eingesetzt wurden
	var known_all := State.mons.has(monster)
	for skill in monster._skills:
		var known: bool = known_all or skill.scouted
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if known:
			icon.texture = physical_texture if skill.damage_type == Enums.SKILL_DAMAGE_TYPE.PHYSICAL else magic_texture
		skill_grid.add_child(icon)

		var skill_name := _label(tr(skill.name) if known else "?", Helper.color_by_type(skill.nature) if known else Color.WHITE)
		skill_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		skill_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		skill_name.clip_text = true
		if known:
			skill_name.mouse_filter = Control.MOUSE_FILTER_STOP
			skill_name.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			skill_name.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					_show_skill_info(skill))
		skill_grid.add_child(skill_name)
		for value in [skill.cost, skill.cooldown, skill.get("value", skill.get("damage", ""))]:
			skill_grid.add_child(_label(str(value) if known else "?"))

func _label(text: String, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.self_modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	return label

func _show_skill_info(skill) -> void:
	skill_info_container._init_with_skill(skill)
	skill_info_container.visible = true

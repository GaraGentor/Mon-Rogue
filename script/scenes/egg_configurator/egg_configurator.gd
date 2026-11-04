extends Control

## Konfigurator nach "Reise beginnen": wähle 3 Ei-Attacken, die dein Monster in den Run mitnimmt.
## Zur Wahl stehen die Standard-Ei-Attacken der Art und alle freigeschalteten.

const SKILLS_TO_PICK := 3
const GOLD := Color(0.858824, 0.717647, 0.45098, 1)
const BG := Color(0.0627451, 0.0862745, 0.0823529, 1)
const BG_TOP := Color(0.560784, 0.301961, 0.85098, 1)
const LOCKED_COLOR := Color(0.5, 0.5, 0.5)
const MISSING_COLOR := Color(1, 0.45, 0.45)
const MAP_BACKGROUND := preload("res://script/scenes/world_map/map_background.gdshader")
const BATTLE_CARD := preload("res://script/scenes/battle/battle_card.tscn")
const PHYSICAL_TEXTURE := preload("res://assets/ui/icons/fist.svg")
const MAGIC_TEXTURE := preload("res://assets/ui/icons/sparkle.svg")

@export var font: Font

var _mon: Monster
var _selected: Array[String] = []
var _cards := {}
var _counter_label: Label
var _go_button: Button
## Spielkarte der zuletzt angeklickten Attacke, wie sie im Kampf aussieht
var _detail_card: Control
## Hinweis unter der Karte: wie man sie freischaltet oder welche Elemente fehlen
var _detail_note: Label

func _ready() -> void:
	_mon = State.mons[0]
	# Vorauswahl: die beim Ei gewürfelten Attacken
	for skill in _mon._skills:
		if _selected.size() < SKILLS_TO_PICK and not _selected.has(skill.name):
			_selected.append(skill.name)
	_build()
	_refresh()

func _build() -> void:
	var background := ColorRect.new()
	var bg_material := ShaderMaterial.new()
	bg_material.shader = MAP_BACKGROUND
	bg_material.set_shader_parameter("bottom_color", Color.BLACK)
	bg_material.set_shader_parameter("top_color", BG_TOP)
	bg_material.set_shader_parameter("wave_amp", 0.115)
	bg_material.set_shader_parameter("wave_size", 1.0)
	bg_material.set_shader_parameter("wave_time_mul", 0.933)
	bg_material.set_shader_parameter("total_phases", 8)
	background.material = bg_material
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 24)
	margin.add_child(root)

	root.add_child(_label(tr("CONFIGURATOR_TITLE"), 36, Color.WHITE))

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 40)
	root.add_child(content)

	# links: oben das gewählte Monster, darunter die Karte der angeklickten Attacke
	var mon_box := VBoxContainer.new()
	mon_box.custom_minimum_size = Vector2(300, 0)
	mon_box.add_theme_constant_override("separation", 4)
	content.add_child(mon_box)
	var texture := TextureRect.new()
	Monmap.show_on(texture, _mon._name, Monmap.MEDIUM)
	texture.custom_minimum_size = Vector2(120, 120)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mon_box.add_child(texture)
	mon_box.add_child(_label(Helper.mon_display_name(_mon._name), 26, Helper.color_by_mon(_mon)))
	mon_box.add_child(_label(tr(Helper.type_name_by_mon(_mon)), 16, Color(1, 1, 1, 0.6)))

	_detail_card = BATTLE_CARD.instantiate()
	_detail_card.custom_minimum_size = Vector2(220, 200)
	_detail_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_detail_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_detail_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_card.visible = false
	mon_box.add_child(_detail_card)
	_detail_note = _label(tr("CONFIGURATOR_PICK_HINT"), 14, Color(1, 1, 1, 0.6))
	_detail_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_note.custom_minimum_size = Vector2(300, 0)
	mon_box.add_child(_detail_note)

	# rechts: verfügbare und noch gesperrte Ei-Attacken
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)

	for skill_name in Skills.get_available_egg_skills(_mon._name):
		var card := _create_card(Skills.get_skill(skill_name), false)
		card.pressed.connect(_on_card_pressed.bind(skill_name))
		_cards[skill_name] = card
		grid.add_child(card)
	for skill_name in Skills.get_locked_egg_skills(_mon._name):
		_add_locked_card(grid, Skills.get_skill(skill_name), "CONFIGURATOR_LOCKED", "EGG_SKILL_HINT")
	for milestone in Skills.get_locked_milestones(_mon._name):
		_add_locked_card(grid, Skills.get_skill(milestone.skill), "CONFIGURATOR_LOCKED_MILESTONE", milestone.hint)
	for bounty in Skills.get_locked_bounties(_mon._name):
		_add_locked_card(grid, Skills.get_skill(bounty.skill), "CONFIGURATOR_LOCKED_BOUNTY", bounty.hint)

	# unten: Zähler und Aufbrechen
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 40)
	root.add_child(footer)
	_counter_label = _label("", 24, Color.WHITE)
	footer.add_child(_counter_label)
	_go_button = Button.new()
	_go_button.text = tr("CONFIGURATOR_GO")
	_go_button.flat = true
	_go_button.add_theme_font_size_override("font_size", 32)
	if font:
		_go_button.add_theme_font_override("font", font)
	_go_button.pressed.connect(_on_go_pressed)
	footer.add_child(_go_button)

func _add_locked_card(grid: GridContainer, skill: Dictionary, locked_label: String, hint: String) -> void:
	var card := _create_card(skill, true, locked_label)
	card.pressed.connect(_show_detail.bind(skill, tr(locked_label) + "\n" + tr(hint), GOLD, true))
	grid.add_child(card)

func _create_card(skill: Dictionary, locked: bool, locked_label := "") -> Button:
	var color := Helper.color_by_type(skill.nature)
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 118)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.toggle_mode = not locked
	card.focus_mode = Control.FOCUS_NONE

	if locked:
		var style := _card_style(Color(0.4, 0.4, 0.4), Color(BG, 0.6), 2)
		card.add_theme_stylebox_override("normal", style)
		card.add_theme_stylebox_override("hover", _card_style(Color(0.6, 0.6, 0.6), Color(BG.lightened(0.08), 0.7), 2))
		card.add_theme_stylebox_override("pressed", style)
	else:
		var pressed := _card_style(GOLD, Color(color.darkened(0.55), 1.0), 4)
		card.add_theme_stylebox_override("normal", _card_style(color, Color(BG.lightened(0.05), 0.95), 2))
		card.add_theme_stylebox_override("hover", _card_style(color.lightened(0.2), Color(BG.lightened(0.12), 0.95), 2))
		card.add_theme_stylebox_override("pressed", pressed)
		card.add_theme_stylebox_override("hover_pressed", pressed)

	# Inhalt als eigene Controls, damit Schadensart und Stärke als Icons erscheinen
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	var lines := VBoxContainer.new()
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	lines.add_theme_constant_override("separation", 4)
	margin.add_child(lines)

	var tint := LOCKED_COLOR if locked else Color.WHITE
	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(name_row)
	var name_label := _card_label(tr(skill.name), 18, LOCKED_COLOR if locked else color.lightened(0.3))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_row.add_child(name_label)
	name_row.add_child(_icon(PHYSICAL_TEXTURE if Skills.is_physical(skill) else MAGIC_TEXTURE, 20, tint))

	var stats_row := HBoxContainer.new()
	stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_row.add_theme_constant_override("separation", 6)
	lines.add_child(stats_row)
	stats_row.add_child(_card_label(tr("CONFIGURATOR_SKILL_STATS").format({"cost": skill.cost, "cooldown": skill.cooldown}), 16, tint))
	stats_row.add_child(_card_label(Helper.format_number(skill.value), 16, tint))

	if locked:
		lines.add_child(_card_label(tr(locked_label), 15, LOCKED_COLOR))
	else:
		lines.add_child(_card_label(tr("CONFIGURATOR_TIER").format({"tier": skill.tier}), 15, Color(1, 1, 1, 0.6)))
		if not Skills.can_use(_mon, skill):
			# wählbar, aber erst spielbar, wenn das Monster die fehlenden Elemente bekommt (z. B. im Shop)
			lines.add_child(_card_label(Skills.missing_elements_text(_mon, skill), 14, MISSING_COLOR))
	return card

func _card_label(text: String, font_size: int, color: Color) -> Label:
	var label := _label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label

func _icon(texture: Texture2D, icon_size: int, color: Color) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = color
	return icon

func _card_style(border: Color, bg: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	return style

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if font:
		label.add_theme_font_override("font", font)
	return label

func _show_detail(skill: Dictionary, note: String, note_color: Color, locked: bool) -> void:
	_detail_card.skill = skill
	_detail_card.modulate = Color(0.6, 0.6, 0.6) if locked else Color.WHITE
	_detail_card.visible = true
	_detail_note.text = note
	_detail_note.add_theme_color_override("font_color", note_color)

func _on_card_pressed(skill_name: String) -> void:
	_toggle(skill_name)
	var skill := Skills.get_skill(skill_name)
	_show_detail(skill, Skills.missing_elements_text(_mon, skill), MISSING_COLOR, false)

func _toggle(skill_name: String) -> void:
	if _selected.has(skill_name):
		_selected.erase(skill_name)
	elif _selected.size() < SKILLS_TO_PICK:
		_selected.append(skill_name)
	_refresh()

func _refresh() -> void:
	for skill_name in _cards:
		_cards[skill_name].set_pressed_no_signal(_selected.has(skill_name))
	# mindestens eine Attacke muss mit dem Start-Element spielbar sein
	var has_usable = _selected.any(func(skill_name): return Skills.can_use_name(_mon, skill_name))
	_counter_label.text = tr("CONFIGURATOR_COUNTER").format({"count": _selected.size(), "max": SKILLS_TO_PICK})
	if _selected.size() == SKILLS_TO_PICK and not has_usable:
		_counter_label.text = tr("CONFIGURATOR_NEED_USABLE")
	_go_button.disabled = _selected.size() != SKILLS_TO_PICK or not has_usable

func _on_go_pressed() -> void:
	_mon._skills = []
	for skill_name in _selected:
		var skill = Skills.get_skill(skill_name)
		skill.scouted = true
		_mon._skills.append(skill)
	get_tree().change_scene_to_file("res://script/scenes/world_map/world_map.tscn")

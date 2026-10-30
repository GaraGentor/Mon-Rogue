extends Control

## Konfigurator nach "Reise beginnen": wähle 3 Ei-Attacken, die dein Monster in den Run mitnimmt.
## Zur Wahl stehen die Standard-Ei-Attacken der Art und alle freigeschalteten.

const SKILLS_TO_PICK := 3
const GOLD := Color(0.858824, 0.717647, 0.45098, 1)
const BG := Color(0.0627451, 0.0862745, 0.0823529, 1)

@export var font: Font

var _mon: Monster
var _selected: Array[String] = []
var _cards := {}
var _counter_label: Label
var _go_button: Button

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
	background.color = BG
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

	# links: das gewählte Monster
	var mon_box := VBoxContainer.new()
	mon_box.custom_minimum_size = Vector2(300, 0)
	mon_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(mon_box)
	var texture := TextureRect.new()
	texture.texture = Monmap.mon_metainfos_by_name(_mon._name).texture_front
	texture.custom_minimum_size = Vector2(260, 260)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mon_box.add_child(texture)
	mon_box.add_child(_label(Helper.mon_display_name(_mon._name), 28, Helper.color_by_mon(_mon)))
	mon_box.add_child(_label(tr(Helper.type_name_by_mon(_mon)), 18, Color(1, 1, 1, 0.6)))

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
		card.pressed.connect(_toggle.bind(skill_name))
		_cards[skill_name] = card
		grid.add_child(card)
	for skill_name in Skills.get_locked_egg_skills(_mon._name):
		grid.add_child(_create_card(Skills.get_skill(skill_name), true))
	for milestone in Skills.get_locked_milestones(_mon._name):
		grid.add_child(_create_card(Skills.get_skill(milestone.skill), true, "CONFIGURATOR_LOCKED_MILESTONE", milestone.hint))
	for bounty in Skills.get_locked_bounties(_mon._name):
		grid.add_child(_create_card(Skills.get_skill(bounty.skill), true, "CONFIGURATOR_LOCKED_BOUNTY", bounty.hint))

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

func _create_card(skill: Dictionary, locked: bool, locked_label := "CONFIGURATOR_LOCKED", hint := "EGG_SKILL_HINT") -> Button:
	var color := Helper.color_by_type(skill.nature)
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 110)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.toggle_mode = not locked
	card.disabled = locked
	card.focus_mode = Control.FOCUS_NONE
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.add_theme_font_size_override("font_size", 18)
	if font:
		card.add_theme_font_override("font", font)

	var damage_type := tr("CONFIGURATOR_PHYSICAL") if skill.damage_type == Enums.SKILL_DAMAGE_TYPE.PHYSICAL else tr("CONFIGURATOR_ABILITY")
	var lines := [
		tr(skill.name),
		tr("CONFIGURATOR_SKILL_STATS").format({"cost": skill.cost, "value": int(skill.value), "type": damage_type}),
		tr("CONFIGURATOR_TIER").format({"tier": skill.tier}),
	]
	if locked:
		lines[2] = tr(locked_label)
	elif not Skills.can_use(_mon, skill):
		# wählbar, aber erst spielbar, wenn das Monster die fehlenden Elemente bekommt (z. B. im Shop)
		lines.append(Skills.missing_elements_text(_mon, skill))
	card.text = "\n".join(PackedStringArray(lines))
	card.tooltip_text = tr(skill.description).format(skill)
	if locked:
		card.tooltip_text += "\n" + tr(hint)

	var normal := _card_style(color, Color(BG.lightened(0.05), 0.95), 2)
	var hover := _card_style(color.lightened(0.2), Color(BG.lightened(0.12), 0.95), 2)
	var pressed := _card_style(GOLD, Color(color.darkened(0.55), 1.0), 4)
	var disabled := _card_style(Color(0.4, 0.4, 0.4), Color(BG, 0.6), 2)
	card.add_theme_stylebox_override("normal", normal)
	card.add_theme_stylebox_override("hover", hover)
	card.add_theme_stylebox_override("pressed", pressed)
	card.add_theme_stylebox_override("hover_pressed", pressed)
	card.add_theme_stylebox_override("disabled", disabled)
	card.add_theme_color_override("font_color", color.lightened(0.3))
	card.add_theme_color_override("font_hover_color", color.lightened(0.4))
	card.add_theme_color_override("font_pressed_color", Color.WHITE)
	card.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	card.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	return card

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

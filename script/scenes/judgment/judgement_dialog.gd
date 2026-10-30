class_name JudgementDialog
extends Control

## Modaler Dialog im Judgement-Screen: Attacke lehren (Attacke -> Ziel-Monster -> ggf. zu vergessende Attacke)
## und einfache Rückfragen. Beide Abläufe laufen per await und liefern das Ergebnis zurück.

signal _choice(result: Dictionary)

const GOLD := Color(0.858824, 0.717647, 0.45098, 1)
const MUTED := Color(0.75, 0.75, 0.75, 1)
const BOX = preload("res://script/ui/materials/monster_widget_boxes.tres")
const FLAT_THEME = preload("res://script/scenes/battle/flat_button_theme.tres")

var _title: Label
var _warning: Label
var _content: HFlowContainer
var _back: Button
var _cancel: Button
var _confirm: Button

func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 0)
	panel.add_theme_stylebox_override("panel", _box(BOX.border_color, 20))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	_title = _label(22, GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_warning = _label(14, GOLD)
	box.add_child(_warning)
	_content = HFlowContainer.new()
	_content.alignment = FlowContainer.ALIGNMENT_CENTER
	_content.add_theme_constant_override("h_separation", 12)
	_content.add_theme_constant_override("v_separation", 12)
	box.add_child(_content)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)
	_back = _action_button("JUDGEMENT_BACK", {"back": true})
	_cancel = _action_button("COMMON_CANCEL", {"cancel": true})
	_confirm = _action_button("", {"confirm": true})
	_confirm.add_theme_color_override("font_color", GOLD)
	for button in [_back, _cancel, _confirm]:
		buttons.add_child(button)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_choice.emit({"cancel": true})
		get_viewport().set_input_as_handled()

# Liefert {skill, target, replace} (replace = Index der vergessenen Attacke oder -1) oder {} bei Abbruch.
func teach(teacher: Monster, targets: Array, warning: String) -> Dictionary:
	var step := 0
	var skill := {}
	var target: Monster = null
	visible = true
	while true:
		_reset(warning)
		_back.visible = step > 0
		match step:
			0:
				_title.text = tr("JUDGEMENT_TEACH_PICK_SKILL").format({"mon": Helper.mon_battle_name(teacher)})
				for teacher_skill in teacher._skills:
					var learnable = targets.any(func(member): return not Skills.knows_skill(member, teacher_skill.name))
					var card = _skill_card(teacher_skill, "" if learnable else tr("JUDGEMENT_TEACH_KNOWN_ALL"))
					if not learnable:
						_disable(card)
					card.pressed.connect(_choice.emit.bind({"value": teacher_skill}))
			1:
				_title.text = tr("JUDGEMENT_TEACH_PICK_TARGET").format({"skill": _skill_name(skill)})
				for member in targets:
					var card = _mon_card(member, skill)
					card.pressed.connect(_choice.emit.bind({"value": member}))
			2:
				_title.text = tr("JUDGEMENT_TEACH_PICK_REPLACE").format({
					"mon": Helper.mon_battle_name(target), "max": Skills.MAX_SKILLS, "skill": _skill_name(skill)})
				for i in target._skills.size():
					var card = _skill_card(target._skills[i], "")
					card.pressed.connect(_choice.emit.bind({"value": i}))
		var result: Dictionary = await _choice
		if result.has("cancel"):
			break
		if result.has("back"):
			step -= 1
			continue
		match step:
			0:
				skill = result.value
				step = 1
			1:
				target = result.value
				if target._skills.size() < Skills.MAX_SKILLS:
					visible = false
					return {"skill": skill, "target": target, "replace": -1}
				step = 2
			2:
				visible = false
				return {"skill": skill, "target": target, "replace": result.value}
	visible = false
	return {}

func confirm(title: String, text: String, confirm_label: String) -> bool:
	_reset(text)
	_title.text = title
	_back.visible = false
	_confirm.visible = true
	_confirm.text = confirm_label
	visible = true
	var result: Dictionary = await _choice
	visible = false
	return result.has("confirm")

# ─────────────────────────
# Aufbau

func _reset(warning: String) -> void:
	for child in _content.get_children():
		child.queue_free()
	_warning.text = warning
	_warning.visible = warning != ""
	_confirm.visible = false

func _skill_name(skill: Dictionary) -> String:
	return tr(skill.name) if skill.scouted else tr("BATTLE_UNKNOWN_SKILL").format(skill)

func _skill_card(skill: Dictionary, note: String) -> Button:
	var card := _card(Vector2(270, 150))
	var lines := _card_lines(card)
	var name_label := _label(19, Helper.color_by_type(skill.nature))
	name_label.text = _skill_name(skill)
	lines.add_child(name_label)
	var stats := _label(14, Color.WHITE)
	var desc := _label(13, MUTED)
	desc.max_lines_visible = 3
	if skill.scouted:
		stats.text = "{cost}: {c}    {cd}: {d}    {power}: {v}".format({
			"cost": tr("SKILL_HEADER_COST"), "cd": tr("SKILL_HEADER_CD"), "power": tr("SKILL_HEADER_POWER"),
			"c": skill.cost, "d": skill.cooldown, "v": skill.value})
		desc.text = tr(skill.description).format(skill)
	else:
		desc.text = tr("BATTLE_UNKNOWN_SKILL_HINT")
	lines.add_child(stats)
	lines.add_child(desc)
	if note != "":
		var note_label := _label(13, GOLD)
		note_label.text = note
		lines.add_child(note_label)
	return card

# Ziel-Monster mit Bild; gesperrt, wenn es die Attacke schon kennt, fehlende Elemente stehen als Hinweis dabei
func _mon_card(mon: Monster, skill: Dictionary) -> Button:
	var card := _card(Vector2(270, 150))
	var row := HBoxContainer.new()
	row.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	_card_lines(card).add_child(row)
	var picture := TextureRect.new()
	picture.texture = Monmap.mon_metainfos_by_name(mon._name).texture_front
	picture.custom_minimum_size = Vector2(100, 100)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(picture)
	var lines := VBoxContainer.new()
	lines.mouse_filter = MOUSE_FILTER_IGNORE
	lines.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(lines)
	var name_label := _label(19, Color.WHITE)
	name_label.text = Helper.mon_battle_name(mon)
	lines.add_child(name_label)
	var count := _label(14, MUTED)
	count.text = tr("JUDGEMENT_TEACH_SKILL_COUNT").format({"count": mon._skills.size(), "max": Skills.MAX_SKILLS})
	lines.add_child(count)
	var note := _label(13, GOLD)
	if Skills.knows_skill(mon, skill.name):
		note.text = tr("JUDGEMENT_LEARN_KNOWN")
		_disable(card)
	else:
		note.text = Skills.missing_elements_text(mon, skill)
	lines.add_child(note)
	return card

func _card(min_size: Vector2) -> Button:
	var card := Button.new()
	card.theme = FLAT_THEME
	card.custom_minimum_size = min_size
	card.add_theme_stylebox_override("normal", _box(BOX.border_color, 0))
	card.add_theme_stylebox_override("hover", _box(GOLD, 0))
	card.add_theme_stylebox_override("pressed", _box(GOLD, 0))
	card.add_theme_stylebox_override("disabled", _box(BOX.border_color, 0))
	_content.add_child(card)
	return card

func _disable(card: Button) -> void:
	card.disabled = true
	card.modulate.a = 0.45

func _card_lines(card: Button) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.mouse_filter = MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	card.add_child(margin)
	var lines := VBoxContainer.new()
	lines.mouse_filter = MOUSE_FILTER_IGNORE
	lines.add_theme_constant_override("separation", 4)
	margin.add_child(lines)
	return lines

func _action_button(text_key: String, result: Dictionary) -> Button:
	var button := Button.new()
	button.theme = FLAT_THEME
	button.text = text_key
	button.custom_minimum_size = Vector2(180, 44)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _box(BOX.border_color, 0))
	button.add_theme_stylebox_override("hover", _box(GOLD, 0))
	button.pressed.connect(_choice.emit.bind(result))
	return button

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label

func _box(border: Color, padding: int) -> StyleBoxFlat:
	var box := BOX.duplicate() as StyleBoxFlat
	box.border_color = border
	if padding > 0:
		box.set_content_margin_all(padding)
	return box

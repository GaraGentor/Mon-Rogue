extends Control

@export var mw1: Control
@export var mw2: Control
@export var mw3: Control

@export var next_button: Button

@export var placeholder_panel: Panel

@export var learning_screen: Panel
@export var leaving_screen: Panel
@export var sacrifice_button: Button

var _index = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.learn_skill.connect(_learn_skill)
	_start()
	pass # Replace with function body.

func _start(index:int = 0):
	State.mons = State.mons
	print(State.mons)
	var new_mons = State.catched_mons
	mw2.monster = State.mons[0]
	if State.mons.size() == 2:
		placeholder_panel.visible = false
		mw3.visible = true
		mw3.monster = State.mons[1]
	print("nm:?", new_mons)
	if new_mons.size() >= 1:
		mw1.monster = new_mons[index]
	else:
		get_tree().change_scene_to_file("res://script/scenes/world_map/world_map.tscn")
		return
	set_strings(new_mons)
	_refresh_sacrifice_button(new_mons[index])

# Opfern ist nur möglich, wenn das gefangene Monster eine noch gesperrte Ei-Attacke trägt
func _refresh_sacrifice_button(mon: Monster) -> void:
	var egg_skill = mon.get_unlockable_egg_skill()
	sacrifice_button.visible = not egg_skill.is_empty()
	if sacrifice_button.visible:
		sacrifice_button.text = tr("JUDGEMENT_SACRIFICE").format({"skill": tr(egg_skill.name)})

func _on_sacrifice_pressed() -> void:
	var mon: Monster = State.catched_mons[_index]
	var egg_skill = mon.get_unlockable_egg_skill()
	if egg_skill.is_empty():
		return
	SaveManager.unlock_egg_skill(mon._name, egg_skill.name)
	_show_unlock_message(tr("EGG_SKILL_UNLOCKED").format({"skill": tr(egg_skill.name), "mon": Helper.mon_display_name(mon._name)}))
	_on_release_pressed()

func _show_unlock_message(text: String) -> void:
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
	label.position.x = (get_viewport_rect().size.x - label.get_minimum_size().x) / 2
	var tween := label.create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func _on_recruit_button_pressed() -> void:
	if State.mons.size() == 2:
		leaving_screen.visible = true
	if State.mons.size() == 1:
		var nm: Monster = State.catched_mons[_index]
		State.mons.append(nm)
		State.catched_mons.remove_at(_index)
		_index = 0
		_start()
	

func _on_release_pressed() -> void:
	State.catched_mons.remove_at(_index)
	_index = 0
	_start()

func set_strings(_mons):
	next_button.text = "{a}/{b}\n\n\n{next}".format({"a":str(_index+1), "b":str(_mons.size()), "next": tr("JUDGEMENT_NEXT")})

func _on_next_pressed() -> void:
	var new_mons = State.catched_mons
	if (_index + 1 >= new_mons.size()):
		_index = 0
	else: _index = _index + 1
	_start(_index)

func _learn_skill(skill) -> void:
	learning_screen.skill = skill
	learning_screen.visible = true

extends Control

signal buy_button_pressed(skill, cost, recommendation)
@export var buy_button: Button
@export var name_label: Label
@export var description_label: Label

@export var can_learn_1: Label
@export var can_learn_2: Label

@export var own_it_1: Label
@export var own_it_2: Label

@export var mon_texture_rect1: TextureRect
@export var mon_texture_rect2: TextureRect

var cost: int = 10

var skill: Dictionary:
	set(val):
		skill = val
		_init_()

var mons: Array[Monster]:
	set(val):
		mons = val
		_init_with_mons(mons)

func _ready() -> void:
	State.ep_changed.connect(_money_changed)
	check_if_money_is_enough(State.ep)

func _money_changed(mone) -> void:
	check_if_money_is_enough(mone)

func check_if_money_is_enough(mone)-> void:
	if mone < cost:
		buy_button.disabled = true

func _init_() -> void:
	var color = Helper.color_by_type(skill.nature)
	name_label.self_modulate = color
	name_label.text = tr(skill.name)
	description_label.text = tr(skill.description).format(skill)
	var rand = randi_range(skill.shop_cost.min, skill.shop_cost.max)
	cost = rand
	buy_button.text = "$ " + str(rand)

func _init_with_mons(mons: Array[Monster]) -> void:
	if mons.size() >= 2:
		var mon = mons[1]
		var minfo = Monmap.mon_metainfos_by_name(mon._name)
		if _mon_has_skill(mon) and _mon_can_use_skill(mon):
			mon_texture_rect2.visible = true
			mon_texture_rect2.texture = minfo.texture_front

	var mon = mons[0]
	var minfo = Monmap.mon_metainfos_by_name(mon._name)
	if _mon_has_skill(mon) and _mon_can_use_skill(mon):
		mon_texture_rect1.visible = true
		mon_texture_rect1.texture = minfo.texture_front

func color_up_labels(label: Label, true_value: bool) -> void:
	if true_value:
		label.self_modulate = Color("#00ff00")
	else: 
		label.self_modulate = Color("#ff0000")

func _mon_has_skill(mon: Monster) -> bool:
	var skills = mon._skills.map(func(_skill): return _skill.name)
	return !skills.has(skill.name)

func _mon_can_use_skill(mon: Monster) -> bool:
	return Skills.can_use(mon, skill)

func _on_buy_button_pressed() -> void:
	var recommendation = 9
	if mon_texture_rect1.visible and mon_texture_rect2.visible:
		recommendation = 2
	elif mon_texture_rect2.visible:
		recommendation = 1
	elif mon_texture_rect1.visible:
		recommendation = 0
	# die Karte entfernt der Trainer erst, wenn der Kauf abgeschlossen ist (Abbrechen ist möglich)
	buy_button_pressed.emit(skill, cost, recommendation)

extends Control

@export var grid_container: GridContainer
@export var money_label: Label
@export var shop_skill_card: PackedScene

@export var deciding_panel: Panel
@export var deciding_skill_name: Label

signal button_chosen(btn)
@export var test_button: Button
@export var test_button2: Button
@export var recom_label_1: Label
@export var recom_label_2: Label

var shop_skills = []
var debug = false

func _ready() -> void:
	if debug:
		var mon1:Monster = Helper.generate_mons({"count": 1, "level": randi_range(10,30)})[0]
		var mon2:Monster = Helper.generate_mons({"count": 1, "level": randi_range(10,30)})[0]
		State.mons.append(mon1)
		State.mons.append(mon2)
		State.ep = randi_range(5, 8)
	_init_()
	State.ep_changed.connect(_ep_changed)

func _init_() -> void:
	# get some random skills
	money_label.text = "$ " + str(State.ep)
	if State.shopped.size() == 0:
		State.shopped.append_array(Skills.attack_skills.duplicate(true))
		State.shopped.append_array(Skills.defensive_skills.duplicate(true))
		State.shopped.append_array(Skills.buff_skills.duplicate(true))
	for i in 8:
		if State.shopped.size() >= 1:
			var random_item = State.shopped.pick_random().duplicate(true)
			State.shopped.erase(random_item)
			shop_skills.append(random_item)
			var ssc = shop_skill_card.instantiate()
			ssc.set_h_size_flags(SIZE_EXPAND_FILL)
			ssc.set_v_size_flags(SIZE_EXPAND_FILL)
			ssc.skill = random_item
			ssc.mons = State.mons
			ssc.buy_button_pressed.connect(_bought_skill)
			grid_container.add_child(ssc)

func _bought_skill(skill, cost, recommendation) -> void:
	deciding_skill_name.self_modulate = ColorMap.get_combo(skill.nature).color
	deciding_skill_name.text = tr(skill.name)
	if State.mons.size() == 1:
		recom_label_2.visible = false
		test_button2.visible = false
	if recommendation == 0:
		recom_label_1.visible = true
	if recommendation == 1:
		recom_label_2.visible = true
	if recommendation == 2:
		recom_label_1.visible = true
		recom_label_2.visible = true
	deciding_panel.visible = true
	var btn = await button_chosen
	State.ep -= cost
	# learn skill
	deciding_panel.visible = false
	State.mons[btn]._skills.append(skill.duplicate())

func _ep_changed(ep) -> void:
	money_label.text = "$ " + str(ep)

func _on_close_pressed() -> void:
	State.ep_changed.disconnect(_ep_changed)
	queue_free()

func _on_learn_to_mon_one_pressed() -> void:
	button_chosen.emit(0)

func _on_learn_to_mon_2_pressed() -> void:
	button_chosen.emit(1)

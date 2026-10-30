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
# Zeile mit den Monster-Buttons und Abbrechen; wird während der Ersetzen-Auswahl ausgeblendet
@export var choice_row: Control
@export var cancel_button: Button
@export var deciding_box: VBoxContainer

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
			ssc.buy_button_pressed.connect(_bought_skill.bind(ssc))
			grid_container.add_child(ssc)

func _bought_skill(skill, cost, recommendation, card: Control) -> void:
	deciding_skill_name.self_modulate = ColorMap.get_combo(skill.nature).color
	deciding_skill_name.text = tr(skill.name)
	recom_label_1.visible = recommendation == 0 or recommendation == 2
	recom_label_2.visible = recommendation == 1 or recommendation == 2
	Skills.setup_learn_button(test_button, State.mons[0], skill, "TRAINER_MONSTER_1")
	if State.mons.size() == 1:
		recom_label_2.visible = false
		test_button2.visible = false
	else:
		Skills.setup_learn_button(test_button2, State.mons[1], skill, "TRAINER_MONSTER_2")
	deciding_panel.visible = true
	_show_choices(true)
	# bezahlt wird erst, wenn der Skill wirklich gelernt wurde
	while true:
		var btn = await button_chosen
		if btn == -1:
			deciding_panel.visible = false
			return
		var mon: Monster = State.mons[btn]
		var learned = Skills.learnable_copy(skill)
		if mon._skills.size() < Skills.MAX_SKILLS:
			mon._skills.append(learned)
			break
		_show_choices(false)
		var picker := SkillReplacePicker.new(mon)
		deciding_box.add_child(picker)
		var index = await picker.picked
		_show_choices(true)
		if index != -1:
			mon._skills[index] = learned
			break
	State.ep -= cost
	deciding_panel.visible = false
	card.queue_free()

func _show_choices(shown: bool) -> void:
	choice_row.visible = shown
	cancel_button.visible = shown

func _on_cancel_pressed() -> void:
	button_chosen.emit(-1)

func _ep_changed(ep) -> void:
	money_label.text = "$ " + str(ep)

func _on_close_pressed() -> void:
	State.ep_changed.disconnect(_ep_changed)
	queue_free()

func _on_learn_to_mon_one_pressed() -> void:
	button_chosen.emit(0)

func _on_learn_to_mon_2_pressed() -> void:
	button_chosen.emit(1)

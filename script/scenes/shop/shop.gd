extends Control

@export var element_pill: PackedScene
var element_pills = [Enums.MON_TYPES.EARTH, Enums.MON_TYPES.AIR, Enums.MON_TYPES.WATER, Enums.MON_TYPES.FIRE]

@export var grid: GridContainer

@export var money_label: Label

var debug = true
var test_money = 40

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if debug:
		test_money = randi_range(70,500)
		State.ep = test_money
	money_label.text = "$ " + str(test_money if debug else State.ep)
	for e in element_pills:
		var e_p = element_pill.instantiate()
		e_p._init_pill(e, 70)
		e_p.set_h_size_flags(SIZE_EXPAND_FILL)
		e_p.set_v_size_flags(SIZE_EXPAND_FILL)
		grid.add_child(e_p)
	State.ep_changed.connect(_money_changed)

func _money_changed(new_val):
	money_label.text = "$ " + str(State.ep)

func _on_button_pressed() -> void:
	queue_free()

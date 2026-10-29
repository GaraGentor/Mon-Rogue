extends Panel

@export var mon_index: int
@export var element: Control

@export var to_label: Label
@export var new_element: Control

@export var texture: TextureRect

@export var info_label: Label

var mon:Monster

var debug = false

func _ready() -> void:
	if debug:
		var mon1:Monster = Helper.generate_mons({"count": 1, "level": randi_range(10,30)})[0]
		var mon2:Monster = Helper.generate_mons({"count": 1, "level": randi_range(10,30)})[0]
		State.mons.append(mon1)
		State.mons.append(mon2)
	_init_mons()

func show_additional_labels():
	to_label.visible = true
	new_element.visible = true

func hide_additional_labels():
	to_label.visible = false
	new_element.visible = false

func _init_mons():
	if mon_index + 1 <= State.mons.size():
		mon = State.mons[mon_index]
		element._init_color(mon)
		texture.texture = Monmap.mon_metainfos_by_name(mon._name).texture_front
	if State.mons.size() == 0:
		var d = ColorMap.get_combo(Enums.MON_TYPES.AIR)
		element._init_with_element(d)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	print(data)
	preview(data)
	return not ColorMap.has_element(mon._type, data.type)

func _drop_data(pos, data):
	print("item dropped left")
	# change mon element
	if State.ep >= data.cost:
		# rerender
		mon._type = ColorMap.add_element(mon._type, data.type)
		_init_mons()
		State.ep -= data.cost
	else:
		info_label.text = tr("SHOP_NOT_ENOUGH_MONEY")
	pass

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		print("Drag beendet (Drop oder Abbruch)")
		hide_additional_labels()

func preview(data):
	# get new element.
	# var d = ColorMap.get_combo(mon._type | data.type)
	var d = ColorMap.get_combo(mon._type | data.type)
	new_element._init_with_element(d)
	show_additional_labels()
	pass

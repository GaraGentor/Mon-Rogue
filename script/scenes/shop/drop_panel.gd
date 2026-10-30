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
	else:
		# kein Monster auf diesem Platz
		self_modulate = Color(1, 1, 1, 0)
		for child in get_children():
			child.visible = false
	if State.mons.size() == 0:
		var d = ColorMap.get_combo(Enums.MON_TYPES.AIR)
		element._init_with_element(d)

func _is_gem(data) -> bool:
	return data.get("kind", "") == "gem"

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if mon == null or typeof(data) != TYPE_DICTIONARY:
		return false
	if _is_gem(data):
		return true
	preview(data)
	return not ColorMap.has_element(mon._type, data.type)

func _drop_data(pos, data):
	if State.ep < data.cost:
		info_label.text = tr("SHOP_NOT_ENOUGH_MONEY")
		return
	State.ep -= data.cost
	if _is_gem(data):
		mon.add_gem(data.stat, data.bonus)
		data.on_bought.call()
		info_label.text = tr("SHOP_GEM_GIVEN").format({"mon": Helper.mon_display_name(mon._name)})
		return
	# change mon element
	mon._type = ColorMap.add_element(mon._type, data.type)
	_init_mons()

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		hide_additional_labels()

func preview(data):
	# get new element.
	var d = ColorMap.get_combo(mon._type | data.type)
	new_element._init_with_element(d)
	show_additional_labels()

class_name SaveSlotBar
extends HBoxContainer

## Spielstand-Auswahl in der Ei-Auswahl. Ein leerer Slot fragt nach dem Kampfmodus, der danach fest zu ihm gehört.

const FONT_SIZE := 16
const MARGIN := 16.0
const SELECTION_SCENE := "res://script/scenes/selection/selection.tscn"
const MODE_LABELS := {
	SaveManager.MODE_CLASSIC: "SAVE_MODE_CLASSIC",
	SaveManager.MODE_THREE_ACTIONS: "SAVE_MODE_THREE_ACTIONS",
}

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	# unten links: oben stehen Titel und Biom-Pfad, rechts das Info-Panel
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = MARGIN
	offset_bottom = -MARGIN
	_show_slots()

func _clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _add_button(text: String, on_pressed: Callable) -> Button:
	var button := RewardDialog.plate_button(text)
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.pressed.connect(on_pressed)
	add_child(button)
	return button

func _show_slots() -> void:
	_clear()
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		var button := _add_button(_slot_text(slot), _slot_pressed.bind(slot))
		button.disabled = slot == SaveManager.active_slot

func _slot_text(slot: int) -> String:
	var content: String = tr(MODE_LABELS[SaveManager.slot_mode(slot)]) if SaveManager.slot_exists(slot) else tr("SAVE_SLOT_EMPTY")
	return tr("SAVE_SLOT").format({"slot": slot, "content": content})

func _slot_pressed(slot: int) -> void:
	if SaveManager.slot_exists(slot):
		_switch_to(slot)
		return
	_clear()
	for mode in MODE_LABELS:
		_add_button(tr(MODE_LABELS[mode]), _switch_to.bind(slot, mode))
	_add_button(tr("COMMON_CANCEL"), _show_slots)

func _switch_to(slot: int, new_mode := SaveManager.MODE_CLASSIC) -> void:
	SaveManager.switch_slot(slot, new_mode)
	State.reset()
	State.boss_shards = SaveManager.save_data["boss_shards"]
	get_tree().change_scene_to_file(SELECTION_SCENE)

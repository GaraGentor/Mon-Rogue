extends Control

@export var sold_panel: Panel
@export var max_upgrade_panel: Panel

@export var buy_button: Button

@export var texture: TextureRect

@export var upgrade_infos: Control

@export var mon_name_label: Label

var current_upgrade_level: int = 0

func _ready():
	State.boss_shards_changed.connect(_changed_boss_shards)

func _init_with_mon(mon: String) -> void:
	mon_name_label.text = Helper.mon_display_name(mon)
	texture.texture = Monmap.mon_metainfos_by_name(mon).texture_front
	if SaveManager.save_data.monsters.has(mon):
		var upgrade_level = SaveManager.save_data.monsters[mon]
		current_upgrade_level = upgrade_level.upgrade
		if upgrade_level.upgrade == Monmap.mon_metainfos_by_name(mon).max_upgrades:
			sold_panel.visible = false
			max_upgrade_panel.visible = true
		upgrade_infos._init_with_infos(mon, upgrade_level.upgrade)
		_changed_boss_shards(State.boss_shards)
		return
	upgrade_infos._init_with_infos(mon, 0)
	_changed_boss_shards(State.boss_shards)

func _changed_boss_shards(shards) -> void:
	print(current_upgrade_level)
	print(current_upgrade_level * 2 + 1)
	print(shards)
	print(shards > (current_upgrade_level * 2 + 1))
	if shards >= (current_upgrade_level * 2 + 1):
		buy_button.disabled = false

func sold() -> void:
	sold_panel.visible = true

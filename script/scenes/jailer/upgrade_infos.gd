extends Control

@export var shard_label: Label
@export var cost_label: Label

@export var current_upgrades_label: Label
@export var max_upgrades_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	State.boss_shards_changed.connect(_shards_changed)
	_shards_changed(State.boss_shards)

func _init_with_infos(mon: String, current_upgrades: int) -> void:
	var infos = Monmap.mon_metainfos_by_name(mon)
	current_upgrades_label.text = tr("JAILER_CURRENT_UPGRADE_LEVEL").format({"level": current_upgrades})
	max_upgrades_label.text = tr("JAILER_MAX_UPGRADE_LEVEL").format({"level": infos.max_upgrades})
	cost_label.text = "x" + str(current_upgrades * 2 + 1)

func _shards_changed(val) -> void:
	shard_label.text = "("+str(val)+")"

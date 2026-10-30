extends RewardDialog

## Edelstein-Feld: drei Edelsteine zur Wahl, der gewählte erhöht einen Wert eines eigenen
## Monsters prozentual für den restlichen Run. Pro Biom-Tiefe werden die Steine stärker.

const GEM_CHOICES := 3
const ACCENT := Color(0.2, 0.6, 0.65)

## Stat-Key (siehe Monster.gem_factor) -> Anzeige
const STATS := {
	"hp": {"name": "GEM_HP", "stat": "STAT_HP", "color": Color(0.85, 0.25, 0.3)},
	"atk": {"name": "GEM_ATK", "stat": "STAT_ATK", "color": Color(0.95, 0.55, 0.2)},
	"def": {"name": "GEM_DEF", "stat": "STAT_DEF", "color": Color(0.6, 0.6, 0.65)},
	"s_atk": {"name": "GEM_S_ATK", "stat": "STAT_SPA", "color": Color(0.7, 0.35, 0.9)},
	"s_def": {"name": "GEM_S_DEF", "stat": "STAT_SPD", "color": Color(0.3, 0.55, 0.95)},
	"speed": {"name": "GEM_SPEED", "stat": "STAT_SPE", "color": Color(0.35, 0.85, 0.45)},
}

## Bonus pro Biom-Tiefe (State.map_level), 0.06 = +6 %
const BONUS_BY_DEPTH := [0.06, 0.08, 0.10, 0.12, 0.15]

const GEM_ICON = preload("res://assets/ui/boss_shard/a_rare_crystal_with_some_spark.jpeg")

var _bonus: float

func _ready() -> void:
	set_accent(ACCENT)
	set_title(tr("GEM_CHOOSE"))
	_bonus = BONUS_BY_DEPTH[clampi(State.map_level, 0, BONUS_BY_DEPTH.size() - 1)]
	var stats = STATS.keys()
	stats.shuffle()
	for stat in stats.slice(0, GEM_CHOICES):
		add_gem_card(self, stat, _bonus, tr("GEM_TAKE"), _on_gem_chosen.bind(stat))

func _on_gem_chosen(stat: String) -> void:
	choose_mon_for_gem(self, stat, _bonus)

## Edelstein-Karte, auch vom Schatz genutzt
static func add_gem_card(dialog: RewardDialog, stat: String, bonus: float, button_text: String, on_pressed: Callable) -> void:
	var info: Dictionary = STATS[stat]
	var text = dialog.tr("GEM_DESC").format({"stat": dialog.tr(info.stat).trim_suffix(":"), "value": roundi(bonus * 100)})
	dialog.add_card(dialog.tr(info.name), text, texture_icon(GEM_ICON, info.color), button_text, on_pressed)

## Schritt 2: Monster wählen, das den Edelstein bekommt, danach schließt der Dialog
static func choose_mon_for_gem(dialog: RewardDialog, stat: String, bonus: float) -> void:
	dialog.next_step(dialog.tr("GEM_CHOOSE_MON"))
	var info: Dictionary = STATS[stat]
	for mon: Monster in State.mons:
		var stat_name = dialog.tr(info.stat).trim_suffix(":")
		var text = "%s +%d%%\n%s" % [stat_name, roundi(bonus * 100), dialog.tr("GEM_CURRENT").format({"value": roundi((mon.gem_factor(stat) - 1.0) * 100)})]
		var give := func():
			mon.add_gem(stat, bonus)
			dialog.close()
		dialog.add_card(Helper.mon_display_name(mon._name), text, mon_icon(mon), dialog.tr("GEM_GIVE"), give)

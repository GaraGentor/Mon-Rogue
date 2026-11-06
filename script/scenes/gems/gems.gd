extends RewardDialog

## Edelstein-Feld: drei Edelsteine zur Wahl, der gewählte erhöht einen Wert eines eigenen
## Monsters um feste Punkte für den restlichen Run. Pro Biom-Tiefe werden die Steine stärker.

const GEM_CHOICES := 3
const ACCENT := Color(0.2, 0.6, 0.65)

## Stat-Key (siehe Monster.gem_bonus) -> Anzeige
const STATS := {
	"hp": {"name": "GEM_HP", "stat": "STAT_HP", "color": Color(0.85, 0.25, 0.3)},
	"atk": {"name": "GEM_ATK", "stat": "STAT_ATK", "color": Color(0.95, 0.55, 0.2)},
	"def": {"name": "GEM_DEF", "stat": "STAT_DEF", "color": Color(0.6, 0.6, 0.65)},
	"s_atk": {"name": "GEM_S_ATK", "stat": "STAT_SPA", "color": Color(0.7, 0.35, 0.9)},
	"s_def": {"name": "GEM_S_DEF", "stat": "STAT_SPD", "color": Color(0.3, 0.55, 0.95)},
	"speed": {"name": "GEM_SPEED", "stat": "STAT_SPE", "color": Color(0.35, 0.85, 0.45)},
}

## Bonus pro Biom-Tiefe (State.map_level) in festen Punkten auf den Wert
const BONUS_BY_DEPTH := [15, 20, 25, 30, 35]

const GEM_ICON = preload("res://assets/ui/shop/gem.svg")
const COUNT_ICON_SIZE := Vector2(20, 20)
const COUNT_FONT_SIZE := 16
## noch nicht gesammelte Steine treten zurück
const NO_GEM_ALPHA := 0.35

var _bonus: int

func _ready() -> void:
	use_map_layout()
	set_accent(ACCENT)
	set_title(tr("GEM_CHOOSE"))
	set_drag_hint("GEM_HINT")
	show_fixed_targets(State.mons, false)
	show_gem_info(self)
	_bonus = BONUS_BY_DEPTH[clampi(State.map_level, 0, BONUS_BY_DEPTH.size() - 1)]
	var stats = STATS.keys()
	stats.shuffle()
	for stat in stats.slice(0, GEM_CHOICES):
		add_gem_card(self, stat, _bonus)

## Monster-Ziele zeigen ihre gesammelten Steine und ihre Werte, beim Ziehen auch die Änderung durch den Stein
static func show_gem_info(dialog: RewardDialog) -> void:
	for target in dialog._fixed_targets:
		if target.mon == null:
			continue
		target.box.add_child(gem_counts(target.mon))
		target.stats = StatsGrid.stacked_for(target.mon)
		target.box.add_child(target.stats)
		ignore_mouse_below(target)

## Eine Zeile mit allen Steinarten und wie viele davon das Monster schon hat
static func gem_counts(mon: Monster) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for stat in STATS:
		var count := mon.gem_count(stat)
		var entry := HBoxContainer.new()
		entry.add_theme_constant_override("separation", 3)
		entry.tooltip_text = TranslationServer.translate(STATS[stat].name)
		if count == 0:
			entry.modulate.a = NO_GEM_ALPHA
		var icon := texture_icon(GEM_ICON, STATS[stat].color)
		icon.custom_minimum_size = COUNT_ICON_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entry.add_child(icon)
		var label := Label.new()
		label.text = str(count)
		label.add_theme_font_size_override("font_size", COUNT_FONT_SIZE)
		label.add_theme_color_override("font_color", IronPlate.TEXT_COLOR)
		entry.add_child(label)
		row.add_child(entry)
	return row

## Edelstein-Karte, auch von Schatz und Shop genutzt: wird auf ein Monster gezogen.
## Die Änderung zeigen die Werte am Ziel (show_gem_info).
static func add_gem_card(dialog: RewardDialog, stat: String, bonus: int) -> RewardDialog.RewardCard:
	var info: Dictionary = STATS[stat]
	var stat_name = dialog.tr(info.stat).trim_suffix(":")
	var text = dialog.tr("GEM_DESC").format({"stat": stat_name, "value": bonus})
	var give := func(mon: Monster):
		mon.add_gem(stat, bonus)
	return dialog.add_mon_card(dialog.tr(info.name), text, texture_icon(GEM_ICON, info.color), dialog.tr("GEM_CHOOSE_MON"), State.mons, give, Callable(), {"stat": stat, "bonus": bonus})

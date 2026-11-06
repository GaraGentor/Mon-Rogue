extends Node

## Passive pro Art im Modus "3 Aktionen": jede beim Kerkermeister gesprengte Kette ist eine Stufe (values[Stufe - 1], in Prozent).
## Sie wirken nur für eigene Monster, wilde Monster derselben Art bekommen nichts.
##
## Effekte:
## - stat: mehr von einem Wert
## - turn_shield / battle_shield: Schild aus (Sp.) Verteidigung zu Beginn jedes eigenen Zuges / zu Kampfbeginn
## - first_skill: mehr Schaden mit dem ersten Skill im Zug
## - full_hp: mehr Schaden gegen unverletzte Ziele
## - low_hp: mehr Schaden, solange das Monster höchstens die Hälfte seiner KP hat
## - catch: höhere Fangchance, solange das Monster im Team kämpft

const PASSIVES := {
	"1": {"name": "PASSIVE_1", "effect": "first_skill", "values": [15, 30]},
	"2": {"name": "PASSIVE_2", "effect": "turn_shield", "physical": true, "values": [10, 20]},
	"3": {"name": "PASSIVE_3", "effect": "stat", "stat": "speed", "values": [10, 20]},
	"4": {"name": "PASSIVE_4", "effect": "low_hp", "values": [20, 40]},
	"5": {"name": "PASSIVE_5", "effect": "full_hp", "values": [15, 30]},
	"6": {"name": "PASSIVE_6", "effect": "stat", "stat": "atk", "values": [10, 20]},
	"7": {"name": "PASSIVE_7", "effect": "turn_shield", "physical": false, "values": [10, 20]},
	"8": {"name": "PASSIVE_8", "effect": "stat", "stat": "s_atk", "values": [10, 20]},
	"9": {"name": "PASSIVE_9", "effect": "stat", "stat": "hp", "values": [10, 20]},
	"10": {"name": "PASSIVE_10", "effect": "battle_shield", "physical": true, "values": [30, 60]},
	"11": {"name": "PASSIVE_11", "effect": "catch", "values": [10, 20]},
	"12": {"name": "PASSIVE_12", "effect": "first_skill", "values": [15, 30]},
	"13": {"name": "PASSIVE_13", "effect": "stat", "stat": "def", "values": [10, 20]},
	"14": {"name": "PASSIVE_14", "effect": "full_hp", "values": [15, 30]},
	"15": {"name": "PASSIVE_15", "effect": "stat", "stat": "s_def", "values": [10, 20]},
	"16": {"name": "PASSIVE_16", "effect": "low_hp", "values": [20, 40]},
}

## Stärke der Passive dieses Monsters in Prozent, 0 ohne Wirkung. effect "" = jeder Effekt.
func _value(mon: Monster, effect: String) -> int:
	if not SaveManager.is_three_actions() or not State.mons.has(mon) or mon._upgrades <= 0:
		return 0
	var passive: Dictionary = PASSIVES[mon._name]
	if passive.effect != effect:
		return 0
	return passive.values[mini(int(mon._upgrades), passive.values.size()) - 1]

func stat_factor(mon: Monster, stat: String) -> float:
	if PASSIVES.get(mon._name, {}).get("stat", "") != stat:
		return 1.0
	return 1.0 + _value(mon, "stat") / 100.0

## Faktor auf den Schaden von from gegen to
func damage_factor(from: Monster, to: Monster) -> float:
	var bonus := 0
	if from._skills_played_this_turn == 0:
		bonus += _value(from, "first_skill")
	if to._lost_hp <= 0:
		bonus += _value(from, "full_hp")
	if from._lost_hp >= from.hp() / 2.0:
		bonus += _value(from, "low_hp")
	return 1.0 + bonus / 100.0

func catch_factor() -> float:
	var bonus := 0
	for mon in State.mons:
		if mon.is_alive():
			bonus += _value(mon, "catch")
	return 1.0 + bonus / 100.0

func on_battle_start(mon: Monster) -> void:
	_add_shield(mon, _value(mon, "battle_shield"))

func on_turn_start(mon: Monster) -> void:
	_add_shield(mon, _value(mon, "turn_shield"))

func _add_shield(mon: Monster, percent: int) -> void:
	if percent <= 0:
		return
	var physical: bool = PASSIVES[mon._name].physical
	var def: float = mon.defense() if physical else mon.s_defense()
	mon.add_shield(ceilf(def * percent / 100.0), physical)

## Wirkung einer Stufe (ab 1), z. B. "+10 % Initiative"
func effect_text(mon_name: String, level: int) -> String:
	var passive: Dictionary = PASSIVES[mon_name]
	var key: String = "PASSIVE_EFFECT_" + passive.effect.to_upper()
	if passive.effect.ends_with("shield"):
		key += "_PHYSICAL" if passive.physical else "_MAGICAL"
	var stat_name: String = tr("PASSIVE_STAT_" + passive.get("stat", "").to_upper())
	return tr(key).format({"value": passive.values[level - 1], "stat": stat_name})

func passive_name(mon_name: String) -> String:
	return tr(PASSIVES[mon_name].name)

## Beschreibung für Tooltips: aktuelle Stufe mit Wirkung, ohne Kette die erste Stufe als Ausblick
func tooltip(mon_name: String, level: int) -> String:
	return tr("PASSIVE_TOOLTIP").format({
		"name": passive_name(mon_name),
		"level": level,
		"max": PASSIVES[mon_name].values.size(),
		"effect": effect_text(mon_name, maxi(level, 1)),
	})

extends Node

## Relics: passive Run-Boni, gesammelt in State.relics (Liste von Relic-IDs).
##
## Wirkung über benannte Hooks: An den Stellen im Spielcode, wo ein Wert entsteht, wird
## Relics.modify("<hook>", wert, kontext) aufgerufen. Jedes Relic kann pro Hook eine
## Funktion (wert, kontext) -> neuer_wert mitbringen. So steht die Logik eines Relics an
## einem Ort, der Spielcode kennt nur die Hooks, nicht die einzelnen Relics.
##
## Bekannte Hooks:
## - "moves": Skillpunkte (Züge) eines Monsters zu Beginn seines Zuges, kontext = Monster
## - "catch_chance": Fangchance 0..1 vor dem Begrenzen, kontext = gegnerisches Monster
## - "battle_ep": EP für einen gewonnenen Kampf, kontext = null
##
## Für reaktive Effekte ("wenn X passiert, tu Y") kann ein Relic später zusätzlich
## "on_<event>" Einträge bekommen, die in _ready() an die Signale aus Events gehängt werden.

signal relics_changed

# var statt const: Lambdas sind keine konstanten Ausdrücke
var RELICS := {
	"extra_move": {
		"name": "RELIC_EXTRA_MOVE",
		"description": "RELIC_EXTRA_MOVE_DESC",
		"icon": "res://assets/ui/icons/sword.svg",
		"hooks": {
			# nur eigene Monster profitieren
			"moves": func(value: int, mon: Monster) -> int: return value + 1 if State.mons.has(mon) else value,
		},
	},
	"lucky_charm": {
		"name": "RELIC_LUCKY_CHARM",
		"description": "RELIC_LUCKY_CHARM_DESC",
		"icon": "res://assets/ui/icons/sparkle.svg",
		"hooks": {
			"catch_chance": func(value: float, _mon: Monster) -> float: return value * 1.25,
		},
	},
	"golden_idol": {
		"name": "RELIC_GOLDEN_IDOL",
		"description": "RELIC_GOLDEN_IDOL_DESC",
		"icon": "res://assets/ui/icons/firework (1).svg",
		"hooks": {
			"battle_ep": func(value: int, _ctx) -> int: return roundi(value * 1.3),
		},
	},
}

func get_relic(id: String) -> Dictionary:
	return RELICS.get(id, {})

func has_relic(id: String) -> bool:
	return State.relics.has(id)

## Relics, die in diesem Run noch nicht gesammelt wurden
func get_unowned() -> Array:
	return RELICS.keys().filter(func(id): return not has_relic(id))

func add_relic(id: String) -> void:
	if not RELICS.has(id) or has_relic(id):
		return
	State.relics.append(id)
	relics_changed.emit()

## Wendet die Hooks aller gesammelten Relics nacheinander auf value an.
func modify(hook: String, value, context = null):
	for id in State.relics:
		var fn = get_relic(id).get("hooks", {}).get(hook)
		if fn:
			value = fn.call(value, context)
	return value

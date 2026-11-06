extends Node

## Einstellungen des Debug-Menüs in einer eigenen Datei, unabhängig von den Spielständen.
## Fertige Builds ignorieren die Datei und nutzen immer die Standardwerte.

const PATH := "user://debug_settings.json"
const STATS := ["hp", "atk", "def", "s_atk", "s_def", "speed"]
const MAX_RESERVED := 100
## Für den Start etwa doppelte KP: bei typisch 15 % KP-Anteil ergibt 18 % Reserve rund 30 % der BST
const DEFAULT_RESERVED := {
	SaveManager.MODE_CLASSIC: {},
	SaveManager.MODE_THREE_ACTIONS: {"hp": 18},
}

## Zeigt den Button "Faule Eier" in der Ei-Auswahl, ohne die Ladungen im Spielstand anzurühren
var rotten_eggs := false
## Kampfmodus -> Wert -> Prozent der BST, die fest diesem Wert gehören
var _reserved := {}

func _ready() -> void:
	_reserved = DEFAULT_RESERVED.duplicate(true)
	if not OS.is_debug_build() or not FileAccess.file_exists(PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		rotten_eggs = parsed.get("rotten_eggs", false)
		_reserved.merge(parsed.get("reserved_stats", {}), true)

func save() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"rotten_eggs": rotten_eggs, "reserved_stats": _reserved}))

func set_rotten_eggs(on: bool) -> void:
	rotten_eggs = on
	save()

## Reservierter Anteil eines Werts im Kampfmodus des aktiven Slots, in Prozent
func reserved(stat: String) -> int:
	return int(_reserved[SaveManager.combat_mode()].get(stat, 0))

func reserved_total() -> int:
	var total := 0
	for stat in STATS:
		total += reserved(stat)
	return total

## Über alle Werte hinweg kann höchstens die ganze BST reserviert werden
func set_reserved(stat: String, percent: int) -> void:
	var others := reserved_total() - reserved(stat)
	_reserved[SaveManager.combat_mode()][stat] = clampi(percent, 0, MAX_RESERVED - others)
	save()

func reset_reserved() -> void:
	var mode := SaveManager.combat_mode()
	_reserved[mode] = DEFAULT_RESERVED[mode].duplicate()
	save()

## Anteil an der BST nach Reserve: fester Teil plus der übliche Anteil am Rest.
## Beispiel: 40 % KP reserviert, üblicher KP-Anteil 15 % -> 0,4 + 0,6 * 0,15 = 49 %.
func effective_share(stat: String, usual_share: float) -> float:
	return reserved(stat) / 100.0 + (1.0 - reserved_total() / 100.0) * usual_share

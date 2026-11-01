extends Node

func mon_metainfos_by_name(name: String) -> Dictionary:
	return mons.filter(func(mon): return mon.name == name)[0]

## Vorhandene Bildgrößen unter assets/mons/<name>/ (<name>_front.png ist 1024, kleinere heißen <name>_frontx512.png usw.)
const FRONT_SIZES := [128, 256, 512, 1024]
const BACK_SIZES := [512, 1024]

## Typische Platzhaltergrößen, damit die Aufrufer nicht raten müssen
const ICON := 128     # Initiative-Rad, kleine Portraits
const SMALL := 256    # Karten, Ziele, Widgets
const MEDIUM := 512   # Kampffeld, große Panels
const LARGE := 1024

## Bild einer Monster-Art in der kleinsten Auflösung, die `display_size` Pixel noch scharf füllt.
## Zu große Bilder werden beim Verkleinern körnig, zu kleine unscharf.
## back = Rückansicht (eigene Monster im Kampf)
func texture(name: String, display_size: float, back := false) -> Texture2D:
	var sizes = BACK_SIZES if back else FRONT_SIZES
	var size: int = sizes.back()
	for s in sizes:
		if s >= display_size:
			size = s
			break
	var view = "back" if back else "front"
	var suffix = "" if size == LARGE else "x%d" % size
	return load("res://assets/mons/%s/%s_%s%s.png" % [name, name, view, suffix])

var mons = [
	# Böenmähne: gefiederter Sturmschamane mit Weltkugel-Keule
	{
		"name": "1",
		"rarity": Enums.MON_RARITY.COMMON,
		"initial_type": Enums.MON_TYPES.AIR,
		"stats": [450, 500],
		"max_upgrades": 2,
		# Ei-Attacken, die immer von Beginn an zur Wahl stehen
		"default_egg_skills": ["SKILL_BASIC_ATTACK_AIR", "SKILL_BASIC_BLOCK_AIR", "SKILL_GUST"],
		# Ei-Attacken, die wilde Monster dieser Art tragen können und durch Opfern freigeschaltet werden
		"unlockable_egg_skills": ["SKILL_PEBBLE_THROW", "SKILL_WIND_BLADE", "SKILL_THUNDER_STRIKE"],
		# Ei-Attacken, die nur über Meilensteine mit dieser Art als Start-Monster freigeschaltet werden (siehe Skills.MILESTONES)
		"milestone_egg_skills": {"boss_1": "SKILL_TAILWIND_STRIKE", "boss_5": "SKILL_CYCLONE", "game_win": "SKILL_NORTHERN_GALE"},
		# Bounty-Hunter-Ei-Attacken: ein Monster dieser Art muss das Kopfgeld-Monster selbst besiegen (siehe Skills.BOUNTIES)
		"bounty_egg_skills": {"alpha_1": "SKILL_RAPTOR_DIVE", "alpha_2": "SKILL_HUNTERS_GALE", "northern_warden": "SKILL_TROPHY_TEMPEST"},
	},
	# Leuchtkrabbe: Krabbe mit Leuchtturm auf dem Panzer
	{
		"name": "2",
		"rarity": Enums.MON_RARITY.COMMON,
		"initial_type": Enums.MON_TYPES.WATER,
		"stats": [450, 500],
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_WATER", "SKILL_BASIC_BLOCK_WATER", "SKILL_SPLASH"],
		"unlockable_egg_skills": ["SKILL_EMBER", "SKILL_TIDAL_SLAM", "SKILL_MAGMA_BURST"],
		"milestone_egg_skills": {"boss_1": "SKILL_UNDERTOW", "boss_5": "SKILL_MAELSTROM", "game_win": "SKILL_NORTHERN_TIDE"},
		"bounty_egg_skills": {"alpha_1": "SKILL_SHARK_BITE", "alpha_2": "SKILL_HUNTERS_TIDE", "northern_warden": "SKILL_TROPHY_TSUNAMI"},
	},
	# Schattflaum: Federgeist aus violettem Rauch
	{
		"name": "3",
		"rarity": Enums.MON_RARITY.UNCOMMON,
		"initial_type": Enums.MON_TYPES.AIR,
		"stats": [470, 520],
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_AIR", "SKILL_BASIC_BLOCK_AIR", "SKILL_GUST"],
		"unlockable_egg_skills": ["SKILL_WIND_BLADE", "SKILL_ICE_SPEAR", "SKILL_THUNDER_STRIKE"],
		"milestone_egg_skills": {"boss_1": "SKILL_PLUME_FLURRY", "boss_5": "SKILL_PHANTOM_DRAFT", "game_win": "SKILL_SHADOW_SQUALL"},
		"bounty_egg_skills": {"alpha_1": "SKILL_SILENT_SWOOP", "alpha_2": "SKILL_HUNTERS_HAUNT", "northern_warden": "SKILL_TROPHY_PHANTASM"},
	},
	# Hackschupp: Echse mit Beil und Schuppenpanzer
	{
		"name": "4",
		"rarity": Enums.MON_RARITY.COMMON,
		"initial_type": Enums.MON_TYPES.FIRE,
		"stats": [450, 500],
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_FIRE", "SKILL_BASIC_BLOCK_FIRE", "SKILL_EMBER"],
		"unlockable_egg_skills": ["SKILL_FLAME_CLAW", "SKILL_ROCK_CRUSH", "SKILL_MAGMA_BURST"],
		"milestone_egg_skills": {"boss_1": "SKILL_SCORCHING_CHOP", "boss_5": "SKILL_BLAZING_CLEAVE", "game_win": "SKILL_INFERNO_EXECUTION"},
		"bounty_egg_skills": {"alpha_1": "SKILL_HOT_HATCHET", "alpha_2": "SKILL_HUNTERS_BLAZE", "northern_warden": "SKILL_TROPHY_PYRE"},
	},
	# Glotzlibelle: Libelle mit Stielaugen
	{
		"name": "5",
		"rarity": Enums.MON_RARITY.COMMON,
		"initial_type": Enums.MON_TYPES.AIR,
		"stats": [450, 500],
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_AIR", "SKILL_BASIC_BLOCK_AIR", "SKILL_GUST"],
		"unlockable_egg_skills": ["SKILL_PEBBLE_THROW", "SKILL_WIND_BLADE", "SKILL_ROCK_CRUSH"],
		"milestone_egg_skills": {"boss_1": "SKILL_DUST_WHIRR", "boss_5": "SKILL_STARING_GAZE", "game_win": "SKILL_MUDWING_DIVE"},
		"bounty_egg_skills": {"alpha_1": "SKILL_STINGER_DART", "alpha_2": "SKILL_HUNTERS_GAZE", "northern_warden": "SKILL_TROPHY_SWARM"},
	},
	# Borkenhieb: Baumkrieger mit zwei Runenäxten
	{
		"name": "6",
		"rarity": Enums.MON_RARITY.RARE,
		"initial_type": Enums.MON_TYPES.EARTH,
		"stats": [510, 560],
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_EARTH", "SKILL_BASIC_BLOCK_EARTH", "SKILL_PEBBLE_THROW"],
		"unlockable_egg_skills": ["SKILL_ROCK_CRUSH", "SKILL_TIDAL_SLAM", "SKILL_MAGMA_BURST"],
		"milestone_egg_skills": {"boss_1": "SKILL_ROOT_LASH", "boss_5": "SKILL_TWIN_AXE_SWEEP", "game_win": "SKILL_ANCIENT_TIMBER"},
		"bounty_egg_skills": {"alpha_1": "SKILL_SAP_CLEAVER", "alpha_2": "SKILL_HUNTERS_GROVE", "northern_warden": "SKILL_TROPHY_TIMBERFALL"},
	},
	# Hainschwestern: vier Baumfeen unter einer Krone
	{
		"name": "7",
		"rarity": Enums.MON_RARITY.EPIC,
		"initial_type": Enums.MON_TYPES.EARTH,
		"stats": [540, 590],
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_EARTH", "SKILL_BASIC_BLOCK_EARTH", "SKILL_PEBBLE_THROW"],
		"unlockable_egg_skills": ["SKILL_SPLASH", "SKILL_ROCK_CRUSH", "SKILL_CHAOS_NOVA"],
		"milestone_egg_skills": {"boss_1": "SKILL_POLLEN_DRIFT", "boss_5": "SKILL_BLOSSOM_CHORUS", "game_win": "SKILL_FOURFOLD_BLOOM"},
		"bounty_egg_skills": {"alpha_1": "SKILL_THORN_EMBRACE", "alpha_2": "SKILL_HUNTERS_BLOOM", "northern_warden": "SKILL_TROPHY_WILDWOOD"},
	},
	# Glutmolch: Lavamolch mit brennendem Schwanz
	{
		"name": "8",
		"rarity": Enums.MON_RARITY.UNCOMMON,
		"initial_type": Enums.MON_TYPES.FIRE,
		"stats": [470, 520],
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_FIRE", "SKILL_BASIC_BLOCK_FIRE", "SKILL_EMBER"],
		"unlockable_egg_skills": ["SKILL_FLAME_CLAW", "SKILL_THUNDER_STRIKE", "SKILL_MAGMA_BURST"],
		"milestone_egg_skills": {"boss_1": "SKILL_SPARK_SPIT", "boss_5": "SKILL_LAVA_TAIL", "game_win": "SKILL_EMBER_SPIRAL"},
		"bounty_egg_skills": {"alpha_1": "SKILL_CINDER_BITE", "alpha_2": "SKILL_HUNTERS_FLAME", "northern_warden": "SKILL_TROPHY_ERUPTION"},
	},
]

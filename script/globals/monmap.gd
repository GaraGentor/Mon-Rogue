extends Node

func mon_metainfos_by_name(name: String) -> Dictionary:
	return mons.filter(func(mon): return mon.name == name)[0]

## Vorhandene Bildgrößen unter assets/mons/<name>/ (<name>_front.png ist 1024, kleinere heißen <name>_frontx512.png usw.)
const FRONT_SIZES := [64, 128, 256, 512, 1024]
const BACK_SIZES := [256, 512, 1024]

## Typische Platzhaltergrößen, damit die Aufrufer nicht raten müssen
const TINY := 64      # Initiative-Rad, Ziele in den Absichten über den Monstern
const ICON := 128     # kleine Portraits
const SMALL := 256    # Kampffeld, Karten, Ziele, Widgets
const MEDIUM := 512   # große Panels
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
		# Bevorzugte Werteverteilung der Art in Prozent (Summe 100), schwankt pro Run um bis zu ±15 % (siehe growth.gd)
		"preferred_stats": {"hp": 15, "atk": 15, "def": 12, "s_atk": 25, "s_def": 15, "speed": 18},
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
		"preferred_stats": {"hp": 18, "atk": 14, "def": 25, "s_atk": 14, "s_def": 19, "speed": 10},
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
		"preferred_stats": {"hp": 12, "atk": 8, "def": 12, "s_atk": 27, "s_def": 21, "speed": 20},
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
		"preferred_stats": {"hp": 16, "atk": 27, "def": 22, "s_atk": 8, "s_def": 12, "speed": 15},
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
		"preferred_stats": {"hp": 13, "atk": 18, "def": 11, "s_atk": 20, "s_def": 14, "speed": 24},
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
		"preferred_stats": {"hp": 19, "atk": 28, "def": 20, "s_atk": 7, "s_def": 14, "speed": 12},
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
		"preferred_stats": {"hp": 17, "atk": 8, "def": 14, "s_atk": 25, "s_def": 24, "speed": 12},
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
		"preferred_stats": {"hp": 17, "atk": 16, "def": 15, "s_atk": 24, "s_def": 14, "speed": 14},
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_FIRE", "SKILL_BASIC_BLOCK_FIRE", "SKILL_EMBER"],
		"unlockable_egg_skills": ["SKILL_FLAME_CLAW", "SKILL_THUNDER_STRIKE", "SKILL_MAGMA_BURST"],
		"milestone_egg_skills": {"boss_1": "SKILL_SPARK_SPIT", "boss_5": "SKILL_LAVA_TAIL", "game_win": "SKILL_EMBER_SPIRAL"},
		"bounty_egg_skills": {"alpha_1": "SKILL_CINDER_BITE", "alpha_2": "SKILL_HUNTERS_FLAME", "northern_warden": "SKILL_TROPHY_ERUPTION"},
	},
	# Quallolotl: Gallert-Axolotl mit Wasserbauch und Quallententakeln
	{
		"name": "9",
		"rarity": Enums.MON_RARITY.UNCOMMON,
		"initial_type": Enums.MON_TYPES.WATER,
		"stats": [470, 520],
		"preferred_stats": {"hp": 24, "atk": 10, "def": 14, "s_atk": 20, "s_def": 22, "speed": 10},
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_WATER", "SKILL_BASIC_BLOCK_WATER", "SKILL_SPLASH"],
		"unlockable_egg_skills": ["SKILL_TIDAL_SLAM", "SKILL_WIND_BLADE", "SKILL_ICE_SPEAR"],
		"milestone_egg_skills": {"boss_1": "SKILL_BUBBLE_SPRAY", "boss_5": "SKILL_TENTACLE_LASH", "game_win": "SKILL_TIDE_HEART"},
		"bounty_egg_skills": {"alpha_1": "SKILL_JELLY_STING", "alpha_2": "SKILL_HUNTERS_CURRENT", "northern_warden": "SKILL_TROPHY_TORRENT"},
	},
	# Glutkoloss: Lavagolem mit glühendem Kern und Felsfäusten
	{
		"name": "10",
		"rarity": Enums.MON_RARITY.RARE,
		"initial_type": Enums.MON_TYPES.FIRE,
		"stats": [510, 560],
		"preferred_stats": {"hp": 24, "atk": 26, "def": 24, "s_atk": 8, "s_def": 10, "speed": 8},
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_FIRE", "SKILL_BASIC_BLOCK_FIRE", "SKILL_EMBER"],
		"unlockable_egg_skills": ["SKILL_FLAME_CLAW", "SKILL_ROCK_CRUSH", "SKILL_MAGMA_BURST"],
		"milestone_egg_skills": {"boss_1": "SKILL_MAGMA_FIST", "boss_5": "SKILL_SMOLDER_STOMP", "game_win": "SKILL_CORE_BLAST"},
		"bounty_egg_skills": {"alpha_1": "SKILL_BOULDER_PUNCH", "alpha_2": "SKILL_HUNTERS_EMBER", "northern_warden": "SKILL_TROPHY_CALDERA"},
	},
	# Wolkenkauz: Wolkeneule auf einem kleinen Wirbelsturm
	{
		"name": "11",
		"rarity": Enums.MON_RARITY.COMMON,
		"initial_type": Enums.MON_TYPES.AIR,
		"stats": [450, 500],
		"preferred_stats": {"hp": 15, "atk": 10, "def": 12, "s_atk": 24, "s_def": 19, "speed": 20},
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_AIR", "SKILL_BASIC_BLOCK_AIR", "SKILL_GUST"],
		"unlockable_egg_skills": ["SKILL_SPLASH", "SKILL_WIND_BLADE", "SKILL_ICE_SPEAR"],
		"milestone_egg_skills": {"boss_1": "SKILL_FEATHER_PUFF", "boss_5": "SKILL_CLOUD_BURST", "game_win": "SKILL_SKY_TWISTER"},
		"bounty_egg_skills": {"alpha_1": "SKILL_DOWNDRAFT", "alpha_2": "SKILL_HUNTERS_BREEZE", "northern_warden": "SKILL_TROPHY_TYPHOON"},
	},
	# Sturmgreif: Greif mit Blitzschwingen und Wirbelsturmschweifen
	{
		"name": "12",
		"rarity": Enums.MON_RARITY.EPIC,
		"initial_type": Enums.MON_TYPES.AIR,
		"stats": [540, 590],
		"preferred_stats": {"hp": 15, "atk": 22, "def": 12, "s_atk": 22, "s_def": 10, "speed": 19},
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_AIR", "SKILL_BASIC_BLOCK_AIR", "SKILL_GUST"],
		"unlockable_egg_skills": ["SKILL_WIND_BLADE", "SKILL_THUNDER_STRIKE", "SKILL_CHAOS_NOVA"],
		"milestone_egg_skills": {"boss_1": "SKILL_STATIC_TALON", "boss_5": "SKILL_THUNDER_WINGS", "game_win": "SKILL_SKYFALL_STORM"},
		"bounty_egg_skills": {"alpha_1": "SKILL_GRYPH_STRIKE", "alpha_2": "SKILL_HUNTERS_THUNDER", "northern_warden": "SKILL_TROPHY_HURRICANE"},
	},
	# Kristallwühler: Felsbestie mit Bernsteinkristallen auf dem Rücken
	{
		"name": "13",
		"rarity": Enums.MON_RARITY.RARE,
		"initial_type": Enums.MON_TYPES.EARTH,
		"stats": [510, 560],
		"preferred_stats": {"hp": 22, "atk": 22, "def": 27, "s_atk": 6, "s_def": 15, "speed": 8},
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_EARTH", "SKILL_BASIC_BLOCK_EARTH", "SKILL_PEBBLE_THROW"],
		"unlockable_egg_skills": ["SKILL_ROCK_CRUSH", "SKILL_FLAME_CLAW", "SKILL_MAGMA_BURST"],
		"milestone_egg_skills": {"boss_1": "SKILL_SHARD_SWIPE", "boss_5": "SKILL_CRYSTAL_SPIKES", "game_win": "SKILL_GEODE_CRASH"},
		"bounty_egg_skills": {"alpha_1": "SKILL_QUARRY_CLAW", "alpha_2": "SKILL_HUNTERS_BOULDER", "northern_warden": "SKILL_TROPHY_AVALANCHE"},
	},
	# Frostfähe: Eisfüchsin mit kristallenen Schweifen
	{
		"name": "14",
		"rarity": Enums.MON_RARITY.RARE,
		"initial_type": Enums.MON_TYPES.WATER,
		"stats": [510, 560],
		"preferred_stats": {"hp": 14, "atk": 20, "def": 12, "s_atk": 20, "s_def": 14, "speed": 20},
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_WATER", "SKILL_BASIC_BLOCK_WATER", "SKILL_SPLASH"],
		"unlockable_egg_skills": ["SKILL_TIDAL_SLAM", "SKILL_ICE_SPEAR", "SKILL_WIND_BLADE"],
		"milestone_egg_skills": {"boss_1": "SKILL_SNOW_FLURRY", "boss_5": "SKILL_FROST_TAILS", "game_win": "SKILL_GLACIAL_GRACE"},
		"bounty_egg_skills": {"alpha_1": "SKILL_ICICLE_FANG", "alpha_2": "SKILL_HUNTERS_FROST", "northern_warden": "SKILL_TROPHY_BLIZZARD"},
	},
	# Nebelspuk: Nebelgeist mit Dunstschwaden und violetten Augen
	{
		"name": "15",
		"rarity": Enums.MON_RARITY.UNCOMMON,
		"initial_type": Enums.MON_TYPES.WATER,
		"stats": [470, 520],
		"preferred_stats": {"hp": 14, "atk": 6, "def": 14, "s_atk": 26, "s_def": 24, "speed": 16},
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_WATER", "SKILL_BASIC_BLOCK_WATER", "SKILL_SPLASH"],
		"unlockable_egg_skills": ["SKILL_EMBER", "SKILL_WIND_BLADE", "SKILL_ICE_SPEAR"],
		"milestone_egg_skills": {"boss_1": "SKILL_MIST_TOUCH", "boss_5": "SKILL_VAPOR_COIL", "game_win": "SKILL_PHANTOM_FOG"},
		"bounty_egg_skills": {"alpha_1": "SKILL_WISP_GRASP", "alpha_2": "SKILL_HUNTERS_MIST", "northern_warden": "SKILL_TROPHY_DELUGE"},
	},
	# Funkenigel: Igel mit elektrisch geladenen Stacheln
	{
		"name": "16",
		"rarity": Enums.MON_RARITY.COMMON,
		"initial_type": Enums.MON_TYPES.FIRE,
		"stats": [450, 500],
		"preferred_stats": {"hp": 14, "atk": 14, "def": 22, "s_atk": 22, "s_def": 10, "speed": 18},
		"max_upgrades": 2,
		"default_egg_skills": ["SKILL_BASIC_ATTACK_FIRE", "SKILL_BASIC_BLOCK_FIRE", "SKILL_EMBER"],
		"unlockable_egg_skills": ["SKILL_WIND_BLADE", "SKILL_THUNDER_STRIKE", "SKILL_FLAME_CLAW"],
		"milestone_egg_skills": {"boss_1": "SKILL_STATIC_ROLL", "boss_5": "SKILL_VOLT_QUILLS", "game_win": "SKILL_BALL_LIGHTNING"},
		"bounty_egg_skills": {"alpha_1": "SKILL_SHOCK_NIP", "alpha_2": "SKILL_HUNTERS_SPARK", "northern_warden": "SKILL_TROPHY_SURGE"},
	},
]

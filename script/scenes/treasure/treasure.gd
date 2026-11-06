extends ChestRewardDialog

## Schatz: Monster Essenz oder ein Bonus-Preis, einer davon darf genommen werden.
## Der Bonus ist meist ein Edelstein, sonst ein Element-Trank oder selten ein gewöhnliches Relic.
## Edelstein und Trank werden danach einem eigenen Monster gegeben.
## Die Trank-Karte nutzt auch der Shop.

const GemField = preload("res://script/scenes/gems/gems.gd")
const RelicReward = preload("res://script/scenes/relic_reward/relic_reward.gd")

const ACCENT := Color(0.74, 0.75, 0.29)

## Monster Essenz: Grundbetrag plus Zuschlag pro Biom-Tiefe (State.map_level)
const GOLD_MIN := 20
const GOLD_MAX := 50
const GOLD_PER_DEPTH := 10

## Gewichte für den Bonus-Preis
const BONUS_WEIGHTS := {"gem": 60, "potion": 30, "relic": 10}

const ELEMENTS := [Enums.MON_TYPES.EARTH, Enums.MON_TYPES.AIR, Enums.MON_TYPES.WATER, Enums.MON_TYPES.FIRE]

const ESSENCE_ICON = preload("res://assets/ui/icons/monster_essence.svg")
const FLASK_TEXTURE = preload("res://assets/ui/shop/potion_flask.svg")
const LIQUID_TEXTURE = preload("res://assets/ui/shop/potion_liquid.svg")
const PROPS_MATERIAL = preload("res://script/scenes/jailer/jailer_props_material.tres")

var _depth: int

func _ready() -> void:
	use_chest_layout()
	set_accent(ACCENT)
	set_title(tr("TREASURE_CHOOSE"))
	set_drag_hint("TREASURE_HINT")
	show_fixed_targets(State.mons, true)
	show_element_chips()
	_depth = clampi(State.map_level, 0, GemField.BONUS_BY_DEPTH.size() - 1)
	var gold := randi_range(GOLD_MIN, GOLD_MAX) + _depth * GOLD_PER_DEPTH
	add_bag_card(tr("TREASURE_GOLD"), Helper.me_text(gold), texture_icon(ESSENCE_ICON), _on_gold_chosen.bind(gold))
	_add_bonus_card()
	play_chest_intro()

func _on_gold_chosen(gold: int) -> void:
	State.ep += gold

func _add_bonus_card() -> void:
	if State.mons.is_empty():
		return
	match _roll_bonus():
		"relic":
			var commons = Relics.get_unowned(Relics.Rarity.COMMON)
			if not commons.is_empty():
				RelicReward.add_relic_card(self, commons.pick_random())
				return
		"potion":
			# nur Elemente, die noch mindestens einem Monster fehlen
			var elements = ELEMENTS.filter(func(e): return mons_without(e).size() > 0)
			if not elements.is_empty():
				add_potion_card(self, elements.pick_random())
				return
	# Fallback, falls kein passendes Relic oder Element übrig ist
	var stat: String = GemField.STATS.keys().pick_random()
	var bonus: int = GemField.BONUS_BY_DEPTH[_depth]
	GemField.show_gem_info(self)
	GemField.add_gem_card(self, stat, bonus)

func _roll_bonus() -> String:
	var total := 0
	for w in BONUS_WEIGHTS.values():
		total += w
	var roll := randi_range(1, total)
	for kind in BONUS_WEIGHTS:
		roll -= BONUS_WEIGHTS[kind]
		if roll <= 0:
			return kind
	return "gem"

# ── Element-Trank ─────────────────────────

## Trank-Karte: wird auf ein Monster gezogen, dem das Element noch fehlt.
## Die Liste wird erst beim Ziehen bestimmt, damit sie im Shop nach jedem Kauf stimmt.
## Was aus dem Monster wird, zeigt der Typ am Ziel (RewardDialog.show_element_preview).
static func add_potion_card(dialog: RewardDialog, element: int) -> RewardDialog.RewardCard:
	var element_name = dialog.tr(ColorMap.get_combo(element).label)
	var text = dialog.tr("TREASURE_POTION_DESC").format({"element": element_name})
	var potion_title = dialog.tr("TREASURE_POTION").format({"element": element_name})
	var give := func(mon: Monster):
		mon.gain_element(element)
	return dialog.add_mon_card(potion_title, text, potion_art(element), dialog.tr("TREASURE_POTION_CHOOSE_MON"), func(): return mons_without(element), give, Callable(), {"element": element})

static func mons_without(element: int) -> Array:
	return State.mons.filter(func(mon): return not ColorMap.has_element(mon._type, element))

## Flasche im Pixel-Look, die Flüssigkeit hat die Farbe des Elements. Glas und Korken bleiben ungefärbt.
static func potion_art(element: int) -> Control:
	var liquid := texture_icon(LIQUID_TEXTURE)
	liquid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var liquid_material: ShaderMaterial = PROPS_MATERIAL.duplicate()
	liquid_material.set_shader_parameter("tint_color", Helper.color_by_type(element))
	liquid.material = liquid_material
	var flask := texture_icon(FLASK_TEXTURE)
	flask.material = PROPS_MATERIAL
	flask.add_child(liquid)
	return flask

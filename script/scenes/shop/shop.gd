extends Control

const GemField = preload("res://script/scenes/gems/gems.gd")
const ShopOffer = preload("res://script/scenes/shop/shop_offer.gd")

## Preise: grob ein Kampf bringt 10-30 EP, ein Biom also etwa 100-150 EP.
## Elemente bleiben beim alten Preis. Edelsteine starten darunter und steigen mit der Tiefe
## (wie ihr Bonus). Relics sind die teuerste Ware, weil es sie sonst nur als Boss-Belohnung gibt.
const ELEMENT_PRICE := 70
## pro Biom-Tiefe (State.map_level)
const GEM_PRICES := [50, 65, 80, 100, 120]
const RELIC_PRICES := [150, 175, 200, 225, 250]
const GEM_OFFERS := 2
const RELIC_OFFERS := 1

@export var element_pill: PackedScene
var element_pills = [Enums.MON_TYPES.EARTH, Enums.MON_TYPES.AIR, Enums.MON_TYPES.WATER, Enums.MON_TYPES.FIRE]

@export var grid: GridContainer
@export var offer_row: HBoxContainer

@export var money_label: Label
@export var info_label: Label

var gem_icon = preload("res://assets/ui/boss_shard/a_rare_crystal_with_some_spark.jpeg")

var debug = false
var test_money = 40

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if debug:
		test_money = randi_range(70,500)
		State.ep = test_money
	money_label.text = "$ " + str(test_money if debug else State.ep)
	for e in element_pills:
		var e_p = element_pill.instantiate()
		e_p._init_pill(e, ELEMENT_PRICE)
		e_p.set_h_size_flags(SIZE_EXPAND_FILL)
		e_p.set_v_size_flags(SIZE_EXPAND_FILL)
		grid.add_child(e_p)
	_add_gem_offers()
	_add_relic_offers()
	State.ep_changed.connect(_money_changed)

func _exit_tree() -> void:
	State.ep_changed.disconnect(_money_changed)

func _depth() -> int:
	return clampi(State.map_level, 0, GEM_PRICES.size() - 1)

## Edelsteine werden wie Elemente auf ein Monster gezogen (drop_panel.gd)
func _add_gem_offers() -> void:
	var bonus: float = GemField.BONUS_BY_DEPTH[_depth()]
	var cost: int = GEM_PRICES[_depth()]
	var stats = GemField.STATS.keys()
	stats.shuffle()
	for stat in stats.slice(0, GEM_OFFERS):
		var info: Dictionary = GemField.STATS[stat]
		var offer := ShopOffer.new()
		var text = tr("GEM_DESC").format({"stat": tr(info.stat).trim_suffix(":"), "value": roundi(bonus * 100)})
		offer.setup(tr(info.name), text, gem_icon, info.color, cost, false)
		offer.drag_data = {"kind": "gem", "stat": stat, "bonus": bonus, "cost": cost, "on_bought": offer.mark_sold}
		offer_row.add_child(offer)

func _add_relic_offers() -> void:
	var cost: int = RELIC_PRICES[_depth()]
	var unowned = Relics.get_unowned()
	unowned.shuffle()
	for id in unowned.slice(0, RELIC_OFFERS):
		var relic = Relics.get_relic(id)
		var offer := ShopOffer.new()
		offer.setup(tr(relic.name), tr(relic.description), load(relic.icon), Color.WHITE, cost, true)
		offer.buy_pressed.connect(_buy_relic.bind(id, cost, offer))
		offer_row.add_child(offer)

func _buy_relic(id: String, cost: int, offer) -> void:
	if State.ep < cost:
		info_label.text = tr("SHOP_NOT_ENOUGH_MONEY")
		return
	State.ep -= cost
	Relics.add_relic(id)
	offer.mark_sold()
	info_label.text = tr("SHOP_BOUGHT").format({"item": tr(Relics.get_relic(id).name)})

func _money_changed(new_val):
	money_label.text = "$ " + str(State.ep)

func _on_button_pressed() -> void:
	queue_free()

extends ShopDialog

## Shop: aufgebaut wie die Belohnungen. Links liegt die Ware, gezogen auf ein Monster bzw. in die
## Tasche ist sie gekauft. Element-Tränke gibt es beliebig oft, Edelsteine und Relics nur einmal.

const GemField = preload("res://script/scenes/gems/gems.gd")
const RelicReward = preload("res://script/scenes/relic_reward/relic_reward.gd")
const Treasure = preload("res://script/scenes/treasure/treasure.gd")

## Bild oben, darunter Name, Preis und Beschreibung; die Höhe ergibt sich aus dem Text
const SHOP_CARD_SIZE := Vector2(210, 0)
const CARD_COLUMNS := 4

## Preise: grob ein Kampf bringt 10-30 EP, ein Biom also etwa 100-150 EP.
## Elemente sind die günstigste Ware, damit sich ein zweites Element früh lohnt. Edelsteine steigen
## mit der Tiefe (wie ihr Bonus). Relics sind die teuerste Ware, weil es sie sonst nur als Boss-Belohnung gibt.
const ELEMENT_PRICE := 45
## pro Biom-Tiefe (State.map_level)
const GEM_PRICES := [50, 65, 80, 100, 120]
const RELIC_PRICES := [150, 175, 200, 225, 250]
const GEM_OFFERS := 2
const RELIC_OFFERS := 1

## Wellen-Hintergrund aus der Szene
@export var background: Control

func _ready() -> void:
	use_scene_layout(background)
	set_title(tr("SHOP_TITLE"))
	set_drag_hint("SHOP_HINT")
	set_card_layout(CARD_COLUMNS, SHOP_CARD_SIZE, true)
	# Tränke in der ersten Reihe, Edelsteine und Relics zusammen in der zweiten
	for element in Treasure.ELEMENTS:
		set_price(Treasure.add_potion_card(self, element), ELEMENT_PRICE, true)
	new_card_group()
	_add_gem_offers()
	_add_relic_offers()
	add_money_footer("SHOP_FINISH")

func _depth() -> int:
	return clampi(State.map_level, 0, GEM_PRICES.size() - 1)

func _add_gem_offers() -> void:
	var bonus: float = GemField.BONUS_BY_DEPTH[_depth()]
	var stats = GemField.STATS.keys()
	stats.shuffle()
	for stat in stats.slice(0, GEM_OFFERS):
		set_price(GemField.add_gem_card(self, stat, bonus), GEM_PRICES[_depth()])

func _add_relic_offers() -> void:
	var unowned = Relics.get_unowned()
	unowned.shuffle()
	for id in unowned.slice(0, RELIC_OFFERS):
		set_price(RelicReward.add_relic_card(self, id), RELIC_PRICES[_depth()])

## Gekauft, sobald die Ware auf einem Ziel liegt
func _taken(card: RewardCard) -> void:
	pay(card)

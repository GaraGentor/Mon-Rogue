extends RewardDialog

## Shop: aufgebaut wie die Belohnungen. Links liegt die Ware, gezogen auf ein Monster bzw. in die
## Tasche ist sie gekauft. Element-Tränke gibt es beliebig oft, Edelsteine und Relics nur einmal.
## Ist das Geld zu knapp, lässt sich die Ware gar nicht erst ziehen.

const GemField = preload("res://script/scenes/gems/gems.gd")
const RelicReward = preload("res://script/scenes/relic_reward/relic_reward.gd")
const Treasure = preload("res://script/scenes/treasure/treasure.gd")
const BUTTON_THEME = preload("res://script/scenes/battle/flat_button_theme.tres")

## Bild oben, darunter Name, Preis und Beschreibung; die Höhe ergibt sich aus dem Text
const SHOP_CARD_SIZE := Vector2(210, 0)
const CARD_COLUMNS := 4
const TOO_EXPENSIVE_COLOR := Color(0.9, 0.3, 0.3)

## Preise: grob ein Kampf bringt 10-30 EP, ein Biom also etwa 100-150 EP.
## Elemente bleiben beim alten Preis. Edelsteine starten darunter und steigen mit der Tiefe
## (wie ihr Bonus). Relics sind die teuerste Ware, weil es sie sonst nur als Boss-Belohnung gibt.
const ELEMENT_PRICE := 70
## pro Biom-Tiefe (State.map_level)
const GEM_PRICES := [50, 65, 80, 100, 120]
const RELIC_PRICES := [150, 175, 200, 225, 250]
const GEM_OFFERS := 2
const RELIC_OFFERS := 1

## Wellen-Hintergrund aus der Szene
@export var background: Control

var _money_label: Label
## Karte -> Preis-Label, wird rot, wenn das Geld nicht reicht
var _price_labels := {}

func _ready() -> void:
	use_scene_layout(background)
	set_title(tr("SHOP_TITLE"))
	set_drag_hint("SHOP_HINT")
	set_card_layout(CARD_COLUMNS, SHOP_CARD_SIZE, true)
	# Tränke in der ersten Reihe, Edelsteine und Relics zusammen in der zweiten
	for element in Treasure.ELEMENTS:
		_offer(Treasure.add_potion_card(self, element), ELEMENT_PRICE, true)
	new_card_group()
	_add_gem_offers()
	_add_relic_offers()
	_add_footer()
	State.ep_changed.connect(_money_changed)
	_money_changed(State.ep)

func _exit_tree() -> void:
	State.ep_changed.disconnect(_money_changed)

func _depth() -> int:
	return clampi(State.map_level, 0, GEM_PRICES.size() - 1)

func _add_gem_offers() -> void:
	var bonus: float = GemField.BONUS_BY_DEPTH[_depth()]
	var stats = GemField.STATS.keys()
	stats.shuffle()
	for stat in stats.slice(0, GEM_OFFERS):
		_offer(GemField.add_gem_card(self, stat, bonus), GEM_PRICES[_depth()], false)

func _add_relic_offers() -> void:
	var unowned = Relics.get_unowned()
	unowned.shuffle()
	for id in unowned.slice(0, RELIC_OFFERS):
		_offer(RelicReward.add_relic_card(self, id), RELIC_PRICES[_depth()], false)

## Preis an die Karte hängen. repeatable: bleibt nach dem Kauf im Angebot
func _offer(card: RewardCard, price: int, repeatable: bool) -> void:
	card.drag.price = price
	card.drag.repeatable = repeatable
	var label := Label.new()
	label.theme = LABEL_THEME
	label.text = "$ " + str(price)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.insert_detail(label)
	_price_labels[card] = label

## Geld links, Fertig-Button rechts
func _add_footer() -> void:
	var footer := HBoxContainer.new()
	_money_label = Label.new()
	_money_label.theme = LABEL_THEME
	_money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_money_label)
	var finish := Button.new()
	finish.theme = BUTTON_THEME
	finish.add_theme_font_size_override("font_size", 24)
	finish.text = tr("SHOP_FINISH")
	finish.pressed.connect(close)
	footer.add_child(finish)
	add_footer(footer)

func _drag_blocked(card: RewardCard) -> String:
	if State.ep < card.drag.price:
		return tr("SHOP_NOT_ENOUGH_MONEY")
	return ""

## Gekauft: bezahlen, Einzelstücke ausgrauen, der Shop bleibt offen
func _taken(card: RewardCard) -> void:
	if not card.drag.repeatable:
		mark_sold(card)
	State.ep -= card.drag.price
	set_drag_hint(tr("SHOP_BOUGHT").format({"item": card.drag.title}))

func _money_changed(_new_val) -> void:
	_money_label.text = "$ " + str(State.ep)
	for card: RewardCard in _price_labels:
		var too_expensive: bool = not card.sold and State.ep < card.drag.price
		_price_labels[card].modulate = TOO_EXPENSIVE_COLOR if too_expensive else Color.WHITE

class_name ShopDialog
extends RewardDialog

## Grundlage für Shop und Trainer: jede Karte hat einen Preis in ME, dazu Geld und Fertig-Button
## als Fußzeile (Shop) oder Tasche und Button oben (Trainer). Ist das Geld zu knapp, wird der Preis rot und die Ware lässt sich nicht ziehen.
## Ein Rabatt-Gutschein gilt automatisch für den nächsten Kauf, solange einer da ist, stehen alle Preise golden und reduziert da.

const TOO_EXPENSIVE_COLOR := Color(0.9, 0.3, 0.3)
const COUPON_DISCOUNT := 0.25
const ESSENCE_ICON = preload("res://assets/ui/icons/monster_essence.svg")
const EXIT_ICON = preload("res://assets/ui/jailer/icon_exit.svg")

var _money_label: Label
## steht hinter dem Betrag, entfällt neben dem Essenz-Icon
var _money_suffix := " ME"
## Karte -> Preis-Label, wird rot, wenn das Geld nicht reicht
var _price_labels := {}

## Preis unter den Titel der Karte hängen. repeatable: bleibt nach dem Kauf im Angebot
func set_price(card: RewardCard, price: int, repeatable := false) -> void:
	card.drag.price = price
	card.drag.repeatable = repeatable
	var label := Label.new()
	label.theme = LABEL_THEME
	label.add_theme_color_override("font_color", IronPlate.TEXT_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.insert_detail(label)
	_price_labels[card] = label
	_show_price(card)

## Was die Karte gerade kostet, mit Gutschein reduziert
func price_of(card: RewardCard) -> int:
	var price: int = card.drag.price
	return ceili(price * (1.0 - COUPON_DISCOUNT)) if State.coupons > 0 else price

func _show_price(card: RewardCard) -> void:
	var label: Label = _price_labels[card]
	label.text = Helper.me_text(price_of(card))
	label.add_theme_color_override("font_color", SkillDetailPopup.GOLD if State.coupons > 0 else IronPlate.TEXT_COLOR)

## Geld links, Fertig-Button rechts; erst aufrufen, wenn alle Karten einen Preis haben
func add_money_footer(finish_key: String) -> void:
	var footer := HBoxContainer.new()
	_money_label = Label.new()
	_money_label.theme = LABEL_THEME
	_money_label.add_theme_color_override("font_color", IronPlate.TEXT_COLOR)
	_money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_money_label)
	var finish := plate_button(tr(finish_key))
	finish.pressed.connect(close)
	footer.add_child(finish)
	add_footer(footer)
	_watch_money()

func _watch_money() -> void:
	State.ep_changed.connect(_money_changed)
	_money_changed(State.ep)

func _exit_tree() -> void:
	if State.ep_changed.is_connected(_money_changed):
		State.ep_changed.disconnect(_money_changed)

## Bezahlen, Einzelstücke ausgrauen, der Dialog bleibt offen
func pay(card: RewardCard) -> void:
	if not card.drag.repeatable:
		mark_sold(card)
	var price := price_of(card)
	if State.coupons > 0 and price > 0:
		State.coupons -= 1
	State.ep -= price
	set_drag_hint(tr("SHOP_BOUGHT").format({"item": card.drag.title}))

func _drag_blocked(card: RewardCard) -> String:
	if State.ep < price_of(card):
		return tr("SHOP_NOT_ENOUGH_MONEY")
	return ""

func _money_changed(_new_val) -> void:
	_money_label.text = str(State.ep) + _money_suffix
	for card: RewardCard in _price_labels:
		_show_price(card)
		var too_expensive: bool = not card.sold and State.ep < price_of(card)
		_price_labels[card].modulate = TOO_EXPENSIVE_COLOR if too_expensive else Color.WHITE

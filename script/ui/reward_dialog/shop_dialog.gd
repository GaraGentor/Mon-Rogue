class_name ShopDialog
extends RewardDialog

## Grundlage für Shop und Trainer: jede Karte hat einen Preis in EP, unten stehen Geld und
## Fertig-Button. Ist das Geld zu knapp, wird der Preis rot und die Ware lässt sich nicht ziehen.

const BUTTON_THEME = preload("res://script/scenes/battle/flat_button_theme.tres")
const TOO_EXPENSIVE_COLOR := Color(0.9, 0.3, 0.3)

var _money_label: Label
## Karte -> Preis-Label, wird rot, wenn das Geld nicht reicht
var _price_labels := {}

## Preis unter den Titel der Karte hängen. repeatable: bleibt nach dem Kauf im Angebot
func set_price(card: RewardCard, price: int, repeatable := false) -> void:
	card.drag.price = price
	card.drag.repeatable = repeatable
	var label := Label.new()
	label.theme = LABEL_THEME
	label.text = "$ " + str(price)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.insert_detail(label)
	_price_labels[card] = label

## Geld links, Fertig-Button rechts; erst aufrufen, wenn alle Karten einen Preis haben
func add_money_footer(finish_key: String) -> void:
	var footer := HBoxContainer.new()
	_money_label = Label.new()
	_money_label.theme = LABEL_THEME
	_money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_money_label)
	var finish := Button.new()
	finish.theme = BUTTON_THEME
	finish.add_theme_font_size_override("font_size", 24)
	finish.text = tr(finish_key)
	finish.pressed.connect(close)
	footer.add_child(finish)
	add_footer(footer)
	State.ep_changed.connect(_money_changed)
	_money_changed(State.ep)

func _exit_tree() -> void:
	if State.ep_changed.is_connected(_money_changed):
		State.ep_changed.disconnect(_money_changed)

## Bezahlen, Einzelstücke ausgrauen, der Dialog bleibt offen
func pay(card: RewardCard) -> void:
	if not card.drag.repeatable:
		mark_sold(card)
	State.ep -= card.drag.price
	set_drag_hint(tr("SHOP_BOUGHT").format({"item": card.drag.title}))

func _drag_blocked(card: RewardCard) -> String:
	if State.ep < card.drag.price:
		return tr("SHOP_NOT_ENOUGH_MONEY")
	return ""

func _money_changed(_new_val) -> void:
	_money_label.text = "$ " + str(State.ep)
	for card: RewardCard in _price_labels:
		var too_expensive: bool = not card.sold and State.ep < card.drag.price
		_price_labels[card].modulate = TOO_EXPENSIVE_COLOR if too_expensive else Color.WHITE

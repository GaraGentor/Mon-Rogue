extends RewardDialog

## Kerkermeister: in seinen Zellen sitzen bis zu drei Monster-Arten, angekettet. Jede Kette ist eine
## fehlende Verbesserung (+1 Aktion pro Zug). Den Boss-Splitter zieht man zum Kerkermeister, danach
## wählt man die Zelle, deren Kette er sprengt. Ist die letzte Kette weg, geht das Gitter auf und die
## Art ist frei (voll verbessert). Andere Gefangene zeigen kostet EP und zieht neue Arten.

const SHARD_ICON = preload("res://assets/ui/boss_shard/ChatGPT Image 25. Dez. 2025, 21_33_55.png")
const BUTTON_THEME = preload("res://script/scenes/battle/flat_button_theme.tres")
const MON_OFFERS := 3
const REROLL_COST := 25
## Fundorte für die Ansage des Kerkermeisters (JAILER_PLACE_0 ...)
const PLACE_COUNT := 5
## Aktionen pro Zug ohne Verbesserung (Monster._initial_moves)
const BASE_MOVES := 3
const SHARD_CARD_SIZE := Vector2(220, 0)
const JAILER_SIZE := Vector2(130, 160)
const TOP_ROW_HEIGHT := 160
const SPEECH_FONT_SIZE := 20
## Sekunden pro Buchstabe, die Sprechblase schreibt sich wie gesprochen
const SPEECH_CHAR_TIME := 0.012
const GOLD := Color(0.858824, 0.717647, 0.45098)
const TOO_EXPENSIVE_COLOR := Color(0.9, 0.3, 0.3)

## Platzhalter-Figur des Kerkermeisters: Kapuze, leuchtende Augen, Schlüsselring
class JailerFigure extends Control:
	func _init() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var cloak := Color(0.16, 0.13, 0.18)
		draw_colored_polygon(PackedVector2Array([Vector2(w * 0.5, h * 0.15), Vector2(w * 0.88, h), Vector2(w * 0.12, h)]), cloak)
		draw_circle(Vector2(w * 0.5, h * 0.3), w * 0.22, cloak)
		draw_circle(Vector2(w * 0.5, h * 0.32), w * 0.14, Color(0.04, 0.03, 0.05))
		for x in [0.44, 0.56]:
			draw_circle(Vector2(w * x, h * 0.31), w * 0.024, Color(1, 0.75, 0.2))
		draw_rect(Rect2(w * 0.28, h * 0.68, w * 0.44, h * 0.04), Color(0.35, 0.25, 0.2))
		var ring := Vector2(w * 0.62, h * 0.8)
		draw_arc(ring, w * 0.06, 0, TAU, 20, GOLD, 3)
		var tip := ring + Vector2(w * 0.1, h * 0.14)
		draw_line(ring + Vector2(w * 0.04, h * 0.04), tip, GOLD, 4)
		draw_line(tip, tip + Vector2(w * 0.05, -h * 0.01), GOLD, 3)
		draw_line(tip - Vector2(w * 0.02, h * 0.03), tip + Vector2(w * 0.03, -h * 0.04), GOLD, 3)

## Gitterstäbe vor dem Monster; open = 1 heißt ganz hochgezogen, shake rüttelt seitlich
class CellBars extends Control:
	var open := 0.0:
		set(value):
			open = value
			queue_redraw()
	var shake := 0.0:
		set(value):
			shake = value
			queue_redraw()

	func _init() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var top := -size.y * open
		var iron := Color(0.2, 0.2, 0.24)
		var shine := Color(0.5, 0.5, 0.56)
		var count := 6
		for i in count:
			var x := size.x * (i + 0.5) / count + shake
			draw_rect(Rect2(x - 4, top, 8, size.y), iron)
			draw_rect(Rect2(x - 2, top, 2, size.y), shine)
		for y in [0.1, 0.9]:
			draw_rect(Rect2(shake, top + size.y * y - 5, size.x, 10), iron)

## Ein Kettenglied-Paar, gesprengte Ketten sind offen und blass
class ChainLink extends Control:
	var broken := false:
		set(value):
			broken = value
			queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(40, 24)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var color := Color(0.45, 0.4, 0.35, 0.6) if broken else Color(0.78, 0.78, 0.84)
		var gap := 0.7 if broken else 0.0
		# gesprengt: die Glieder sind an der Bruchstelle offen und rücken auseinander
		var apart := 4.0 if broken else 0.0
		var mid := custom_minimum_size.y / 2
		_link(Vector2(size.x * 0.33 - apart, mid), 0.0, gap, color)
		_link(Vector2(size.x * 0.67 + apart, mid), PI, gap, color)

	## Glied mit Lücke um den Winkel start (gap = 0: geschlossen)
	func _link(center: Vector2, start: float, gap: float, color: Color) -> void:
		draw_set_transform(center, 0, Vector2(1.5, 1))
		draw_arc(Vector2.ZERO, custom_minimum_size.y * 0.35, start + gap, start + TAU - gap, 24, color, 2.5)
		draw_set_transform(Vector2.ZERO)

## Zelle einer Monster-Art: Name, Stufe, Ketten, Bild hinter Gittern, Fundort, Preis, Wirkung
class JailCell extends PanelContainer:
	var jailer: Node
	var mon_name: String
	var place: String
	var _level_label: Label
	var _chains: HBoxContainer
	var _picture: TextureRect
	var _bars: CellBars
	var _cost_label: Label
	var _moves_label: Label

	func _init(owner_dialog: Node, species: String, caught_at: String) -> void:
		jailer = owner_dialog
		mon_name = species
		place = caught_at
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		add_child(box)
		_label(box, Helper.mon_display_name(mon_name), true)
		var level_row := HBoxContainer.new()
		level_row.alignment = BoxContainer.ALIGNMENT_CENTER
		level_row.add_theme_constant_override("separation", 10)
		box.add_child(level_row)
		_level_label = _label(level_row, "")
		_level_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_chains = HBoxContainer.new()
		_chains.add_theme_constant_override("separation", 2)
		level_row.add_child(_chains)
		for i in jailer.max_level(mon_name):
			_chains.add_child(ChainLink.new())

		# Bild und Gitter in einem freien Control, damit die Gitter-Animation nicht vom Container überschrieben wird
		var holder := Control.new()
		holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		holder.custom_minimum_size.y = 60
		holder.clip_contents = true
		box.add_child(holder)
		_picture = RewardDialog.mon_icon(mon_name) as TextureRect
		_picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(_picture)
		_bars = CellBars.new()
		_bars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(_bars)

		_label(box, tr("JAILER_CAUGHT").format({"place": place}))
		_cost_label = _label(box, "", true)
		_moves_label = _label(box, "")
		RewardDialog.ignore_mouse_below(self)
		refresh()
		if jailer.is_free(mon_name):
			_bars.open = 1.0

	func _label(parent: Control, text: String, big := false) -> Label:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if big:
			label.theme = RewardDialog.LABEL_THEME
		parent.add_child(label)
		return label

	func refresh() -> void:
		var level: int = jailer.upgrade_level(mon_name)
		_level_label.text = tr("JAILER_LEVEL").format({"level": level, "max": jailer.max_level(mon_name)})
		for i in _chains.get_child_count():
			_chains.get_child(i).broken = i < level
		var moves := BASE_MOVES + level
		if jailer.is_free(mon_name):
			_cost_label.text = tr("JAILER_FREE")
			_cost_label.modulate = GOLD
			_moves_label.text = tr("JAILER_MOVES_MAX").format({"now": moves})
		else:
			_cost_label.text = tr("JAILER_COST").format({"cost": jailer.upgrade_cost(mon_name)})
			_cost_label.modulate = Color.WHITE if jailer.affordable(mon_name) else TOO_EXPENSIVE_COLOR
			_moves_label.text = tr("JAILER_MOVES").format({"now": moves, "next": moves + 1})

	## choosable: nach der Bestechung anklickbar (goldener Rahmen); locked: ausgegraut
	func set_choosable(choosable: bool, locked: bool) -> void:
		var style := RewardDialog.BOX.duplicate() as StyleBoxFlat
		style.set_content_margin_all(12)
		if choosable:
			style.border_color = GOLD
			style.set_border_width_all(4)
		add_theme_stylebox_override("panel", style)
		modulate = RewardDialog.LOCKED_COLOR if locked else Color.WHITE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if choosable else Control.CURSOR_ARROW

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			jailer.cell_clicked(self)

	## Kette springt ab und das Gitter wackelt; bei der letzten Kette geht das Gitter hoch
	func break_chain() -> void:
		var link: Control = _chains.get_child(jailer.upgrade_level(mon_name) - 1)
		link.pivot_offset = link.size / 2
		var tween := create_tween()
		tween.tween_property(link, "scale", Vector2(1.6, 1.6), 0.12)
		tween.tween_callback(refresh)
		tween.tween_property(link, "scale", Vector2.ONE, 0.15)
		var rattle := create_tween()
		for offset in [8.0, -8.0, 5.0, -5.0, 0.0]:
			rattle.tween_property(_bars, "shake", offset, 0.05)
		if not jailer.is_free(mon_name):
			return
		rattle.tween_property(_bars, "open", 1.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		_picture.pivot_offset = _picture.size / 2
		rattle.tween_property(_picture, "scale", Vector2(1.15, 1.15), 0.15)
		rattle.tween_property(_picture, "scale", Vector2.ONE, 0.2)

## Wellen-Hintergrund aus der Szene
@export var background: Control

## Arten im Angebot und wo sie gefangen wurden (Art -> Fundort-Text)
var _offers: Array = []
var _places := {}
var _cells: HBoxContainer
var _jailer: DropTarget
var _speech: Label
var _speech_tween: Tween
var _shard_card: RewardCard
var _shard_count_label: Label
var _reroll_button: Button
var _cancel_button: Button
## Splitter liegt beim Kerkermeister, man wählt gerade die Zelle
var _choosing := false

func _ready() -> void:
	use_scene_layout(background)
	set_title(tr("JAILER_TITLE"))
	set_drag_hint("JAILER_DESC")
	set_card_layout(1, SHARD_CARD_SIZE, true)
	_shard_card = add_bag_card(tr("JAILER_SHARD"), "", texture_icon(SHARD_ICON), _bribe)
	_shard_card.drag.header = tr("JAILER_DRAG_HINT")
	_shard_count_label = _shard_card.info.get_child(1)
	_build_layout()
	_add_footer()
	_roll_offers()
	State.boss_shards_changed.connect(_shards_changed)
	State.ep_changed.connect(_ep_changed)
	_shards_changed(State.boss_shards)
	_ep_changed(State.ep)

func _exit_tree() -> void:
	State.boss_shards_changed.disconnect(_shards_changed)
	State.ep_changed.disconnect(_ep_changed)

## Statt Karten links und Zielen rechts: oben Kerkermeister, Sprechblase und Splitter,
## darunter der Hinweis und die Zellen über den ganzen restlichen Platz
func _build_layout() -> void:
	_columns.visible = false
	var root := VBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 16)
	_content.add_child(root)

	var top := HBoxContainer.new()
	top.custom_minimum_size.y = TOP_ROW_HEIGHT
	top.add_theme_constant_override("separation", 20)
	root.add_child(top)
	_jailer = DropTarget.new()
	_jailer.dialog = self
	_jailer.custom_minimum_size = JAILER_SIZE
	_jailer.add_theme_stylebox_override("panel", BOX)
	var figure := JailerFigure.new()
	_jailer.add_child(figure)
	ignore_mouse_below(_jailer)
	top.add_child(_jailer)

	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bubble_style := BOX.duplicate() as StyleBoxFlat
	bubble_style.set_content_margin_all(20)
	bubble_style.set_corner_radius_all(18)
	bubble.add_theme_stylebox_override("panel", bubble_style)
	top.add_child(bubble)
	_speech = Label.new()
	_speech.add_theme_font_size_override("font_size", SPEECH_FONT_SIZE)
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble.add_child(_speech)

	_shard_card.get_parent().remove_child(_shard_card)
	top.add_child(_shard_card)

	_target_header.get_parent().remove_child(_target_header)
	_target_header.add_theme_font_size_override("font_size", 20)
	root.add_child(_target_header)

	_cells = HBoxContainer.new()
	_cells.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cells.add_theme_constant_override("separation", 20)
	root.add_child(_cells)

## Doch-nicht links (nur beim Wählen), Andere Gefangene und Fertig rechts
func _add_footer() -> void:
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	_cancel_button = _footer_button(footer, tr("JAILER_CANCEL"))
	_cancel_button.pressed.connect(_cancel_choice)
	_cancel_button.visible = false
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	_reroll_button = _footer_button(footer, "")
	_reroll_button.pressed.connect(_reroll)
	_footer_button(footer, tr("JAILER_FINISH")).pressed.connect(close)
	add_footer(footer)

func _footer_button(footer: HBoxContainer, text: String) -> Button:
	var button := Button.new()
	button.theme = BUTTON_THEME
	button.add_theme_font_size_override("font_size", 24)
	button.text = text
	footer.add_child(button)
	return button

static func upgrade_level(mon_name: String) -> int:
	return SaveManager.save_data.monsters.get(mon_name, {}).get("upgrade", 0)

static func max_level(mon_name: String) -> int:
	return Monmap.mon_metainfos_by_name(mon_name).max_upgrades

static func upgrade_cost(mon_name: String) -> int:
	return upgrade_level(mon_name) * 2 + 1

static func is_free(mon_name: String) -> bool:
	return upgrade_level(mon_name) >= max_level(mon_name)

func affordable(mon_name: String) -> bool:
	return State.boss_shards >= upgrade_cost(mon_name)

func _chained(mon_name: String) -> bool:
	return not is_free(mon_name)

## Bis zu MON_OFFERS Arten, die schon verbessert wurden, Start-Monster sind oder gefangen wurden,
## jede an einem anderen Fundort gefangen
func _roll_offers() -> void:
	var pool: Array = SaveManager.save_data.monsters.keys()
	for mon_name in Helper.get_all_owned_monster_names():
		if not pool.has(mon_name):
			pool.append(mon_name)
	pool = pool.filter(_chained)
	pool.shuffle()
	_offers = pool.slice(0, MON_OFFERS)
	var places := range(PLACE_COUNT)
	places.shuffle()
	_places.clear()
	for i in _offers.size():
		_places[_offers[i]] = tr("JAILER_PLACE_%d" % places[i % PLACE_COUNT])
	_build_cells()
	_announce_offers()

func _build_cells() -> void:
	for cell in _cells.get_children():
		_cells.remove_child(cell)
		cell.queue_free()
	for mon_name in _offers:
		_cells.add_child(JailCell.new(self, mon_name, _places[mon_name]))
	_update_cells()

func _update_cells() -> void:
	for cell: JailCell in _cells.get_children():
		var open := _chained(cell.mon_name)
		cell.set_choosable(_choosing and open and affordable(cell.mon_name), _choosing and not (open and affordable(cell.mon_name)))
		if not _choosing:
			cell.refresh()

## "Heute im Angebot: 1 und 2! Gefangen in ... und ..., versteigert zum Preis von 1 und 3 Boss-Splittern."
func _announce_offers() -> void:
	var open := _offers.filter(_chained)
	if open.is_empty():
		_say(tr("JAILER_SAY_EMPTY"))
		return
	var key := "JAILER_SAY_OFFER_ONE" if open.size() == 1 else "JAILER_SAY_OFFER"
	_say(tr(key).format({
		"mons": _join(open.map(Helper.mon_display_name)),
		"places": _join(open.map(func(mon_name): return _places[mon_name])),
		"costs": _join(open.map(func(mon_name): return str(upgrade_cost(mon_name)))),
	}) + "\n" + tr("JAILER_SAY_OFFER_END"))

## "a, b und c"
func _join(parts: Array) -> String:
	if parts.size() <= 1:
		return "".join(parts)
	return tr("JAILER_LIST_AND").format({"rest": ", ".join(parts.slice(0, -1)), "last": parts[-1]})

## Sprechblase schreibt den Text Buchstabe für Buchstabe
func _say(text: String) -> void:
	_speech.text = text
	if _speech_tween:
		_speech_tween.kill()
	_speech.visible_ratio = 0.0
	_speech_tween = create_tween()
	_speech_tween.tween_property(_speech, "visible_ratio", 1.0, text.length() * SPEECH_CHAR_TIME)

## Splitter beim Kerkermeister abgelegt: jetzt die Zelle wählen
func _bribe() -> void:
	_set_choosing(true)
	set_drag_hint("JAILER_CHOOSE_CELL")
	_say(tr("JAILER_SAY_WHO"))

func cell_clicked(cell: JailCell) -> void:
	var mon_name := cell.mon_name
	if not _choosing or not _chained(mon_name) or not affordable(mon_name):
		return
	var cost := upgrade_cost(mon_name)
	State.boss_shards -= cost
	SaveManager.subtract_boss_shard(cost)
	SaveManager.add_mon_upgrade(mon_name)
	Events.mon_upgraded.emit(mon_name)
	_set_choosing(false)
	cell.break_chain()
	var display_name := Helper.mon_display_name(mon_name)
	if is_free(mon_name):
		_say(tr("JAILER_SAY_FREED").format({"mon": display_name}))
		set_drag_hint(tr("JAILER_FREED").format({"mon": display_name}))
	else:
		var moves := BASE_MOVES + upgrade_level(mon_name)
		_say(tr("JAILER_SAY_CHAIN").format({"mon": display_name, "moves": moves}))
		set_drag_hint(tr("JAILER_CHAIN_BROKEN").format({"mon": display_name}))

func _cancel_choice() -> void:
	_set_choosing(false)
	set_drag_hint("JAILER_DESC")
	_say(tr("JAILER_SAY_CANCEL"))

func _set_choosing(choosing: bool) -> void:
	_choosing = choosing
	# der Splitter liegt solange beim Kerkermeister
	_shard_card.modulate.a = 0.4 if choosing else 1.0
	_cancel_button.visible = choosing
	_update_cells()

## Nach dem Ablegen setzt die Basis die Karte zurück, beim Wählen bleibt sie blass
func _hide_targets() -> void:
	super()
	if _choosing:
		_shard_card.modulate.a = 0.4

## Der Dialog bleibt nach einer Befreiung offen
func _taken(_card: RewardCard) -> void:
	pass

## Ziel ist immer der Kerkermeister selbst, keine Monster-Kästchen
func _build_targets(_card: RewardCard) -> void:
	pass

func _drag_blocked(_card: RewardCard) -> String:
	if _choosing:
		return tr("JAILER_CHOOSE_CELL")
	var open = _offers.filter(_chained)
	if open.is_empty():
		_say(tr("JAILER_SAY_EMPTY"))
		return tr("JAILER_ALL_MAXED")
	if not open.any(affordable):
		_say(tr("JAILER_SAY_POOR"))
		return tr("JAILER_NOT_ENOUGH_SHARDS")
	return ""

func _process(delta: float) -> void:
	super(delta)
	var over := _dragged != null and _jailer.get_global_rect().has_point(get_global_mouse_position())
	_jailer.modulate = HOVER_COLOR if over else Color.WHITE

func _reroll() -> void:
	if State.ep < REROLL_COST:
		return
	State.ep -= REROLL_COST
	_set_choosing(false)
	set_drag_hint("JAILER_DESC")
	_roll_offers()

func _shards_changed(shards: int) -> void:
	_shard_count_label.text = tr("JAILER_SHARD_DESC").format({"amount": shards})
	if _cells and not _choosing:
		_update_cells()

func _ep_changed(ep: int) -> void:
	_reroll_button.text = tr("JAILER_REROLL").format({"cost": REROLL_COST, "money": ep})
	_reroll_button.disabled = ep < REROLL_COST

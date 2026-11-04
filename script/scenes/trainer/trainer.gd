extends ShopDialog

## Trainer: verkauft seltene Skills (ab Stufe 2), die Hälfte davon mit mehreren Elementen, damit
## sich der Weg lohnt. Gezogen auf ein Monster ist der Skill gelernt; hat es keinen freien Slot,
## wählt man rechts, welcher Skill dafür vergessen wird. Bezahlt wird erst, wenn wirklich gelernt wurde.
## Auf jeder Karte zeigen kleine Bilder, welche Monster den Skill einsetzen können.

const TRAINER_CARD_SIZE := Vector2(210, 0)
const CARD_COLUMNS := 4
const MIN_TIER := 2
const SINGLE_ELEMENT_OFFERS := 2
const MULTI_ELEMENT_OFFERS := 2
const PORTRAIT_SIZE := Vector2(60, 60)
## Bilder auf der Karte: Monster fehlen Elemente / kennt den Skill schon
const UNUSABLE_MODULATE := Color(0.3, 0.3, 0.3)
const KNOWN_MODULATE := Color(1, 1, 1, 0.25)
const FITS_COLOR := Color(0.45, 1.0, 0.45)
const FITS_NONE_COLOR := Color(1.0, 0.5, 0.5)

## Wellen-Hintergrund aus der Szene
@export var background: Control

## gerade offene Auswahl, welcher Skill vergessen wird (null = keine)
var _picker: SkillReplacePicker

func _ready() -> void:
	use_scene_layout(background)
	set_title(tr("TRAINER_TITLE"))
	set_drag_hint("TRAINER_HINT")
	set_card_layout(CARD_COLUMNS, TRAINER_CARD_SIZE, true)
	for skill in _pick_offers():
		_add_skill_card(skill)
	add_money_footer("SHOP_FINISH")

static func element_count(nature: int) -> int:
	return Enums.MON_TYPES.values().filter(func(element): return nature & element).size()

## Ei-Attacken ab MIN_TIER, je zur Hälfte mit einem und mit mehreren Elementen.
## Nur Skills, die mindestens ein Monster im Team sofort einsetzen kann und noch nicht kennt;
## fehlen davon welche, wird mit den übrigen passenden Skills aufgefüllt.
## Mit der Biom-Tiefe werden höhere Stufen wahrscheinlicher.
func _pick_offers() -> Array:
	var rare = Skills.egg_skills.filter(func(skill): return skill.tier >= MIN_TIER)
	var usable = rare.filter(func(skill): return State.mons.any(func(mon): return Skills.can_use(mon, skill) and not Skills.knows_skill(mon, skill.name)))
	# passt gar nichts (sollte nicht vorkommen), lieber unpassende Skills als ein leerer Trainer
	if usable.is_empty():
		usable = rare
	var single = usable.filter(func(skill): return element_count(skill.nature) == 1).map(func(skill): return skill.name)
	var multi = usable.filter(func(skill): return element_count(skill.nature) > 1).map(func(skill): return skill.name)
	var names = Skills.pick_weighted_unique(single, SINGLE_ELEMENT_OFFERS, State.map_level)
	names.append_array(Skills.pick_weighted_unique(multi, MULTI_ELEMENT_OFFERS, State.map_level))
	var rest = usable.map(func(skill): return skill.name).filter(func(skill_name): return not names.has(skill_name))
	names.append_array(Skills.pick_weighted_unique(rest, SINGLE_ELEMENT_OFFERS + MULTI_ELEMENT_OFFERS - names.size(), State.map_level))
	return names.map(func(skill_name): return Skills.get_skill(skill_name))

func _add_skill_card(skill: Dictionary) -> void:
	var element_name = tr(ColorMap.get_combo(skill.nature).label)
	var text = tr(skill.description).format({"value": roundi(skill.value)}) + "\n" + tr("TRAINER_ELEMENT").format({"element": element_name})
	var learners := func(): return State.mons.filter(func(mon): return not Skills.knows_skill(mon, skill.name))
	var card := add_mon_card(tr(skill.name), text, _portraits(skill), tr("TRAINER_CHOOSE_MON"), learners,
		func(mon: Monster): _learn(_dragged, mon), _target_tooltip.bind(skill), {"no_target": tr("TRAINER_ALL_KNOW")})
	card.drag.skill = skill
	# Titel in der Farbe des Elements
	card.info.get_child(0).add_theme_color_override("font_color", Helper.color_by_type(skill.nature))
	set_price(card, randi_range(skill.shop_cost.min, skill.shop_cost.max))
	card.info.add_child(_fits_label(skill))
	ignore_mouse_below(card)

## Bilder der eigenen Monster: hell = kann den Skill einsetzen, dunkel = Elemente fehlen,
## durchscheinend = kennt ihn schon
func _portraits(skill: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for mon: Monster in State.mons:
		var portrait := mon_icon(mon)
		portrait.custom_minimum_size = PORTRAIT_SIZE
		if Skills.knows_skill(mon, skill.name):
			portrait.modulate = KNOWN_MODULATE
		elif not Skills.can_use(mon, skill):
			portrait.modulate = UNUSABLE_MODULATE
		row.add_child(portrait)
	return row

## "Passt zu: ..." mit den Monstern, die den Skill lernen und sofort einsetzen können
func _fits_label(skill: Dictionary) -> Label:
	var fits = State.mons.filter(func(mon): return Skills.can_use(mon, skill) and not Skills.knows_skill(mon, skill.name))
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if fits.is_empty():
		label.text = tr("TRAINER_FITS_NONE")
		label.modulate = FITS_NONE_COLOR
	else:
		var names = fits.map(func(mon): return Helper.mon_display_name(mon._name))
		label.text = tr("TRAINER_FITS").format({"mons": ", ".join(PackedStringArray(names))})
		label.modulate = FITS_COLOR
	return label

## Beim Drüberziehen: kann es den Skill einsetzen, und muss es dafür einen vergessen?
func _target_tooltip(mon: Monster, skill: Dictionary) -> String:
	var text = tr("TRAINER_CAN_USE") if Skills.can_use(mon, skill) else Skills.missing_elements_text(mon, skill)
	if mon._skills.size() >= Skills.MAX_SKILLS:
		text += "\n" + tr("TRAINER_REPLACES")
	return text

func _learn(card: RewardCard, mon: Monster) -> void:
	var learned := Skills.learnable_copy(card.drag.skill)
	if mon._skills.size() < Skills.MAX_SKILLS:
		mon._skills.append(learned)
		pay(card)
		return
	_picker = SkillReplacePicker.new(mon)
	add_side_content(_picker)
	set_drag_hint(card.drag.title)
	var index: int = await _picker.picked
	_picker = null
	if index == -1:
		set_drag_hint("TRAINER_HINT")
		return
	mon._skills[index] = learned
	pay(card)

## Bezahlt wird in _learn, erst wenn der Skill wirklich gelernt ist
func _taken(_card: RewardCard) -> void:
	pass

func _drag_blocked(card: RewardCard) -> String:
	if _picker:
		return tr("TRAINER_FINISH_CHOICE")
	return super(card)

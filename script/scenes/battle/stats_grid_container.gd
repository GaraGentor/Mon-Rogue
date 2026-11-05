extends GridContainer

@export var label: Label
@export var is_leveling: bool = false
## Alle Werte in einer Zeile: Name in Gold, direkt dahinter die Zahl
@export var horizontal: bool = false

const GAIN_COLOR := Color(0.45, 0.85, 0.45)

var plabels: Array[Label] = []

var map = [
	{
		"key": "hp",
		"label": "STAT_HP",
		"value": func(monster:Monster): return monster.hp(),
	},
	{
		"key": "atk",
		"label": "STAT_ATK",
		"value": func(monster:Monster): return monster.attack(),
	},
	{
		"key": "def",
		"label": "STAT_DEF",
		"value": func(monster:Monster): return monster.defense(),
	},
	{
		"key": "s_atk",
		"label": "STAT_SPA",
		"value": func(monster:Monster): return monster.s_attack(),
	},
	{
		"key": "s_def",
		"label": "STAT_SPD",
		"value": func(monster:Monster): return monster.s_defense(),
	},
	{
		"key": "speed",
		"label": "STAT_SPE",
		"value": func(monster:Monster): return monster.speed(),
	},
	{
		"key": "bst",
		"label": "STAT_BST",
		"value": func(monster:Monster): return monster._best_points,
	}
]

func clear():
	var children = get_children()
	for child in children:
		if child and child.visible:
			remove_child(child)
			child.queue_free()

## hidden: Keys der Werte, die als "?" angezeigt werden (noch nicht aufgedeckte Werte von Gegnern)
func init_with_mon(monster, hidden: Array = []) -> void:
	if (is_leveling):
		columns = 3
		plabels = []
	clear()
	if horizontal:
		_init_horizontal(monster, hidden)
		return
	for i in range(map.size()):
		var obj = map[i]
		var tlabel = label.duplicate()
		tlabel.text = tr(obj.label)
		tlabel.add_theme_color_override("font_color", SkillDetailPopup.GOLD)
		var vlabel = label.duplicate()
		vlabel.text = _value_text(obj, monster, hidden)
		vlabel.add_theme_color_override("font_color", IronPlate.TEXT_COLOR)

		tlabel.visible = true
		vlabel.visible = true
		add_child(tlabel)
		add_child(vlabel)

		if is_leveling:
			var plabel = label.duplicate()
			plabel.visible = true
			plabel.text = ""
			plabel.add_theme_color_override("font_color", GAIN_COLOR)
			plabels.append(plabel)
			add_child(plabel)

func _value_text(obj: Dictionary, monster, hidden: Array) -> String:
	return "?" if hidden.has(obj.key) else str(int(obj.value.call(monster)))

func _init_horizontal(monster, hidden: Array = []) -> void:
	columns = map.size() * 2
	for obj in map:
		var tlabel = _horizontal_label(tr(obj.label).trim_suffix(":"), SkillDetailPopup.GOLD)
		tlabel.size_flags_horizontal = Control.SIZE_FILL
		add_child(tlabel)
		add_child(_horizontal_label(_value_text(obj, monster, hidden), IronPlate.TEXT_COLOR))

func _horizontal_label(text: String, color: Color) -> Label:
	var new_label = label.duplicate()
	new_label.text = text
	new_label.add_theme_color_override("font_color", color)
	new_label.visible = true
	return new_label

func show_p_labels(texts: Array[String] = ["+1","+1","+1","+1","+1","+1","+1"]) -> void:
	for plabel in plabels:
		var index = plabels.find(plabel)
		plabel.text = texts[index]
		plabel.visible = true

func hide_p_labels() -> void:
	for plabel in plabels:
		plabel.text = ""

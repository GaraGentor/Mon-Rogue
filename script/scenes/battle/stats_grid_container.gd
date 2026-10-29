extends GridContainer
 
@export var label: Label
@export var is_leveling: bool = false
## Werte nebeneinander: oben eine Zeile mit Namen, darunter die Zahlen
@export var horizontal: bool = false

var plabels: Array[Label] = []

var map = [
	{
		"label": "STAT_HP",
		"value": func(monster:Monster): return monster.hp(),
	},
	{
		"label": "STAT_ATK",
		"value": func(monster:Monster): return monster.attack(),
	},
	{
		"label": "STAT_DEF",
		"value": func(monster:Monster): return monster.defense(),
	},
	{
		"label": "STAT_SPA",
		"value": func(monster:Monster): return monster.s_attack(),
	},
	{
		"label": "STAT_SPD",
		"value": func(monster:Monster): return monster.s_defense(),
	},
	{
		"label": "STAT_SPE",
		"value": func(monster:Monster): return monster.speed(),
	},
	{
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

# Called when the node enters the scene tree for the first time.
## hidden: Werte als "?" anzeigen (Gegner, deren Art in diesem Run noch nicht besiegt wurde)
func init_with_mon(monster, hidden: bool = false) -> void:
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
		var vlabel = label.duplicate()
		vlabel.text = _value_text(obj, monster, hidden)

		tlabel.visible = true
		vlabel.visible = true
		add_child(tlabel)
		add_child(vlabel)
		
		if is_leveling:
			var plabel = label.duplicate()
			plabel.visible = true
			plabel.text = ""
			plabels.append(plabel)
			add_child(plabel)

func _value_text(obj: Dictionary, monster, hidden: bool) -> String:
	return "?" if hidden else str(int(obj.value.call(monster)))

func _init_horizontal(monster, hidden: bool = false) -> void:
	columns = map.size()
	for obj in map:
		var tlabel = label.duplicate()
		tlabel.text = tr(obj.label).trim_suffix(":")
		tlabel.visible = true
		add_child(tlabel)
	for obj in map:
		var vlabel = label.duplicate()
		vlabel.text = _value_text(obj, monster, hidden)
		vlabel.visible = true
		add_child(vlabel)

func show_p_labels(texts: Array[String] = ["+1","+1","+1","+1","+1","+1","+1"]) -> void:
	for plabel in plabels:
		var index = plabels.find(plabel)
		plabel.text = texts[index]
		plabel.visible = true

func hide_p_labels() -> void:
	for plabel in plabels:
		plabel.text = ""

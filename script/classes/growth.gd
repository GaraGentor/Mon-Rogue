class_name Growth
extends RefCounted

var hp: float
var atk: float
var def: float
var s_atk: float
var s_def: float
var speed: float

func _init() -> void:
	var min_v := 0.05
	var attrs := ["hp", "atk", "def", "s_atk", "s_def", "speed"]
	
	# Schritt 1: Mindestwerte setzen
	for a in attrs:
		self[a] = min_v
	
	# Schritt 2: Rest berechnen
	var rest := 1.0 - min_v * attrs.size()
	
	# Schritt 3: Zufällige Gewichte erzeugen
	var weights := []
	var sum_w := 0.0
	for a in attrs:
		var w := randf()   # gleichverteilte Zufallszahl 0..1
		weights.append(w)
		sum_w += w
	
	# Schritt 4: Rest proportional verteilen
	for i in range(attrs.size()):
		var adden = rest * (weights[i] / sum_w)
		self[attrs[i]] += adden
	
	print("hp:", hp, " atk:", atk, " def:", def, " s_atk:", s_atk, " s_def:", s_def, " speed:", speed)
	print("sum =", hp + atk + def + s_atk + s_def + speed)

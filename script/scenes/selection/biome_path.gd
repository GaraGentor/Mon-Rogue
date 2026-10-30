extends Control

# Zeigt den Biom-Pfad des Runs von links nach rechts an (Platzhalter mit Namen, bis Assets existieren).

@export var font: Font
@export var node_height := 56.0
@export var connector_width := 36.0
@export var reveal_time := 0.25

var _hbox: HBoxContainer
var _panels: Array[Control] = []
var _lines: Array[ColorRect] = []
var _traveler: Panel
var _traveler_tween: Tween

func show_path(biomes: Array) -> void:
	_build(biomes)
	await get_tree().process_frame
	_animate_reveal()

func _build(biomes: Array) -> void:
	for child in get_children():
		child.queue_free()
	_panels.clear()
	_lines.clear()

	# Lichtpunkt, der den Pfad entlangwandert (liegt hinter den Biom-Feldern)
	_traveler = Panel.new()
	_traveler.size = Vector2(12, 12)
	_traveler.pivot_offset = _traveler.size / 2
	_traveler.modulate.a = 0
	var dot_style = StyleBoxFlat.new()
	dot_style.bg_color = Color(0.858824, 0.717647, 0.45098, 1)
	dot_style.set_corner_radius_all(6)
	dot_style.shadow_color = Color(0.858824, 0.717647, 0.45098, 0.5)
	dot_style.shadow_size = 6
	_traveler.add_theme_stylebox_override("panel", dot_style)
	add_child(_traveler)

	_hbox = HBoxContainer.new()
	_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.add_theme_constant_override("separation", 0)
	add_child(_hbox)

	for i in biomes.size():
		if i > 0:
			_hbox.add_child(_create_connector(ColorMap.get_combo(biomes[i - 1])["color"]))
		_hbox.add_child(_create_biome(i, biomes[i]))

func _create_connector(color: String) -> Control:
	var holder = Control.new()
	holder.custom_minimum_size = Vector2(connector_width, node_height)
	var line = ColorRect.new()
	line.color = Color(color)
	line.anchor_top = 0.5
	line.anchor_bottom = 0.5
	line.anchor_right = 1.0
	line.offset_top = -2
	line.offset_bottom = 2
	line.scale.x = 0
	holder.add_child(line)
	_lines.append(line)
	return holder

func _create_biome(depth_index: int, mask: int) -> Control:
	var combo = ColorMap.get_combo(mask)
	var color = Color(combo["color"])

	# Container setzen scale zurück, daher wird ein inneres Panel animiert
	var holder = Control.new()
	holder.custom_minimum_size = Vector2(0, node_height)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.modulate.a = 0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0627451, 0.0862745, 0.0823529, 0.85)
	style.border_color = color
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(color, 0.3)
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)
	holder.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	var depth_label = _create_label(tr("BIOME_DEPTH").format({"depth": depth_index + 1}), 12, Color(1, 1, 1, 0.6))
	vbox.add_child(depth_label)
	var name_label = _create_label(tr(combo["label"]), 18, color.lightened(0.25))
	vbox.add_child(name_label)

	_panels.append(panel)
	return holder

func _create_label(text: String, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if font:
		label.add_theme_font_override("font", font)
	return label

func _animate_reveal() -> void:
	var tween = create_tween()
	for i in _panels.size():
		var panel = _panels[i]
		panel.pivot_offset = panel.size / 2
		panel.scale = Vector2(0.6, 0.6)
		tween.tween_property(panel, "modulate:a", 1.0, reveal_time)
		tween.parallel().tween_property(panel, "scale", Vector2.ONE, reveal_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if i < _lines.size():
			tween.tween_property(_lines[i], "scale:x", 1.0, reveal_time * 0.8)
	tween.tween_callback(_start_traveler)

func _start_traveler() -> void:
	if _panels.size() < 2:
		return
	if _traveler_tween:
		_traveler_tween.kill()
	_traveler_tween = create_tween().set_loops()
	_traveler_tween.tween_property(_traveler, "modulate:a", 1.0, 0.2)
	_traveler_tween.parallel().tween_method(_move_traveler, 0.0, 1.0, 0.4 * _panels.size())
	_traveler_tween.tween_property(_traveler, "modulate:a", 0.0, 0.2)
	_traveler_tween.tween_interval(0.6)

func _move_traveler(t: float) -> void:
	var start = _panel_center(_panels.front())
	var end = _panel_center(_panels.back())
	_traveler.position = start.lerp(end, t) - _traveler.size / 2

func _panel_center(panel: Control) -> Vector2:
	return panel.get_parent().position + panel.get_parent().size / 2

extends Panel

const STARTER_ICON = preload("res://assets/ui/eggs/common_1.png")
const GOLD := Color(0.858824, 0.717647, 0.45098, 1)
# Anzeigenamen der Meilenstein-Zähler (siehe Skills.MILESTONES)
const MILESTONE_STAT_LABELS = {
	"biome_boss_kills": "MILESTONE_STAT_BIOME_BOSS_KILLS",
	"game_wins": "MILESTONE_STAT_GAME_WINS",
}

@export var mw1: Control
@export var mw2: Control

@export var exit_panel: Panel

@export var jugment: Control

@export var release_button_1: Button
@export var release_button_2: Button
# Platz unter den Buttons für die Warnung beim Start-Monster
@export var warning_panel: Panel

var _warning_label: Label
# Index des Start-Monsters, dessen Freilassen schon einmal gewarnt wurde (zweiter Klick bestätigt), sonst -1
var _confirm_index := -1

func _ready() -> void:
	_warning_label = Label.new()
	_warning_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_warning_label.offset_left = 24
	_warning_label.offset_right = -24
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warning_label.add_theme_color_override("font_color", GOLD)
	_warning_label.visible = false
	warning_panel.add_child(_warning_label)

func _start(index: int) -> bool:
	exit_panel.monster_rect.texture = Monmap.mon_metainfos_by_name(State.mons[index]._name).texture_back
	mw1.visible = false
	mw2.visible = false
	exit_panel.visible = true
	await exit_panel._start_animation()
	return true


func _on_visibility_changed() -> void:
	_reset_warning()
	if visible:
		mw1.monster = State.mons[0]
		mw2.monster = State.mons[1]
		# Start-Monster schon vor dem Klick kenntlich machen
		for i in 2:
			var button = _release_button(i)
			button.icon = STARTER_ICON if State.mons[i] == State.starter else null
			button.expand_icon = false
			button.add_theme_constant_override("icon_max_width", 28)
	else:
		mw1.visible = true
		mw2.visible = true
		exit_panel.visible = false
		exit_panel.reset_animation()

func _on_first_mon_pressed() -> void:
	_release(0)

func _on_second_mon_pressed() -> void:
	_release(1)

func _release(index: int) -> void:
	# Beim Start-Monster mit offenen Meilensteinen erst warnen, der zweite Klick lässt es frei
	if _confirm_index != index and _starter_has_open_milestones(index):
		_show_warning(index)
		return
	_reset_warning()
	await _start(index)
	State.mons.remove_at(index)
	visible = false
	jugment._start()
	jugment._on_recruit_button_pressed()

func _release_button(index: int) -> Button:
	return release_button_1 if index == 0 else release_button_2

func _starter_has_open_milestones(index: int) -> bool:
	return State.mons[index] == State.starter and not Skills.get_locked_milestones(State.starter_name).is_empty()

func _show_warning(index: int) -> void:
	_reset_warning()
	_confirm_index = index
	_release_button(index).text = tr("JUDGEMENT_RELEASE_CONFIRM")
	var lines = [tr("JUDGEMENT_STARTER_WARNING").format({"mon": Helper.mon_display_name(State.starter_name)})]
	for milestone in Skills.get_locked_milestones(State.starter_name):
		lines.append(tr("JUDGEMENT_STARTER_MILESTONE_LINE").format({
			"skill": tr(milestone.skill),
			"stat": tr(MILESTONE_STAT_LABELS.get(milestone.stat, milestone.stat)),
			"progress": SaveManager.get_milestone_progress(State.starter_name, milestone.stat),
			"count": milestone.count,
		}))
	_warning_label.text = "\n".join(PackedStringArray(lines))
	_warning_label.visible = true

func _reset_warning() -> void:
	_confirm_index = -1
	release_button_1.text = "JUDGEMENT_RELEASE_1"
	release_button_2.text = "JUDGEMENT_RELEASE_2"
	if _warning_label:
		_warning_label.visible = false

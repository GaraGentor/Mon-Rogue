extends RewardDialog

## Relic-Auswahl nach einem Boss-Sieg (Boss-Feld oder Biom-Boss): bis zu RELIC_CHOICES
## noch nicht gesammelte Relics, eins davon darf genommen werden.

const RELIC_CHOICES := 3
const ACCENT := Color(0.55, 0.32, 0.75)

func _ready() -> void:
	State.pending_relic_reward = false
	set_accent(ACCENT)
	set_title(tr("RELIC_REWARD_CHOOSE"))
	var offered = Relics.get_unowned()
	offered.shuffle()
	for id in offered.slice(0, RELIC_CHOICES):
		add_relic_card(self, id)

## Relic-Karte, auch vom Schatz genutzt: Nehmen schließt den Dialog
static func add_relic_card(dialog: RewardDialog, id: String) -> void:
	var relic = Relics.get_relic(id)
	var take := func():
		Relics.add_relic(id)
		dialog.close()
	dialog.add_card(dialog.tr(relic.name), dialog.tr(relic.description), texture_icon(load(relic.icon)), dialog.tr("RELIC_REWARD_TAKE"), take)

# data/quests/quest_db.gd
const AlleyBackrooms3f = preload("res://data/quests/alley_backrooms_3f.gd")

const QUESTS := {
	"alley_backrooms_3f": AlleyBackrooms3f
}

static func get_quest_data(quest_id: String):
	return QUESTS.get(quest_id, null)

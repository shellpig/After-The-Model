# data/quests/quest_db.gd
const AlleyBackrooms3f = preload("res://data/quests/alley_backrooms_3f.gd")
const RepairVendorBot = preload("res://data/quests/repair_vendor_bot.gd")

const QUESTS := {
	"alley_backrooms_3f": AlleyBackrooms3f,
	"repair_vendor_bot": RepairVendorBot
}

static func get_quest_data(quest_id: String):
	return QUESTS.get(quest_id, null)

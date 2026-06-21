# Dialogue Database
# File: res://data/dialogue/dialogue_db.gd
class_name DialogueDB


const WanDialogue = preload("res://data/dialogue/wan.gd")
const StoreRobotDialogue = preload("res://data/dialogue/store_robot.gd")
const StoreRegistryHostDialogue = preload("res://data/dialogue/store_registry_host.gd")
const TravelStreetEastDialogue = preload("res://data/dialogue/travel_street_east.gd")
const TravelStreetWestDialogue = preload("res://data/dialogue/travel_street_west.gd")
const LuQichenDialogue = preload("res://data/dialogue/lu_qichen.gd")
const CenDialogue = preload("res://data/dialogue/cen.gd")

const TREES := {
	"wan": WanDialogue.TREE,
	"store_robot": StoreRobotDialogue.TREE,
	"store_registry_host": StoreRegistryHostDialogue.TREE,
	"travel_street_east": TravelStreetEastDialogue.TREE,
	"travel_street_west": TravelStreetWestDialogue.TREE,
	"lu_qichen": LuQichenDialogue.TREE,
	"cen": CenDialogue.TREE
}

static func get_tree_for(dialogue_id: String) -> Dictionary:
	return TREES.get(dialogue_id, {})

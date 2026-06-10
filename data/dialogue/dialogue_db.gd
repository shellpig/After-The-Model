# Dialogue Database
# File: res://data/dialogue/dialogue_db.gd
class_name DialogueDB


const WanDialogue = preload("res://data/dialogue/wan.gd")
const StoreRobotDialogue = preload("res://data/dialogue/store_robot.gd")
const StoreRegistryHostDialogue = preload("res://data/dialogue/store_registry_host.gd")

const TREES := {
	"wan": WanDialogue.TREE,
	"store_robot": StoreRobotDialogue.TREE,
	"store_registry_host": StoreRegistryHostDialogue.TREE
}

static func get_tree_for(dialogue_id: String) -> Dictionary:
	return TREES.get(dialogue_id, {})

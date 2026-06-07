# Dialogue Database
# File: res://data/dialogue/dialogue_db.gd

const WanDialogue = preload("res://data/dialogue/wan.gd")

const TREES := {
	"wan": WanDialogue.TREE
}

static func get_tree_for(dialogue_id: String) -> Dictionary:
	return TREES.get(dialogue_id, {})

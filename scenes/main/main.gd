extends Node

const SCENES := {
	"apartment": {
		"path": "res://scenes/levels/apartment/apartment_room.tscn",
		"default_entry_point_id": "wake_bed",
		"entry_points": ["wake_bed", "from_street"],
		"music_id": "apartment_night"
	},
	"street_stub": {
		"path": "res://scenes/levels/street_stub.tscn",
		"default_entry_point_id": "from_apartment",
		"entry_points": ["from_apartment"],
		"music_id": "street_rain"
	}
}

@onready var world_root: Node2D = $WorldRoot

var _current_scene_id: String = ""
var _current_entry_point_id: String = ""

func _ready() -> void:
	# Load default scene on start
	transition_to("apartment", "wake_bed")

func transition_to(scene_id: String, entry_point_id: String = "", payload: Dictionary = {}) -> void:
	if not SCENES.has(scene_id):
		push_error("SceneRouter: Scene ID not found in registry: " + scene_id)
		return
	
	var scene_config: Dictionary = SCENES[scene_id]
	var path: String = scene_config["path"]
	
	var target_entry := entry_point_id
	if target_entry.is_empty():
		target_entry = scene_config["default_entry_point_id"]
		
	# Reset UI mode to NONE before transition to prevent lingering states
	UIMode.set_mode(UIMode.Mode.NONE)
	
	var packed := load(path) as PackedScene
	if not packed:
		push_error("SceneRouter: Failed to load scene path: " + path)
		return
		
	# Clear old children from WorldRoot
	for child in world_root.get_children():
		child.queue_free()
		
	var level := packed.instantiate()
	
	# Prepare entry point before adding to tree (e.g. for monologue condition checks)
	if level.has_method("prepare_entry_point"):
		level.prepare_entry_point(target_entry, payload)
		
	world_root.add_child(level)
	
	# Apply final entry point positioning after node is ready
	if level.has_method("set_entry_point"):
		level.set_entry_point(target_entry, payload)
		
	_current_scene_id = scene_id
	_current_entry_point_id = target_entry

func reload_current_scene(entry_point_id: String = "") -> void:
	var target_entry := entry_point_id
	if target_entry.is_empty():
		target_entry = _current_entry_point_id
	transition_to(_current_scene_id, target_entry)

func get_current_scene_id() -> String:
	return _current_scene_id

func get_current_entry_point_id() -> String:
	return _current_entry_point_id

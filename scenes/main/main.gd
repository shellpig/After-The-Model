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
@onready var game_ui: CanvasLayer = $GameUI

var _current_scene_id: String = ""
var _current_entry_point_id: String = ""

func _ready() -> void:
	# Register GameUI reference to TouchControls Autoload
	TouchControls.set_game_ui(game_ui)
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
		
	# Clear old level context and children from WorldRoot
	game_ui.clear_world_context()
	for child in world_root.get_children():
		if child.has_signal("current_interactable_changed") and child.current_interactable_changed.is_connected(_on_level_current_interactable_changed):
			child.current_interactable_changed.disconnect(_on_level_current_interactable_changed)
		if child.has_signal("interaction_requested") and child.interaction_requested.is_connected(_on_level_interaction_requested):
			child.interaction_requested.disconnect(_on_level_interaction_requested)
		if child.has_signal("scene_transition_requested") and child.scene_transition_requested.is_connected(_on_level_scene_transition_requested):
			child.scene_transition_requested.disconnect(_on_level_scene_transition_requested)
		child.queue_free()
		
	var level := packed.instantiate()
	
	# Set world context on GameUI
	game_ui.set_world_context(level)
	
	# Prepare entry point before adding to tree (e.g. for monologue condition checks)
	if level.has_method("prepare_entry_point"):
		level.prepare_entry_point(target_entry, payload)
		
	world_root.add_child(level)
	
	# Connect level signals for interaction contract
	if level.has_signal("current_interactable_changed"):
		level.current_interactable_changed.connect(_on_level_current_interactable_changed)
	if level.has_signal("interaction_requested"):
		level.interaction_requested.connect(_on_level_interaction_requested)
	if level.has_signal("scene_transition_requested"):
		level.scene_transition_requested.connect(_on_level_scene_transition_requested)
	
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

func _on_level_current_interactable_changed(data: Dictionary) -> void:
	if not data.is_empty():
		game_ui.show_prompt(data)
	else:
		game_ui.hide_prompt()

func _on_level_interaction_requested(data: Dictionary) -> void:
	var type: String = data.get("type", "")
	match type:
		"message":
			var text: String = data.get("message_text", "")
			var on_closed: Callable = data.get("on_closed", Callable())
			var note_title: String = data.get("note_title", "")
			game_ui.show_message(text, on_closed, note_title)
		"container":
			var container_id: String = data.get("container_id", "")
			var container_title: String = data.get("container_title", "")
			var slot_count: int = data.get("container_slot_count", 0)
			game_ui.open_container(container_id, container_title, slot_count)
		"dialogue":
			var dialogue_id: String = data.get("dialogue_id", "")
			game_ui.show_message("對話系統未接入 (dialogue_id: %s)" % dialogue_id)
		"transition":
			var target_scene_id: String = data.get("target_scene_id", "")
			var entry_point_id: String = data.get("entry_point_id", "")
			var payload: Dictionary = data.get("payload", {})
			transition_to(target_scene_id, entry_point_id, payload)

func _on_level_scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary) -> void:
	transition_to(scene_id, entry_point_id, payload)

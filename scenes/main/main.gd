extends Node

const SCENES := {
	"apartment": {
		"path": "res://scenes/levels/apartment/apartment_room.tscn",
		"default_entry_point_id": "wake_bed",
		"entry_points": ["wake_bed", "from_street", "from_fire_escape"],
		"music_id": "apartment_night"
	},
	"apartment_entrance": {
		"path": "res://scenes/levels/apartment_entrance.tscn",
		"default_entry_point_id": "from_apartment",
		"entry_points": ["from_apartment", "from_store", "from_collector_shop"],
		"music_id": "street_rain"
	},
	"convenience_store": {
		"path": "res://scenes/levels/convenience_store/convenience_store.tscn",
		"default_entry_point_id": "from_street",
		"entry_points": ["from_street"],
		"music_id": "store_interior"
	},
	"apartment_fire_escape": {
		"path": "res://scenes/levels/apartment_fire_escape/apartment_fire_escape.tscn",
		"default_entry_point_id": "from_window",
		"entry_points": ["from_window"],
		"music_id": "street_rain"
	},
	"collector_shop": {
		"path": "res://scenes/levels/collector_shop/collector_shop.tscn",
		"default_entry_point_id": "from_street",
		"entry_points": ["from_street"],
		"music_id": "collector_shop"
	}
}

@onready var world_root: Node2D = $WorldRoot
@onready var game_ui: CanvasLayer = $GameUI

var _current_scene_id: String = ""
var _current_entry_point_id: String = ""

# BGM Manager variables
var _bgm_player1: AudioStreamPlayer
var _bgm_player2: AudioStreamPlayer
var _active_player: AudioStreamPlayer = null
var _current_bgm_path: String = ""
var _bgm_tween: Tween = null

func _ready() -> void:
	# Initialize BGM players
	_bgm_player1 = AudioStreamPlayer.new()
	_bgm_player1.name = "BGMPlayer1"
	add_child(_bgm_player1)
	
	_bgm_player2 = AudioStreamPlayer.new()
	_bgm_player2.name = "BGMPlayer2"
	add_child(_bgm_player2)

	# Register GameUI reference to TouchControls Autoload
	TouchControls.set_game_ui(game_ui)
	if game_ui.has_signal("travel_requested"):
		game_ui.travel_requested.connect(_on_travel_requested)
	# Load default scene or pending load slot
	if SaveSystem.pending_load_slot != -1:
		var slot = SaveSystem.pending_load_slot
		SaveSystem.pending_load_slot = -1
		var success = load_game_slot(slot)
		if not success:
			start_new_game()
	else:
		transition_to("apartment", "wake_bed")

func _on_travel_requested(scene_id: String, entry_point_id: String) -> void:
	transition_to(scene_id, entry_point_id, {})

func transition_to(scene_id: String, entry_point_id: String = "", payload: Dictionary = {}, restore: Dictionary = {}) -> void:
	if not SCENES.has(scene_id):
		push_error("SceneRouter: Scene ID not found in registry: " + scene_id)
		return
	
	var restore_data := restore
	var actual_payload := payload
	if payload.has("player_x"):
		restore_data = payload
		actual_payload = {}
	
	var scene_config: Dictionary = SCENES[scene_id]
	var path: String = scene_config["path"]
	
	var target_entry := entry_point_id
	if not restore_data.is_empty():
		target_entry = "restore"
	elif target_entry.is_empty():
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
		level.prepare_entry_point(target_entry, actual_payload)
		
	world_root.add_child(level)
	
	# Connect level signals for interaction contract
	if level.has_signal("current_interactable_changed"):
		level.current_interactable_changed.connect(_on_level_current_interactable_changed)
	if level.has_signal("interaction_requested"):
		level.interaction_requested.connect(_on_level_interaction_requested)
	if level.has_signal("scene_transition_requested"):
		level.scene_transition_requested.connect(_on_level_scene_transition_requested)
	
	# Apply final entry point positioning after node is ready
	if not restore_data.is_empty():
		var player_node = level.find_child("Player", true, false)
		if player_node:
			if player_node.has_method("set_save_x"):
				player_node.set_save_x(restore_data["player_x"])
			else:
				player_node.global_position.x = restore_data["player_x"]
			
			if restore_data.has("player_facing"):
				if player_node.has_method("set_facing"):
					player_node.set_facing(restore_data["player_facing"])
				elif "facing" in player_node:
					player_node.facing = restore_data["player_facing"]
			
			var player_anim = player_node.get_node_or_null("AnimatedSprite2D")
			if player_anim:
				player_anim.play("idle")
	elif level.has_method("set_entry_point"):
		level.set_entry_point(target_entry, actual_payload)
		
	_current_scene_id = scene_id
	_current_entry_point_id = target_entry

func start_new_game() -> void:
	GameState.reset_for_new_game()
	transition_to("apartment", "wake_bed")

func load_game_slot(slot: int) -> bool:
	var payload = SaveSystem.read_slot(slot)
	if payload.is_empty():
		return false
	if not SaveSystem.validate(payload):
		push_error("Main: Save validation failed (invalid shape or version).")
		return false
	
	var data = payload.get("data", {})
	var scene_id = data.get("current_scene_id", "")
	if not SCENES.has(scene_id):
		push_error("Main: Save validation failed (scene ID not in registry: " + scene_id + ").")
		return false
	
	# Apply state and transition
	SaveSystem.apply(payload)
	
	var restore_data = {
		"player_x": data.get("player_x", 0.0),
		"player_facing": data.get("player_facing", 1)
	}
	transition_to(scene_id, "", restore_data)
	return true

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
			game_ui.start_dialogue(dialogue_id)
		"transition":
			var target_scene_id: String = data.get("target_scene_id", "")
			var entry_point_id: String = data.get("entry_point_id", "")
			var payload: Dictionary = data.get("payload", {})
			transition_to(target_scene_id, entry_point_id, payload)
		"shop":
			var shop_id: String = data.get("shop_id", "")
			game_ui.open_shop(shop_id)

func _on_level_scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary) -> void:
	transition_to(scene_id, entry_point_id, payload)

# ==========================================
# Global BGM Manager APIs
# ==========================================
func play_bgm(stream_path: String, fade_duration: float = 2.0) -> void:
	if stream_path.is_empty():
		stop_bgm(fade_duration)
		return

	if _current_bgm_path == stream_path:
		if _active_player and not _active_player.playing:
			_active_player.play()
		return

	var next_player: AudioStreamPlayer = _bgm_player2 if _active_player == _bgm_player1 else _bgm_player1
	var prev_player: AudioStreamPlayer = _active_player

	var stream := load(stream_path) as AudioStream
	if not stream:
		push_error("Main: Failed to load BGM stream: " + stream_path)
		return

	# Enable looping on stream safely
	if "loop" in stream:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true

	next_player.stream = stream
	next_player.volume_db = -80.0 # Start fully silent
	next_player.play()

	_active_player = next_player
	_current_bgm_path = stream_path

	if _bgm_tween:
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.set_parallel(true)
	
	_bgm_tween.tween_property(next_player, "volume_db", -12.0, fade_duration)
	if prev_player:
		_bgm_tween.tween_property(prev_player, "volume_db", -80.0, fade_duration)
		_bgm_tween.chain().tween_callback(prev_player.stop)

func stop_bgm(fade_duration: float = 2.0) -> void:
	_current_bgm_path = ""
	if not _active_player:
		return
	var prev_player = _active_player
	_active_player = null
	if _bgm_tween:
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(prev_player, "volume_db", -80.0, fade_duration)
	_bgm_tween.tween_callback(prev_player.stop)

func get_active_bgm_player() -> AudioStreamPlayer:
	return _active_player

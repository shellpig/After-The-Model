# res://scenes/levels/broadcast/broadcast_station.gd
# Phase 27-A: 地下廣播站正式場景。單室、唯一 entry from_backup_core、單向（無回資料中心出口）、can_save_here=true。
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const CAMERA_HALF_WIDTH := 640.0
const CAMERA_Y := 728.0 # 1088 - 360
const MAP_WIDTH := 3904.0

const BGM_PATH := "res://assets/bgm/The Yellow Light Tape.mp3"

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_backup_core"
var _entry_payload: Dictionary = {}

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "from_backup_core"
	_entry_payload = payload.duplicate(true)

func set_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	prepare_entry_point(entry_point_id, payload)
	var spawn := $SpawnPoints.get_node_or_null(_entry_point_id) as Marker2D
	if spawn != null:
		player.global_position = spawn.global_position
	player.anim.play("idle")
	_update_camera()

func _ready() -> void:
	SaveSystem.can_save_here = true
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.has_method("play_bgm"):
		main.play_bgm(BGM_PATH)

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)
	player.anim.play("idle")
	_refresh_current_interactable()

	# 進場一次性 MessageBox：只在真正走 from_backup_core 轉場時播放；讀檔 entry_point_id 為 "restore"（main.gd transition_to 慣例），天然不觸發、不需去重旗標。
	if _entry_point_id == "from_backup_core":
		call_deferred("_play_arrival_message")

func _play_arrival_message() -> void:
	interaction_requested.emit({
		"type": "message",
		"message_text": GameState.STORY_MESSAGES["broadcast_arrival"]
	})

func _process(_delta: float) -> void:
	_update_camera()

	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	_refresh_current_interactable()

	if DisplayServer.get_name() == "headless":
		if current_interactable != null and Input.is_action_just_pressed("interact_primary"):
			_trigger_interaction()

func _unhandled_input(event: InputEvent) -> void:
	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	_refresh_current_interactable()
	if current_interactable == null:
		return

	if event.is_action_pressed("interact_primary"):
		get_viewport().set_input_as_handled()
		_trigger_interaction()

func _trigger_interaction() -> void:
	if current_interactable.dialogue_id != "":
		interaction_requested.emit({
			"type": "dialogue",
			"dialogue_id": current_interactable.dialogue_id
		})
		return

	match current_interactable.interaction_id:
		"broadcast_flavor_transmitter":
			interaction_requested.emit({
				"type": "message",
				"message_text": GameState.STORY_MESSAGES["broadcast_flavor_transmitter"]
			})
		"broadcast_flavor_old_media":
			interaction_requested.emit({
				"type": "message",
				"message_text": GameState.STORY_MESSAGES["broadcast_flavor_old_media"]
			})
		"broadcast_flavor_predecessor":
			interaction_requested.emit({
				"type": "message",
				"message_text": GameState.STORY_MESSAGES["broadcast_flavor_predecessor"]
			})

func _update_camera() -> void:
	if camera == null:
		return
	camera.global_position = Vector2(
		clamp(player.global_position.x, CAMERA_HALF_WIDTH, MAP_WIDTH - CAMERA_HALF_WIDTH),
		CAMERA_Y
	)

func _on_interactable_entered(interactable: Area2D) -> void:
	if not nearby_interactables.has(interactable):
		nearby_interactables.append(interactable)
	_refresh_current_interactable()

func _on_interactable_exited(interactable: Area2D) -> void:
	nearby_interactables.erase(interactable)
	_refresh_current_interactable()

func _refresh_current_interactable() -> void:
	var closest_interactable := _get_closest_interactable()
	if current_interactable == closest_interactable:
		return

	current_interactable = closest_interactable

	if current_interactable == null:
		current_interactable_changed.emit({})
	else:
		current_interactable_changed.emit({
			"prompt_text": current_interactable.prompt_text
		})

func _get_closest_interactable() -> Area2D:
	var closest_interactable: Area2D = null
	var closest_distance := INF
	var player_position := player.global_position

	for interactable in nearby_interactables:
		if not is_instance_valid(interactable):
			continue

		var distance := player_position.distance_squared_to(_get_interactable_position(interactable))
		if distance < closest_distance:
			closest_distance = distance
			closest_interactable = interactable

	return closest_interactable

func _get_interactable_position(interactable: Area2D) -> Vector2:
	var collision_shape := interactable.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		return collision_shape.global_position

	return interactable.global_position

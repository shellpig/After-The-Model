# res://scenes/levels/nightclub/nightclub.gd
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const CAMERA_HALF_WIDTH := 640.0
const CAMERA_Y := 600.0
const MAP_WIDTH := 4288.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_entrance"
var _entry_payload: Dictionary = {}

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "from_entrance"
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
		main.play_bgm("res://assets/bgm/nightclub-1.mp3")

	if GameState.has_flag("found_staff_pass"):
		var pass_node = $Interactables.get_node_or_null("StaffPassExamine")
		if pass_node != null:
			pass_node.queue_free()

	for interactable in $Interactables.get_children():
		if interactable == null or interactable.is_queued_for_deletion():
			continue
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)
	player.anim.play("idle")
	_refresh_current_interactable()

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
	match current_interactable.interaction_id:
		"exit_to_entrance":
			scene_transition_requested.emit("nightclub_entrance", "from_lobby", {})
		"back_door":
			if GameState.has_flag("passed_nightclub_security"):
				scene_transition_requested.emit("nightclub_back", "from_lobby", {})
			else:
				interaction_requested.emit({
					"type": "message",
					"message_text": GameState.STORY_MESSAGES["nightclub_security_blocked"]
				})
		"staff_pass_examine":
			if GameState.has_flag("found_staff_pass"):
				return
			var added := GameState.add_item("nightclub_staff_pass", 1)
			if not added:
				interaction_requested.emit({
					"type": "message",
					"message_text": GameState.STORY_MESSAGES["nightclub_examine_pass_bag_full"]
				})
				return
			GameState.set_flag("found_staff_pass", true)
			interaction_requested.emit({
				"type": "message",
				"message_text": GameState.STORY_MESSAGES["nightclub_staff_pass_found"]
			})
			_hide_staff_pass_interactable()

func _update_camera() -> void:
	if camera == null or player == null:
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
	if player == null:
		return null
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

func _hide_staff_pass_interactable() -> void:
	var pass_node = $Interactables.get_node_or_null("StaffPassExamine")
	if pass_node != null:
		# Disable interactions and hide the node
		pass_node.process_mode = PROCESS_MODE_DISABLED
		pass_node.visible = false
		nearby_interactables.erase(pass_node)
		_refresh_current_interactable()

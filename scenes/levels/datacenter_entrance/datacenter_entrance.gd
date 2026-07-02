# res://scenes/levels/datacenter_entrance/datacenter_entrance.gd
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const CAMERA_HALF_WIDTH := 640.0
const CAMERA_Y := 408.0
const MAP_WIDTH := 1376.0

const BGM_PATH := "res://assets/bgm/The Cold Mirror (Loop).mp3"

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var ada_npc: Area2D = $Interactables.get_node_or_null("AdaNPC")

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_nightclub"
var _entry_payload: Dictionary = {}
var _ada_faded: bool = false

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "from_nightclub"
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

	_setup_ada()

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)
	player.anim.play("idle")
	_refresh_current_interactable()

# Phase 26-B: 阿達④順序護欄——已看過永久消失；未看過但工單尚未揭露（③早於④）本趟也不登場。
func _setup_ada() -> void:
	if GameState.get_flag("ada_final_words_seen", false):
		_ada_faded = true
	elif GameState.get_flag("read_old_work_order", false):
		return

	if ada_npc != null:
		ada_npc.free()
		ada_npc = null
	var ada_trigger := $Interactables.get_node_or_null("AdaTriggerArea")
	if ada_trigger != null:
		ada_trigger.free()

# Phase 26-B: 對話結束（UIMode 回 NONE 且旗標已設）→ 淡出並永久停用 AdaNPC / 觸發區。
func _update_ada_fade() -> void:
	if _ada_faded or ada_npc == null:
		return
	if not GameState.get_flag("ada_final_words_seen", false):
		return
	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	_ada_faded = true
	var ada_trigger := $Interactables.get_node_or_null("AdaTriggerArea")
	if ada_trigger != null:
		ada_trigger.free()

	var npc_to_fade := ada_npc
	npc_to_fade.dialogue_id = "" # fade 窗口內 E 重談失效，避免對半透明的阿達重播最後一句
	ada_npc = null
	var tween := create_tween()
	tween.tween_property(npc_to_fade, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func():
		if is_instance_valid(npc_to_fade):
			npc_to_fade.queue_free()
	)

func _process(_delta: float) -> void:
	_update_camera()
	_update_ada_fade()

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
		"exit_to_nightclub":
			scene_transition_requested.emit("nightclub_entrance", "from_datacenter", {})
		"main_gate":
			# Phase 25-A: 善後員合法門禁（反諷）。兩條件皆既有，零新旗標 / 零新道具。
			if GameState.has_item("old_work_badge") and GameState.get_flag("read_old_work_order", false):
				scene_transition_requested.emit("datacenter_backup", "from_entrance", {})
			else:
				interaction_requested.emit({
					"type": "message",
					"message_text": GameState.STORY_MESSAGES["datacenter_access_denied"]
				})
		"delivery_bot":
			interaction_requested.emit({
				"type": "message",
				"message_text": GameState.STORY_MESSAGES["datacenter_delivery_bot_flavor"]
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

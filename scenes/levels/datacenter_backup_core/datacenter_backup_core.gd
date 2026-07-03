# res://scenes/levels/datacenter_backup_core/datacenter_backup_core.gd
# Phase 25-A: 核心備份區骨架。Phase 26-D: 結局觸發點武裝——「自己的備份」依 mem_frag_chose_deletion 分派中性/重量級文字並武裝
# stood_before_own_backup（27-B 三結局路由掛點）；新增「檔案索引終端」依 seven_stopped_partial 分派 Branch B 檔案重標記變體。
# Phase 27-B: 「自己的備份」升級四層分派——任一 ending_route_* 已設 -> DECIDED 中性 examine（不可重選）；
# stood_before_own_backup -> start_dialogue("own_backup") 三選路由；其餘沿用 26-D（TRUTH+武裝 / 25-A 中性佔位）。
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const CAMERA_HALF_WIDTH := 640.0
const CAMERA_Y := 536.0 # 896 - 360
const MAP_WIDTH := 4768.0

const BGM_PATH := "res://assets/bgm/The Cold Mirror (Loop).mp3"

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_backup"
var _entry_payload: Dictionary = {}

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "from_backup"
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
		"exit_to_backup":
			scene_transition_requested.emit("datacenter_backup", "from_core", {})
		"own_backup":
			if _has_any_ending_route():
				# Phase 27-B：已決定，鎖點不可重選——中性 examine。
				interaction_requested.emit({
					"type": "message",
					"message_text": GameState.STORY_MESSAGES["datacenter_own_backup_decided"]
				})
			elif GameState.get_flag("stood_before_own_backup", false):
				# Phase 27-B：第一次讀懂自己（26-D TRUTH），再伸手才是決定——開三選路由對話。
				interaction_requested.emit({
					"type": "dialogue",
					"dialogue_id": "own_backup"
				})
			elif GameState.get_flag("mem_frag_chose_deletion", false):
				# Phase 26-D：碎片後換重量級文字（名字露出一次）＋ 武裝 forward 契約（27-B 三結局路由掛點）。
				GameState.set_flag("stood_before_own_backup", true)
				interaction_requested.emit({
					"type": "message",
					"message_text": GameState.STORY_MESSAGES["datacenter_own_backup_truth"]
				})
			else:
				# 碎片前維持 25-A 中性佔位，不 set 旗標。
				interaction_requested.emit({
					"type": "message",
					"message_text": GameState.STORY_MESSAGES["datacenter_own_backup_placeholder"]
				})
		"file_index_terminal":
			# Phase 26-D：Branch B（seven_stopped_partial）具體重標記變體；其餘中性 flavor。可重看、不 set 旗標。
			if GameState.get_flag("seven_stopped_partial", false):
				interaction_requested.emit({
					"type": "message",
					"message_text": GameState.STORY_MESSAGES["datacenter_file_index_remarked"]
				})
			else:
				interaction_requested.emit({
					"type": "message",
					"message_text": GameState.STORY_MESSAGES["datacenter_file_index_neutral"]
				})

func _has_any_ending_route() -> bool:
	# Phase 27-B：互斥旗標，任一成立即代表玩家已鎖點決定。
	return GameState.get_flag("ending_route_reclaim", false) \
		or GameState.get_flag("ending_route_protect", false) \
		or GameState.get_flag("ending_route_expose", false)

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

# res://scenes/levels/apartment_fire_escape/apartment_fire_escape.gd
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const UPPER_WALK_Y := 400.0
const LOWER_WALK_Y := 655.0
const CAMERA_HALF_WIDTH := 640.0
const CAMERA_HALF_HEIGHT := 360.0
const MAP_WIDTH := 1672.0
const MAP_HEIGHT := 941.0

const UPPER_WALK_PLATFORM_PATHS := [
	"Collision/RightBuilding4FPlatform"
]
const LOWER_WALK_PLATFORM_PATHS := [
	"Collision/LeftBuilding3FPlatform",
	"Collision/Bridge3F",
	"Collision/RightBuilding3FPlatform"
]

const MESSAGES := {
	"quest_box_locked": "箱子被雨水泡得發脹，裡面也許有東西，但現在還不是翻它的時候。",
	"quest_box_preview": "窗裡還亮著燈，薄窗簾後偶爾有人影晃過。你得先確認周圍動靜，再一點一點掀開箱蓋。",
	"quest_box_search_quiet": "窗裡還亮著燈，薄窗簾後偶爾有人影晃過。你放慢動作，把箱蓋一點一點掀開，盡量不讓潮濕的鉸鏈叫出聲。",
	"inventory_full_for_activation_box": "背包放不下了。整理一下空間後再試試看。",
	"quest_box_obtained_box": "你在舊雜物堆底下找到了「早期 AI 助理啟用盒」。\n它看起來保存良好，但拿起來時，你感覺到它的底部有股不對勁的第二重重量，且隱約傳來金屬夾扣的喀噠聲。"
}

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_window"
var _entry_payload: Dictionary = {}

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "from_window"
	_entry_payload = payload.duplicate(true)

func set_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	prepare_entry_point(entry_point_id, payload)
	var spawn := $SpawnPoints.get_node_or_null(_entry_point_id) as Marker2D
	if spawn != null:
		player.global_position = spawn.global_position
	_apply_upper_walk_line()
	player.anim.play("idle")
	player.set_facing(-1)
	_update_camera()

func _ready() -> void:
	SaveSystem.can_save_here = false
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.has_method("play_bgm"):
		main.play_bgm("res://assets/bgm/Faded Neon Departure.mp3")

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)
	_refresh_current_interactable()

func _exit_tree() -> void:
	SaveSystem.can_save_here = true

func _process(_delta: float) -> void:
	_update_camera()

	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	_refresh_current_interactable()

	if DisplayServer.get_name() == "headless" and Input.is_action_just_pressed("interact_primary"):
		_handle_primary_interaction()

func _unhandled_input(event: InputEvent) -> void:
	if UIMode.get_mode() != UIMode.Mode.NONE:
		return
	if event.is_action_pressed("interact_primary"):
		get_viewport().set_input_as_handled()
		_handle_primary_interaction()

func _handle_primary_interaction() -> void:
	if player.is_climbing():
		_exit_ladder()
		return

	_refresh_current_interactable()
	if current_interactable == null:
		return
	_trigger_interaction()

func _trigger_interaction() -> void:
	match current_interactable.interaction_id:
		"main_ladder":
			player.enter_climb_mode(_get_ladder_x(), UPPER_WALK_Y, LOWER_WALK_Y)
			current_interactable_changed.emit({"prompt_text": "E: 離開梯子"})
		"window_return":
			scene_transition_requested.emit("apartment", "from_fire_escape", {})
		"quest_box":
			if QuestManager.get_status("alley_backrooms_3f") == "active" \
				and QuestManager.get_step("alley_backrooms_3f") == "checked_alley":
				interaction_requested.emit({
					"type": "message",
					"message_text": MESSAGES["quest_box_search_quiet"],
					"on_closed": func():
						var added := GameState.add_item("early_ai_assistant_activation_box", 1)
						if not added:
							interaction_requested.emit({
								"type": "message",
								"message_text": MESSAGES["inventory_full_for_activation_box"]
							})
							return
						
						QuestManager.advance("alley_backrooms_3f", "found_activation_box", {"found_activation_box": true})
						
						interaction_requested.emit({
							"type": "message",
							"message_text": MESSAGES["quest_box_obtained_box"]
						})
				})
			else:
				interaction_requested.emit({
					"type": "message",
					"message_text": MESSAGES["quest_box_locked"]
				})

func _exit_ladder() -> void:
	var target_y := UPPER_WALK_Y
	if abs(player.global_position.y - LOWER_WALK_Y) < abs(player.global_position.y - UPPER_WALK_Y):
		target_y = LOWER_WALK_Y

	player.exit_climb_mode(target_y)
	if target_y == UPPER_WALK_Y:
		_apply_upper_walk_line()
	else:
		_apply_lower_walk_line()
	_refresh_current_interactable()

func _apply_upper_walk_line() -> void:
	var bounds := _get_platform_x_bounds(UPPER_WALK_PLATFORM_PATHS)
	player.min_x = bounds.x
	player.max_x = bounds.y
	player.walk_line_y = UPPER_WALK_Y
	player.global_position.y = UPPER_WALK_Y

func _apply_lower_walk_line() -> void:
	var bounds := _get_platform_x_bounds(LOWER_WALK_PLATFORM_PATHS)
	player.min_x = bounds.x
	player.max_x = bounds.y
	player.walk_line_y = LOWER_WALK_Y
	player.global_position.y = LOWER_WALK_Y

func _get_platform_x_bounds(platform_paths: Array) -> Vector2:
	var min_x := INF
	var max_x := -INF

	for platform_path in platform_paths:
		var platform := get_node_or_null(platform_path)
		if platform == null:
			continue
		var collision_shape := platform.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision_shape == null:
			continue
		var half_width := _get_collision_half_width(collision_shape)
		min_x = min(min_x, collision_shape.global_position.x - half_width)
		max_x = max(max_x, collision_shape.global_position.x + half_width)

	if min_x == INF or max_x == -INF:
		return Vector2(player.min_x, player.max_x)
	return Vector2(min_x, max_x)

func _get_ladder_x() -> float:
	var ladder_shape := get_node_or_null("Interactables/MainLadderArea/CollisionShape2D") as CollisionShape2D
	if ladder_shape == null:
		return player.global_position.x
	return ladder_shape.global_position.x

func _get_collision_half_width(collision_shape: CollisionShape2D) -> float:
	if collision_shape.shape is RectangleShape2D:
		var rect_shape := collision_shape.shape as RectangleShape2D
		return rect_shape.size.x * abs(collision_shape.global_scale.x) * 0.5
	return 0.0

func _update_camera() -> void:
	if camera == null:
		return
	camera.global_position = Vector2(
		clamp(player.global_position.x, CAMERA_HALF_WIDTH, MAP_WIDTH - CAMERA_HALF_WIDTH),
		clamp(player.global_position.y, CAMERA_HALF_HEIGHT, MAP_HEIGHT - CAMERA_HALF_HEIGHT)
	)

func _on_interactable_entered(interactable: Area2D) -> void:
	if not nearby_interactables.has(interactable):
		nearby_interactables.append(interactable)
	_refresh_current_interactable()

func _on_interactable_exited(interactable: Area2D) -> void:
	nearby_interactables.erase(interactable)
	_refresh_current_interactable()

func _refresh_current_interactable() -> void:
	if player.is_climbing():
		current_interactable = null
		current_interactable_changed.emit({"prompt_text": "E: 離開梯子"})
		return

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
		if interactable.interaction_id == "quest_box" and not _is_quest_box_available():
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

func _is_quest_box_available() -> bool:
	return QuestManager.get_status("alley_backrooms_3f") != "completed" \
		and not QuestManager.get_flag("alley_backrooms_3f", "found_activation_box", false)

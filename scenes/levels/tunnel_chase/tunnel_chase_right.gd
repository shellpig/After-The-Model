# res://scenes/levels/tunnel_chase/tunnel_chase_right.gd
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const UPPER_WALK_Y := 600.0
const LOWER_WALK_Y := 1050.0
const CLIMB_ENGAGE_MARGIN := 8.0
const CLIMB_EXIT_MARGIN := 2.0

const CAMERA_HALF_WIDTH := 640.0
const CAMERA_HALF_HEIGHT := 360.0
const MAP_WIDTH := 3392.0
const MAP_HEIGHT := 1248.0

const COUNTDOWN_RED := Color(1.0, 0.2, 0.2, 1.0)
const LADDER_X := 1800.0

const SHOWDOWN_IMAGE_PATH := "res://assets/generated/sprites/seven_tunnel_showdown/situation/seven-tunnel-showdown-situation-20260628-174900.jpeg"

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_left"
var _entry_payload: Dictionary = {}

var _climb_entry_y: float = 0.0
var _climb_engaged: bool = false
var _showdown_triggered := false

# UI elements (created dynamically)
var _ui_layer: CanvasLayer = null
var _timer_title_label: Label = null
var _progress_label: Label = null

# Showdown overlay elements
var _showdown_layer: CanvasLayer = null
var _showdown_rect: ColorRect = null
var _showdown_texture: TextureRect = null

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "from_left"
	_entry_payload = payload.duplicate(true)

func set_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	prepare_entry_point(entry_point_id, payload)
	var spawn := $SpawnPoints.get_node_or_null(_entry_point_id) as Marker2D
	if spawn != null:
		player.global_position = spawn.global_position
	
	_apply_upper_walk_line()
	player.anim.play("idle")
	_update_camera()

	# If room 1 passed time_up immediately, start showdown
	if _entry_payload.get("time_up", false) or GameState._tunnel_chase_time_left <= 0.0:
		_start_showdown()

func _ready() -> void:
	SaveSystem.can_save_here = false
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.has_method("play_bgm"):
		main.play_bgm("res://assets/bgm/nightclub-chaos.mp3")

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)
	
	_setup_timer_ui()
	_refresh_current_interactable()

func _exit_tree() -> void:
	if _ui_layer != null:
		_ui_layer.queue_free()
	if _showdown_layer != null:
		_showdown_layer.queue_free()

func _setup_timer_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 90
	add_child(_ui_layer)

	_timer_title_label = Label.new()
	_timer_title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_timer_title_label.offset_top = 28.0
	_timer_title_label.offset_bottom = 68.0
	_timer_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_title_label.text = tr("UI_TUNNEL_CALL_TIMER_TITLE")
	_timer_title_label.add_theme_font_size_override("font_size", 30)
	_timer_title_label.add_theme_color_override("font_color", COUNTDOWN_RED)
	_timer_title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_timer_title_label.add_theme_constant_override("outline_size", 8)
	_ui_layer.add_child(_timer_title_label)

	_progress_label = Label.new()
	_progress_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_progress_label.offset_top = 64.0
	_progress_label.offset_bottom = 174.0
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 60)
	_progress_label.add_theme_color_override("font_color", COUNTDOWN_RED)
	_progress_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_progress_label.add_theme_constant_override("outline_size", 10)
	_ui_layer.add_child(_progress_label)
	
	_update_ui_labels()

func _update_ui_labels() -> void:
	if _progress_label == null:
		return
	var time_left = GameState._tunnel_chase_time_left
	var pct = clamp(int((1.0 - time_left / 180.0) * 100.0), 0, 100)
	var milestone_key := "UI_TUNNEL_CALL_DIALING"
	if pct >= 75:
		milestone_key = "UI_TUNNEL_CALL_CLOSING"
	elif pct >= 50:
		milestone_key = "UI_TUNNEL_CALL_CONFIRMING"
	elif pct >= 25:
		milestone_key = "UI_TUNNEL_CALL_VERIFYING"
		
	_progress_label.text = str(pct) + "% (" + tr(milestone_key) + ")"

func _process(delta: float) -> void:
	_update_camera()

	if UIMode.get_mode() != UIMode.Mode.NONE or _showdown_triggered:
		return

	# Handle chase timer tick
	GameState._tunnel_chase_time_left -= delta
	_update_ui_labels()

	if GameState._tunnel_chase_time_left <= 0.0:
		GameState._tunnel_chase_time_left = 0.0
		_update_ui_labels()
		_start_showdown()
		return

	if player.is_climbing():
		_update_climb_state()
		return

	_refresh_current_interactable()
	_try_enter_ladder()

	if DisplayServer.get_name() == "headless":
		if current_interactable != null and Input.is_action_just_pressed("interact_primary"):
			_trigger_interaction()

func _unhandled_input(event: InputEvent) -> void:
	if UIMode.get_mode() != UIMode.Mode.NONE or _showdown_triggered:
		return

	_refresh_current_interactable()
	if current_interactable == null:
		return

	if event.is_action_pressed("interact_primary"):
		get_viewport().set_input_as_handled()
		_trigger_interaction()

func _trigger_interaction() -> void:
	match current_interactable.interaction_id:
		"chase_backtrack":
			# Backtrack to room 1 upper level right spawn
			scene_transition_requested.emit("tunnel_chase", "from_right", {})
		"chase_exit_0", "chase_exit_1", "chase_exit_2":
			_handle_exit_attempt(current_interactable.interaction_id)

func _handle_exit_attempt(exit_id: String) -> void:
	var target_idx := 0
	if exit_id == "chase_exit_1":
		target_idx = 1
	elif exit_id == "chase_exit_2":
		target_idx = 2

	if GameState.tunnel_chase_true_exit == target_idx:
		# Correct exit found! Start showdown
		_start_showdown()
	else:
		# Wrong exit: handle dead end
		_handle_dead_end(exit_id)

func _handle_dead_end(dead_id: String) -> void:
	var already_tried: bool = GameState._tunnel_chase_tried.has(dead_id)
	var msg_key = "MSG_TUNNEL_DEAD_END_SHORT" if already_tried else "MSG_TUNNEL_DEAD_END_LONG"
	
	if not already_tried:
		GameState._tunnel_chase_tried.append(dead_id)
		GameState._tunnel_chase_time_left = max(0.0, GameState._tunnel_chase_time_left - 20.0)
		_update_ui_labels()

	var game_ui = get_tree().root.find_child("GameUI", true, false)
	if game_ui != null:
		game_ui.set_monologue_active(true)
		
	interaction_requested.emit({
		"type": "message",
		"message_text": msg_key,
		"on_closed": func():
			if game_ui != null:
				game_ui.set_monologue_active(false)
	})

func _start_showdown() -> void:
	if _showdown_triggered:
		return
	_showdown_triggered = true

	# Lock player physics and GUI
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	
	var game_ui = get_tree().root.find_child("GameUI", true, false)
	if game_ui != null:
		game_ui.set_monologue_active(true)

	# Setup showdown overlay
	_showdown_layer = CanvasLayer.new()
	_showdown_layer.layer = 99
	add_child(_showdown_layer)

	_showdown_rect = ColorRect.new()
	_showdown_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_showdown_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_showdown_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_showdown_layer.add_child(_showdown_rect)

	_showdown_texture = TextureRect.new()
	_showdown_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_showdown_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_showdown_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_showdown_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_showdown_texture.modulate.a = 0.0
	_showdown_texture.visible = false
	
	var tex = load(SHOWDOWN_IMAGE_PATH)
	if tex != null:
		_showdown_texture.texture = tex
	_showdown_layer.add_child(_showdown_texture)

	# Hide timer UI
	if _ui_layer != null:
		_ui_layer.visible = false

	# Play transition
	var tw = create_tween()
	_showdown_texture.visible = true
	tw.tween_property(_showdown_rect, "color:a", 0.85, 0.5)
	tw.parallel().tween_property(_showdown_texture, "modulate:a", 1.0, 0.5)
	tw.tween_callback(_on_showdown_fade_complete)

func _on_showdown_fade_complete() -> void:
	# Calculate quest resolution using seven_betrayal.gd
	var SevenBetrayal = load("res://data/quests/seven_betrayal.gd")
	SevenBetrayal.resolve_betrayal_results()

	# Pick message key based on A/B branch
	var msg_key = "MSG_TUNNEL_SHOWDOWN_FULL"
	if GameState.get_flag("seven_stopped_partial", false):
		msg_key = "MSG_TUNNEL_SHOWDOWN_PARTIAL"

	# Show MessageBox
	interaction_requested.emit({
		"type": "message",
		"message_text": msg_key,
		"on_closed": _on_showdown_message_closed
	})

func _on_showdown_message_closed() -> void:
	# Clean up overlay
	var tw = create_tween()
	tw.tween_property(_showdown_rect, "color:a", 0.0, 0.5)
	tw.parallel().tween_property(_showdown_texture, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		var game_ui = get_tree().root.find_child("GameUI", true, false)
		if game_ui != null:
			game_ui.set_monologue_active(false)
		
		# Teleport back to underground_settlement_right:from_deep_tunnel
		scene_transition_requested.emit("underground_settlement_right", "from_deep_tunnel", {})
	)

func _try_enter_ladder() -> void:
	if current_interactable == null or current_interactable.interaction_id != "chase_ladder":
		return

	var on_upper := absf(player.global_position.y - UPPER_WALK_Y) <= absf(player.global_position.y - LOWER_WALK_Y)
	if on_upper and Input.is_action_just_pressed("move_down"):
		_begin_climb()
	elif not on_upper and Input.is_action_just_pressed("move_up"):
		_begin_climb()

func _begin_climb() -> void:
	player.enter_climb_mode(LADDER_X, UPPER_WALK_Y, LOWER_WALK_Y)
	_climb_entry_y = player.global_position.y
	_climb_engaged = false
	current_interactable_changed.emit({})

func _update_climb_state() -> void:
	var y := player.global_position.y
	if not _climb_engaged and abs(y - _climb_entry_y) > CLIMB_ENGAGE_MARGIN:
		_climb_engaged = true

	if not _climb_engaged:
		return

	if abs(y - UPPER_WALK_Y) <= CLIMB_EXIT_MARGIN:
		_exit_ladder_to(UPPER_WALK_Y)
	elif abs(y - LOWER_WALK_Y) <= CLIMB_EXIT_MARGIN:
		_exit_ladder_to(LOWER_WALK_Y)

func _exit_ladder_to(target_y: float) -> void:
	player.exit_climb_mode(target_y)
	if target_y == UPPER_WALK_Y:
		_apply_upper_walk_line()
	else:
		_apply_lower_walk_line()
	_climb_engaged = false
	_refresh_current_interactable()

func _apply_upper_walk_line() -> void:
	player.min_x = 100.0
	player.max_x = 3200.0
	player.walk_line_y = UPPER_WALK_Y
	player.walk_height_points = []
	player.snap_to_walk_line()

func _apply_lower_walk_line() -> void:
	player.min_x = 100.0
	player.max_x = 3200.0
	player.walk_line_y = LOWER_WALK_Y
	player.walk_height_points = []
	player.snap_to_walk_line()

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
		current_interactable_changed.emit({})
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
		var distance := player_position.distance_squared_to(interactable.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_interactable = interactable

	return closest_interactable

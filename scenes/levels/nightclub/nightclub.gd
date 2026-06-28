# res://scenes/levels/nightclub/nightclub.gd
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const CAMERA_HALF_WIDTH := 640.0
const CAMERA_Y := 600.0
const MAP_WIDTH := 4288.0

# Phase 23-C (redesign): bar-bot distraction is a one-shot, timed stealth beat.
# Triggered only after the player has talked to the bodyguard. On trigger the
# guard + bar bot fade out, a situation image holds the screen (player locked),
# then a countdown opens a window to sneak through the back door. If the window
# expires the guard returns and the distraction is permanently spent.
const SITUATION_IMAGE_PATH := "res://assets/generated/sprites/nightclub_bar_bot_distraction/situation/nightclub-bar-distraction-situation-20260628-123600.jpg"
const SITUATION_IMAGE_HOLD := 5.0   # seconds the locked situation image is shown
const SNEAK_WINDOW_SECONDS := 10.0  # seconds the player has to sneak in after it
const DISTRACT_FADE_TIME := 0.6

enum DistractPhase { IDLE, IMAGE, WINDOW, RESOLVING }

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_entrance"
var _bodyguard_off_post: bool = false
var _entry_payload: Dictionary = {}

var _distract_phase: int = DistractPhase.IDLE
var _distract_countdown: float = 0.0
var _game_ui: Node = null
var _distract_fx_layer: CanvasLayer = null
var _situation_backdrop: ColorRect = null
var _situation_image: TextureRect = null
var _countdown_label: Label = null
var _blackout_layer: CanvasLayer = null
var _blackout_rect: ColorRect = null

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

	_bodyguard_off_post = false
	var passed := GameState.has_flag("passed_nightclub_security")
	var bodyguard = $Interactables.get_node_or_null("Bodyguard")
	if bodyguard != null:
		if passed:
			bodyguard.visible = false
			bodyguard.process_mode = PROCESS_MODE_DISABLED
		else:
			bodyguard.visible = true
			bodyguard.modulate.a = 1.0
			bodyguard.process_mode = PROCESS_MODE_INHERIT

	for interactable in $Interactables.get_children():
		if interactable == null or interactable.is_queued_for_deletion():
			continue
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)
	player.anim.play("idle")

	_game_ui = get_tree().root.find_child("GameUI", true, false)
	_build_distraction_overlay()

	_refresh_current_interactable()

func _process(_delta: float) -> void:
	_update_camera()

	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	# Sneak-window countdown only ticks while no menu is open (auto-pauses on pause).
	if _distract_phase == DistractPhase.WINDOW and DisplayServer.get_name() != "headless":
		_distract_countdown -= _delta
		if _countdown_label != null:
			_countdown_label.text = str(max(0, int(ceil(_distract_countdown))))
		if _distract_countdown <= 0.0:
			_resolve_distraction()
			return

	_refresh_current_interactable()

	if DisplayServer.get_name() == "headless":
		if current_interactable != null and Input.is_action_just_pressed("interact_primary"):
			_trigger_interaction()

func _unhandled_input(event: InputEvent) -> void:
	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	# Ignore world interaction while the situation image holds or the guard returns.
	if _distract_phase == DistractPhase.IMAGE or _distract_phase == DistractPhase.RESOLVING:
		return

	_refresh_current_interactable()
	if current_interactable == null:
		return

	if event.is_action_pressed("interact_primary"):
		get_viewport().set_input_as_handled()
		_trigger_interaction()

func _trigger_interaction() -> void:
	if current_interactable.dialogue_id != "":
		# Talking to the bodyguard (any branch) unlocks the bar-bot distraction.
		if current_interactable.dialogue_id == "nightclub_bodyguard":
			GameState.set_flag("talked_nightclub_bodyguard", true)
		interaction_requested.emit({
			"type": "dialogue",
			"dialogue_id": current_interactable.dialogue_id
		})
		return

	match current_interactable.interaction_id:
		"exit_to_entrance":
			scene_transition_requested.emit("nightclub_entrance", "from_lobby", {})
		"back_door":
			if GameState.has_flag("passed_nightclub_security"):
				scene_transition_requested.emit("nightclub_back", "from_lobby", {})
			elif _bodyguard_off_post:
				# Sneak succeeds: close the window so it can't expire mid-transition.
				_distract_phase = DistractPhase.IDLE
				if _countdown_label != null:
					_countdown_label.visible = false
				GameState.set_flag("passed_nightclub_security", true)
				scene_transition_requested.emit("nightclub_back", "from_lobby", {})
			else:
				interaction_requested.emit({
					"type": "message",
					"message_text": GameState.STORY_MESSAGES["nightclub_security_blocked"]
				})
		"bar_bot_distract":
			if not GameState.has_flag("talked_nightclub_bodyguard"):
				interaction_requested.emit({
					"type": "message",
					"message_text": GameState.STORY_MESSAGES["nightclub_bar_bot_pre_talk"]
				})
			elif GameState.has_flag("nightclub_bar_bot_used"):
				interaction_requested.emit({
					"type": "message",
					"message_text": GameState.STORY_MESSAGES["nightclub_bar_bot_used"]
				})
			elif _distract_phase == DistractPhase.IDLE:
				_begin_distraction()
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
			"prompt_text": _prompt_text_for(current_interactable)
		})

func _prompt_text_for(interactable: Area2D) -> String:
	# The bar bot only reads as "tamper" once it's a real option (talked to the
	# guard, not yet spent). Otherwise it's just something to examine.
	if interactable.interaction_id == "bar_bot_distract":
		if not GameState.has_flag("talked_nightclub_bodyguard") or GameState.has_flag("nightclub_bar_bot_used"):
			return "PROMPT_NIGHTCLUB_BAR_BOT_EXAMINE"
	return interactable.prompt_text

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

# ==========================================
# Phase 23-C: bar-bot distraction (one-shot timed sneak)
# ==========================================
func _build_distraction_overlay() -> void:
	# High layer: situation image + countdown sit above the persistent GameUI (layer 2).
	_distract_fx_layer = CanvasLayer.new()
	_distract_fx_layer.layer = 60
	add_child(_distract_fx_layer)

	_situation_backdrop = ColorRect.new()
	_situation_backdrop.color = Color(0.0, 0.0, 0.0, 0.85)
	_situation_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_situation_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_situation_backdrop.visible = false
	_distract_fx_layer.add_child(_situation_backdrop)

	_situation_image = TextureRect.new()
	if ResourceLoader.exists(SITUATION_IMAGE_PATH):
		_situation_image.texture = load(SITUATION_IMAGE_PATH)
	_situation_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_situation_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_situation_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_situation_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_situation_image.visible = false
	_distract_fx_layer.add_child(_situation_image)

	_countdown_label = Label.new()
	_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_countdown_label.offset_top = 40.0
	_countdown_label.offset_bottom = 150.0
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 72)
	_countdown_label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84, 1.0))
	_countdown_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_countdown_label.add_theme_constant_override("outline_size", 10)
	_countdown_label.visible = false
	_distract_fx_layer.add_child(_countdown_label)

	# Low layer (below GameUI=2): the final blackout, so the messagebox shows on top.
	_blackout_layer = CanvasLayer.new()
	_blackout_layer.layer = 1
	add_child(_blackout_layer)

	_blackout_rect = ColorRect.new()
	_blackout_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_blackout_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blackout_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blackout_rect.visible = false
	_blackout_layer.add_child(_blackout_rect)

func _begin_distraction() -> void:
	GameState.set_flag("nightclub_bar_bot_used", true)
	_bodyguard_off_post = true

	var bodyguard := $Interactables.get_node_or_null("Bodyguard")
	var bar_bot := $Interactables.get_node_or_null("BarBot")
	_fade_out_disable(bodyguard)
	_fade_out_disable(bar_bot)
	if bodyguard != null:
		nearby_interactables.erase(bodyguard)
	if bar_bot != null:
		nearby_interactables.erase(bar_bot)
	_refresh_current_interactable()

	if DisplayServer.get_name() == "headless":
		# Skip the cinematic; the window is logically open so headless tests can
		# drive the back-door sneak or call force_resolve_distraction().
		_distract_phase = DistractPhase.WINDOW
		return

	_distract_phase = DistractPhase.IMAGE
	_set_player_locked(true)
	_situation_backdrop.visible = true
	_situation_image.visible = true
	_countdown_label.visible = false
	get_tree().create_timer(SITUATION_IMAGE_HOLD).timeout.connect(_on_situation_image_done)

func _fade_out_disable(n: Node) -> void:
	if n == null:
		return
	n.process_mode = PROCESS_MODE_DISABLED
	if not (n is CanvasItem):
		return
	if DisplayServer.get_name() == "headless":
		n.visible = false
		return
	var tw := create_tween()
	tw.tween_property(n, "modulate:a", 0.0, DISTRACT_FADE_TIME)
	tw.tween_callback(func(): n.visible = false)

func _on_situation_image_done() -> void:
	_situation_image.visible = false
	_situation_backdrop.visible = false
	_set_player_locked(false)
	_distract_phase = DistractPhase.WINDOW
	_distract_countdown = SNEAK_WINDOW_SECONDS
	_countdown_label.text = str(int(SNEAK_WINDOW_SECONDS))
	_countdown_label.visible = true

func _resolve_distraction() -> void:
	_distract_phase = DistractPhase.RESOLVING
	if _countdown_label != null:
		_countdown_label.visible = false

	if DisplayServer.get_name() == "headless":
		_restore_guard_and_bar_bot()
		_bodyguard_off_post = false
		_distract_phase = DistractPhase.IDLE
		interaction_requested.emit({
			"type": "message",
			"message_text": GameState.STORY_MESSAGES["nightclub_guard_returned"]
		})
		return

	_set_player_locked(true)
	_blackout_rect.visible = true
	_blackout_rect.color.a = 0.0
	var tw := create_tween()
	tw.tween_property(_blackout_rect, "color:a", 1.0, DISTRACT_FADE_TIME)
	tw.tween_callback(_show_guard_returned_message)

func _show_guard_returned_message() -> void:
	interaction_requested.emit({
		"type": "message",
		"message_text": GameState.STORY_MESSAGES["nightclub_guard_returned"],
		"on_closed": Callable(self, "_on_guard_returned_closed")
	})

func _on_guard_returned_closed() -> void:
	_restore_guard_and_bar_bot()
	_bodyguard_off_post = false
	_distract_phase = DistractPhase.IDLE
	if _blackout_rect != null:
		var tw := create_tween()
		tw.tween_property(_blackout_rect, "color:a", 0.0, DISTRACT_FADE_TIME)
		tw.tween_callback(func(): _blackout_rect.visible = false)
	_set_player_locked(false)

func _restore_guard_and_bar_bot() -> void:
	var bodyguard := $Interactables.get_node_or_null("Bodyguard")
	if bodyguard != null:
		bodyguard.visible = true
		bodyguard.modulate.a = 1.0
		bodyguard.process_mode = PROCESS_MODE_INHERIT
	var bar_bot := $Interactables.get_node_or_null("BarBot")
	if bar_bot != null:
		bar_bot.visible = true
		bar_bot.modulate.a = 1.0
		bar_bot.process_mode = PROCESS_MODE_INHERIT

func _set_player_locked(locked: bool) -> void:
	if player != null:
		player.set_physics_process(not locked)
		if locked:
			player.velocity = Vector2.ZERO
	# Reuse the monologue gate to block inventory/notebook/pause hotkeys without
	# opening any GameUI panel (UIMode stays NONE during the locked image beat).
	if _game_ui != null and _game_ui.has_method("set_monologue_active"):
		_game_ui.set_monologue_active(locked)

# Test hook (Phase 23-C headless): simulate the sneak window expiring.
func force_resolve_distraction() -> void:
	if _distract_phase == DistractPhase.WINDOW:
		_resolve_distraction()

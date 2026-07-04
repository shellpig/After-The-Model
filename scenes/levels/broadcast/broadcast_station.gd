# res://scenes/levels/broadcast/broadcast_station.gd
# Phase 27-A: 地下廣播站正式場景。單室、唯一 entry from_backup_core、單向（無回資料中心出口）、can_save_here=true。
# Phase 27-C: 上傳終端（UploadTerminal）分派升級——expose_upload_done 已設 -> 中性 idle examine（不重開清洗閘樹）；
# 否則開 broadcast_upload 對話（五拍清洗閘）。
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
@onready var game_ui: CanvasLayer = _find_game_ui()

# Phase 29-A: Expose 三判定結局演出
const EXPOSE_TRACE_THRESHOLD := 3
const EXPOSE_UPLOAD_PAGES := [
	"MSG_EPILOGUE_EXPOSE_UPLOAD_P1",
	"MSG_EPILOGUE_EXPOSE_UPLOAD_P2"
]

var _expose_active: bool = false
var _expose_verdict: String = "" # "a", "b", "c"
var _expose_pages: Array = []
var _expose_page_index: int = 0
var _expose_page_done: bool = false

var _blackout_canvas: CanvasLayer = null
var _blackout_rect: ColorRect = null

func _find_game_ui() -> CanvasLayer:
	var root := get_tree().root if is_inside_tree() else null
	if root:
		var gu = root.find_child("GameUI", true, false)
		if gu:
			return gu
	return null

func _setup_blackout() -> void:
	_blackout_canvas = CanvasLayer.new()
	_blackout_canvas.layer = 5 # 覆蓋在 2D 場景最前面
	add_child(_blackout_canvas)
	
	_blackout_rect = ColorRect.new()
	_blackout_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_blackout_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blackout_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blackout_rect.visible = false
	_blackout_canvas.add_child(_blackout_rect)

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

func _has_any_expose_ending_played() -> bool:
	return GameState.get_flag("ending_expose_a_played", false) or \
		GameState.get_flag("ending_expose_b_played", false) or \
		GameState.get_flag("ending_expose_c_played", false)

func _ready() -> void:
	SaveSystem.can_save_here = not _has_any_expose_ending_played()
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.has_method("play_bgm"):
		main.play_bgm(BGM_PATH)

	_setup_blackout()

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)
	player.anim.play("idle")
	_refresh_current_interactable()

	# 進場一次性 MessageBox：只在真正走 from_backup_core 轉場時播放；讀檔 entry_point_id 為 "restore"（main.gd transition_to 慣例），天然不觸發、不需去重旗標。
	# 若已上傳完成則不再播放（例如讀檔救援）。
	if _entry_point_id == "from_backup_core" and not GameState.get_flag("expose_upload_done", false):
		call_deferred("_play_arrival_message")

func _play_arrival_message() -> void:
	interaction_requested.emit({
		"type": "message",
		"message_text": GameState.STORY_MESSAGES["broadcast_arrival"]
	})

func _process(_delta: float) -> void:
	_update_camera()

	if _has_any_expose_ending_played():
		return

	if _expose_active:
		_update_expose_sequence()
		return

	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	_refresh_current_interactable()
	_maybe_start_expose_sequence()

	if DisplayServer.get_name() == "headless":
		if current_interactable != null and Input.is_action_just_pressed("interact_primary"):
			_trigger_interaction()

func _unhandled_input(event: InputEvent) -> void:
	if _has_any_expose_ending_played():
		return

	if _expose_active:
		return

	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	_refresh_current_interactable()
	if current_interactable == null:
		return

	if event.is_action_pressed("interact_primary"):
		get_viewport().set_input_as_handled()
		_trigger_interaction()

func _trigger_interaction() -> void:
	if current_interactable.interaction_id == "upload_terminal":
		# Phase 27-C：已上傳（expose_upload_done）-> 中性 idle examine，不重開清洗閘樹。
		if GameState.get_flag("expose_upload_done", false):
			interaction_requested.emit({
				"type": "message",
				"message_text": GameState.STORY_MESSAGES["broadcast_upload_done_idle"]
			})
		else:
			interaction_requested.emit({
				"type": "dialogue",
				"dialogue_id": "broadcast_upload"
			})
		return

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


# ==========================================
# Phase 29-A: Expose 三判定結局演出序列
# ==========================================
func _maybe_start_expose_sequence() -> void:
	if not GameState.get_flag("expose_upload_done", false):
		return
	if GameState.get_flag("ending_expose_a_played", false) or GameState.get_flag("ending_expose_b_played", false) or GameState.get_flag("ending_expose_c_played", false):
		return
	_start_expose_sequence()

func _start_expose_sequence() -> void:
	_expose_active = true
	SaveSystem.can_save_here = false
	current_interactable = null
	current_interactable_changed.emit({})

	player.min_x = player.global_position.x
	player.max_x = player.global_position.x
	player.anim.play("idle")

	# 判定分派
	if GameState.get_trace() >= EXPOSE_TRACE_THRESHOLD:
		_expose_verdict = "c"
	elif not GameState.get_flag("expose_upload_cleaned", false):
		_expose_verdict = "a"
	else:
		_expose_verdict = "b"

	_expose_pages = EXPOSE_UPLOAD_PAGES.duplicate()
	_expose_page_index = 0
	_show_expose_page()

func _show_expose_page() -> void:
	_expose_page_done = false
	if game_ui:
		game_ui.begin_message(_expose_pages[_expose_page_index])
		game_ui.set_message_page_hint("", false)

func _update_expose_sequence() -> void:
	if _expose_pages.size() > 0 and _expose_page_index < _expose_pages.size() and _expose_pages[_expose_page_index] == "CG_PLAY":
		if game_ui and not game_ui.is_photo_viewer_open():
			_advance_expose_page()
		return

	if _expose_pages.size() > 0 and _expose_page_index < _expose_pages.size() and _expose_pages[_expose_page_index] == "BLACKOUT_FADE":
		return

	if not _expose_page_done:
		if game_ui and game_ui.is_message_finished():
			_expose_page_done = true
			if game_ui:
				game_ui.set_message_page_hint(tr("UI_MSG_CONTINUE_HINT"), true)
		return

	var advance_pressed := (
		Input.is_action_just_pressed("interact_primary") or
		Input.is_action_just_pressed("ui_accept") or
		Input.is_action_just_pressed("ui_cancel")
	)
	if DisplayServer.get_name() == "headless":
		advance_pressed = true

	if advance_pressed:
		_advance_expose_page()

func _advance_expose_page() -> void:
	_expose_page_index += 1
	
	if _expose_pages == EXPOSE_UPLOAD_PAGES and _expose_page_index >= EXPOSE_UPLOAD_PAGES.size():
		_finish_upload_and_dispatch()
		return

	if _expose_page_index >= _expose_pages.size():
		_finish_expose_sequence()
	else:
		var next_item = _expose_pages[_expose_page_index]
		if next_item == "CG_PLAY":
			if game_ui:
				game_ui.close_message()
				UIMode.set_mode(UIMode.Mode.NONE)
				game_ui.open_photo_viewer("res://assets/generated/maps/cg_settlement_burning/cg_settlement_burning.png", null)
		elif next_item == "BLACKOUT_FADE":
			if game_ui:
				game_ui.close_message()
				UIMode.set_mode(UIMode.Mode.NONE)
			
			if _blackout_rect:
				_blackout_rect.visible = true
				_blackout_rect.color.a = 0.0
				var fade_duration := 2.0
				if DisplayServer.get_name() == "headless":
					fade_duration = 0.0
				var tw := create_tween()
				tw.tween_property(_blackout_rect, "color:a", 1.0, fade_duration)
				tw.tween_callback(func():
					_advance_expose_page()
				)
		else:
			_show_expose_page()

func _finish_upload_and_dispatch() -> void:
	_expose_pages.clear()
	_expose_page_index = 0
	
	if _expose_verdict == "a":
		_expose_pages = [
			"MSG_EPILOGUE_EXPOSE_A_ALARM",
			"CG_PLAY",
			"MSG_EPILOGUE_EXPOSE_A_AFTER"
		]
	elif _expose_verdict == "b":
		_expose_pages = [
			"MSG_EPILOGUE_EXPOSE_B_P1"
		]
	elif _expose_verdict == "c":
		_expose_pages = [
			"MSG_EPILOGUE_EXPOSE_C_INTERCEPT",
			"MSG_EPILOGUE_EXPOSE_C_ERASE",
			"BLACKOUT_FADE"
		]
		
	_show_expose_page()

func _finish_expose_sequence() -> void:
	_expose_active = false
	if game_ui:
		game_ui.close_message()
		
	if _expose_verdict == "a":
		GameState.set_flag("ending_expose_a_played", true)
	elif _expose_verdict == "b":
		GameState.set_flag("ending_expose_b_played", true)
	elif _expose_verdict == "c":
		GameState.set_flag("ending_expose_c_played", true)
		
	if game_ui and game_ui.has_method("start_ending_epilogue"):
		game_ui.start_ending_epilogue()


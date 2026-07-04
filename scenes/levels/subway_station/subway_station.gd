# res://scenes/levels/subway_station/subway_station.gd
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const CAMERA_HALF_WIDTH := 640.0
const CAMERA_Y := 408.0
const MAP_WIDTH := 1376.0

const MESSAGES := {
	"station_sign": "入口牆上的站名牌被雨水泡得發白，只剩底色還固執地亮著。這裡曾經把人往上送，現在只把人往下吞。",
	"dead_kiosk": "售票機螢幕停在服務中止畫面。付款感應區還有微弱電流，像一隻不願承認自己已經沒用的眼睛。",
	"fare_gate": "閘口卡在半開的位置，通勤人潮早就消失，只剩轉軸偶爾發出乾澀的喀聲。往右走，就是月台。"
}

# Phase 28-C：Protect not-B 中間站 — 上行線復駛廣播 + 小岑過閘 CG（假聲紋不認得你）。
const SUBWAY_RUMBLE_PATHS := [
	"res://assets/audio/ambient/subway_rumble_a.mp3",
	"res://assets/audio/ambient/subway_rumble_b.mp3"
]
const CEN_CG_GATE_PASS_PATH := "res://assets/generated/sprites/cen/cg_gate_pass/cg_gate_pass.jpeg"

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var ambient_subway: AudioStreamPlayer = $AmbientSubway
@onready var game_ui: CanvasLayer = _find_game_ui()

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_street"
var _entry_payload: Dictionary = {}

# stage: 0 = 復駛廣播頁, 1 = 小岑台詞頁, 2 = CG 顯示中
var _cen_epilogue_active: bool = false
var _cen_epilogue_stage: int = 0
var _cen_epilogue_page_done: bool = false

func _find_game_ui() -> CanvasLayer:
	var root := get_tree().root if is_inside_tree() else null
	if root:
		var gu = root.find_child("GameUI", true, false)
		if gu:
			return gu
	return null

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "from_street"
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
		main.play_bgm("res://assets/bgm/The Last Platform.mp3")

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)
	player.anim.play("idle")
	_refresh_current_interactable()

	if _entry_point_id == "epilogue_cen" and GameState.get_flag("ending_route_protect", false) and not GameState.get_flag("cen_voiceprint_exposed", false) and not GameState.get_flag("ending_protect_cen_seen", false):
		_cen_epilogue_active = true
		SaveSystem.can_save_here = false
		_start_cen_epilogue()

func _process(_delta: float) -> void:
	_update_camera()

	if _cen_epilogue_active:
		_update_cen_epilogue()
		return

	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	_refresh_current_interactable()

	if DisplayServer.get_name() == "headless":
		if current_interactable != null and Input.is_action_just_pressed("interact_primary"):
			_trigger_interaction()

func _unhandled_input(event: InputEvent) -> void:
	if _cen_epilogue_active:
		return

	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	_refresh_current_interactable()
	if current_interactable == null:
		return

	if event.is_action_pressed("interact_primary"):
		get_viewport().set_input_as_handled()
		_trigger_interaction()

# ==========================================
# Phase 28-C: Protect not-B 中間站 — 復駛廣播 -> 小岑過閘台詞 -> CG -> 移除 + travel
# ==========================================
func _start_cen_epilogue() -> void:
	_cen_epilogue_stage = 0
	if ambient_subway:
		var path: String = SUBWAY_RUMBLE_PATHS[randi() % SUBWAY_RUMBLE_PATHS.size()]
		var stream := load(path) as AudioStream
		if stream:
			ambient_subway.stream = stream
			ambient_subway.play()
	_show_cen_epilogue_page("MSG_EPILOGUE_SUBWAY_RESUME")

func _show_cen_epilogue_page(message_key: String) -> void:
	_cen_epilogue_page_done = false
	if game_ui:
		game_ui.begin_message(message_key)
		game_ui.set_message_page_hint("", false)

func _update_cen_epilogue() -> void:
	if _cen_epilogue_stage == 2:
		if game_ui and not game_ui.is_photo_viewer_open():
			_finish_cen_epilogue()
		return

	if not _cen_epilogue_page_done:
		if game_ui and game_ui.is_message_finished():
			_cen_epilogue_page_done = true
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
		_advance_cen_epilogue()

func _advance_cen_epilogue() -> void:
	if _cen_epilogue_stage == 0:
		_cen_epilogue_stage = 1
		var cen_node := get_node_or_null("NpcCenEpilogue")
		if cen_node:
			cen_node.visible = true
		_show_cen_epilogue_page("MSG_EPILOGUE_CEN_PASS")
	elif _cen_epilogue_stage == 1:
		_cen_epilogue_stage = 2
		if game_ui:
			game_ui.close_message()
			UIMode.set_mode(UIMode.Mode.NONE)
			player.min_x = player.global_position.x
			player.max_x = player.global_position.x
			game_ui.open_photo_viewer(CEN_CG_GATE_PASS_PATH, null)

func _finish_cen_epilogue() -> void:
	_cen_epilogue_active = false
	GameState.set_flag("ending_protect_cen_seen", true)
	var cen_node := get_node_or_null("NpcCenEpilogue")
	if cen_node:
		cen_node.queue_free()
	scene_transition_requested.emit("apartment_entrance", "epilogue_wan", {})

func _trigger_interaction() -> void:
	match current_interactable.interaction_id:
		"exit_to_street":
			scene_transition_requested.emit("apartment_entrance", "from_subway", {})
		"gate_to_platform":
			scene_transition_requested.emit("subway_station_platform", "from_concourse", {})
		"station_sign", "dead_kiosk", "fare_gate":
			interaction_requested.emit({
				"type": "message",
				"message_text": MESSAGES[current_interactable.interaction_id]
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

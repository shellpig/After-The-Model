# res://scenes/levels/underground_settlement/underground_settlement.gd
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const CAMERA_HALF_WIDTH := 640.0
const CAMERA_Y := 600.0
const MAP_WIDTH := 4352.0

const MESSAGES := {
	"empty_tent": "MSG_SETTLEMENT_EMPTY_TENT",
	"settlement_center": "聚落中央空出一圈位置，沒有招牌，也沒有正式邊界。人們用破布、延長線和沉默把這裡劃成了可以暫時活下去的地方。"
}

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var game_ui: CanvasLayer = _find_game_ui()

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_subway"
var _entry_payload: Dictionary = {}

# Phase 28-C：Protect Branch B 中間站 — 空帳篷一拍 + 伍姐沉默搖頭一拍（純文字，不開對話樹）。
# stage: 0 = 空帳篷頁（複用 24-D empty_tent 文字）, 1 = 伍姐沉默搖頭頁
var _wu_epilogue_active: bool = false
var _wu_epilogue_stage: int = 0
var _wu_epilogue_page_done: bool = false

func _find_game_ui() -> CanvasLayer:
	var root := get_tree().root if is_inside_tree() else null
	if root:
		var gu = root.find_child("GameUI", true, false)
		if gu:
			return gu
	return null

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "from_subway"
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
	GameState.set_flag("reached_settlement", true)
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.has_method("play_bgm"):
		main.play_bgm("res://assets/bgm/The Deleted Still Breathe.mp3")

	var motif_player = get_node_or_null("ThemeMotifPlayer")
	if motif_player and motif_player.stream and "loop" in motif_player.stream:
		# duplicate() 避免污染共享快取資源：此 mp3 同時是可賣殘響 echo_song_rain_doesnt_stop
		# 的媒體檔，直接改 loop 會讓筆記回放變成無限循環（比照 echo_point.gd）
		motif_player.stream = motif_player.stream.duplicate()
		motif_player.stream.loop = true

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)

	# Phase 24-D: Cen exposure handling
	var cen_exposed: bool = GameState.get_flag("cen_voiceprint_exposed", false)
	var npc_cen = get_node_or_null("Interactables/NpcCen")
	var empty_tent = get_node_or_null("Interactables/EmptyTentArea")
	if cen_exposed:
		if npc_cen != null:
			npc_cen.queue_free()
		if empty_tent != null:
			empty_tent.visible = true
			var col = empty_tent.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if col != null:
				col.disabled = false
	else:
		if empty_tent != null:
			empty_tent.visible = false
			var col = empty_tent.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if col != null:
				col.disabled = true

	player.anim.play("idle")
	_refresh_current_interactable()

	if _entry_point_id == "epilogue_settlement" and GameState.get_flag("ending_route_protect", false) and GameState.get_flag("cen_voiceprint_exposed", false) and not GameState.get_flag("ending_protect_wu_seen", false):
		_wu_epilogue_active = true
		SaveSystem.can_save_here = false
		_start_wu_epilogue()

func _process(_delta: float) -> void:
	_update_camera()

	if _wu_epilogue_active:
		_update_wu_epilogue()
		return

	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	_refresh_current_interactable()

	if DisplayServer.get_name() == "headless":
		if current_interactable != null and Input.is_action_just_pressed("interact_primary"):
			_trigger_interaction()

func _unhandled_input(event: InputEvent) -> void:
	if _wu_epilogue_active:
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
# Phase 28-C: Protect Branch B 中間站 — 空帳篷 -> 伍姐沉默搖頭 -> travel
# ==========================================
func _start_wu_epilogue() -> void:
	_wu_epilogue_stage = 0
	_show_wu_epilogue_page(MESSAGES["empty_tent"])

func _show_wu_epilogue_page(text: String) -> void:
	_wu_epilogue_page_done = false
	if game_ui:
		game_ui.begin_message(text)
		game_ui.set_message_page_hint("", false)

func _update_wu_epilogue() -> void:
	if not _wu_epilogue_page_done:
		if game_ui and game_ui.is_message_finished():
			_wu_epilogue_page_done = true
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
		_advance_wu_epilogue()

func _advance_wu_epilogue() -> void:
	if _wu_epilogue_stage == 0:
		_wu_epilogue_stage = 1
		_show_wu_epilogue_page("MSG_EPILOGUE_WU_SILENT")
	else:
		_finish_wu_epilogue()

func _finish_wu_epilogue() -> void:
	_wu_epilogue_active = false
	GameState.set_flag("ending_protect_wu_seen", true)
	scene_transition_requested.emit("apartment_entrance", "epilogue_wan", {})

func _trigger_interaction() -> void:
	if current_interactable.dialogue_id != "":
		interaction_requested.emit({
			"type": "dialogue",
			"dialogue_id": current_interactable.dialogue_id
		})
		return

	match current_interactable.interaction_id:
		"exit_to_subway":
			scene_transition_requested.emit("subway_station_platform", "from_settlement", {})
		"go_right":
			scene_transition_requested.emit("underground_settlement_right", "from_left", {})
		"empty_tent", "settlement_center":
			interaction_requested.emit({
				"type": "message",
				"message_text": MESSAGES[current_interactable.interaction_id]
			})
		"examine_old_work_order":
			if not GameState.is_echo_complete("echo_ada_reset"):
				interaction_requested.emit({
					"type": "message",
					"message_text": "MSG_OLD_WORK_ORDER_NEUTRAL"
				})
			else:
				if not GameState.get_flag("read_old_work_order", false):
					GameState.set_flag("read_old_work_order", true)
					GameState.add_knowledge(GameState.STORY_NOTES["clue_old_work_order"])
					interaction_requested.emit({
						"type": "message",
						"message_text": "MSG_OLD_WORK_ORDER_REVEALED"
					})
				else:
					interaction_requested.emit({
						"type": "message",
						"message_text": "MSG_OLD_WORK_ORDER_READ"
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


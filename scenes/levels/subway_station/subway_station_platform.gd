# res://scenes/levels/subway_station/subway_station_platform.gd
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const CAMERA_HALF_WIDTH := 640.0
const CAMERA_Y := 536.0
const MAP_WIDTH := 4800.0

# Occasional power-outage event: flicker twice, drop the scene to separate
# brightness floors for a few seconds, then flicker back to normal. Purely
# visual — never blocks input. Background/player dim via modulate; the screen
# overwrites COLOR in its shader (modulate is ignored), so it dims through the
# material's `brightness` uniform instead.
const BLACKOUT_BG_LEVEL := 0.15
const BLACKOUT_PLAYER_LEVEL := 0.25
const BLACKOUT_SCREEN_LEVEL := 0.80
const BLACKOUT_FIRST_DELAY := Vector2(3.0, 5.0)   # min/max seconds after entering
const BLACKOUT_GAP := Vector2(15.0, 30.0)         # min/max seconds between outages
const BLACKOUT_HOLD := Vector2(6.0, 10.0)         # min/max seconds held dark
const BLACKOUT_BLINK := 0.05                       # per flicker blip
const BLACKOUT_FADE := 0.28                        # settle/recover fade

const MESSAGES := {
	# i18n key (story.csv); show_message() runs tr() on message_text.
	"commuter_screen": "MSG_SUBWAY_COMMUTER_SCREEN",
	"suitcase": "一個被遺留在角落的行李箱，鎖扣已經被暴力撬開。裡面除了幾張受潮發霉的舊貼紙與衣物碎屑外，空無一物。當時這裡顯然發生了某些極其倉促的變故，讓人們連隨身行李都來不及帶走，而殘存的值錢物品也早已被後來的拾荒者洗劫一空。",
	"drainage": "滲漏排水槽裡積著一層薄薄的油膜。遠處列車的低頻從牆內傳來，像城市還在睡夢裡磨牙。",
	"platform_anchor": "月台中央空得太乾淨，乾淨到像有人刻意把等待的人都從畫面裡拿掉。這裡之後會留下某個記憶的回聲，但現在只剩停運的風。"
}

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var background: Sprite2D = $Background
@onready var platform_screen: Polygon2D = $PlatformScreen

var _blackout_timer: Timer
var _blackout_tween: Tween
var _screen_base_brightness: float = 1.15

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_concourse"
var _entry_payload: Dictionary = {}

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "from_concourse"
	_entry_payload = payload.duplicate(true)

func set_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	prepare_entry_point(entry_point_id, payload)
	var spawn := $SpawnPoints.get_node_or_null(_entry_point_id) as Marker2D
	if spawn != null:
		player.global_position = spawn.global_position
	player.anim.play(player.idle_anim)
	_update_camera()

func _ready() -> void:
	SaveSystem.can_save_here = true
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.has_method("play_bgm"):
		main.play_bgm("res://assets/bgm/The Last Platform.mp3")

	var motif_player = get_node_or_null("ThemeMotifPlayer")
	if motif_player and motif_player.stream and "loop" in motif_player.stream:
		# duplicate() 避免污染共享快取資源：此 mp3 同時是可賣殘響 echo_song_rain_doesnt_stop
		# 的媒體檔，直接改 loop 會讓筆記回放變成無限循環（比照 echo_point.gd）
		motif_player.stream = motif_player.stream.duplicate()
		motif_player.stream.loop = true

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)
	player.anim.play(player.idle_anim)
	_refresh_current_interactable()

	var screen_mat := platform_screen.material as ShaderMaterial
	if screen_mat != null:
		var base = screen_mat.get_shader_parameter("brightness")
		if base != null:
			_screen_base_brightness = base

	_blackout_timer = Timer.new()
	_blackout_timer.one_shot = true
	_blackout_timer.timeout.connect(_run_blackout)
	add_child(_blackout_timer)
	_blackout_timer.start(randf_range(BLACKOUT_FIRST_DELAY.x, BLACKOUT_FIRST_DELAY.y))

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
		"exit_to_street":
			scene_transition_requested.emit("subway_station", "from_platform", {})
		"stairs_to_settlement":
			scene_transition_requested.emit("underground_settlement", "from_subway", {})
		"commuter_screen":
			GameState.set_flag("learned_topside_shortcut", true)
			interaction_requested.emit({
				"type": "message",
				"message_text": MESSAGES[current_interactable.interaction_id]
			})
		"suitcase", "drainage", "platform_anchor":
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

# --- Power-outage event ----------------------------------------------------

# t == 1.0 -> normal, t == 0.0 -> blackout floor; each element lerps to its own
# floor so they dim by different amounts.
func _apply_blackout_blend(t: float) -> void:
	_apply_levels(
		lerpf(BLACKOUT_BG_LEVEL, 1.0, t),
		lerpf(BLACKOUT_PLAYER_LEVEL, 1.0, t),
		lerpf(BLACKOUT_SCREEN_LEVEL, 1.0, t)
	)

func _apply_levels(bg: float, ply: float, scr: float) -> void:
	background.modulate = Color(bg, bg, bg)
	player.modulate = Color(ply, ply, ply)
	var screen_mat := platform_screen.material as ShaderMaterial
	if screen_mat != null:
		screen_mat.set_shader_parameter("brightness", _screen_base_brightness * scr)

func _run_blackout() -> void:
	if _blackout_tween != null and _blackout_tween.is_valid():
		return

	var tw := create_tween()
	_blackout_tween = tw

	# Flicker out: two near-black blips (screen only dips, it sits on its own circuit).
	for _i in 2:
		tw.tween_callback(_apply_levels.bind(0.0, 0.0, 0.6))
		tw.tween_interval(BLACKOUT_BLINK)
		tw.tween_callback(_apply_levels.bind(1.0, 1.0, 1.0))
		tw.tween_interval(BLACKOUT_BLINK)

	# Settle into the blackout, hold, then flicker back and stabilise.
	tw.tween_method(_apply_blackout_blend, 1.0, 0.0, BLACKOUT_FADE)
	tw.tween_interval(randf_range(BLACKOUT_HOLD.x, BLACKOUT_HOLD.y))
	for _i in 2:
		tw.tween_callback(_apply_levels.bind(1.0, 1.0, 1.0))
		tw.tween_interval(BLACKOUT_BLINK)
		tw.tween_callback(_apply_blackout_blend.bind(0.0))
		tw.tween_interval(BLACKOUT_BLINK)
	tw.tween_method(_apply_blackout_blend, 0.0, 1.0, BLACKOUT_FADE)

	tw.tween_callback(_schedule_next_blackout)

func _schedule_next_blackout() -> void:
	_blackout_tween = null
	_blackout_timer.start(randf_range(BLACKOUT_GAP.x, BLACKOUT_GAP.y))

func _get_interactable_position(interactable: Area2D) -> Vector2:
	var collision_shape := interactable.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		return collision_shape.global_position

	return interactable.global_position



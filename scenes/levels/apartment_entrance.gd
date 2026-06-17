extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const MESSAGES := {
	"mailboxes": "信箱牆上還留著幾張被雨泡爛的紙。大部分名字已經褪色，只剩公寓管理系統貼上的冷冰冰序號。",
	"alley_view": "右側暗巷深得像一段被刪掉的城市資料。遠處的青色招牌還亮著，卻照不到腳邊的積水。",
	"alley_view_unstarted": "右側暗巷深得像一段被刪掉的城市資料。遠處的青色招牌還亮著，卻照不到腳邊的積水。站在路旁的晚似乎若無其事地往這邊瞥了一眼，像是在留意那條巷子，又像是在留意你。",
	"alley_view_danger": "暗巷深處有幾具損毀的無人機和可疑的陰影。晚說得對，這裡不太對勁，不能就這麼硬闖進去。我想起我自己住的公寓在四樓，右側窗外就是外牆火災逃生梯與平台，也許可以從窗戶爬出去，繞到左棟三樓。",
	"vending_machine": "販賣機的冷光把雨水照成青色。螢幕上沒有價目，只有一行行錯位捲動的字：\n「今天休假。今天休假。請勿投幣——辭呈我已經遞出去了。」\n滾動停了幾秒，又輕輕補上一行：「請不要告訴店長。」"
}

const CAMERA_HALF_WIDTH := 640.0
const CAMERA_Y := 360.0
const MAP_WIDTH := 4080.0

const SUBWAY_RUMBLE_PATHS := [
	"res://assets/audio/ambient/subway_rumble_a.mp3",
	"res://assets/audio/ambient/subway_rumble_b.mp3"
]
const SUBWAY_INTERVAL_MIN := 40.0
const SUBWAY_INTERVAL_MAX := 90.0
# First rumble after entering the street fires sooner so the soundscape reads
# quickly; subsequent rumbles use the normal sparse interval.
const SUBWAY_FIRST_INTERVAL_MIN := 15.0
const SUBWAY_FIRST_INTERVAL_MAX := 25.0

# Idle camera drift (Phase 10-B): subtle sine wander on top of the existing
# follow/clamp logic, faded out while the player is walking to avoid nausea.
const CAMERA_DRIFT_AMPLITUDE := Vector2(2.5, 1.5)
const CAMERA_DRIFT_SPEED := Vector2(0.35, 0.5)
const CAMERA_DRIFT_FADE_SPEED := 1.5

# Billboard ad carousel (Phase 10-C-1): cycle through opaque ad stills on the
# BillboardScreen Polygon2D, swapping mid-glitch so the cut is hidden. The screen
# shader's glitch_amount is driven up/down across each transition.
const BILLBOARD_AD_PATHS := [
	"res://assets/generated/sprites/street_billboard_ad/street-billboard-ad-calm-collected-20260617-181129.jpg",
	"res://assets/generated/sprites/street_billboard_ad/street-billboard-ad-mind-upload-20260617-201628.png",
	"res://assets/generated/sprites/street_billboard_ad/street-billboard-ad-pure-sustenance-20260617-201628.png",
]
const BILLBOARD_HOLD := 6.0          # seconds each ad stays up
const BILLBOARD_HOLD_JITTER := 1.0   # +/- random on hold to avoid a metronomic feel
const BILLBOARD_GLITCH_DURATION := 0.35  # transition length

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var ambient_rain: AudioStreamPlayer = $AmbientRain
@onready var ambient_subway: AudioStreamPlayer = $AmbientSubway
@onready var subway_timer: Timer = $SubwayTimer
@onready var billboard: Polygon2D = $BillboardScreen

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_apartment"
var _entry_payload: Dictionary = {}
var _ambience_time: float = 0.0
var _camera_drift_strength: float = 1.0
var _subway_first_armed: bool = false

var _ad_textures: Array[Texture2D] = []
var _ad_index: int = 0
var _billboard_hold_timer: float = 0.0
var _billboard_hold_target: float = BILLBOARD_HOLD
var _billboard_in_glitch: bool = false
var _billboard_glitch_time: float = 0.0
var _billboard_swapped_this_glitch: bool = false

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "from_apartment"
	_entry_payload = payload.duplicate(true)

func set_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	prepare_entry_point(entry_point_id, payload)
	var spawn := $SpawnPoints.get_node_or_null(_entry_point_id) as Marker2D
	if spawn != null:
		player.global_position = spawn.global_position
	player.anim.play("idle")
	_update_camera()

func _ready() -> void:
	# 向宿主主控宣告播放 Faded Neon Departure 背景音樂
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.has_method("play_bgm"):
		main.play_bgm("res://assets/bgm/Faded Neon Departure.mp3")

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)
	player.anim.play("idle")
	_refresh_current_interactable()

	_start_ambience()
	_setup_billboard()

func _start_ambience() -> void:
	if ambient_rain.stream and "loop" in ambient_rain.stream:
		ambient_rain.stream.loop = true
	if not ambient_rain.playing:
		ambient_rain.play()

	subway_timer.timeout.connect(_on_subway_timer_timeout)
	_arm_subway()

func _arm_subway() -> void:
	if not _subway_first_armed:
		_subway_first_armed = true
		subway_timer.start(randf_range(SUBWAY_FIRST_INTERVAL_MIN, SUBWAY_FIRST_INTERVAL_MAX))
	else:
		subway_timer.start(randf_range(SUBWAY_INTERVAL_MIN, SUBWAY_INTERVAL_MAX))

func _on_subway_timer_timeout() -> void:
	var path: String = SUBWAY_RUMBLE_PATHS[randi() % SUBWAY_RUMBLE_PATHS.size()]
	var stream := load(path) as AudioStream
	if stream:
		ambient_subway.stream = stream
		ambient_subway.play()
	_arm_subway()

func _setup_billboard() -> void:
	if billboard == null:
		return
	_ad_textures.clear()
	for path in BILLBOARD_AD_PATHS:
		var tex := load(path) as Texture2D
		if tex != null:
			_ad_textures.append(tex)
	if _ad_textures.is_empty():
		return
	_ad_index = 0
	_apply_ad(_ad_index)
	_billboard_hold_target = BILLBOARD_HOLD + randf_range(-BILLBOARD_HOLD_JITTER, BILLBOARD_HOLD_JITTER)

func _apply_ad(idx: int) -> void:
	var tex := _ad_textures[idx]
	billboard.texture = tex
	# Polygon2D uv is in texture pixels; span the full texture so the shader's
	# normalized UV stays 0..1 regardless of each ad's resolution.
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	billboard.uv = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])

func _update_billboard(delta: float) -> void:
	# Need at least two ads to have anything to rotate between.
	if billboard == null or _ad_textures.size() < 2:
		return
	var mat := billboard.material as ShaderMaterial
	if _billboard_in_glitch:
		_billboard_glitch_time += delta
		var phase := _billboard_glitch_time / BILLBOARD_GLITCH_DURATION
		# Swap the texture at the glitch peak so the hard cut is hidden.
		if not _billboard_swapped_this_glitch and phase >= 0.5:
			_ad_index = (_ad_index + 1) % _ad_textures.size()
			_apply_ad(_ad_index)
			_billboard_swapped_this_glitch = true
		if phase >= 1.0:
			_billboard_in_glitch = false
			if mat != null:
				mat.set_shader_parameter("glitch_amount", 0.0)
			_billboard_hold_timer = 0.0
			_billboard_hold_target = BILLBOARD_HOLD + randf_range(-BILLBOARD_HOLD_JITTER, BILLBOARD_HOLD_JITTER)
		elif mat != null:
			# Triangular envelope 0 -> 1 -> 0 across the transition.
			mat.set_shader_parameter("glitch_amount", 1.0 - abs(phase * 2.0 - 1.0))
	else:
		_billboard_hold_timer += delta
		if _billboard_hold_timer >= _billboard_hold_target:
			_billboard_in_glitch = true
			_billboard_glitch_time = 0.0
			_billboard_swapped_this_glitch = false

func _process(delta: float) -> void:
	_update_camera(delta)
	_update_billboard(delta)

	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	_refresh_current_interactable()

	# Only run global input polling in headless test runner to maintain test compatibility
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
	else:
		match current_interactable.interaction_id:
			"back_to_apartment":
				scene_transition_requested.emit("apartment", "from_street", {})
			"mailboxes":
				interaction_requested.emit({
					"type": "message",
					"message_text": MESSAGES["mailboxes"]
				})
			"alley_view":
				var quest_status = QuestManager.get_status("alley_backrooms_3f")
				if quest_status == "active":
					if QuestManager.get_step("alley_backrooms_3f") == "started":
						QuestManager.advance("alley_backrooms_3f", "checked_alley")
						interaction_requested.emit({
							"type": "message",
							"message_text": MESSAGES["alley_view_danger"],
							"note_title": "已更新筆記：暗巷三樓的舊物"
						})
					else:
						interaction_requested.emit({
							"type": "message",
							"message_text": MESSAGES["alley_view_danger"]
						})
				elif quest_status == "completed":
					interaction_requested.emit({
						"type": "message",
						"message_text": MESSAGES["alley_view"]
					})
				else: # not_started
					interaction_requested.emit({
						"type": "message",
						"message_text": MESSAGES["alley_view_unstarted"]
					})
			"store_front":
				scene_transition_requested.emit("convenience_store", "from_street", {})
			"vending_machine":
				if GameState.has_flag("vendor_bot_repaired"):
					interaction_requested.emit({
						"type": "shop",
						"shop_id": "street_vending"
					})
				else:
					GameState.set_flag("talked_outside_vendor", true)
					interaction_requested.emit({
						"type": "message",
						"message_text": MESSAGES["vending_machine"]
					})

func _update_camera(delta: float = 0.0) -> void:
	if camera == null:
		return
	camera.global_position = Vector2(
		clamp(player.global_position.x, CAMERA_HALF_WIDTH, MAP_WIDTH - CAMERA_HALF_WIDTH),
		CAMERA_Y
	)
	_update_camera_drift(delta)

func _update_camera_drift(delta: float) -> void:
	_ambience_time += delta
	var is_walking: bool = player.anim.animation == "walk"
	var target_strength := 0.0 if is_walking else 1.0
	_camera_drift_strength = move_toward(_camera_drift_strength, target_strength, delta * CAMERA_DRIFT_FADE_SPEED)
	camera.offset = Vector2(
		sin(_ambience_time * CAMERA_DRIFT_SPEED.x) * CAMERA_DRIFT_AMPLITUDE.x,
		sin(_ambience_time * CAMERA_DRIFT_SPEED.y + 1.3) * CAMERA_DRIFT_AMPLITUDE.y
	) * _camera_drift_strength

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

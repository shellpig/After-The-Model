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

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var ambient_rain: AudioStreamPlayer = $AmbientRain
@onready var ambient_subway: AudioStreamPlayer = $AmbientSubway
@onready var subway_timer: Timer = $SubwayTimer

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_apartment"
var _entry_payload: Dictionary = {}

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

func _start_ambience() -> void:
	if ambient_rain.stream and "loop" in ambient_rain.stream:
		ambient_rain.stream.loop = true
	if not ambient_rain.playing:
		ambient_rain.play()

	subway_timer.timeout.connect(_on_subway_timer_timeout)
	_arm_subway()

func _arm_subway() -> void:
	subway_timer.start(randf_range(SUBWAY_INTERVAL_MIN, SUBWAY_INTERVAL_MAX))

func _on_subway_timer_timeout() -> void:
	var path: String = SUBWAY_RUMBLE_PATHS[randi() % SUBWAY_RUMBLE_PATHS.size()]
	var stream := load(path) as AudioStream
	if stream:
		ambient_subway.stream = stream
		ambient_subway.play()
	_arm_subway()

func _process(_delta: float) -> void:
	_update_camera()

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

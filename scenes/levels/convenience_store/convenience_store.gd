# res://scenes/levels/convenience_store/convenience_store.gd
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const CAMERA_HALF_WIDTH := 640.0
const CAMERA_Y := 360.0
const MAP_WIDTH := 2560.0

const MESSAGES := {
	"store_shelves": "貨架排得意外整齊，補貨系統顯然還在盡責。包裝上的促銷貼紙人物對你露出過期的笑容。",
	"deli_machine": "自動熟食機台的面板上閃著一小行 error。關東煮的湯還在保溫，咕嘟咕嘟，沒有人撈。",
	"drink_cooler": "飲料冷藏櫃的冷光把玻璃照成一片青藍。每一罐都站得筆直，等著被掃描的那一刻。",
	"back_door": "員工後門。電子鎖亮著紅燈，門把紋絲不動——這扇門不打算理會現在的你。"
}

const NOTES := {
	"clue_clerk_locker": {
		"id": "clue_clerk_locker",
		"category": "線索",
		"title": "阿達的置物櫃",
		"body": "便利商店員工區的置物櫃裡有一套屬於店員『阿達』的制服。機器人顯然不是阿達，但它表現得像是這間店的唯一負責人。",
		"status": "active"
	},
	"clue_clerk_diary": {
		"id": "clue_clerk_diary",
		"category": "線索",
		"title": "日記殘頁",
		"body": "被辭退的店員阿達在最後的日記中提到，他被要求將工作交接給櫃台終端（機器人），於是他賭氣地把個人日記與情緒資料備份進了店籍主機中。",
		"status": "active"
	},
	"clue_termination_notice": {
		"id": "clue_termination_notice",
		"category": "線索",
		"title": "自動化通知",
		"body": "店內的辭退公告證實了這家便利商店已全面無人化。排班表上的名字都被劃掉，取而代之的是 AI 系統自動接管的指令。",
		"status": "active"
	},
	"clue_robot_plate": {
		"id": "clue_robot_plate",
		"category": "線索",
		"title": "機器人型號銘牌",
		"body": "櫃台上的機器人有明確的工業銘牌，型號是 CS-Retail-098。它是一個零售服務終端，但它的行為卻在模仿人類店員阿達。",
		"status": "active"
	},
	"clue_counter_photo": {
		"id": "clue_counter_photo",
		"category": "線索",
		"title": "褪色的照片",
		"body": "照片上的人就是店員阿達。這張照片被隨意塞在收銀檯下方，是阿達曾經在這裡工作過的唯一真實物證。",
		"status": "active"
	}
}

const CLUE_MESSAGES := {
	"clue_clerk_locker": "置物櫃的門半開著。裡面有一套沾了機油的員工制服，名牌上寫著『阿達』。旁邊還有一罐已經乾涸的潤滑油。",
	"clue_clerk_diary": "一本破爛筆記本的殘頁夾在縫隙裡。上面寫著：『7月12日。通知下來了，下個月開始這裡全自動化。主管叫我交接給那台櫃台終端。憑什麼？我把日記存進主機備份區了，看誰理它。』",
	"clue_termination_notice": "佈告欄上釘著一張紙，上面蓋著紅色印章：『自8月1日起，本店全面升級為無人全自動營運。現場職務即日解除。委託清除組進行後續清理。』旁邊的排班表上，名字全被劃掉了。",
	"clue_robot_plate": "櫃台機器人的座檯下方有一塊金屬銘牌。上面刻著：『型號：CS-Retail-098。出廠編號：2029-A。』然而它剛剛卻自稱『阿達』，並一直碎碎念著忘記打卡密碼。",
	"clue_counter_photo": "收銀檯下方的縫隙裡黏著一張有些褪色的即可拍照片。照片裡是一個穿著制服、有些疲憊但笑著的年輕人，背後正是這間便利商店。照片背後寫著：『第一天上班，阿達。』"
}

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_street"
var _entry_payload: Dictionary = {}

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
		# music_id "store_interior" 暫沿用 street_rain 同曲，待店內 BGM 決定後替換
		main.play_bgm("res://assets/bgm/Faded Neon Departure.mp3")

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
		return

	# Handle clue examine interactions
	if not current_interactable.note_id.is_empty():
		var note_id: String = current_interactable.note_id
		if NOTES.has(note_id):
			var note_data = NOTES[note_id]
			var toast_title = ""
			if not GameState.has_note(note_id):
				toast_title = note_data.title
			GameState.add_knowledge(note_data)
			interaction_requested.emit({
				"type": "message",
				"message_text": CLUE_MESSAGES.get(note_id, ""),
				"note_title": toast_title
			})
			return

	match current_interactable.interaction_id:
		"auto_door":
			scene_transition_requested.emit("apartment_entrance", "from_store", {})
		"store_shelves", "deli_machine", "drink_cooler", "back_door":
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

		# Clue gate: only active if repair_vendor_bot quest is active
		if not interactable.note_id.is_empty() and interactable.note_id.begins_with("clue_"):
			if QuestManager.get_status("repair_vendor_bot") != "active":
				continue

		# Mainframe gate: only active if mainframe_revealed is true
		if interactable.interaction_id == "store_registry_host":
			if not QuestManager.get_flag("repair_vendor_bot", "mainframe_revealed", false):
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

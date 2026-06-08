extends Node2D

const MESSAGES := GameState.STORY_MESSAGES
const NOTES := GameState.STORY_NOTES

var CONTAINERS := {
	"cabinet_storage": {
		"title": "櫥櫃",
		"cols": 5,
		"rows": 6,
		"skin": "cabinet",
		"panel_position": Vector2(844.0, 64.0)
	},
	"fridge_storage": {
		"title": "冰箱",
		"cols": 5,
		"rows": 2,
		"skin": "fridge",
		"panel_position": Vector2(720.0, 64.0)
	}
}


const MESSAGE_CHARS_PER_SECOND := 12.0
const MESSAGE_PADDING := Vector2(32.0, 20.0)

const OPENING_CHARS_PER_SECOND := 12.0
const OPENING_MONOLOGUES := [
	"[感官甦醒]\n\n耳鳴在腦袋深處擴散。 我貼著發霉的地板，能聞到舊機油與防潮石灰混合的酸澀霉味。 窗外，深夜輕軌的金屬車輪在酸雨裡滑過，發出尖銳且遙遠的摩擦聲。唯有書桌上那台老舊的 CRT 螢幕，還在無聲地閃爍著溫暖的琥珀色光芒。",
	"[空白的記憶]\n\n我想不起來自己是誰。 腦袋裡空無一物，像是一張被反覆磁化、格式化過的空白磁帶。 當我嘗試撐起身體，赤裸的雙手撐在滿是沙塵的木地板上，指尖只傳來麻木與冰冷。沒有記憶，沒有溫度，連每一次呼吸都沉重得像是拖著鐵鍊。",
	"[自囚與尋回]\n\n我掙扎著站起身，生鏽般的關節發出沉悶的喀噠聲。 公寓的大門亮著紅色的閉鎖指示燈。我不記得自己是怎麼進來的，更想不起該怎麼出去。 房間一片死寂，唯有那部 CRT 螢幕無聲地呼吸著。 既然已經退無可退……我就先從這間發霉的溫室開始，把我自己的記憶，一點一點撿回來。"
]

# Signals for Level Interaction Contract
signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

@onready var game_ui: CanvasLayer = _find_game_ui()

func _find_game_ui() -> CanvasLayer:
	var root := get_tree().root if is_inside_tree() else null
	if root:
		var gu = root.find_child("GameUI", true, false)
		if gu:
			return gu
	return null

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "wake_bed"
	_entry_payload = payload.duplicate(true)

func set_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "wake_bed"
	match _entry_point_id:
		"wake_bed":
			pass
		"from_street":
			player.global_position = Vector2(1160.0, 700.0)
			player.anim.play("idle")
		"from_fire_escape":
			player.global_position = Vector2(1000.0, 700.0)
			player.anim.play("idle")


var _entry_point_id: String = "wake_bed"
var _entry_payload: Dictionary = {}
var _opening_monologue_active: bool = false

var _opening_page_index: int = 0
var _opening_page_done: bool = false
var _dev_skip_count: int = 0
var _dev_skip_timer: float = 0.0

@onready var player: Node2D = $Player

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _sonar_active: bool = false
var _sonar_time_left: float = 10.0
var _sonar_dwell_time: float = 0.0
var _sonar_ping_timer: float = 0.0
var sonar_ui: PanelContainer = null
var sonar_label: Label = null
var _audio_ping: AudioStreamPlayer = null
var _audio_reveal: AudioStreamPlayer = null
var _audio_electromagnetic: AudioStreamPlayer = null

var _pending_toast_title: String = ""

func _ready() -> void:
	if not GameState.apartment_initialized:
		GameState.apartment_initialized = true
		# Preload containers for Phase 1-D
		GameState.configure_container("cabinet_storage", 30)  # 5 x 6
		GameState.configure_container("fridge_storage", 10)   # 5 x 2

		var _ok_jacket := GameState.seed_container("cabinet_storage", "faded_jacket", 1)
		var _ok_cabinet_food := GameState.seed_container("cabinet_storage", "canned_food", 2)
		var _ok_fridge_food := GameState.seed_container("fridge_storage", "canned_food", 3)
		var _ok_fridge_blueberry := GameState.seed_container("fridge_storage", "nutrition_bar_synth_blueberry", 1)
		var _ok_rubik := GameState.seed_container("cabinet_storage", "worn_rubiks_cube", 1)

		# Preload inventory robustly
		var has_item := false
		for slot in GameState.get_inventory():
			if not slot.is_empty():
				has_item = true
				break
		if not has_item:
			GameState.add_item("fingerless_gloves", 1)
			GameState.add_item("old_work_badge", 1)

		# Preload 2 story notes for Phase 2
		GameState.add_knowledge({
			"id": "identity_apartment_is_mine",
			"category": "身份",
			"title": "這裡是我的公寓",
			"body": "你雖然不記得名字, 但這裡的氣味、磨損的痕跡、書桌的擺法...都是你熟悉的。",
			"status": "active"
		})
		GameState.add_knowledge({
			"id": "clue_door_sensor_scratch",
			"category": "線索",
			"title": "門旁感應器的刮痕",
			"body": "門旁的感應器有長期使用的刮痕。看起來是右手手套經常碰過的位置。",
			"status": "active"
		})
		GameState.add_knowledge({
			"id": "identity_rainy_night",
			"category": "身份",
			"title": "雨還沒停",
			"body": "雨還在下。窗外的霓虹把積水染成一片溶開的顏色, 像誰把整座城市的記憶倒進了水溝裡。\n房間很安靜, 安靜到能聽見牆裡那點微弱的嗡嗡聲。\nAI 接手了大半個世界之後, 剩下的人就學著在縫隙裡活。我大概也是其中一個。\n有些晚上我會想不起自己是誰, 但只要還記得回到這裡, 好像就還沒真的輸掉什麼。",
			"status": "active"
		})

	# Sonar UI Panel Creation
	sonar_ui = PanelContainer.new()
	sonar_ui.name = "SonarUI"
	sonar_ui.visible = false
	sonar_ui.custom_minimum_size = Vector2(300, 100)
	
	var sonar_style := StyleBoxFlat.new()
	sonar_style.bg_color = Color(0.08, 0.10, 0.12, 0.85)
	sonar_style.border_color = Color(0.78, 0.42, 0.20, 1.0)
	sonar_style.border_width_left = 2
	sonar_style.border_width_top = 2
	sonar_style.border_width_right = 2
	sonar_style.border_width_bottom = 2
	sonar_style.corner_radius_top_left = 4
	sonar_style.corner_radius_top_right = 4
	sonar_style.corner_radius_bottom_left = 4
	sonar_style.corner_radius_bottom_right = 4
	sonar_ui.add_theme_stylebox_override("panel", sonar_style)
	
	var margin_c := MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 16)
	margin_c.add_theme_constant_override("margin_top", 16)
	margin_c.add_theme_constant_override("margin_right", 16)
	margin_c.add_theme_constant_override("margin_bottom", 16)
	sonar_ui.add_child(margin_c)
	
	sonar_label = Label.new()
	sonar_label.name = "SonarLabel"
	sonar_label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84, 1.0))
	margin_c.add_child(sonar_label)
	
	# Create a local canvas layer for sonar UI so it doesn't shift with camera and doesn't pollute GameUI
	var local_canvas := CanvasLayer.new()
	local_canvas.name = "SonarLocalCanvas"
	add_child(local_canvas)
	local_canvas.add_child(sonar_ui)
	
	sonar_ui.anchors_preset = Control.PRESET_CENTER_TOP
	sonar_ui.anchor_left = 0.5
	sonar_ui.anchor_right = 0.5
	sonar_ui.offset_left = -150
	sonar_ui.offset_right = 150
	sonar_ui.offset_top = 80
	sonar_ui.offset_bottom = 180

	# Sonar Audio Players
	_audio_ping = AudioStreamPlayer.new()
	_audio_ping.name = "AudioPing"
	_audio_ping.stream = load("res://assets/sound/sonar_ping.wav")
	_audio_ping.volume_db = 1.0
	add_child(_audio_ping)

	_audio_reveal = AudioStreamPlayer.new()
	_audio_reveal.name = "AudioReveal"
	_audio_reveal.stream = load("res://assets/sound/hidden_slot_reveal.wav")
	_audio_reveal.volume_db = 6.0
	add_child(_audio_reveal)

	_audio_electromagnetic = AudioStreamPlayer.new()
	_audio_electromagnetic.name = "AudioElectromagnetic"
	_audio_electromagnetic.stream = load("res://assets/sound/slot_electromagnetic.wav")
	_audio_electromagnetic.volume_db = 6.0
	add_child(_audio_electromagnetic)

	# 向宿主主控宣告播放 Cozy Night 背景音樂
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.has_method("play_bgm"):
		main.play_bgm("res://assets/bgm/Echoes of a Cozy Night.mp3", 0.0)



	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)

	GameState.item_moved.connect(_on_item_moved)
	GameState.container_changed.connect(_on_container_changed)

	player.anim.animation_finished.connect(_on_player_animation_finished)
	UIMode.mode_changed.connect(_on_ui_mode_changed)

	# Restore persistent puzzle state if already solved
	if GameState.apartment_sonar_revealed:
		var clock = $Interactables.get_node_or_null("ProjectionClockArea")
		if clock:
			nearby_interactables.erase(clock)
			clock.queue_free()
		
		# Ensure the slot container configuration is registered in GameState
		GameState.configure_container("apartment_slot", 1, ["decoder_cube"], true)
		
		CONTAINERS["apartment_slot"] = {
			"title": "隱藏插槽",
			"cols": 1,
			"rows": 1,
			"skin": "cabinet",
			"panel_position": Vector2(782.0, 64.0)
		}
		
		if GameState.apartment_slot_unlocked:
			var slot_area = $Interactables.get_node_or_null("ApartmentSlotArea")
			if slot_area:
				nearby_interactables.erase(slot_area)
				slot_area.queue_free()

	# Start opening monologue sequence if entry point is wake_bed
	if _entry_point_id == "wake_bed":
		_opening_monologue_active = true
		if game_ui:
			game_ui.set_monologue_active(true)
		_opening_page_index = 0
		_opening_page_done = false
		player.anim.play("prone")
		_start_opening_page()
	else:
		_opening_monologue_active = false
		GameState.apartment_beyond_door_bgm_triggered = true
		player.anim.play("idle")
		UIMode.set_mode(UIMode.Mode.NONE)


func _process(_delta: float) -> void:
	_adjust_bgm_volume_dynamics()

	if _opening_monologue_active and not _opening_page_done:
		if game_ui and game_ui.is_message_finished():
			_opening_page_done = true
			_show_page_hint()

	if _sonar_active:
		if UIMode.get_mode() == UIMode.Mode.NONE:
			_sonar_time_left -= _delta
			if _sonar_time_left <= 0.0:
				_stop_sonar(false)
				return
			else:
				var target_x: float = 750.0
				var slot_area := $Interactables.get_node_or_null("ApartmentSlotArea")
				if slot_area:
					target_x = _get_interactable_position(slot_area).x

				var player_x := player.global_position.x
				var dx: float = abs(player_x - target_x)

				var ping_interval: float
				if dx <= 30.0:
					ping_interval = 0.2
				else:
					ping_interval = lerp(0.2, 1.5, clamp((dx - 30.0) / 350.0, 0.0, 1.0))

				_sonar_ping_timer += _delta
				if _sonar_ping_timer >= ping_interval:
					_sonar_ping_timer = 0.0
					_play_sonar_ping()
				
				var strength: float
				if dx <= 30.0:
					strength = 100.0
				else:
					strength = clamp(100.0 - ((dx - 30.0) / 4.0), 0.0, 100.0)

				if dx <= 30.0:
					_sonar_dwell_time += _delta
					if _sonar_dwell_time >= 4.0:
						_reveal_hidden_slot()
						return
				else:
					_sonar_dwell_time = 0.0
				
				sonar_label.text = "聲納探測中...\n強度: %d%%\n定位鎖定: %d%%\n剩餘時間: %.1fs" % [
					int(strength),
					int(clamp((_sonar_dwell_time / 4.0) * 100.0, 0.0, 100.0)),
					_sonar_time_left
				]

	var current_mode := UIMode.get_mode()

	# Layered UI input handling
	if current_mode != UIMode.Mode.NONE:
		if _opening_monologue_active:
			_handle_opening_monologue_input()
		return # Block world actions when UI is open

	_refresh_current_interactable()

	# Only run global input polling in headless test runner to maintain test compatibility
	if DisplayServer.get_name() == "headless":
		if current_interactable != null and Input.is_action_just_pressed("interact_primary"):
			_trigger_interaction()

func _unhandled_input(event: InputEvent) -> void:
	var current_mode := UIMode.get_mode()
	if current_mode != UIMode.Mode.NONE:
		return

	_refresh_current_interactable()
	if current_interactable == null:
		return

	if event.is_action_pressed("interact_primary"):
		get_viewport().set_input_as_handled()
		_trigger_interaction()

func _trigger_interaction() -> void:
	if CONTAINERS.has(current_interactable.interaction_id):
		var c_id = current_interactable.interaction_id
		var c_data = CONTAINERS[c_id]
		interaction_requested.emit({
			"type": "container",
			"container_id": c_id,
			"container_title": c_data.title,
			"container_slot_count": c_data.cols * c_data.rows
		})
	elif not current_interactable.note_id.is_empty():
		var note_id: String = current_interactable.note_id
		if not GameState.has_note(note_id):
			_pending_toast_title = NOTES[note_id].title
		else:
			_pending_toast_title = ""
		GameState.add_knowledge(NOTES[note_id])
		interaction_requested.emit({
			"type": "message",
			"message_text": MESSAGES.get(current_interactable.message_id, ""),
			"note_title": _pending_toast_title
		})
		_pending_toast_title = ""
	else:
		match current_interactable.interaction_id:
			"bed_sleep":
				interaction_requested.emit({
					"type": "message",
					"message_text": MESSAGES.get(current_interactable.message_id, "")
				})
			"door_exit":
				if GameState.apartment_slot_unlocked or GameState.has_knowledge("identity_door_unlock_method"):
					if not GameState.has_knowledge("identity_door_unlock_method"):
						GameState.add_knowledge(NOTES["identity_door_unlock_method"])

						var existing_note: Dictionary = {}
						for note in GameState.get_notes("身份"):
							if note.get("id") == "identity_door_unlock_method":
								existing_note = note
								break
						if not existing_note.is_empty() and not "氣壓大門在背後合上" in existing_note.get("body", ""):
							var updated_note = existing_note.duplicate()
							updated_note.body = existing_note.get("body", "") + "\n\n氣壓大門在背後合上，把這間發霉的安全溫室反鎖在身後。\n迎面而來的是深夜的冷雨，高架軌道上輕軌呼嘯而過，將鐵鏽與酸雨的水霧灑在我的護目鏡上。下層街區的霓虹招柄在積水裡折射出廉價的青色與桃紅。\n這裡沒有陽光，沒有申訴管道，只有成千上萬在 AI 陰影下掙扎討生活的普通人。\n我踏進了水窪，邁向雨夜。已經沒有回頭路了，我的名字與記憶，一定就藏在這座城市的某個夜班角落。"
							GameState.add_knowledge(updated_note)
							_pending_toast_title = "已更新筆記：我鎖上的門"
						
						interaction_requested.emit({
							"type": "message",
							"message_text": MESSAGES.get("door_opened", ""),
							"note_title": _pending_toast_title,
							"on_closed": func():
								scene_transition_requested.emit("apartment_entrance", "from_apartment", {})
						})

						_pending_toast_title = ""
						if not GameState.apartment_beyond_door_bgm_triggered:
							GameState.apartment_beyond_door_bgm_triggered = true
							_trigger_bgm_transition()
					else:
						scene_transition_requested.emit("apartment_entrance", "from_apartment", {})
				else:
					interaction_requested.emit({
						"type": "message",
						"message_text": MESSAGES.get("door_locked", "")
					})
			"projection_clock":
				_start_sonar()
			"apartment_slot":
				var c_id = "apartment_slot"
				var c_data = CONTAINERS[c_id]
				interaction_requested.emit({
					"type": "container",
					"container_id": c_id,
					"container_title": c_data.title,
					"container_slot_count": c_data.cols * c_data.rows
				})
			"fire_escape_window":
				scene_transition_requested.emit("apartment_fire_escape", "from_window", {})

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

		# If the interactable has a note associated with it, and the player already has that note,
		# disable any further interaction.
		if not interactable.note_id.is_empty() and GameState.has_note(interactable.note_id):
			continue

		if interactable.interaction_id == "projection_clock" and (not GameState.has_note("clue_projection_clock") or GameState.apartment_sonar_revealed):
			continue
		if interactable.interaction_id == "apartment_slot" and (not GameState.apartment_sonar_revealed or GameState.apartment_slot_unlocked):
			continue
		if interactable.interaction_id == "fire_escape_window" and not _is_fire_escape_window_available():
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

func _find_item_id_anywhere(instance_id: String) -> String:
	for slot in GameState.get_inventory():
		if slot.get("instance_id", "") == instance_id:
			return slot.get("item_id", "")
	for c_id in GameState.external_containers.keys():
		for slot in GameState.get_container(c_id):
			if slot.get("instance_id", "") == instance_id:
				return slot.get("item_id", "")
	return ""

func _player_has_decoding_ability() -> bool:
	var eq := GameState.get_equipment()
	var hand_instances: Array = eq.get("hand", [])
	for instance_id in hand_instances:
		var item_id := _find_item_id_anywhere(instance_id)
		if not item_id.is_empty():
			var item_meta: Dictionary = GameState.ITEMS_DB.get(item_id, {})
			if item_meta.get("can_decode", false):
				return true
	return false

func _execute_item_decoding(instance_id: String, target_item_id: String) -> void:
	var success = GameState.change_item_id(instance_id, target_item_id)
	if success:
		GameState.add_knowledge(NOTES["clue_decoder_cube"])
		_play_electromagnetic_sound()
		interaction_requested.emit({
			"type": "message",
			"message_text": MESSAGES["decoder_cube_decoded"]
		})

func _on_item_moved(move: Dictionary) -> void:
	var target_container_id: String = move.get("target_container_id", "")
	var item_id: String = move.get("item_id", "")
	var target_instance_id: String = move.get("target_instance_id", "")

	if target_container_id == "player_inventory":
		var item_meta: Dictionary = GameState.ITEMS_DB.get(item_id, {})
		var decodable_to: String = item_meta.get("decodable_to", "")
		if not decodable_to.is_empty() and _player_has_decoding_ability():
			_execute_item_decoding(target_instance_id, decodable_to)

func _on_container_changed(container_id: String) -> void:
	if container_id == "apartment_slot":
		var items := GameState.get_container("apartment_slot")
		if items.size() > 0 and not items[0].is_empty() and items[0].get("item_id", "") == "decoder_cube":
			if not GameState.apartment_slot_unlocked:
				GameState.apartment_slot_unlocked = true
				_play_electromagnetic_sound()
				interaction_requested.emit({
					"type": "message",
					"message_text": MESSAGES["slot_unlocked"]
				})

func _play_sonar_ping() -> void:
	if _audio_ping and _audio_ping.stream:
		_audio_ping.play()
	else:
		print("[Sonar Ping] beep!")

func _play_sonar_reveal() -> void:
	if _audio_reveal and _audio_reveal.stream:
		_audio_reveal.play()
	else:
		print("[Sonar Reveal] CHIRP! Hidden Slot Revealed.")

func _play_electromagnetic_sound() -> void:
	if _audio_electromagnetic and _audio_electromagnetic.stream:
		_audio_electromagnetic.play()
	else:
		print("[Slot Electromagnetic] CLANK! Electromagnetic Lock Connected.")

func _start_sonar() -> void:
	if GameState.apartment_sonar_revealed:
		return
	_sonar_active = true
	_sonar_time_left = 10.0
	_sonar_dwell_time = 0.0
	_sonar_ping_timer = 0.0
	sonar_ui.visible = true
	current_interactable_changed.emit({})

func _stop_sonar(revealed: bool) -> void:
	_sonar_active = false
	sonar_ui.visible = false
	if not revealed:
		FloatingToast.show_toast("聲納超時關閉，定位失敗。", player)
		_refresh_current_interactable()

func _reveal_hidden_slot() -> void:
	_stop_sonar(true)
	GameState.apartment_sonar_revealed = true
	_play_sonar_reveal()

	# Completely remove projection clock interaction
	var clock = $Interactables.get_node_or_null("ProjectionClockArea")
	if clock:
		nearby_interactables.erase(clock)
		clock.queue_free()
	
	# Configure slot container in GameState
	GameState.configure_container("apartment_slot", 1, ["decoder_cube"], true)
	
	# Dynamic insertion in CONTAINERS DB
	CONTAINERS["apartment_slot"] = {
		"title": "隱藏插槽",
		"cols": 1,
		"rows": 1,
		"skin": "cabinet",
		"panel_position": Vector2(782.0, 64.0)
	}

	# Force prompt update
	_refresh_current_interactable()
	
	FloatingToast.show_toast("成功鎖定！牆內滑動插槽已開啟。", player)

func _on_player_animation_finished() -> void:
	if _opening_monologue_active and player.anim.animation == "get_up":
		player.anim.play("idle")

func _start_opening_page() -> void:
	_opening_page_done = false
	
	if _opening_page_index == 2:
		player.anim.play("get_up")
	
	var text = OPENING_MONOLOGUES[_opening_page_index]
	if game_ui:
		game_ui.begin_message(text, {"chars_per_second": OPENING_CHARS_PER_SECOND})
		game_ui.set_message_page_hint("", false)

func _show_page_hint() -> void:
	if game_ui:
		var hint_text = "▼ 開始" if _opening_page_index == 2 else "▼ 繼續"
		game_ui.set_message_page_hint(hint_text, true)

func _advance_opening_page() -> void:
	_opening_page_index += 1
	if _opening_page_index >= OPENING_MONOLOGUES.size():
		_end_opening_monologue()
	else:
		_start_opening_page()

func _skip_opening_page() -> void:
	if not _opening_monologue_active:
		return
	
	_opening_page_done = true
	if game_ui:
		game_ui.force_finish_message()
	_advance_opening_page()

func _end_opening_monologue() -> void:
	_opening_monologue_active = false
	if game_ui:
		game_ui.set_monologue_active(false)
		game_ui.close_message()
	UIMode.set_mode(UIMode.Mode.NONE)
	player.anim.play("idle")
	_refresh_current_interactable()

func _handle_opening_monologue_input() -> void:
	# Debug skip: T key 3 times in 1 second
	if Input.is_action_just_pressed("interact_tertiary"):
		var now := Time.get_ticks_msec() / 1000.0
		if now - _dev_skip_timer > 1.0:
			_dev_skip_count = 1
		else:
			_dev_skip_count += 1
		
		_dev_skip_timer = now
		
		if _dev_skip_count >= 3:
			_dev_skip_count = 0
			_skip_opening_page()
			return

	if _opening_page_done:
		var page_turn_pressed := (
			Input.is_action_just_pressed("move_left") or
			Input.is_action_just_pressed("move_right") or
			Input.is_action_just_pressed("move_up") or
			Input.is_action_just_pressed("move_down") or
			Input.is_action_just_pressed("ui_left") or
			Input.is_action_just_pressed("ui_right") or
			Input.is_action_just_pressed("ui_up") or
			Input.is_action_just_pressed("ui_down") or
			Input.is_action_just_pressed("ui_accept") or
			Input.is_action_just_pressed("interact_primary") or
			Input.is_action_just_pressed("ui_cancel")
		)
		if page_turn_pressed:
			_advance_opening_page()
	else:
		var finish_pressed := (
			Input.is_action_just_pressed("interact_primary") or
			Input.is_action_just_pressed("ui_accept") or
			Input.is_action_just_pressed("ui_cancel")
		)
		if finish_pressed:
			if game_ui:
				game_ui.force_finish_message()
			_opening_page_done = true
			_show_page_hint()

func _adjust_bgm_volume_dynamics() -> void:
	if GameState.apartment_beyond_door_bgm_triggered:
		return
	var main = get_tree().root.find_child("Main", true, false)
	var bgm_player: AudioStreamPlayer = null
	if main and main.has_method("get_active_bgm_player"):
		bgm_player = main.get_active_bgm_player()
	if is_instance_valid(bgm_player) and bgm_player.playing:
		var pos := bgm_player.get_playback_position()
		if pos < 6.5:
			bgm_player.volume_db = 5.0
		elif pos >= 6.5 and pos < 8.0:
			var t := pos - 6.5
			bgm_player.volume_db = lerp(0.0, -8.0, t)
		else:
			bgm_player.volume_db = -8.0

func _trigger_bgm_transition() -> void:
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.has_method("play_bgm"):
		main.play_bgm("res://assets/bgm/Faded Neon Departure.mp3", 5.0)

func _is_fire_escape_window_available() -> bool:
	var status := QuestManager.get_status("alley_backrooms_3f")
	if status == "completed" or status == "failed":
		return true
	return status == "active" \
		and QuestManager.get_step("alley_backrooms_3f") == "checked_alley"

func _on_ui_mode_changed(new_mode: int) -> void:
	if new_mode == UIMode.Mode.NONE and GameState.apartment_slot_unlocked:
		var slot_area = $Interactables.get_node_or_null("ApartmentSlotArea")
		if slot_area:
			nearby_interactables.erase(slot_area)
			slot_area.queue_free()
			_refresh_current_interactable()

# res://scenes/ui/ending_epilogue.gd
extends Control

@onready var blackout_rect: ColorRect = $BlackoutRect
@onready var bg_rect: ColorRect = $Background
@onready var cg_texture: TextureRect = $CgTexture
@onready var text_overlay: Control = $TextOverlay
@onready var dialogue_label: RichTextLabel = $TextOverlay/DialogueLabel
@onready var page_hint_label: Label = $TextOverlay/PageHintLabel
@onready var credits_container: Control = $CreditsContainer
@onready var credits_label: RichTextLabel = $CreditsContainer/CreditsLabel
@onready var audio_rain: AudioStreamPlayer = $AudioRain
@onready var audio_song: AudioStreamPlayer = $AudioSong

var _ending_id: String = ""
var _is_peace: bool = false
var _step: int = 0 # 0: Fade-in, 1: Beat 1 (Shared P1-P2), 2: Beat 2 (Orange), 3: Beat 3 (Final), 4: Credits
var _sub_page: int = 0 # 拍 1 子頁數

var _full_text: String = ""
var _displayed_text: String = ""
var _typewriter_elapsed: float = 0.0
var _char_index: int = 0
const CHARS_PER_SECOND := 12.0
var _typewriter_finished: bool = false

var _credits_scroll_y: float = 0.0
var _credits_speed_mult: float = 1.0
var _credits_finished: bool = false

const CREDITS_SECTIONS := [
	{
		"title": "UI_CREDITS_DEVELOPER",
		"names": ["DeepMind Team"]
	},
	{
		"title": "UI_CREDITS_ENGINE",
		"names": ["Godot Engine 4.6.3"]
	},
	{
		"title": "UI_CREDITS_MUSIC",
		"names": [
			"Beyond the Door",
			"Echoes of a Cozy Night",
			"Faded Neon Departure",
			"Heartbeat of the Machine",
			"The Yellow Light Tape",
			"The Deleted Still Breathe",
			"Echo Song: Rain Doesn't Stop"
		]
	},
	{
		"title": "UI_CREDITS_ASSETS",
		"names": [
			"agent-sprite-forge",
			"Riso-inspired Generative Art Pipeline"
		]
	},
	{
		"title": "UI_CREDITS_SPECIAL_THANKS",
		"names": ["The Player", "Advanced Agentic Coding Team"]
	}
]

func _ready() -> void:
	visible = false
	blackout_rect.visible = false
	credits_container.visible = false
	audio_rain.stream = load("res://assets/audio/ambient/street_rain_loop.mp3")
	audio_song.stream = load("res://assets/audio/echoes/echo_song_rain_doesnt_stop.mp3")
	
func start_epilogue() -> void:
	# 讀取結局狀態
	if GameState.get_flag("ending_reclaim_played", false):
		_ending_id = "reclaim"
	elif GameState.get_flag("ending_protect_played", false):
		_ending_id = "protect"
	elif GameState.get_flag("ending_expose_a_played", false):
		_ending_id = "expose_a"
	elif GameState.get_flag("ending_expose_b_played", false):
		_ending_id = "expose_b"
	elif GameState.get_flag("ending_expose_c_played", false):
		_ending_id = "expose_c"
	else:
		_ending_id = "reclaim" # Fallback

	_is_peace = GameState.get_flag("seven_peace_branch_d", false)
	_step = 0
	_sub_page = 0
	visible = true
	
	# 音訊播放
	audio_rain.play()
	audio_song.play()
	
	# BGM fade out
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.has_method("fade_out_bgm"):
		main.fade_out_bgm(1.5)
	
	# 淡黑接手
	blackout_rect.visible = true
	blackout_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	text_overlay.visible = false
	cg_texture.texture = null
	
	UIMode.set_mode(UIMode.Mode.MESSAGE) # 全程鎖定輸入狀態
	
	var fade_time := 2.0
	if DisplayServer.get_name() == "headless":
		fade_time = 0.0
		
	var tw := create_tween()
	tw.tween_property(blackout_rect, "color:a", 1.0, fade_time)
	tw.tween_callback(func():
		_start_beat_1()
	)

func _start_beat_1() -> void:
	_step = 1
	_sub_page = 0
	blackout_rect.visible = false
	text_overlay.visible = true
	
	var path := "res://assets/generated/maps/cg_ending_street_wide/cg_ending_street_wide.png"
	cg_texture.texture = load(path)
	_show_page("MSG_ENDING_SHARED_P1")

func _start_beat_2() -> void:
	_step = 2
	var path := "res://assets/generated/maps/cg_ending_orange_%s/cg_ending_orange_%s.png" % [_ending_id, _ending_id]
	cg_texture.texture = load(path)
	
	var key := ""
	if _is_peace:
		key = "MSG_ENDING_ORANGE_%s_PEACE" % [_ending_id.to_upper()]
	else:
		key = "MSG_ENDING_ORANGE_%s" % [_ending_id.to_upper()]
	_show_page(key)

func _start_beat_3() -> void:
	_step = 3
	var path := "res://assets/generated/maps/cg_ending_final_%s/cg_ending_final_%s.png" % [_ending_id, _ending_id]
	cg_texture.texture = load(path)
	_show_page("MSG_ENDING_FINAL_LINE")

func _start_credits() -> void:
	_step = 4
	text_overlay.visible = false
	cg_texture.texture = null
	credits_container.visible = true
	
	# 歌 fade out，雨聲墊底
	var song_tween := create_tween()
	var fade_time := 1.5
	if DisplayServer.get_name() == "headless":
		fade_time = 0.0
	song_tween.tween_property(audio_song, "volume_db", -40.0, fade_time)
	song_tween.tween_callback(func():
		audio_song.stop()
	)
	
	# 建立 credits bbcode 文字
	var text_lines := []
	text_lines.append("[center]")
	text_lines.append("[font_size=40][b]After-The-Model[/b][/font_size]")
	text_lines.append("\n\n\n\n")
	
	for section in CREDITS_SECTIONS:
		text_lines.append("[font_size=24][color=#c76b33][b]%s[/b][/color][/font_size]" % tr(section.title))
		text_lines.append("")
		for name in section.names:
			text_lines.append("[font_size=20]%s[/font_size]" % name)
		text_lines.append("\n\n\n")
		
	text_lines.append("\n\n\n\n")
	text_lines.append("[font_size=24][i]Thank You For Playing[/i][/font_size]")
	text_lines.append("[/center]")
	
	credits_label.text = "\n".join(text_lines)
	credits_label.position.y = size.y
	_credits_scroll_y = size.y
	_credits_finished = false
	
	if DisplayServer.get_name() == "headless":
		_finish_epilogue_entirely()

func _finish_epilogue_entirely() -> void:
	audio_rain.stop()
	audio_song.stop()
	credits_container.visible = false
	visible = false
	
	# 回標題畫面
	if DisplayServer.get_name() == "headless":
		var main_node = get_parent()
		while main_node and not main_node.has_method("get_current_scene_id"):
			main_node = main_node.get_parent()
		if main_node:
			main_node._current_scene_id = "title_screen"
	else:
		get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")

func _show_page(key: String) -> void:
	_full_text = tr(key)
	_typewriter_elapsed = 0.0
	_char_index = 0
	_typewriter_finished = false
	dialogue_label.text = ""
	page_hint_label.text = ""
	
	if DisplayServer.get_name() == "headless":
		_typewriter_finished = true
		dialogue_label.text = _full_text
		page_hint_label.text = tr("UI_MSG_CONTINUE_HINT")

func _process(delta: float) -> void:
	if not visible:
		return
		
	if _step in [1, 2, 3]:
		if not _typewriter_finished:
			_typewriter_elapsed += delta
			var count = int(_typewriter_elapsed * CHARS_PER_SECOND)
			if count > _char_index:
				_char_index = count
				if _char_index >= _full_text.length():
					_char_index = _full_text.length()
					_typewriter_finished = true
					page_hint_label.text = tr("UI_MSG_CONTINUE_HINT")
				dialogue_label.text = _full_text.substr(0, _char_index)
				
		# 推進輸入
		var advance_pressed := (
			Input.is_action_just_pressed("interact_primary") or
			Input.is_action_just_pressed("ui_accept")
		)
		if advance_pressed:
			if not _typewriter_finished:
				# 一鍵秀完
				_typewriter_finished = true
				_char_index = _full_text.length()
				dialogue_label.text = _full_text
				page_hint_label.text = tr("UI_MSG_CONTINUE_HINT")
			else:
				_advance_page()
				
	elif _step == 4:
		# Credits 滾動
		_credits_speed_mult = 4.0 if (
			Input.is_action_pressed("interact_primary") or
			Input.is_action_pressed("ui_accept")
		) else 1.0
		
		# 每一秒上移 50 像素
		var scroll_speed = 50.0 * _credits_speed_mult * delta
		_credits_scroll_y -= scroll_speed
		credits_label.position.y = _credits_scroll_y
		
		# 檢查是否滾完 (文字高度 + label 座標都跑出了螢幕)
		var label_size = credits_label.get_minimum_size()
		if _credits_scroll_y + label_size.y < 0:
			_credits_finished = true
			
		# 若已經滾動完，或者玩家在滾完後再次點擊即可結束
		var click_to_skip := (
			Input.is_action_just_pressed("interact_primary") or
			Input.is_action_just_pressed("ui_accept")
		)
		if _credits_finished or (_credits_scroll_y < size.y - 200 and click_to_skip):
			_finish_epilogue_entirely()

func _advance_page() -> void:
	if _step == 1:
		_sub_page += 1
		if _sub_page == 1:
			_show_page("MSG_ENDING_SHARED_P2")
		else:
			_start_beat_2()
	elif _step == 2:
		_start_beat_3()
	elif _step == 3:
		# 拍 3 結束，寫入 meta 成就並進入 credits
		GameState.mark_ending_achieved(_ending_id)
		_start_credits()

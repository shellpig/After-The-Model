extends Control

signal back_pressed

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var slots_vbox: VBoxContainer = $Panel/VBoxContainer/SlotsVBox
@onready var btn_back: Button = $Panel/VBoxContainer/BtnBack
@onready var footer_hint_label: Label = $Panel/VBoxContainer/FooterHintLabel

var is_save_mode: bool = false
var _buttons: Array[Button] = []

func _ready() -> void:
	# Populate buttons array
	_buttons.clear()
	for child in slots_vbox.get_children():
		if child is Button:
			_buttons.append(child)
			
	# Connect button signals
	for i in range(_buttons.size()):
		var btn = _buttons[i]
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_slot_button_pressed.bind(i + 1))
		
	btn_back.pressed.connect(_on_back_pressed)
	btn_back.focus_mode = Control.FOCUS_ALL
	
	_apply_theme_style()

func _apply_theme_style() -> void:
	# Panel background (deep teal-black with solid slate border)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.10, 0.12, 0.95)
	panel_style.border_color = Color(0.22, 0.28, 0.29, 0.90)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	$Panel.add_theme_stylebox_override("panel", panel_style)

	# Label styling
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84, 1.0)) # Faded cream
	
	footer_hint_label.add_theme_font_size_override("font_size", 14)
	footer_hint_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6, 0.8)) # Desaturated gray-blue
	
	# Button styles
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.12, 0.14, 0.16, 0.6)
	btn_normal.border_color = Color(0.22, 0.28, 0.29, 0.85)
	btn_normal.border_width_left = 1
	btn_normal.border_width_top = 1
	btn_normal.border_width_right = 1
	btn_normal.border_width_bottom = 1
	btn_normal.corner_radius_top_left = 2
	btn_normal.corner_radius_top_right = 2
	btn_normal.corner_radius_bottom_left = 2
	btn_normal.corner_radius_bottom_right = 2
	btn_normal.content_margin_left = 15
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_bottom = 8

	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.16, 0.19, 0.21, 0.8)
	btn_hover.border_color = Color(0.78, 0.42, 0.20, 1.0) # Saturated burnt orange focus

	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(0.78, 0.42, 0.20, 0.3)
	btn_pressed.border_color = Color(0.78, 0.42, 0.20, 1.0)
	
	# Apply style to slot buttons and back button
	var buttons_to_style = []
	buttons_to_style.append_array(_buttons)
	buttons_to_style.append(btn_back)
	
	for btn in buttons_to_style:
		btn.add_theme_stylebox_override("normal", btn_normal)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("focus", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_pressed)
		btn.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84, 0.90))
		btn.add_theme_color_override("font_hover_color", Color(0.94, 0.92, 0.84, 1.0))
		btn.add_theme_color_override("font_focus_color", Color(0.94, 0.92, 0.84, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.78, 0.42, 0.20, 1.0))
		btn.add_theme_font_size_override("font_size", 16)

func initialize(is_save: bool) -> void:
	is_save_mode = is_save
	title_label.text = "— 選擇存檔槽 (儲存) —" if is_save_mode else "— 選擇存檔槽 (載入) —"
	refresh_list()
	
	# Grab initial focus on the first button or back button
	if _buttons.size() > 0:
		var first_available = null
		for btn in _buttons:
			if not btn.disabled:
				first_available = btn
				break
		if first_available:
			first_available.grab_focus()
		else:
			btn_back.grab_focus()
	else:
		btn_back.grab_focus()

func refresh_list() -> void:
	var slots = SaveSystem.list_slots()
	for i in range(_buttons.size()):
		var btn = _buttons[i]
		var slot_idx = i + 1
		var slot_data = slots[i]
		
		# Set text and state based on mode and metadata
		if slot_data.get("empty", true):
			btn.text = "存檔槽 %02d  [ 空白 ]" % slot_idx
			if is_save_mode:
				btn.disabled = false
				btn.modulate = Color(1, 1, 1, 1)
			else:
				btn.disabled = true
				btn.modulate = Color(1, 1, 1, 0.4) # Faded for disabled
		elif slot_data.get("corrupt", false):
			btn.text = "存檔槽 %02d  [ 損毀 / 版本不符 ]" % slot_idx
			if is_save_mode:
				btn.disabled = false
				btn.modulate = Color(1, 0.3, 0.3, 1) # Red tint for overwriting corrupt slot
			else:
				btn.disabled = true
				btn.modulate = Color(1, 0.3, 0.3, 0.4)
		else:
			var meta = slot_data["meta"]
			var scene_name = meta.get("scene_name", "未知關卡")
			var credits_val = meta.get("credits", 0)
			var timestamp = meta.get("timestamp", 0)
			
			# Format timestamp
			var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
			var time_str = "%04d-%02d-%02d %02d:%02d" % [
				datetime["year"], datetime["month"], datetime["day"],
				datetime["hour"], datetime["minute"]
			]
			
			btn.text = "存檔槽 %02d  |  %s  |  %d CR  |  %s" % [slot_idx, scene_name, credits_val, time_str]
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1)

func _on_slot_button_pressed(slot: int) -> void:
	var slots = SaveSystem.list_slots()
	var slot_data = slots[slot - 1]
	
	if is_save_mode:
		if slot_data.get("empty", true) or slot_data.get("corrupt", false):
			_perform_save(slot)
		else:
			# Needs overwrite confirmation
			_confirm_overwrite(slot)
	else:
		if not slot_data.get("empty", true) and not slot_data.get("corrupt", false):
			_perform_load(slot)

func _perform_save(slot: int) -> void:
	var main = get_tree().root.find_child("Main", true, false)
	if not main:
		push_error("SaveSlotList: Main instance not found in scene tree!")
		return
		
	var scene_id = main.get_current_scene_id()
	var world_root = main.get_node("WorldRoot")
	var player_node = world_root.find_child("Player", true, false)
	
	var player_x = 0.0
	var facing = 1
	if player_node:
		if player_node.has_method("get_save_x"):
			player_x = player_node.get_save_x()
		else:
			player_x = player_node.global_position.x
			
		if player_node.has_method("get_facing"):
			facing = player_node.get_facing()
		elif "facing" in player_node:
			facing = player_node.facing
			
	var payload = SaveSystem.capture(scene_id, player_x, facing)
	var success = SaveSystem.write_slot(slot, payload)
	
	var game_ui = get_tree().root.find_child("GameUI", true, false)
	if success:
		if game_ui and game_ui.has_method("show_toast"):
			game_ui.show_toast("儲存成功！", self)
		refresh_list()
		# Refocus button after save
		_buttons[slot - 1].grab_focus()
	else:
		if game_ui and game_ui.has_method("show_toast"):
			game_ui.show_toast("儲存失敗！", self)

func _confirm_overwrite(slot: int) -> void:
	var game_ui = get_tree().root.find_child("GameUI", true, false)
	if game_ui and game_ui.has_node("ConfirmDialog"):
		var confirm_dialog = game_ui.get_node("ConfirmDialog")
		
		# Set UIMode to CONFIRM, which handles overlay state
		UIMode.enter_confirm()
		
		confirm_dialog.show_dialog(
			"確定要覆蓋此存檔？",
			func():
				_perform_save(slot),
			_buttons[slot - 1],
			slot - 1
		)

func _perform_load(slot: int) -> void:
	var main = get_tree().root.find_child("Main", true, false)
	if main:
		var success = main.load_game_slot(slot)
		if success:
			back_pressed.emit()
		else:
			var game_ui = get_tree().root.find_child("GameUI", true, false)
			if game_ui and game_ui.has_method("show_message"):
				game_ui.show_message("載入失敗：存檔無效或損毀！")
	else:
		# We are in Title Screen (no Main exists)
		var payload = SaveSystem.read_slot(slot)
		if payload.is_empty() or not SaveSystem.validate(payload):
			# Invalid save, do not load
			return
			
		# Set pending load and transition scene
		SaveSystem.pending_load_slot = slot
		TouchControls.set_force_hidden(false)
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_back_pressed() -> void:
	back_pressed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	var game_ui = get_tree().root.find_child("GameUI", true, false)
	if game_ui and game_ui.has_node("ConfirmDialog") and game_ui.get_node("ConfirmDialog").visible:
		return

	var vp = get_viewport()
	if not vp:
		return

	if event.is_action_pressed("move_up"):
		var focused = vp.gui_get_focus_owner()
		var idx = _buttons.find(focused)
		if idx != -1:
			var found_prev = false
			for prev_idx in range(idx - 1, -1, -1):
				if not _buttons[prev_idx].disabled:
					_buttons[prev_idx].grab_focus()
					vp.set_input_as_handled()
					found_prev = true
					break
			if not found_prev:
				btn_back.grab_focus()
				vp.set_input_as_handled()
		elif focused == btn_back:
			var found_prev = false
			for last_idx in range(_buttons.size() - 1, -1, -1):
				if not _buttons[last_idx].disabled:
					_buttons[last_idx].grab_focus()
					vp.set_input_as_handled()
					found_prev = true
					break
			if not found_prev:
				vp.set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		var focused = vp.gui_get_focus_owner()
		var idx = _buttons.find(focused)
		if idx != -1:
			var found_next = false
			for next_idx in range(idx + 1, _buttons.size()):
				if not _buttons[next_idx].disabled:
					_buttons[next_idx].grab_focus()
					vp.set_input_as_handled()
					found_next = true
					break
			if not found_next:
				btn_back.grab_focus()
				vp.set_input_as_handled()
		elif focused == btn_back:
			var found_next = false
			for first_idx in range(0, _buttons.size()):
				if not _buttons[first_idx].disabled:
					_buttons[first_idx].grab_focus()
					vp.set_input_as_handled()
					found_next = true
					break
			if not found_next:
				vp.set_input_as_handled()
	elif event.is_action_pressed("interact_primary"):
		var focused = vp.gui_get_focus_owner()
		var idx = _buttons.find(focused)
		if idx != -1:
			vp.set_input_as_handled()
			_on_slot_button_pressed(idx + 1)
		elif focused == btn_back:
			vp.set_input_as_handled()
			_on_back_pressed()
	elif event.is_action_pressed("ui_cancel"):
		vp.set_input_as_handled()
		_on_back_pressed()

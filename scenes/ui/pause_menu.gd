extends Control

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var btn_resume: Button = $Panel/VBoxContainer/ButtonsVBox/BtnResume
@onready var btn_save: Button = $Panel/VBoxContainer/ButtonsVBox/BtnSave
@onready var btn_load: Button = $Panel/VBoxContainer/ButtonsVBox/BtnLoad
@onready var btn_title: Button = $Panel/VBoxContainer/ButtonsVBox/BtnTitle
@onready var buttons_vbox: VBoxContainer = $Panel/VBoxContainer/ButtonsVBox
@onready var footer_hint_label: Label = $Panel/VBoxContainer/FooterHintLabel

@onready var save_slot_list: Control = $SaveSlotList

func _ready() -> void:
	save_slot_list.visible = false
	save_slot_list.back_pressed.connect(_on_save_slot_list_back)
	
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_title.pressed.connect(_on_title_pressed)
	
	for btn in [btn_resume, btn_save, btn_load, btn_title]:
		btn.focus_mode = Control.FOCUS_ALL
		
	_apply_theme_style()

func initialize_menu() -> void:
	save_slot_list.visible = false
	buttons_vbox.visible = true
	footer_hint_label.visible = true
	btn_resume.grab_focus()

func _on_resume_pressed() -> void:
	UIMode.set_mode(UIMode.Mode.NONE)

func _on_save_pressed() -> void:
	# Check SaveSystem.can_save_here gate
	if not SaveSystem.can_save_here:
		var game_ui = get_tree().root.find_child("GameUI", true, false)
		if game_ui and game_ui.has_method("show_toast"):
			game_ui.show_toast("目前區域無法儲存進度！", self)
		return
		
	buttons_vbox.visible = false
	footer_hint_label.visible = false
	save_slot_list.visible = true
	save_slot_list.initialize(true) # Save mode

func _on_load_pressed() -> void:
	buttons_vbox.visible = false
	footer_hint_label.visible = false
	save_slot_list.visible = true
	save_slot_list.initialize(false) # Load mode

func _on_save_slot_list_back() -> void:
	save_slot_list.visible = false
	buttons_vbox.visible = true
	footer_hint_label.visible = true
	btn_save.grab_focus()

func _on_title_pressed() -> void:
	var game_ui = get_tree().root.find_child("GameUI", true, false)
	if game_ui and game_ui.has_node("ConfirmDialog"):
		var confirm_dialog = game_ui.get_node("ConfirmDialog")
		
		# Set UIMode to CONFIRM, which handles overlay state
		UIMode.enter_confirm()
		
		confirm_dialog.show_dialog(
			"確定返回標題畫面？\n(未儲存的進度將會遺失)",
			func():
				UIMode.set_mode(UIMode.Mode.NONE)
				get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn"),
			btn_title,
			3
		)

func _apply_theme_style() -> void:
	# Background Panel style
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.10, 0.12, 0.95)
	bg_style.border_color = Color(0.22, 0.28, 0.29, 0.90)
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	$Panel.add_theme_stylebox_override("panel", bg_style)
	
	# Title styling
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.78, 0.42, 0.20, 1.0)) # Saturated burnt orange
	
	# Footer styling
	footer_hint_label.add_theme_font_size_override("font_size", 14)
	footer_hint_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6, 0.8)) # Desaturated gray-blue
	
	# Button styling
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
	btn_normal.content_margin_left = 20
	btn_normal.content_margin_top = 10
	btn_normal.content_margin_right = 20
	btn_normal.content_margin_bottom = 10

	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.16, 0.19, 0.21, 0.8)
	btn_hover.border_color = Color(0.78, 0.42, 0.20, 1.0) # Active focus border color

	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(0.78, 0.42, 0.20, 0.3)
	btn_pressed.border_color = Color(0.78, 0.42, 0.20, 1.0)
	
	for btn in [btn_resume, btn_save, btn_load, btn_title]:
		btn.add_theme_stylebox_override("normal", btn_normal)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("focus", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_pressed)
		btn.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84, 0.90))
		btn.add_theme_color_override("font_hover_color", Color(0.94, 0.92, 0.84, 1.0))
		btn.add_theme_color_override("font_focus_color", Color(0.94, 0.92, 0.84, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.78, 0.42, 0.20, 1.0))
		btn.add_theme_font_size_override("font_size", 18)

func _input(event: InputEvent) -> void:
	if not visible or save_slot_list.visible:
		return
		
	var game_ui = get_tree().root.find_child("GameUI", true, false)
	if game_ui and game_ui.has_node("ConfirmDialog") and game_ui.get_node("ConfirmDialog").visible:
		return

	var buttons = [btn_resume, btn_save, btn_load, btn_title]
	if event.is_action_pressed("move_up"):
		var focused = get_viewport().gui_get_focus_owner()
		var idx = buttons.find(focused)
		if idx > 0:
			buttons[idx - 1].grab_focus()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		var focused = get_viewport().gui_get_focus_owner()
		var idx = buttons.find(focused)
		if idx != -1 and idx < buttons.size() - 1:
			buttons[idx + 1].grab_focus()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact_primary"):
		var focused = get_viewport().gui_get_focus_owner()
		if focused == btn_resume:
			_on_resume_pressed()
			get_viewport().set_input_as_handled()
		elif focused == btn_save:
			_on_save_pressed()
			get_viewport().set_input_as_handled()
		elif focused == btn_load:
			_on_load_pressed()
			get_viewport().set_input_as_handled()
		elif focused == btn_title:
			_on_title_pressed()
			get_viewport().set_input_as_handled()

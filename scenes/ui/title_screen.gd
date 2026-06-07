extends Control

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var btn_new_game: Button = $Panel/VBoxContainer/ButtonsVBox/BtnNewGame
@onready var btn_load_game: Button = $Panel/VBoxContainer/ButtonsVBox/BtnLoadGame
@onready var main_buttons_vbox: VBoxContainer = $Panel/VBoxContainer/ButtonsVBox
@onready var footer_hint_label: Label = $Panel/VBoxContainer/FooterHintLabel

@onready var save_slot_list: Control = $SaveSlotList

func _ready() -> void:
	# Hide TouchControls HUD in title screen
	TouchControls.set_force_hidden(true)
	
	# Initial UI state setup
	save_slot_list.visible = false
	save_slot_list.back_pressed.connect(_on_save_slot_list_back)
	
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_load_game.pressed.connect(_on_load_game_pressed)
	
	btn_new_game.focus_mode = Control.FOCUS_ALL
	btn_load_game.focus_mode = Control.FOCUS_ALL
	
	_apply_theme_style()
	btn_new_game.grab_focus()

func _on_new_game_pressed() -> void:
	# Clear force hidden TouchControls before transitioning to game
	TouchControls.set_force_hidden(false)
	
	# Start new game (resets GameState state)
	GameState.reset_for_new_game()
	
	# Switch scene to Main
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_load_game_pressed() -> void:
	# Show Slot List in Load mode
	main_buttons_vbox.visible = false
	footer_hint_label.visible = false
	save_slot_list.visible = true
	save_slot_list.initialize(false) # Load mode

func _on_save_slot_list_back() -> void:
	save_slot_list.visible = false
	main_buttons_vbox.visible = true
	footer_hint_label.visible = true
	btn_load_game.grab_focus()

func _apply_theme_style() -> void:
	# Background Panel style
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.06, 0.07, 0.08, 1.0)
	$Panel.add_theme_stylebox_override("panel", bg_style)
	
	# Title styling
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(0.78, 0.42, 0.20, 1.0)) # Saturated burnt orange
	
	# Footer Hint styling
	footer_hint_label.add_theme_font_size_override("font_size", 14)
	footer_hint_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6, 0.8)) # Desaturated gray-blue
	
	# Button styling
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.08, 0.10, 0.12, 0.90)
	btn_normal.border_color = Color(0.22, 0.28, 0.29, 0.85)
	btn_normal.border_width_left = 1
	btn_normal.border_width_top = 1
	btn_normal.border_width_right = 1
	btn_normal.border_width_bottom = 1
	btn_normal.corner_radius_top_left = 4
	btn_normal.corner_radius_top_right = 4
	btn_normal.corner_radius_bottom_left = 4
	btn_normal.corner_radius_bottom_right = 4
	btn_normal.content_margin_left = 20
	btn_normal.content_margin_top = 12
	btn_normal.content_margin_right = 20
	btn_normal.content_margin_bottom = 12

	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.12, 0.14, 0.16, 1.0)
	btn_hover.border_color = Color(0.78, 0.42, 0.20, 1.0) # Active focus border color

	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(0.78, 0.42, 0.20, 0.3)
	btn_pressed.border_color = Color(0.78, 0.42, 0.20, 1.0)
	
	for btn in [btn_new_game, btn_load_game]:
		btn.add_theme_stylebox_override("normal", btn_normal)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("focus", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_pressed)
		btn.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84, 0.90))
		btn.add_theme_color_override("font_hover_color", Color(0.94, 0.92, 0.84, 1.0))
		btn.add_theme_color_override("font_focus_color", Color(0.94, 0.92, 0.84, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.78, 0.42, 0.20, 1.0))
		btn.add_theme_font_size_override("font_size", 20)

func _input(event: InputEvent) -> void:
	if save_slot_list.visible:
		return
		
	if event.is_action_pressed("move_up"):
		btn_new_game.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		btn_load_game.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact_primary"):
		var focused = get_viewport().gui_get_focus_owner()
		if focused == btn_new_game:
			_on_new_game_pressed()
			get_viewport().set_input_as_handled()
		elif focused == btn_load_game:
			_on_load_game_pressed()
			get_viewport().set_input_as_handled()

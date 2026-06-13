extends PanelContainer

var _restore_focus_control: Control = null

@onready var texture_rect: TextureRect = $VBoxContainer/TextureRect
@onready var footer_hint: Label = $VBoxContainer/FooterHint

func _ready() -> void:
	visible = false
	_apply_style()

func _apply_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.09, 0.10, 0.95)
	panel_style.border_color = Color(0.78, 0.42, 0.20, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.content_margin_left = 16.0
	panel_style.content_margin_top = 16.0
	panel_style.content_margin_right = 16.0
	panel_style.content_margin_bottom = 16.0
	add_theme_stylebox_override("panel", panel_style)

func show_photo(image_path: String, restore_focus_control: Control = null) -> void:
	_restore_focus_control = restore_focus_control
	var tex = load(image_path) as Texture2D
	texture_rect.texture = tex
	visible = true
	
	if footer_hint is PanelFooterHint:
		footer_hint.set_hints(self, ["E/Esc: 關閉"])
	else:
		footer_hint.text = "E/Esc: 關閉"

	# Center it on screen
	await get_tree().process_frame
	if not is_inside_tree():
		return
	reset_size()
	var viewport_size := get_viewport_rect().size
	position = (viewport_size - size) * 0.5

func close_photo() -> void:
	visible = false
	if _restore_focus_control != null and is_instance_valid(_restore_focus_control):
		_restore_focus_control.grab_focus()
		# Reactivate input on restore control's parent notebook panel if applicable
		var notebook = _restore_focus_control.get_parent()
		while notebook != null:
			if notebook.has_method("set_input_active"):
				notebook.set_input_active(true)
				break
			notebook = notebook.get_parent()

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		get_viewport().set_input_as_handled()
		close_photo()

func _input(event: InputEvent) -> void:
	if not visible or UIMode.get_mode() == UIMode.Mode.MESSAGE:
		return
	
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventAction:
		if event.is_action_pressed("interact_primary") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			close_photo()


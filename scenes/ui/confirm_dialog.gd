extends PanelContainer

## T 鍵丟棄確認 dialog。切 UIMode.CONFIRM，caller UI 不關閉。
## 關閉後由 UIMode.exit_confirm() 還原 caller mode。

var _on_confirm: Callable
var _on_cancel: Callable
var _restore_grid: Control = null
var _restore_index: int = 0

@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var footer_hint: Label = $VBoxContainer/FooterHint

func _ready() -> void:
	visible = false
	_apply_style()

func _apply_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.14, 0.18, 0.97)
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

func show_dialog(message: String, on_confirm: Callable,
				 restore_grid: Control = null, restore_index: int = 0,
				 on_cancel: Callable = Callable()) -> void:
	_on_confirm = on_confirm
	_on_cancel = on_cancel
	_restore_grid = restore_grid
	_restore_index = restore_index
	message_label.text = message
	visible = true
	# Viewport-center position
	reset_size()
	var vp_size := get_viewport_rect().size
	position = (vp_size - size) * 0.5

func close_dialog() -> void:
	visible = false
	UIMode.exit_confirm()
	if _restore_grid != null:
		_restore_grid.set_input_active(true)
		_restore_grid.set_focused_index(_restore_index)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact_primary"):
		if _on_confirm.is_valid():
			_on_confirm.call()
		close_dialog()
	elif event.is_action_pressed("ui_cancel"):
		if _on_cancel.is_valid():
			_on_cancel.call()
		close_dialog()

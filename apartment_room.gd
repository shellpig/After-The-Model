extends Node2D

const MESSAGES := {
	"bed_bad_sleep": "你心中有事, 睡得並不好..."
}

const CONTAINERS := {
	"cabinet_storage": {
		"title": "櫥櫃",
		"cols": 5,
		"rows": 3
	}
}

const MESSAGE_CHARS_PER_SECOND := 3.0
const MESSAGE_PADDING := Vector2(32.0, 20.0)

@onready var prompt_panel: Control = $UI/PromptPanel
@onready var prompt_label: Label = $UI/PromptPanel/MarginContainer/PromptLabel
@onready var container_panel: Control = $UI/ContainerPanel
@onready var container_title_label: Label = $UI/ContainerPanel/VBoxContainer/ContainerTitleLabel
@onready var container_grid: GridContainer = $UI/ContainerPanel/VBoxContainer/GridContainer
@onready var message_box: Control = $UI/MessageBox
@onready var message_label: Label = $UI/MessageBox/MarginContainer/MessageLabel
@onready var player: Node2D = $Player

var current_interactable: Area2D = null
var message_full_text := ""
var message_elapsed := 0.0

func _ready() -> void:
	_apply_container_panel_style()
	_apply_message_box_style()
	prompt_panel.visible = false
	prompt_label.visible = true
	container_panel.visible = false
	message_box.visible = false
	message_label.visible = true

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)

func _process(_delta: float) -> void:
	_update_message_typewriter(_delta)

	if current_interactable == null:
		return

	_position_prompt_above_player()

	if Input.is_action_just_pressed("interact_primary"):
		match current_interactable.interaction_id:
			"cabinet_storage":
				_toggle_container()
			"bed_sleep":
				_toggle_message()

func _on_interactable_entered(interactable: Area2D) -> void:
	current_interactable = interactable
	_update_prompt()

func _on_interactable_exited(interactable: Area2D) -> void:
	if current_interactable != interactable:
		return

	current_interactable = null
	prompt_panel.visible = false
	container_panel.visible = false
	message_box.visible = false
	_clear_message_typewriter()

func _toggle_container() -> void:
	message_box.visible = false
	_clear_message_typewriter()
	container_panel.visible = not container_panel.visible
	if container_panel.visible:
		_setup_container(current_interactable.interaction_id)
	_update_prompt()

func _toggle_message() -> void:
	container_panel.visible = false
	message_box.visible = not message_box.visible

	var message_id: String = current_interactable.message_id
	if message_box.visible:
		_start_message_typewriter(MESSAGES.get(message_id, ""))
	else:
		_clear_message_typewriter()
	_update_prompt()

func _setup_container(container_id: String) -> void:
	var container_data: Dictionary = CONTAINERS.get(container_id, {})
	container_title_label.text = container_data.get("title", "")
	container_grid.columns = container_data.get("cols", 1)

	var slot_count: int = container_data.get("cols", 1) * container_data.get("rows", 1)
	while container_grid.get_child_count() < slot_count:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(64, 64)
		container_grid.add_child(slot)

	for index in range(container_grid.get_child_count()):
		var slot := container_grid.get_child(index)
		slot.visible = index < slot_count
		_apply_container_slot_style(slot)

func _apply_container_panel_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.16, 0.10, 0.06, 0.88)
	panel_style.border_color = Color(0.48, 0.27, 0.12, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.content_margin_left = 16
	panel_style.content_margin_top = 12
	panel_style.content_margin_right = 16
	panel_style.content_margin_bottom = 16
	container_panel.add_theme_stylebox_override("panel", panel_style)

	container_title_label.add_theme_font_size_override("font_size", 18)
	container_title_label.add_theme_color_override("font_color", Color(0.96, 0.82, 0.58, 1.0))

	container_grid.add_theme_constant_override("h_separation", 4)
	container_grid.add_theme_constant_override("v_separation", 4)

func _apply_container_slot_style(slot: Control) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.10, 0.07, 0.04, 0.80)
	normal_style.border_color = Color(0.36, 0.22, 0.12, 1.0)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.18, 0.11, 0.06, 0.92)
	hover_style.border_color = Color(0.70, 0.42, 0.18, 1.0)

	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = Color(0.07, 0.04, 0.025, 0.95)

	slot.add_theme_stylebox_override("normal", normal_style)
	slot.add_theme_stylebox_override("hover", hover_style)
	slot.add_theme_stylebox_override("pressed", pressed_style)
	slot.add_theme_stylebox_override("focus", hover_style)

func _apply_message_box_style() -> void:
	var message_style := StyleBoxFlat.new()
	message_style.bg_color = Color(0.08, 0.09, 0.10, 0.78)
	message_style.border_color = Color(0.22, 0.28, 0.29, 0.9)
	message_style.border_width_left = 1
	message_style.border_width_top = 1
	message_style.border_width_right = 1
	message_style.border_width_bottom = 1
	message_style.corner_radius_top_left = 4
	message_style.corner_radius_top_right = 4
	message_style.corner_radius_bottom_left = 4
	message_style.corner_radius_bottom_right = 4
	message_style.content_margin_left = MESSAGE_PADDING.x
	message_style.content_margin_top = MESSAGE_PADDING.y
	message_style.content_margin_right = MESSAGE_PADDING.x
	message_style.content_margin_bottom = MESSAGE_PADDING.y
	message_box.add_theme_stylebox_override("panel", message_style)

	message_label.add_theme_font_size_override("font_size", 40)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _start_message_typewriter(text: String) -> void:
	message_full_text = text
	message_elapsed = 0.0
	message_label.text = ""
	_resize_message_box_for_text(message_full_text)

func _clear_message_typewriter() -> void:
	message_full_text = ""
	message_elapsed = 0.0
	message_label.text = ""

func _update_message_typewriter(delta: float) -> void:
	if not message_box.visible or message_full_text.is_empty():
		return

	message_elapsed += delta
	var visible_chars: int = min(message_full_text.length(), int(floor(message_elapsed * MESSAGE_CHARS_PER_SECOND)))
	message_label.text = message_full_text.substr(0, visible_chars)

func _resize_message_box_for_text(text: String) -> void:
	var font: Font = message_label.get_theme_font("font")
	var font_size: int = message_label.get_theme_font_size("font_size")
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	message_box.size = text_size + MESSAGE_PADDING * 2.0

	var viewport_size: Vector2 = get_viewport_rect().size
	message_box.position = (viewport_size - message_box.size) * 0.5

func _position_prompt_above_player() -> void:
	prompt_panel.reset_size()
	var player_screen_position := player.get_global_transform_with_canvas().origin
	var prompt_size := prompt_panel.size
	prompt_panel.position = player_screen_position + Vector2(-prompt_size.x * 0.45, -260.0)

func _update_prompt() -> void:
	if current_interactable == null:
		prompt_panel.visible = false
		return

	prompt_panel.visible = true
	_position_prompt_above_player()

	match current_interactable.interaction_id:
		"cabinet_storage":
			prompt_label.text = "E: 關閉櫥櫃" if container_panel.visible else current_interactable.prompt_text
		"bed_sleep":
			prompt_label.text = "E: 關閉訊息" if message_box.visible else current_interactable.prompt_text
		_:
			prompt_label.text = current_interactable.prompt_text

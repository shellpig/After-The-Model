extends CanvasLayer

@onready var prompt_panel: Control = $PromptPanel
@onready var prompt_label: Label = $PromptPanel/MarginContainer/PromptLabel
@onready var ui_overlay: ColorRect = $UIOverlay
@onready var notebook_panel: Control = $NotebookPanel
@onready var dual_pane_container: Control = $DualPaneContainer
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var bag_grid: Control = $InventoryPanel/VBoxContainer/BagGrid
@onready var credits_label: Label = $InventoryPanel/VBoxContainer/HBoxContainer/CreditsLabel
@onready var panel_footer_hint: Control = $InventoryPanel/VBoxContainer/PanelFooterHint
@onready var item_detail_modal: Control = $ItemDetailModal
@onready var confirm_dialog: Control = $ConfirmDialog
@onready var world_hud_label: Label = $WorldHUDLabel
@onready var message_box: Control = $MessageBox
@onready var message_label: Label = $MessageBox/MarginContainer/MessageLabel
@onready var page_hint_label: Label = $MessageBox/PageHintLabel

var _last_mode: int = UIMode.Mode.NONE
var _mode_before_message: int = UIMode.Mode.NONE
var _message_just_opened: bool = false
var _level_context: Node = null
var _is_simple_message: bool = false

# Typewriter variables for show_message
var _message_full_text := ""
var _message_elapsed := 0.0
var _current_chars_per_second := 12.0
var _message_on_closed: Callable = Callable()

func _ready() -> void:
	prompt_panel.visible = false
	prompt_label.visible = true
	message_box.visible = false
	message_label.visible = true
	ui_overlay.visible = false
	inventory_panel.visible = false
	notebook_panel.visible = false
	dual_pane_container.visible = false
	item_detail_modal.visible = false
	confirm_dialog.visible = false
	page_hint_label.text = ""
	page_hint_label.visible = false
	
	_apply_message_box_style()
	
	UIMode.mode_changed.connect(_on_ui_mode_changed)
	
	# Enable item actions for bag grid
	if bag_grid.has_method("set_item_actions_enabled"):
		bag_grid.set_item_actions_enabled(true)

func _process(delta: float) -> void:
	_update_message_typewriter(delta)
	
	var current_mode := UIMode.get_mode()
	if current_mode == UIMode.Mode.MESSAGE:
		if _message_just_opened:
			_message_just_opened = false
			return
		if _is_simple_message and (Input.is_action_just_pressed("interact_primary") or Input.is_action_just_pressed("ui_cancel")):
			close_message()
			if _message_on_closed.is_valid():
				_message_on_closed.call()
				_message_on_closed = Callable()

func set_world_context(level: Node) -> void:
	_level_context = level

func clear_world_context(level: Node = null) -> void:
	if level == null or _level_context == level:
		_level_context = null

func show_prompt(data: Dictionary) -> void:
	if UIMode.get_mode() != UIMode.Mode.NONE:
		prompt_panel.visible = false
		return
	prompt_label.text = data.get("prompt_text", "")
	prompt_panel.visible = true

func hide_prompt() -> void:
	prompt_panel.visible = false

func has_current_interactable() -> bool:
	if _level_context and _level_context.get("current_interactable") != null:
		return true
	return false

func is_touch_toggle_blocked() -> bool:
	# Block touch controls toggle during monologue or message screens
	if _level_context and _level_context.get("_opening_monologue_active") == true:
		return true
	return false

func show_message(text: String, on_closed: Callable = Callable()) -> void:
	_is_simple_message = true
	_message_on_closed = on_closed
	_message_full_text = text
	_message_elapsed = 0.0
	message_label.text = ""
	_current_chars_per_second = 12.0
	_resize_message_box_for_text(_message_full_text)
	UIMode.enter_overlay(UIMode.Mode.MESSAGE)

func begin_message(text: String, options: Dictionary = {}) -> void:
	_is_simple_message = false
	_message_full_text = text
	_message_elapsed = 0.0
	message_label.text = ""
	_current_chars_per_second = options.get("chars_per_second", 12.0)
	_resize_message_box_for_text(_message_full_text)
	UIMode.enter_overlay(UIMode.Mode.MESSAGE)

func force_finish_message() -> void:
	message_label.text = _message_full_text
	_message_elapsed = _message_full_text.length() / _current_chars_per_second + 1.0

func is_message_finished() -> bool:
	return message_label.text.length() >= _message_full_text.length()

func set_message_page_hint(text: String, visible: bool) -> void:
	page_hint_label.text = text
	page_hint_label.visible = visible

func close_message() -> void:
	_is_simple_message = false
	_message_full_text = ""
	_message_elapsed = 0.0
	message_label.text = ""
	page_hint_label.text = ""
	page_hint_label.visible = false
	UIMode.exit_overlay()

func show_toast(text: String, anchor_node: Control = null) -> void:
	FloatingToast.show_toast(text, anchor_node)

func open_inventory() -> void:
	UIMode.set_mode(UIMode.Mode.INVENTORY)

func open_notebook() -> void:
	UIMode.set_mode(UIMode.Mode.NOTEBOOK)

func open_container(container_id: String, title: String, slot_count: int) -> void:
	UIMode.set_mode(UIMode.Mode.CONTAINER)
	dual_pane_container.set_input_active(true, container_id, slot_count, title)

func close_all_ui(reset_mode: bool = true) -> void:
	if reset_mode:
		UIMode.set_mode(UIMode.Mode.NONE)

func get_focused_item_context() -> Dictionary:
	var current_mode := UIMode.get_mode()
	if current_mode == UIMode.Mode.INVENTORY:
		var idx: int = bag_grid.focused_index
		var items := GameState.get_inventory()
		if idx >= 0 and idx < items.size() and not items[idx].is_empty():
			var item = items[idx]
			return {
				"mode": current_mode,
				"instance_id": item.get("instance_id", ""),
				"item_id": item.get("item_id", ""),
				"source_pane": "left",
				"available_actions": ["view", "discard", "equip_toggle"]
			}
	elif current_mode == UIMode.Mode.CONTAINER:
		var is_left = (dual_pane_container.active_pane == 0)
		var grid: Control = dual_pane_container.left_grid if is_left else dual_pane_container.right_grid
		var idx: int = grid.focused_index
		var items = GameState.get_inventory() if is_left else GameState.get_container(dual_pane_container.container_id)
		if idx >= 0 and idx < items.size() and not items[idx].is_empty():
			var item = items[idx]
			return {
				"mode": current_mode,
				"instance_id": item.get("instance_id", ""),
				"item_id": item.get("item_id", ""),
				"source_pane": "left" if is_left else "right",
				"available_actions": ["view", "discard", "move"]
			}
	return {}

func can_primary_action() -> bool:
	var ctx := get_focused_item_context()
	return not ctx.is_empty()

func can_secondary_action() -> bool:
	var ctx := get_focused_item_context()
	return not ctx.is_empty()

func can_tertiary_action() -> bool:
	var ctx := get_focused_item_context()
	if ctx.is_empty():
		return false
	var item_meta: Dictionary = GameState.ITEMS_DB.get(ctx["item_id"], {})
	return item_meta.get("discardable", true) and not GameState.is_equipped(ctx["instance_id"])

func _on_ui_mode_changed(new_mode: int) -> void:
	if new_mode == UIMode.Mode.CONFIRM:
		confirm_dialog.visible = true
		return

	if new_mode == UIMode.Mode.MESSAGE:
		_message_just_opened = true
		if _last_mode != UIMode.Mode.MESSAGE:
			_mode_before_message = _last_mode

	ui_overlay.visible = (new_mode != UIMode.Mode.NONE)
	inventory_panel.visible = (new_mode == UIMode.Mode.INVENTORY) or (new_mode == UIMode.Mode.MESSAGE and _mode_before_message == UIMode.Mode.INVENTORY)
	dual_pane_container.visible = (new_mode == UIMode.Mode.CONTAINER) or (new_mode == UIMode.Mode.MESSAGE and _mode_before_message == UIMode.Mode.CONTAINER)
	message_box.visible = (new_mode == UIMode.Mode.MESSAGE)
	notebook_panel.visible = (new_mode == UIMode.Mode.NOTEBOOK) or (new_mode == UIMode.Mode.MESSAGE and _mode_before_message == UIMode.Mode.NOTEBOOK)

	if is_instance_valid(world_hud_label):
		world_hud_label.visible = (new_mode == UIMode.Mode.NONE and _level_context and not _level_context.get("_opening_monologue_active") == true)

	bag_grid.set_input_active(new_mode == UIMode.Mode.INVENTORY)
	notebook_panel.set_input_active(new_mode == UIMode.Mode.NOTEBOOK)

	if new_mode == UIMode.Mode.INVENTORY:
		var items := GameState.get_inventory()
		bag_grid.initialize_grid(items)
		bag_grid.set_focused_index(0)
		credits_label.text = "credits : %d" % GameState.get_credits()
		prompt_panel.visible = false
	elif new_mode == UIMode.Mode.MESSAGE:
		prompt_panel.visible = false
	elif new_mode == UIMode.Mode.NOTEBOOK:
		notebook_panel.load_notebook_data()
		prompt_panel.visible = false
	elif new_mode == UIMode.Mode.NONE:
		item_detail_modal.visible = false
		confirm_dialog.visible = false
		prompt_panel.visible = false

	_last_mode = new_mode

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
	message_style.content_margin_left = 32.0
	message_style.content_margin_top = 20.0
	message_style.content_margin_right = 32.0
	message_style.content_margin_bottom = 20.0
	message_box.add_theme_stylebox_override("panel", message_style)

	message_label.add_theme_font_size_override("font_size", 40)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _update_message_typewriter(delta: float) -> void:
	if not message_box.visible or _message_full_text.is_empty():
		return

	_message_elapsed += delta
	var visible_chars: int = min(_message_full_text.length(), int(floor(_message_elapsed * _current_chars_per_second)))
	message_label.text = _message_full_text.substr(0, visible_chars)

func _resize_message_box_for_text(text: String) -> void:
	var font: Font = message_label.get_theme_font("font")
	var font_size: int = message_label.get_theme_font_size("font_size")

	var max_width: float = 800.0
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	if text_size.x > max_width:
		message_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		message_label.custom_minimum_size = Vector2(max_width - 64.0, 0.0)
		message_box.size = Vector2(max_width, 0.0)
	else:
		message_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		message_label.custom_minimum_size = Vector2.ZERO
		message_box.size = text_size + Vector2(64.0, 40.0)

	message_box.reset_size()
	
	# Center the box horizontally and vertically
	var viewport_size = get_viewport().get_visible_rect().size
	message_box.global_position = (viewport_size - message_box.size) * 0.5

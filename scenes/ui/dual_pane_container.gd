extends PanelContainer
class_name DualPaneContainer

signal item_action_requested(action: String, instance_id: String, source_pane: String)

@onready var left_panel: PanelContainer = $HBoxContainer/BackpackPanel
@onready var right_panel: PanelContainer = $HBoxContainer/ContainerPanel

@onready var left_title: Label = $HBoxContainer/BackpackPanel/VBoxContainer/Title
@onready var right_title: Label = $HBoxContainer/ContainerPanel/VBoxContainer/Title
@onready var left_grid: Control = $HBoxContainer/BackpackPanel/VBoxContainer/BagGrid
@onready var right_grid: Control = $HBoxContainer/ContainerPanel/VBoxContainer/ExternalGrid
@onready var left_footer: Label = $HBoxContainer/BackpackPanel/VBoxContainer/FooterHint
@onready var right_footer: Label = $HBoxContainer/ContainerPanel/VBoxContainer/FooterHint

var active_pane: String = "right"
var is_input_active: bool = false
var container_id: String = ""
var slot_count: int = 10
var title_text: String = ""

func _ready() -> void:
	$HBoxContainer.add_theme_constant_override("separation", 16)

	left_grid.boundary_crossed.connect(_on_left_grid_boundary_crossed)
	right_grid.boundary_crossed.connect(_on_right_grid_boundary_crossed)

	# Ensure left BagGrid does NOT handle E/R/T item actions (DualPane owns that routing)
	if left_grid.has_method("set_item_actions_enabled"):
		left_grid.set_item_actions_enabled(false)

	GameState.inventory_changed.connect(func():
		if is_input_active:
			refresh_ui()
	)
	GameState.container_changed.connect(func(changed_id: String):
		if is_input_active and changed_id == container_id:
			refresh_ui()
	)

	_apply_panels_styling()

func set_input_active(active: bool, c_id: String = "", s_count: int = 0, title: String = "") -> void:
	is_input_active = active

	if active:
		container_id = c_id
		slot_count = s_count
		title_text = title

		# Dynamic Y height per spec
		if slot_count == 30:
			right_panel.custom_minimum_size.y = 388  # Cabinet 5x6
		else:
			right_panel.custom_minimum_size.y = 152  # Fridge 5x2

		active_pane = "right"
		refresh_ui()
		right_grid.set_input_active(true)
		right_grid.set_focused_index(0)
		left_grid.set_input_active(false)
	else:
		left_grid.set_input_active(false)
		right_grid.set_input_active(false)

func refresh_ui() -> void:
	left_title.text = "背包 (Credits: %d)" % GameState.get_credits()
	right_title.text = title_text

	left_grid.initialize_grid(GameState.get_inventory())
	right_grid.initialize_grid(GameState.get_container(container_id))

	left_footer.text = "E: 移動    R: 查看    T: 丟棄    Esc: 關閉"
	right_footer.text = "E: 移動    R: 查看    T: 丟棄    Esc: 關閉"

	# Re-grab focus on same index to keep focus locked after transfers (per spec line 575)
	if active_pane == "left":
		left_grid.set_focused_index(left_grid.focused_index)
	else:
		right_grid.set_focused_index(right_grid.focused_index)

func _on_left_grid_boundary_crossed(direction: String, row: int) -> void:
	if direction == "right":
		active_pane = "right"
		left_grid.set_input_active(false)
		right_grid.set_input_active(true)

		var max_row: int = int(slot_count / 5) - 1
		var target_row: int = clampi(row, 0, max_row)
		var new_index: int = target_row * 5 + 0
		right_grid.set_focused_index(new_index)

func _on_right_grid_boundary_crossed(direction: String, row: int) -> void:
	if direction == "left":
		active_pane = "left"
		right_grid.set_input_active(false)
		left_grid.set_input_active(true)

		# BagGrid is fixed 5 x 3 = 3 rows
		var max_row: int = int(left_grid.get_child_count() / 5) - 1
		var target_row: int = clampi(row, 0, max_row)
		var new_index: int = target_row * 5 + 4
		left_grid.set_focused_index(new_index)

func _unhandled_input(event: InputEvent) -> void:
	if not is_input_active:
		return

	if event.is_action_pressed("interact_primary"):
		_sync_active_pane_from_focus_owner()
		_handle_item_move()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact_secondary"):
		_sync_active_pane_from_focus_owner()
		_emit_dual_action("view")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact_tertiary"):
		_sync_active_pane_from_focus_owner()
		_emit_dual_action("discard")
		get_viewport().set_input_as_handled()

func _sync_active_pane_from_focus_owner() -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner == null:
		return
	if focus_owner.get_parent() == left_grid:
		active_pane = "left"
	elif focus_owner.get_parent() == right_grid:
		active_pane = "right"

func _get_grid_focused_index(grid: Control) -> int:
	if grid.has_method("get_focused_index"):
		return grid.get_focused_index()
	return grid.focused_index

func _emit_dual_action(action: String) -> void:
	var items_array: Array
	var index: int
	var pane: String
	if active_pane == "left":
		items_array = GameState.get_inventory()
		index = _get_grid_focused_index(left_grid)
		pane = "left"
	else:
		items_array = GameState.get_container(container_id)
		index = _get_grid_focused_index(right_grid)
		pane = "right"
	var slot: Dictionary = items_array[index] if index < items_array.size() else {}
	item_action_requested.emit(action, slot.get("instance_id", ""), pane)

func _handle_item_move() -> void:
	var items_array: Array
	var index: int
	var target_id: String
	var target_panel: Control

	if active_pane == "left":
		items_array = GameState.get_inventory()
		index = _get_grid_focused_index(left_grid)
		target_id = container_id
		target_panel = right_panel  # toast appears above target panel
	else:
		items_array = GameState.get_container(container_id)
		index = _get_grid_focused_index(right_grid)
		target_id = "player_inventory"
		target_panel = left_panel

	if index < items_array.size() and not items_array[index].is_empty():
		var instance_id: String = items_array[index].get("instance_id", "")
		var moved: bool = GameState.move_one_item_to(target_id, instance_id)
		if not moved:
			FloatingToast.show_toast("放不下了。", target_panel)

func _apply_panels_styling() -> void:
	# Reuse the InventoryPanel skin to avoid color drift (same pattern as NotebookPanel)
	var sibling_panel: Node = get_parent().get_node_or_null("InventoryPanel") if get_parent() != null else null
	var panel_style: StyleBox = null
	if sibling_panel != null:
		panel_style = sibling_panel.get_theme_stylebox("panel")

	if panel_style == null:
		panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.12, 0.14, 0.18, 0.88)
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.border_color = Color(0.78, 0.42, 0.20, 1.0)
		panel_style.corner_radius_top_left = 4
		panel_style.corner_radius_top_right = 4
		panel_style.corner_radius_bottom_left = 4
		panel_style.corner_radius_bottom_right = 4
		panel_style.content_margin_left = 16
		panel_style.content_margin_top = 16
		panel_style.content_margin_right = 16
		panel_style.content_margin_bottom = 16

	left_panel.add_theme_stylebox_override("panel", panel_style)
	right_panel.add_theme_stylebox_override("panel", panel_style)

	# Outer PanelContainer renders nothing — only the two inner panels draw
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

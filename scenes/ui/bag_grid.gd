extends GridContainer
class_name BagGrid

signal boundary_crossed(direction: String, row: int)
signal item_action_requested(action: String, instance_id: String)

var focused_index: int = 0
var _input_active: bool = false
var _items_data: Array = []
var _item_actions_enabled: bool = false

func _ready() -> void:
	self.columns = 5
	# Ensure separators are 4px per spec
	add_theme_constant_override("h_separation", 4)
	add_theme_constant_override("v_separation", 4)

	# Dynamically pre-populate 15 slots if they don't exist
	_ensure_slots_exist()

	# Connect inventory_changed so equipped markers refresh without reopening the UI
	if not GameState.inventory_changed.is_connected(_on_inventory_changed):
		GameState.inventory_changed.connect(_on_inventory_changed)

func _on_inventory_changed() -> void:
	if _input_active:
		initialize_grid(GameState.get_inventory())

func set_item_actions_enabled(enabled: bool) -> void:
	_item_actions_enabled = enabled

func set_input_active(active: bool) -> void:
	_input_active = active
	if _input_active:
		set_focused_index(focused_index)
	else:
		# Unfocus all slots when input is deactivated
		for i in range(get_child_count()):
			var button := get_child(i) as Button
			if button and button.has_focus():
				button.release_focus()

func initialize_grid(items: Array) -> void:
	_items_data = items
	_ensure_slots_exist()
	
	for i in range(15):
		var slot_button := get_child(i) as Button
		if not slot_button:
			continue
			
		var icon_rect := slot_button.get_node("Icon") as TextureRect
		var quantity_label := slot_button.get_node("Quantity") as Label
		var equip_marker := slot_button.get_node("EquippedMarker") as Control
		var placeholder_label := slot_button.get_node("Placeholder") as Label
		
		var slot_data: Dictionary = items[i] if i < items.size() else {}
		
		if slot_data.is_empty():
			# Empty slot
			icon_rect.texture = null
			quantity_label.visible = false
			equip_marker.visible = false
			placeholder_label.visible = false
		else:
			# Occupied slot
			var item_id: String = slot_data.get("item_id", "")
			var quantity: int = slot_data.get("quantity", 1)
			var instance_id: String = slot_data.get("instance_id", "")
			
			var item_meta: Dictionary = GameState.ITEMS_DB.get(item_id, {})
			var icon_path: String = item_meta.get("icon_path", "")
			
			var tex: Texture2D = null
			if not icon_path.is_empty():
				tex = load(icon_path) as Texture2D
				
			if tex:
				icon_rect.texture = tex
				placeholder_label.visible = false
			else:
				# Show fallback red '?' placeholder per spec
				icon_rect.texture = null
				placeholder_label.visible = true
			
			# Quantity label (only if quantity > 1)
			if quantity > 1:
				quantity_label.text = str(quantity)
				quantity_label.visible = true
			else:
				quantity_label.visible = false
				
			# Equipped marker (E tag top-right)
			if not instance_id.is_empty() and GameState.is_equipped(instance_id):
				equip_marker.visible = true
			else:
				equip_marker.visible = false

func set_focused_index(index: int) -> void:
	focused_index = clamp(index, 0, 14)
	if get_child_count() > focused_index:
		var target_button := get_child(focused_index) as Button
		if target_button:
			target_button.grab_focus()

func _ensure_slots_exist() -> void:
	while get_child_count() < 15:
		_create_slot_button(get_child_count())

func _create_slot_button(index: int) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(64, 64)
	button.focus_mode = Control.FOCUS_ALL
	button.focus_entered.connect(_on_slot_focus_entered.bind(index))
	button.pressed.connect(_on_slot_pressed.bind(index))
	
	# Apply normal style: desaturated dark blue-grey slot background
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.08, 0.10, 0.12, 0.80)
	normal_style.border_color = Color(0.30, 0.32, 0.36, 1.0)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	
	# Apply focus style: 2px flat orange border (#c76b33)
	var focus_style := normal_style.duplicate() as StyleBoxFlat
	focus_style.border_color = Color(0.78, 0.42, 0.20, 1.0)
	focus_style.border_width_left = 2
	focus_style.border_width_top = 2
	focus_style.border_width_right = 2
	focus_style.border_width_bottom = 2
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", normal_style) # Disables hovering color shift to let keyboard focus stand out
	button.add_theme_stylebox_override("pressed", normal_style)
	button.add_theme_stylebox_override("focus", focus_style)
	
	# Icon child (centered absolutely inside 64x64 slot)
	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.position = Vector2(8, 8)
	icon_rect.size = Vector2(48, 48)
	button.add_child(icon_rect)
	
	# Fallback Label (Red '?' placeholder)
	var placeholder := Label.new()
	placeholder.name = "Placeholder"
	placeholder.text = "?"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.visible = false
	placeholder.position = Vector2(8, 8)
	placeholder.size = Vector2(48, 48)
	
	# Add red backplate to placeholder label
	var label_style := StyleBoxFlat.new()
	label_style.bg_color = Color(0.8, 0.2, 0.2, 1.0)
	placeholder.add_theme_stylebox_override("normal", label_style)
	button.add_child(placeholder)
	
	# Quantity Label
	var qty := Label.new()
	qty.name = "Quantity"
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	qty.visible = false
	
	# Ensure small font size and outline for readability per spec
	qty.add_theme_font_size_override("font_size", 14)
	qty.add_theme_color_override("font_color", Color.WHITE)
	qty.add_theme_color_override("font_outline_color", Color.BLACK)
	qty.add_theme_constant_override("outline_size", 4)
	button.add_child(qty)
	qty.anchor_left = 1.0
	qty.anchor_top = 1.0
	qty.anchor_right = 1.0
	qty.anchor_bottom = 1.0
	qty.offset_left = -40
	qty.offset_right = -4
	qty.offset_top = -20
	qty.offset_bottom = -2
	
	# Equipped Marker (white-background 12x12 panel with a dark letter "E")
	var marker_panel := PanelContainer.new()
	marker_panel.name = "EquippedMarker"
	marker_panel.custom_minimum_size = Vector2(12, 12)
	marker_panel.visible = false
	
	var marker_style := StyleBoxFlat.new()
	marker_style.bg_color = Color.WHITE
	marker_panel.add_theme_stylebox_override("panel", marker_style)
	
	var marker_label := Label.new()
	marker_label.text = "E"
	marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker_label.add_theme_color_override("font_color", Color.BLACK)
	marker_label.add_theme_font_size_override("font_size", 10)
	marker_panel.add_child(marker_label)
	
	button.add_child(marker_panel)
	marker_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	marker_panel.offset_top = 2
	marker_panel.offset_right = -2
	
	add_child(button)

func _on_slot_focus_entered(index: int) -> void:
	focused_index = clamp(index, 0, 14)

func _on_slot_pressed(index: int) -> void:
	set_focused_index(index)

func _unhandled_input(event: InputEvent) -> void:
	if not _input_active:
		return

	var row: int = int(focused_index / 5)
	var col: int = int(focused_index % 5)

	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		if col > 0:
			set_focused_index(focused_index - 1)
		# col == 0: left border, no jump (per spec). Swallow either way.
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		if col < 4:
			set_focused_index(focused_index + 1)
		else:
			boundary_crossed.emit("right", row)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		if row > 0:
			set_focused_index(focused_index - 5)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		if row < 2:
			set_focused_index(focused_index + 5)
		get_viewport().set_input_as_handled()
	elif _item_actions_enabled and event.is_action_pressed("interact_primary"):
		_emit_item_action("equip_toggle")
		get_viewport().set_input_as_handled()
	elif _item_actions_enabled and event.is_action_pressed("interact_secondary"):
		_emit_item_action("view")
		get_viewport().set_input_as_handled()
	elif _item_actions_enabled and event.is_action_pressed("interact_tertiary"):
		_emit_item_action("discard")
		get_viewport().set_input_as_handled()

func _emit_item_action(action: String) -> void:
	var items := GameState.get_inventory()
	var slot: Dictionary = items[focused_index] if focused_index < items.size() else {}
	item_action_requested.emit(action, slot.get("instance_id", ""))

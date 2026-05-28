extends GridContainer
class_name ExternalGrid

signal boundary_crossed(direction: String, row: int)

var focused_index: int = 0
var _input_active: bool = false
var _items_data: Array = []
var slot_count: int = 10

func _ready() -> void:
	self.columns = 5
	add_theme_constant_override("h_separation", 4)
	add_theme_constant_override("v_separation", 4)

func set_input_active(active: bool) -> void:
	_input_active = active
	if _input_active:
		set_focused_index(focused_index)
	else:
		for i in range(get_child_count()):
			var button := get_child(i) as Button
			if button and button.has_focus():
				button.release_focus()

func initialize_grid(items: Array) -> void:
	_items_data = items
	slot_count = items.size()

	for child in get_children():
		remove_child(child)
		child.queue_free()

	for i in range(slot_count):
		_create_slot_button(i)

	for i in range(slot_count):
		var slot_button := get_child(i) as Button
		var icon_rect := slot_button.get_node("Icon") as TextureRect
		var quantity_label := slot_button.get_node("Quantity") as Label
		var placeholder_label := slot_button.get_node("Placeholder") as Label

		var slot_data: Dictionary = items[i] if i < items.size() else {}

		if slot_data.is_empty():
			icon_rect.texture = null
			quantity_label.visible = false
			placeholder_label.visible = false
		else:
			var item_id: String = slot_data.get("item_id", "")
			var quantity: int = slot_data.get("quantity", 1)
			var item_meta: Dictionary = GameState.ITEMS_DB.get(item_id, {})
			var icon_path: String = item_meta.get("icon_path", "")

			var tex: Texture2D = null
			if not icon_path.is_empty():
				tex = load(icon_path) as Texture2D

			if tex:
				icon_rect.texture = tex
				placeholder_label.visible = false
			else:
				icon_rect.texture = null
				placeholder_label.visible = true

			if quantity > 1:
				quantity_label.text = str(quantity)
				quantity_label.visible = true
			else:
				quantity_label.visible = false

	if _input_active:
		set_focused_index(focused_index)

func set_focused_index(index: int) -> void:
	if slot_count <= 0:
		return
	focused_index = clampi(index, 0, slot_count - 1)
	if get_child_count() > focused_index:
		var target_button := get_child(focused_index) as Button
		if target_button:
			target_button.grab_focus()

func get_focused_index() -> int:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null and focus_owner.get_parent() == self and slot_count > 0:
		var index := focus_owner.get_index()
		focused_index = clampi(index, 0, slot_count - 1)
	return focused_index

func _create_slot_button(index: int) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(64, 64)
	button.focus_mode = Control.FOCUS_ALL
	button.focus_entered.connect(_on_slot_focus_entered.bind(index))
	button.pressed.connect(_on_slot_pressed.bind(index))

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.08, 0.10, 0.12, 0.80)
	normal_style.border_color = Color(0.30, 0.32, 0.36, 1.0)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1

	var focus_style := normal_style.duplicate() as StyleBoxFlat
	focus_style.border_color = Color(0.78, 0.42, 0.20, 1.0)
	focus_style.border_width_left = 2
	focus_style.border_width_top = 2
	focus_style.border_width_right = 2
	focus_style.border_width_bottom = 2

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", normal_style)
	button.add_theme_stylebox_override("pressed", normal_style)
	button.add_theme_stylebox_override("focus", focus_style)

	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.position = Vector2(8, 8)
	icon_rect.size = Vector2(48, 48)
	button.add_child(icon_rect)

	var placeholder := Label.new()
	placeholder.name = "Placeholder"
	placeholder.text = "?"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.visible = false
	placeholder.position = Vector2(8, 8)
	placeholder.size = Vector2(48, 48)

	var label_style := StyleBoxFlat.new()
	label_style.bg_color = Color(0.8, 0.2, 0.2, 1.0)
	placeholder.add_theme_stylebox_override("normal", label_style)
	button.add_child(placeholder)

	var qty := Label.new()
	qty.name = "Quantity"
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	qty.visible = false
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

	add_child(button)

func _on_slot_focus_entered(index: int) -> void:
	if slot_count <= 0:
		return
	focused_index = clampi(index, 0, slot_count - 1)

func _on_slot_pressed(index: int) -> void:
	set_focused_index(index)

func _unhandled_input(event: InputEvent) -> void:
	if not _input_active:
		return

	var current_index := get_focused_index()
	var row: int = int(current_index / 5)
	var col: int = int(current_index % 5)
	var max_rows: int = int(slot_count / 5)

	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		if col > 0:
			set_focused_index(focused_index - 1)
		else:
			boundary_crossed.emit("left", row)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		if col < 4:
			set_focused_index(focused_index + 1)
		# col == 4: right border, no jump (per spec). Swallow either way.
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		if row > 0:
			set_focused_index(focused_index - 5)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		if row < (max_rows - 1):
			set_focused_index(focused_index + 5)
		get_viewport().set_input_as_handled()

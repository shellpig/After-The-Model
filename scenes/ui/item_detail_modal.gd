extends PanelContainer

## R 鍵查看物品詳細資訊的浮動 modal。
## 不切 UIMode（INVENTORY / CONTAINER 不變），開啟時 capture 鍵盤，關閉後焦點回原 grid 格。

var _restore_grid: Control = null
var _restore_index: int = 0
var _last_instance_id: String = ""

@onready var icon_rect: TextureRect = $VBoxContainer/IconRect
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var desc_label: RichTextLabel = $VBoxContainer/DescLabel
@onready var category_label: Label = $VBoxContainer/CategoryLabel
@onready var footer_hint: Label = $VBoxContainer/FooterHint

func _ready() -> void:
	visible = false
	_apply_style()

func _apply_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.14, 0.18, 0.95)
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

func show_modal(instance_id: String, restore_grid: Control, restore_index: int, anchor_node: Control = null) -> void:
	_last_instance_id = instance_id
	_restore_grid = restore_grid
	_restore_index = restore_index
	_fill_content(instance_id)
	visible = true
	# Position after visible so size is computed
	await get_tree().process_frame
	_position_for_anchor(anchor_node)

func refresh_modal() -> void:
	if not _last_instance_id.is_empty():
		_fill_content(_last_instance_id)

func close_modal() -> void:
	visible = false
	if _restore_grid != null:
		_restore_grid.set_input_active(true)
		_restore_grid.set_focused_index(_restore_index)

func _fill_content(instance_id: String) -> void:
	# Find item in inventory or containers
	var item_id := ""
	for slot in GameState.get_inventory():
		if slot.get("instance_id", "") == instance_id:
			item_id = slot.get("item_id", "")
			break
	if item_id.is_empty():
		for c_key in GameState.external_containers.keys():
			for slot in GameState.get_container(c_key):
				if slot.get("instance_id", "") == instance_id:
					item_id = slot.get("item_id", "")
					break
			if not item_id.is_empty():
				break

	var item_meta: Dictionary = GameState.ITEMS_DB.get(item_id, {})

	# Icon
	var icon_path: String = item_meta.get("icon_path", "")
	if not icon_path.is_empty():
		var tex := load(icon_path) as Texture2D
		icon_rect.texture = tex
	else:
		icon_rect.texture = null

	# Name
	name_label.text = item_meta.get("name", "???")

	# Description
	desc_label.text = item_meta.get("description", "")

	# Category tag
	var category: String = item_meta.get("category", "misc")
	var equipment_slot: String = item_meta.get("equipment_slot", "")
	var slot_zh := {"clothing": "衣服", "hand": "手持", "accessory": "其他"}
	match category:
		"key_item":
			category_label.text = "劇情物品（不可丟棄）"
		"equipment":
			var slot_name: String = slot_zh.get(equipment_slot, equipment_slot)
			category_label.text = "裝備（%s）" % slot_name
		"consumable":
			category_label.text = "消耗品"
		_:
			category_label.text = "物品"

func _position_for_anchor(anchor_node: Control = null) -> void:
	reset_size()
	var viewport_size := get_viewport_rect().size
	if anchor_node == null:
		position = (viewport_size - size) * 0.5
		return
	var anchor_pos := anchor_node.global_position
	var anchor_size := anchor_node.size
	global_position = anchor_pos + Vector2((anchor_size.x - size.x) * 0.5, (anchor_size.y - size.y) * 0.5)

func _input(event: InputEvent) -> void:
	if not visible or UIMode.get_mode() == UIMode.Mode.MESSAGE:
		return
	
	# 只攔截鍵盤、搖桿與模擬動作事件，允許實體滑鼠與觸控點擊穿透到 GUI 按鈕
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventAction:
		get_viewport().set_input_as_handled()
		if event.is_action_pressed("interact_secondary") or event.is_action_pressed("ui_cancel"):
			close_modal()

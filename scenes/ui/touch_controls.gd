extends CanvasLayer

@export var force_show_in_debug: bool = true

var touch_buttons_enabled: bool = false
var is_pc_platform: bool = false
var _style_normal: StyleBoxFlat
var _style_pressed: StyleBoxFlat

@onready var btn_up: Button = $Control/DPad/BtnUp
@onready var btn_down: Button = $Control/DPad/BtnDown
@onready var btn_left: Button = $Control/DPad/BtnLeft
@onready var btn_right: Button = $Control/DPad/BtnRight

@onready var btn_e: Button = $Control/Actions/BtnE
@onready var btn_r: Button = $Control/Actions/BtnR
@onready var btn_t: Button = $Control/Actions/BtnT

@onready var btn_bag: Button = $Control/Menus/BtnBag
@onready var btn_note: Button = $Control/Menus/BtnNote
@onready var btn_close: Button = $Control/Menus/BtnClose
@onready var btn_toggle: Button = $Control/BtnToggle

func _ready() -> void:
	# 1. 偵測設備並初始化預設啟用狀態 (以作業系統平台為準)
	var platform := OS.get_name()
	is_pc_platform = platform in ["Windows", "macOS", "Linux", "UWP", "FreeBSD", "NetBSD", "OpenBSD", "BSD"]
	
	# 手機板預設直接啟用，PC 版預設不啟用
	touch_buttons_enabled = not is_pc_platform

	# 2. 為了在 PC 端顯示左上角的開關按鈕，CanvasLayer 必須始終保持 visible = true
	self.visible = true

	# 2. 套用 Cyberpunk 視覺樣式與尺寸
	_apply_cyber_style()

	# 3. 綁定按鈕壓下 (button_down) 與放開 (button_up) 信號至 InputEventAction 模擬
	_bind_button(btn_up, "move_up")
	_bind_button(btn_down, "move_down")
	_bind_button(btn_left, "move_left")
	_bind_button(btn_right, "move_right")

	_bind_button(btn_e, "interact_primary")
	_bind_button(btn_r, "interact_secondary")
	_bind_button(btn_t, "interact_tertiary")

	_bind_button(btn_bag, "open_inventory")
	_bind_button(btn_note, "open_notebook")
	_bind_button(btn_close, "ui_cancel")

	# 4. 綁定 PC 端 HUD 觸控開關按鈕
	btn_toggle.focus_mode = Control.FOCUS_NONE
	btn_toggle.pressed.connect(_on_toggle_pressed)

	# 5. 監聽 UIMode 的變更以動態切換按鍵顯示
	if UIMode.has_signal("mode_changed"):
		UIMode.mode_changed.connect(_on_ui_mode_changed)
	_update_dynamic_button_visibility()
	_update_toggle_button_visual()

func _process(_delta: float) -> void:
	if not visible:
		return
	_update_dynamic_button_visibility()

func _bind_button(btn: Button, action: String) -> void:
	if not btn:
		return
	# 核心安全機制：取消按鈕的焦點模式，防止點擊時搶走鍵盤焦點導致方向鍵失靈
	btn.focus_mode = Control.FOCUS_NONE
	btn.button_down.connect(func(): _simulate_action(action, true))
	btn.button_up.connect(func(): _simulate_action(action, false))

func _simulate_action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func _apply_cyber_style() -> void:
	# Riso-inspired Cyberpunk 專用限色
	var bg_color := Color(0.08, 0.10, 0.12, 0.80)             # 深灰藍
	var border_color_normal := Color(0.22, 0.28, 0.29, 0.85)   # 鋼青灰
	var border_color_pressed := Color(0.78, 0.42, 0.20, 1.0)  # 主角橙紅
	var text_color_normal := Color(0.94, 0.92, 0.84, 0.90)    # 米白

	# 正常狀態樣式 (Flat, 1px 青灰邊框)
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = bg_color
	style_normal.border_color = border_color_normal
	style_normal.border_width_left = 1
	style_normal.border_width_top = 1
	style_normal.border_width_right = 1
	style_normal.border_width_bottom = 1
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	_style_normal = style_normal

	# 壓下狀態樣式 (2px 主角橙紅邊框)
	var style_pressed := style_normal.duplicate() as StyleBoxFlat
	style_pressed.border_color = border_color_pressed
	style_pressed.border_width_left = 2
	style_pressed.border_width_top = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_bottom = 2
	_style_pressed = style_pressed

	# 按鈕名單
	var all_buttons: Array[Button] = [
		btn_up, btn_down, btn_left, btn_right,
		btn_e, btn_r, btn_t,
		btn_bag, btn_note, btn_close
	]

	# 統一配置視覺樣式，防止點擊焦點影響外觀
	for btn in all_buttons:
		if not btn:
			continue
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_normal)
		btn.add_theme_stylebox_override("pressed", style_pressed)
		btn.add_theme_stylebox_override("focus", style_normal)

		btn.add_theme_color_override("font_color", text_color_normal)
		btn.add_theme_color_override("font_hover_color", text_color_normal)
		btn.add_theme_color_override("font_pressed_color", border_color_pressed)

	# 針對各按鈕調整合適的觸控尺寸 (滿足且大於 iOS HIG 44x44px 規範)
	for btn in [btn_up, btn_down, btn_left, btn_right]:
		btn.custom_minimum_size = Vector2(54, 54)
		btn.add_theme_font_size_override("font_size", 22)
	
	# 右上與右下所有功能按鈕統一採用 60x60 的正方形設計，字體統一為 18px，外觀尺寸絕對一致
	for btn in [btn_e, btn_r, btn_t, btn_bag, btn_note, btn_close]:
		btn.custom_minimum_size = Vector2(60, 60)
		btn.add_theme_font_size_override("font_size", 18)

	# 針對切換按鍵套用專屬的長方形 HUD 扁平樣式，與鍵盤提示高度貼合
	btn_toggle.custom_minimum_size = Vector2(110, 32)
	btn_toggle.add_theme_font_size_override("font_size", 14)
	btn_toggle.add_theme_stylebox_override("normal", style_normal)
	btn_toggle.add_theme_stylebox_override("hover", style_normal)
	btn_toggle.add_theme_stylebox_override("pressed", style_pressed)
	btn_toggle.add_theme_stylebox_override("focus", style_normal)
	btn_toggle.add_theme_color_override("font_color", text_color_normal)

func _on_ui_mode_changed(_new_mode: int) -> void:
	# 信號觸發時立即更新一次，以獲得最即時的響應
	_update_dynamic_button_visibility()

func _on_toggle_pressed() -> void:
	touch_buttons_enabled = not touch_buttons_enabled
	_update_toggle_button_visual()
	_update_dynamic_button_visibility()

func _update_toggle_button_visual() -> void:
	if btn_toggle == null:
		return
	if touch_buttons_enabled:
		btn_toggle.text = "[ 觸控: 開 ]"
		if _style_pressed:
			btn_toggle.add_theme_stylebox_override("normal", _style_pressed)
			btn_toggle.add_theme_stylebox_override("hover", _style_pressed)
	else:
		btn_toggle.text = "[ 觸控: 關 ]"
		if _style_normal:
			btn_toggle.add_theme_stylebox_override("normal", _style_normal)
			btn_toggle.add_theme_stylebox_override("hover", _style_normal)

func _update_dynamic_button_visibility() -> void:
	var mode := UIMode.get_mode()
	var scene := get_tree().current_scene
	if scene == null:
		return

	# 1. 決定左上角 BtnToggle 的顯示狀態：
	# 僅在 PC 端且為世界 NONE 模式、且開場獨白 monologue 播完時，才顯示該滑鼠切換開關。
	var is_pc := is_pc_platform
	var is_world_mode := (mode == UIMode.Mode.NONE)
	var monologue_active := false
	if scene.get("_opening_monologue_active") != null:
		monologue_active = scene._opening_monologue_active
	
	btn_toggle.visible = is_pc and is_world_mode and not monologue_active

	# 2. 如果是 PC 端且使用者未開啟「模擬觸控」，則強制隱藏 D-pad、Actions 和 Menus 所有按鈕
	if is_pc and not touch_buttons_enabled:
		$Control/DPad.visible = false
		$Control/Actions.visible = false
		$Control/Menus.visible = false
		return

	# 3. 正常啟用狀態下，按鍵顯示規則：D-pad 與 Menus 只要觸控啟用皆顯示 (Menus 依 mode 決定 Bag/Note vs Close)
	$Control/DPad.visible = true
	$Control/Actions.visible = true
	$Control/Menus.visible = true

	# 右上角選單快捷鍵與「X 返回」按鈕之動態切換顯示
	if mode == UIMode.Mode.NONE:
		btn_bag.visible = true
		btn_note.visible = true
		btn_close.visible = false
	else:
		btn_bag.visible = false
		btn_note.visible = false
		btn_close.visible = true

	# 右下角 E / R / T 交互按鍵的動態功能感知顯示
	match mode:
		UIMode.Mode.NONE:
			# 世界探索模式：僅在有可互動物件時浮現 E 按鍵；R 與 T 無功能，隱藏
			btn_r.visible = false
			btn_t.visible = false
			
			var current_interactable = scene.get("current_interactable")
			btn_e.visible = (current_interactable != null)

		UIMode.Mode.INVENTORY:
			# 背包模式：根據當前 Focused 的物品欄位狀態動態顯示
			var bag_grid = scene.get_node_or_null("UI/InventoryPanel/VBoxContainer/BagGrid")
			if bag_grid == null:
				btn_e.visible = false
				btn_r.visible = false
				btn_t.visible = false
				return
				
			var focused_index: int = bag_grid.get_focused_index()
			var items := GameState.get_inventory()
			var slot: Dictionary = items[focused_index] if focused_index < items.size() else {}
			
			if slot.is_empty():
				# 空格欄位：無動作可施，全數隱藏
				btn_e.visible = false
				btn_r.visible = false
				btn_t.visible = false
			else:
				var item_id: String = slot.get("item_id", "")
				var instance_id: String = slot.get("instance_id", "")
				var item_meta: Dictionary = GameState.ITEMS_DB.get(item_id, {})
				var category: String = item_meta.get("category", "")
				
				# E 鍵：如果是裝備、或可消耗、或有特殊使用效果時顯示
				var has_e_action = (category == "equipment") or (category == "consumable") or item_meta.has("consume_grants_note")
				btn_e.visible = has_e_action
				
				# R 鍵：任何佔用格均可查看詳細
				btn_r.visible = true
				
				# T 鍵：可丟棄且目前非裝備中
				var is_discardable = item_meta.get("discardable", true) and not GameState.is_equipped(instance_id)
				btn_t.visible = is_discardable

		UIMode.Mode.CONTAINER:
			# 雙欄儲存箱模式：根據 active_pane 以及對應 Focused 欄位狀態動態顯示
			var dual_pane = scene.get_node_or_null("UI/DualPaneContainer")
			if dual_pane == null or not dual_pane.is_input_active:
				btn_e.visible = false
				btn_r.visible = false
				btn_t.visible = false
				return
				
			var items_array: Array = []
			var index: int = 0
			if dual_pane.active_pane == "left":
				items_array = GameState.get_inventory()
				index = dual_pane._get_grid_focused_index(dual_pane.left_grid)
			else:
				items_array = GameState.get_container(dual_pane.container_id)
				index = dual_pane._get_grid_focused_index(dual_pane.right_grid)
				
			var slot: Dictionary = items_array[index] if index < items_array.size() else {}
			
			if slot.is_empty():
				# 空格欄位：無動作可施，全數隱藏
				btn_e.visible = false
				btn_r.visible = false
				btn_t.visible = false
			else:
				# 佔用格：E 移動、R 查看詳細
				btn_e.visible = true
				btn_r.visible = true
				
				# T 鍵：可丟棄且目前非裝備中
				var item_id: String = slot.get("item_id", "")
				var instance_id: String = slot.get("instance_id", "")
				var item_meta: Dictionary = GameState.ITEMS_DB.get(item_id, {})
				var is_discardable = item_meta.get("discardable", true) and not GameState.is_equipped(instance_id)
				btn_t.visible = is_discardable

		UIMode.Mode.NOTEBOOK:
			# 筆記本模式：沒有任何 E/R/T 面板行為，全數隱藏
			btn_e.visible = false
			btn_r.visible = false
			btn_t.visible = false

		UIMode.Mode.MESSAGE:
			# 訊息模式：E 鍵用於繼續；T 鍵為隱藏 skip 獨白捷徑；R 鍵隱藏
			btn_e.visible = true
			btn_r.visible = false
			btn_t.visible = true

		UIMode.Mode.CONFIRM:
			# 丟棄確認彈窗：E 鍵確定，X 返回鍵取消；R/T 隱藏
			btn_e.visible = true
			btn_r.visible = false
			btn_t.visible = false

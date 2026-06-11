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
@onready var dialogue_panel: Control = $DialoguePanel
@onready var pause_menu: Control = $PauseMenu
@onready var shop_panel: Control = $ShopPanel
@onready var world_hud_label: Label = $WorldHUDLabel
@onready var message_box: Control = $MessageBoxContainer/MessageBox
@onready var message_label: Label = $MessageBoxContainer/MessageBox/MarginContainer/MessageLabel
@onready var page_hint_label: Label = $MessageBoxContainer/MessageBox/PageHintLabel


var _last_mode: int = UIMode.Mode.NONE
var _mode_before_message: int = UIMode.Mode.NONE
var _message_just_opened: bool = false
var _level_context: Node = null
var _is_simple_message: bool = false
var _monologue_active: bool = false
var _current_prompt_data: Dictionary = {}

# Typewriter variables for show_message
var _message_full_text := ""
var _message_elapsed := 0.0
var _current_chars_per_second := 12.0
var _message_on_closed: Callable = Callable()
var _message_hint_shown: bool = false

var _pending_toast_title: String = ""
var _pending_inspect_modal: Dictionary = {}
var _audio_electromagnetic: AudioStreamPlayer = null

const DECODER_NOTES := GameState.STORY_NOTES
const DECODER_MESSAGES := GameState.STORY_MESSAGES

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
	dialogue_panel.visible = false
	pause_menu.visible = false
	shop_panel.visible = false
	page_hint_label.text = ""
	page_hint_label.visible = false
	
	_apply_message_box_style()
	
	UIMode.mode_changed.connect(_on_ui_mode_changed)
	
	# Enable item actions for bag grid
	if bag_grid.has_method("set_item_actions_enabled"):
		bag_grid.set_item_actions_enabled(true)
	
	# Connect UI item actions
	if bag_grid:
		bag_grid.item_action_requested.connect(_on_bag_item_action)
		bag_grid.focus_changed.connect(_on_bag_grid_focus_changed)
	if dual_pane_container:
		dual_pane_container.item_action_requested.connect(_on_dual_pane_item_action)

	# Setup electromagnetic audio player
	_audio_electromagnetic = AudioStreamPlayer.new()
	_audio_electromagnetic.name = "AudioElectromagnetic"
	_audio_electromagnetic.stream = load("res://assets/sound/slot_electromagnetic.wav")
	_audio_electromagnetic.volume_db = 6.0
	add_child(_audio_electromagnetic)

	GameState.note_added.connect(_on_note_added)

func _process(delta: float) -> void:
	if prompt_panel.visible and _level_context and _level_context.has_node("Player"):
		var player_node := _level_context.get_node("Player") as Node2D
		var anim_sprite := player_node.get_node("AnimatedSprite2D") as AnimatedSprite2D
		prompt_panel.reset_size()
		var sprite_screen_position: Vector2 = anim_sprite.get_global_transform_with_canvas().origin
		var prompt_size := prompt_panel.size
		var scale_factor: float = player_node.global_scale.y
		prompt_panel.position = sprite_screen_position + Vector2(-prompt_size.x * 0.45, -100.0 * scale_factor)

	_update_message_typewriter(delta)
	
	var current_mode := UIMode.get_mode()
	if current_mode == UIMode.Mode.MESSAGE:
		if _message_just_opened:
			_message_just_opened = false
			return
		
		if _is_simple_message:
			if is_message_finished() and not _message_hint_shown:
				_message_hint_shown = true
				set_message_page_hint("▼ 關閉" if not _message_on_closed.is_valid() and _pending_inspect_modal.is_empty() else "▼ 繼續", true)
			
			if Input.is_action_just_pressed("interact_primary") or Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_accept"):
				if not is_message_finished():
					force_finish_message()
					_message_hint_shown = true
					set_message_page_hint("▼ 關閉" if not _message_on_closed.is_valid() and _pending_inspect_modal.is_empty() else "▼ 繼續", true)
				else:
					if not _pending_inspect_modal.is_empty():
						close_message()
						var grid: Control = _pending_inspect_modal.get("restore_grid")
						if grid and grid.has_method("set_input_active"):
							grid.set_input_active(false)
						item_detail_modal.show_modal(
							_pending_inspect_modal.get("instance_id"),
							_pending_inspect_modal.get("restore_grid"),
							_pending_inspect_modal.get("restore_index"),
							_pending_inspect_modal.get("anchor_node")
						)
						_pending_inspect_modal.clear()
					else:
						var cb = _message_on_closed
						_message_on_closed = Callable()
						close_message()
						if cb.is_valid():
							cb.call()

	# UI Hotkey Navigation Handling
	if current_mode == UIMode.Mode.NONE:
		# Only allow opening UI if monologue is not active
		if not _monologue_active:
			if Input.is_action_just_pressed("open_inventory"):
				open_inventory()
				return
			if Input.is_action_just_pressed("open_notebook"):
				open_notebook()
				return
			if Input.is_action_just_pressed("ui_cancel"):
				open_pause_menu()
				return

	elif current_mode == UIMode.Mode.PAUSE:
		if pause_menu.visible and not pause_menu.save_slot_list.visible and not confirm_dialog.visible:
			if Input.is_action_just_pressed("ui_cancel"):
				close_all_ui()
				return
	elif current_mode == UIMode.Mode.INVENTORY:
		# Guard against modal/confirm overrides
		if Input.is_action_just_pressed("ui_cancel"):
			if item_detail_modal.visible:
				item_detail_modal.close_modal()
			else:
				close_all_ui()
			return
		if not item_detail_modal.visible:
			if Input.is_action_just_pressed("open_inventory"):
				close_all_ui()
				return
			if Input.is_action_just_pressed("open_notebook"):
				open_notebook()
				return
	elif current_mode == UIMode.Mode.NOTEBOOK:
		if Input.is_action_just_pressed("open_notebook") or Input.is_action_just_pressed("ui_cancel"):
			close_all_ui()
			return
		if Input.is_action_just_pressed("open_inventory"):
			open_inventory()
			return
	elif current_mode == UIMode.Mode.CONTAINER:
		# Guard against modal/confirm overrides
		if Input.is_action_just_pressed("ui_cancel"):
			if item_detail_modal.visible:
				item_detail_modal.close_modal()
			else:
				close_all_ui()
			return
		if not item_detail_modal.visible:
			if Input.is_action_just_pressed("open_inventory"):
				open_inventory()
				return
			if Input.is_action_just_pressed("open_notebook"):
				open_notebook()
				return
	elif current_mode == UIMode.Mode.SHOP:
		# SHOP 與 INVENTORY / NOTEBOOK 互斥：不處理 open_inventory / open_notebook
		if Input.is_action_just_pressed("ui_cancel"):
			close_all_ui()
			return

func set_world_context(level: Node) -> void:
	_level_context = level

func clear_world_context(level: Node = null) -> void:
	if level == null or _level_context == level:
		_level_context = null

func show_prompt(data: Dictionary) -> void:
	_current_prompt_data = data
	if UIMode.get_mode() != UIMode.Mode.NONE:
		prompt_panel.visible = false
		return
	prompt_label.text = data.get("prompt_text", "")
	prompt_panel.visible = true
	if _level_context and _level_context.has_node("Player"):
		var player_node := _level_context.get_node("Player") as Node2D
		var anim_sprite := player_node.get_node("AnimatedSprite2D") as AnimatedSprite2D
		prompt_panel.reset_size()
		var sprite_screen_position: Vector2 = anim_sprite.get_global_transform_with_canvas().origin
		var prompt_size := prompt_panel.size
		var scale_factor: float = player_node.global_scale.y
		prompt_panel.position = sprite_screen_position + Vector2(-prompt_size.x * 0.45, -100.0 * scale_factor)

func hide_prompt() -> void:
	_current_prompt_data = {}
	prompt_panel.visible = false

func has_current_interactable() -> bool:
	return not _current_prompt_data.is_empty()

func is_touch_toggle_blocked() -> bool:
	# Block touch controls toggle during monologue or message screens
	return _monologue_active

func set_monologue_active(active: bool) -> void:
	_monologue_active = active
	if world_hud_label:
		world_hud_label.visible = (UIMode.get_mode() == UIMode.Mode.NONE and not _monologue_active)

func show_message(text: String, on_closed: Callable = Callable(), note_title: String = "") -> void:
	_is_simple_message = true
	_message_on_closed = on_closed
	_message_full_text = text
	_message_elapsed = 0.0
	message_label.text = ""
	_current_chars_per_second = 12.0
	_message_hint_shown = false
	set_message_page_hint("", false)
	_resize_message_box_for_text(_message_full_text)
	if not note_title.is_empty():
		_pending_toast_title = note_title
	UIMode.enter_overlay(UIMode.Mode.MESSAGE)
	if DisplayServer.get_name() == "headless":
		force_finish_message()

func begin_message(text: String, options: Dictionary = {}) -> void:
	_is_simple_message = false
	_message_full_text = text
	_message_elapsed = 0.0
	message_label.text = ""
	_current_chars_per_second = options.get("chars_per_second", 12.0)
	_message_hint_shown = false
	set_message_page_hint("", false)
	_resize_message_box_for_text(_message_full_text)
	UIMode.enter_overlay(UIMode.Mode.MESSAGE)
	if DisplayServer.get_name() == "headless":
		force_finish_message()


func force_finish_message() -> void:
	message_label.text = _message_full_text
	_message_elapsed = _message_full_text.length() / _current_chars_per_second + 1.0

func is_message_finished() -> bool:
	return message_label.text.length() >= _message_full_text.length()

func set_message_page_hint(text: String, visible: bool) -> void:
	page_hint_label.text = text
	if visible:
		page_hint_label.visible = true
		page_hint_label.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(page_hint_label, "modulate:a", 1.0, 0.5)
	else:
		page_hint_label.visible = false

func close_message() -> void:
	_is_simple_message = false
	_message_full_text = ""
	_message_elapsed = 0.0
	message_label.text = ""
	page_hint_label.text = ""
	page_hint_label.visible = false
	_message_hint_shown = false
	UIMode.exit_overlay()

func show_toast(text: String, anchor_node: CanvasItem = null) -> void:
	FloatingToast.show_toast(text, anchor_node)

func open_inventory() -> void:
	UIMode.set_mode(UIMode.Mode.INVENTORY)

func open_notebook() -> void:
	UIMode.set_mode(UIMode.Mode.NOTEBOOK)

func open_pause_menu() -> void:
	UIMode.set_mode(UIMode.Mode.PAUSE)

func open_container(container_id: String, title: String, slot_count: int) -> void:
	UIMode.set_mode(UIMode.Mode.CONTAINER)
	dual_pane_container.set_input_active(true, container_id, slot_count, title)

func close_all_ui(reset_mode: bool = true) -> void:
	if reset_mode:
		UIMode.set_mode(UIMode.Mode.NONE)

func start_dialogue(dialogue_id: String) -> void:
	close_all_ui(false)
	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	if dialogue_panel:
		dialogue_panel.start_dialogue(dialogue_id)

func has_active_dialogue() -> bool:
	return dialogue_panel != null and dialogue_panel.visible

func dialogue_move_focus(dir: int) -> void:
	if dialogue_panel and dialogue_panel.visible:
		dialogue_panel.move_focus(dir)

func dialogue_confirm() -> void:
	if dialogue_panel and dialogue_panel.visible:
		dialogue_panel.confirm_current()

# ==========================================
# Shop API (Phase 8-F)
# ==========================================
func open_shop(shop_id: String) -> void:
	close_all_ui(false)
	UIMode.set_mode(UIMode.Mode.SHOP)
	if shop_panel:
		shop_panel.open(shop_id)

func is_shop_open() -> bool:
	return shop_panel != null and shop_panel.is_open()

func shop_move_focus(dir: int) -> void:
	if is_shop_open():
		shop_panel.move_focus(dir)

func shop_switch_pane(dir: int) -> void:
	if is_shop_open():
		shop_panel.switch_pane(dir)

func shop_confirm() -> void:
	if is_shop_open():
		shop_panel.confirm_current()


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
		var is_left = (dual_pane_container.active_pane == "left")
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
	if is_instance_valid(dialogue_panel):
		dialogue_panel.visible = (new_mode == UIMode.Mode.DIALOGUE) or (new_mode == UIMode.Mode.MESSAGE and _mode_before_message == UIMode.Mode.DIALOGUE)
	if is_instance_valid(pause_menu):
		pause_menu.visible = (new_mode == UIMode.Mode.PAUSE) or (new_mode == UIMode.Mode.MESSAGE and _mode_before_message == UIMode.Mode.PAUSE)
	if is_instance_valid(shop_panel):
		shop_panel.visible = (new_mode == UIMode.Mode.SHOP) or (new_mode == UIMode.Mode.MESSAGE and _mode_before_message == UIMode.Mode.SHOP)

	if is_instance_valid(world_hud_label):
		world_hud_label.visible = (new_mode == UIMode.Mode.NONE and not _monologue_active)

	bag_grid.set_input_active(new_mode == UIMode.Mode.INVENTORY)
	notebook_panel.set_input_active(new_mode == UIMode.Mode.NOTEBOOK)
	dual_pane_container.set_input_active(false)
	if is_instance_valid(dialogue_panel):
		dialogue_panel.set_input_active(new_mode == UIMode.Mode.DIALOGUE)
	if is_instance_valid(shop_panel):
		shop_panel.set_input_active(new_mode == UIMode.Mode.SHOP)

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
	elif new_mode == UIMode.Mode.DIALOGUE:
		prompt_panel.visible = false
	elif new_mode == UIMode.Mode.PAUSE:
		prompt_panel.visible = false
		if is_instance_valid(pause_menu):
			pause_menu.initialize_menu()
	elif new_mode == UIMode.Mode.SHOP:
		prompt_panel.visible = false
	elif new_mode == UIMode.Mode.NONE:
		item_detail_modal.visible = false
		confirm_dialog.visible = false
		if is_instance_valid(shop_panel) and shop_panel.is_open():
			shop_panel.close()
		if has_current_interactable():
			show_prompt(_current_prompt_data)
		else:
			prompt_panel.visible = false
		_check_and_trigger_endings()

	if (_last_mode == UIMode.Mode.MESSAGE or _last_mode == UIMode.Mode.DIALOGUE) and not _pending_toast_title.is_empty():
		var anchor: Node2D = null
		if _level_context and _level_context.has_node("Player"):
			anchor = _level_context.get_node("Player")
		if _pending_toast_title.begins_with("已更新") or _pending_toast_title.begins_with("已記入"):
			show_toast(_pending_toast_title, anchor)
		else:
			show_toast("已記入筆記：" + _pending_toast_title, anchor)
		_pending_toast_title = ""

	_last_mode = new_mode

func _check_and_trigger_endings() -> void:
	if QuestManager.get_status("alley_backrooms_3f") == "completed" and not GameState.get_flag("alley_backrooms_ended", false):
		GameState.set_flag("alley_backrooms_ended", true)
		
		if GameState.get_flag("gave_wan_old_module", false):
			var page1 := "【第二段劇情完成 - 結局 3：託付】\n\n你將啟用盒連同隱密夾層中發現的「舊式 AI 授權模組」一起交給了晚。\n你選擇了信任與慷慨，將這份可能非比尋常的遺產託付給了同樣對抗遺忘的晚。"
			var page2 := "晚感到驚訝，她看著那枚精緻的金屬晶片，眼中閃過少有的溫潤。這份多出來的重禮，讓你們之間多了一層心照不宣的默契。\n\n（提示：若保留授權模組不交，將會觸發「結局 2：拾遺者的直覺」；若從未發現隱密夾層，將觸發「結局 1：盲目的清理者」）"
			show_message(page1, func(): show_message(page2))
		elif QuestManager.get_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false):
			var page1 := "【第二段劇情完成 - 結局 2：拾遺者的直覺】\n\n你只交出了明面上的啟用盒，而將暗中拆解出的「舊式 AI 授權模組」留在了背包深處。\n你用直覺對抗了系統的遺忘，將真正的遺產扣留了下來。"
			var page2 := "晚沒有察覺，或者，她只是看破而不說破。這枚晶片將由你妥善保管。\n\n（提示：若連同夾層模組一同交還給晚，將會觸發「結局 3：託付」；若未發現隱密夾層直接回報，將觸發「結局 1：盲目的清理者」）"
			show_message(page1, func(): show_message(page2))
		else:
			var page1 := "【第二段劇情完成 - 結局 1：盲目的清理者】\n\n你將啟用盒原封不動地交給了晚。你得到了應得的酬勞，轉身步入下層街區的冷雨之中。"
			var page2 := "這座城市依然在雨中運轉，舊日的痕跡在一點點被抹去。你將手收入口袋，繼續尋找著自己失落的記憶。"
			show_message(page1, func(): show_message(page2))

	if QuestManager.get_status("repair_vendor_bot") == "completed" and not GameState.get_flag("repair_vendor_bot_ended", false):
		GameState.set_flag("repair_vendor_bot_ended", true)
		
		var resolution = GameState.get_flag("store_robot_resolution", "")
		if resolution == "gleaned":
			var page1 := "【第三段劇情完成 - 結局 2：溫存的殘響】\n\n你拷貝了阿達在主機備份區留下的最後日記與情緒包，然後才按下了重置鍵。\n店籍主機發出低沉的嗡鳴，重啟後的機器人重新抬起頭，用字正腔圓、毫無溫度的AI合成語音向你致謝。"
			var page2 := "阿達的怒吼、無奈、與最後的「憑什麼」，在機器人的記憶庫中已經蕩然無存。\n但那塊晶片安靜地躺在你的背包裡。只要你的儲存載體還在，他在這座冰冷都市留下的溫度，就不算完全被系統抹殺。"
			var page3 := "這座城市不再需要人類的呼吸與體溫，系統只要求一切高效、無瑕。\n但在那段被你帶走的殘響裡，你聽見了一個被拋棄的白領店員最後的掙扎──那是人類不願輕易被AI取代、拒絕被無聲抹除的證明。\n\n（提示：若未深入診斷、未拷貝殘響即直接重置主機，將會觸發「結局 1：高效的系統」）"
			show_message(page1, func(): show_message(page2, func(): show_message(page3)))
		else:
			var page1 := "【第三段劇情完成 - 結局 1：高效的系統】\n\n你重置了店籍主機。那台曾發出人類夢囈與怨言的機器人，如今安靜地退回了原本的零售人格。\n螢幕上的紅色故障燈熄滅，換來的是一行行冰冷、精準且毫無破綻的服務日誌。"
			var page2 := "阿達這個名字，連同他寫在程式底層的情緒殘留，已經在數據格式化的過程中被徹底抹除。\n店裡的招牌燈光重新亮起，連鎖路由順暢運轉。一切都很完美，沒有留下一絲人類待過的累贅痕跡。"
			show_message(page1, func(): show_message(page2))






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


# ==========================================
# UI Item Action Routing & Execution
# ==========================================

func _on_bag_item_action(action: String, instance_id: String) -> void:
	if UIMode.get_mode() != UIMode.Mode.INVENTORY:
		return
	if instance_id.is_empty():
		return

	var item_id := ""
	for slot in GameState.get_inventory():
		if slot.get("instance_id", "") == instance_id:
			item_id = slot.get("item_id", "")
			break
	var item_meta: Dictionary = GameState.ITEMS_DB.get(item_id, {})

	match action:
		"view":
			if item_meta.has("consume_grants_note"):
				_handle_item_use(instance_id, item_meta)
			else:
				var decodable_to: String = item_meta.get("decodable_to", "")
				if not decodable_to.is_empty() and _player_has_decoding_ability():
					_pending_inspect_modal = {
						"instance_id": instance_id,
						"restore_grid": bag_grid,
						"restore_index": bag_grid.focused_index,
						"anchor_node": inventory_panel
					}
					_execute_item_decoding(instance_id, decodable_to)
				else:
					if item_id == "fingerless_gloves" and not GameState.has_note("clue_gloves_decoder"):
						GameState.add_knowledge(DECODER_NOTES["clue_gloves_decoder"])

					if item_meta.has("inspect_grants_item"):
						_handle_inspect_grants_item(instance_id, item_meta, bag_grid, bag_grid.focused_index, inventory_panel)
					else:
						bag_grid.set_input_active(false)
						item_detail_modal.show_modal(instance_id, bag_grid, bag_grid.focused_index, inventory_panel)
		"discard":
			_start_discard_flow(instance_id, item_meta, bag_grid, bag_grid.focused_index)
		"equip_toggle":
			var category: String = item_meta.get("category", "")
			if category == "consumable" or item_meta.has("consume_grants_note"):
				_handle_item_use(instance_id, item_meta)
			elif category == "equipment":
				_handle_equip_toggle(instance_id, item_meta)

func _on_dual_pane_item_action(action: String, instance_id: String, source_pane: String) -> void:
	if UIMode.get_mode() != UIMode.Mode.CONTAINER:
		return
	if instance_id.is_empty():
		return

	var item_id := _find_item_id_anywhere(instance_id)
	var item_meta: Dictionary = GameState.ITEMS_DB.get(item_id, {})
	var active_grid: Control = dual_pane_container.left_grid if source_pane == "left" else dual_pane_container.right_grid
	var active_idx: int = active_grid.focused_index
	var anchor_panel: Control = dual_pane_container.left_panel if source_pane == "left" else dual_pane_container.right_panel

	match action:
		"view":
			if item_meta.has("consume_grants_note"):
				_handle_item_use(instance_id, item_meta)
			else:
				var decodable_to: String = item_meta.get("decodable_to", "")
				if not decodable_to.is_empty() and _player_has_decoding_ability():
					_pending_inspect_modal = {
						"instance_id": instance_id,
						"restore_grid": active_grid,
						"restore_index": active_idx,
						"anchor_node": anchor_panel
					}
					_execute_item_decoding(instance_id, decodable_to)
				else:
					if item_id == "fingerless_gloves" and not GameState.has_note("clue_gloves_decoder"):
						GameState.add_knowledge(DECODER_NOTES["clue_gloves_decoder"])

					if item_meta.has("inspect_grants_item"):
						_handle_inspect_grants_item(instance_id, item_meta, active_grid, active_idx, anchor_panel)
					else:
						item_detail_modal.show_modal(instance_id, active_grid, active_idx, anchor_panel)
		"discard":
			_start_discard_flow(instance_id, item_meta, active_grid, active_idx)

func _handle_inspect_grants_item(instance_id: String, item_meta: Dictionary, grid: Control, index: int, anchor: Control) -> void:
	var inspect_grants_flag: String = item_meta.get("inspect_grants_flag", "")
	var grants_item_id: String = item_meta.get("inspect_grants_item", "")
	
	if QuestManager.get_flag("alley_backrooms_3f", inspect_grants_flag, false):
		grid.set_input_active(false)
		item_detail_modal.show_modal(instance_id, grid, index, anchor)
		return
		
	grid.set_input_active(false)
	
	var on_first_inspect_closed = func():
		var added := GameState.add_item(grants_item_id, 1)
		if added:
			QuestManager.set_flag("alley_backrooms_3f", inspect_grants_flag, true)
			item_detail_modal.show_modal(instance_id, grid, index, anchor)
		else:
			show_message(
				"你發現了啟用盒底部的夾層，裡面塞著一片泛著冷光的薄卡片，但你的背包太滿了，無法將它取出。整理一下空間後再查看吧。",
				func():
					item_detail_modal.show_modal(instance_id, grid, index, anchor)
			)
			
	show_message(
		"你仔細端詳啟用盒的底部，掀開了一個隱蔽的塑料卡扣夾層。夾層內嵌著一片泛著冷光的薄金屬卡。\n（獲得了「舊式 AI 授權模組」。）",
		on_first_inspect_closed
	)

func _handle_item_use(instance_id: String, item_meta: Dictionary) -> void:
	var note_id: String = item_meta.get("consume_grants_note", "")
	if not note_id.is_empty():
		var note_data: Dictionary = DECODER_NOTES.get(note_id, {})
		_pending_toast_title = note_data.get("title", "")
		GameState.add_knowledge(note_data)
		show_message(DECODER_MESSAGES["nutrition_bar_consume"])
		GameState.discard_item(instance_id)
	else:
		var toast_panel := _get_active_panel()
		show_toast("現在用不上。", toast_panel)

func _handle_equip_toggle(instance_id: String, item_meta: Dictionary) -> void:
	if item_meta.get("category", "") != "equipment":
		return

	var item_id: String = item_meta.get("id", "")
	if GameState.is_equipped(instance_id):
		GameState.unequip_by_instance(instance_id)
	else:
		if not GameState.equip(instance_id):
			show_toast(
				"這類裝備已經滿了，先卸下身上的再裝備新的。",
				inventory_panel
			)
		elif item_id == "fingerless_gloves" and not GameState.has_note("clue_gloves_decoder"):
			GameState.add_knowledge(DECODER_NOTES["clue_gloves_decoder"])

func _start_discard_flow(instance_id: String, item_meta: Dictionary,
						 restore_grid: Control, restore_index: int) -> void:
	var item_name: String = item_meta.get("name", "物品")
	var toast_panel := _get_active_panel()

	if not item_meta.get("discardable", true):
		show_toast("無法丟棄 " + item_name, toast_panel)
		return
	if GameState.is_equipped(instance_id):
		show_toast("請先卸下再丟棄", toast_panel)
		return

	UIMode.enter_confirm()
	confirm_dialog.show_dialog(
		"確定要丟棄 " + item_name + "？",
		_on_discard_confirmed.bind(instance_id, item_name, toast_panel),
		restore_grid,
		restore_index
	)

func _on_discard_confirmed(instance_id: String, item_name: String, toast_panel: Control) -> void:
	if GameState.discard_item(instance_id):
		show_toast("已丟棄 " + item_name, toast_panel)

func _get_active_panel() -> Control:
	if UIMode.get_mode() == UIMode.Mode.INVENTORY:
		return inventory_panel
	return dual_pane_container

func _find_item_id_anywhere(instance_id: String) -> String:
	for slot in GameState.get_inventory():
		if slot.get("instance_id", "") == instance_id:
			return slot.get("item_id", "")
	for c_id in GameState.external_containers.keys():
		for slot in GameState.get_container(c_id):
			if slot.get("instance_id", "") == instance_id:
				return slot.get("item_id", "")
	return ""

func _player_has_decoding_ability() -> bool:
	var eq := GameState.get_equipment()
	var hand_instances: Array = eq.get("hand", [])
	for instance_id in hand_instances:
		var item_id := _find_item_id_anywhere(instance_id)
		if not item_id.is_empty():
			var item_meta: Dictionary = GameState.ITEMS_DB.get(item_id, {})
			if item_meta.get("can_decode", false):
				return true
	return false

func _execute_item_decoding(instance_id: String, target_item_id: String) -> void:
	var success = GameState.change_item_id(instance_id, target_item_id)
	if success:
		GameState.add_knowledge(DECODER_NOTES["clue_decoder_cube"])
		if _audio_electromagnetic:
			_audio_electromagnetic.play()
		show_message(DECODER_MESSAGES["decoder_cube_decoded"])

func _on_bag_grid_focus_changed(index: int) -> void:
	_update_backpack_footer(index)

func _update_backpack_footer(index: int) -> void:
	if UIMode.get_mode() != UIMode.Mode.INVENTORY:
		return
	var items := GameState.get_inventory()
	if index < 0 or index >= items.size() or items[index].is_empty():
		panel_footer_hint.set_hints(panel_footer_hint, ["Esc/I: 關閉"])
		return

	var slot_data: Dictionary = items[index]
	var item_id: String = slot_data.get("item_id", "")
	var instance_id: String = slot_data.get("instance_id", "")
	var item_meta: Dictionary = GameState.ITEMS_DB.get(item_id, {})
	var category: String = item_meta.get("category", "")

	var hints := []
	if category == "equipment":
		if GameState.is_equipped(instance_id):
			hints.append("E: 卸下")
		else:
			hints.append("E: 裝備")
	elif category == "consumable" or item_meta.has("consume_grants_note"):
		hints.append("E: 使用")

	hints.append_array(["R: 查看", "T: 丟棄", "Esc/I: 關閉"])
	panel_footer_hint.set_hints(panel_footer_hint, hints)

func _on_note_added(note_data: Dictionary, is_update: bool) -> void:
	_show_or_queue_note_toast.call_deferred(note_data, is_update)

func _show_or_queue_note_toast(note_data: Dictionary, is_update: bool) -> void:
	var title: String = note_data.get("title", "")
	var category: String = note_data.get("category", "")
	var prefix = "已更新" if is_update else "已記入"
	
	# Determine toast text
	var toast_text = ""
	if category == "工作":
		toast_text = prefix + "工作：" + title
	else:
		toast_text = prefix + "筆記：" + title

	# If message box or dialogue is active, queue it
	var mode := UIMode.get_mode()
	if mode == UIMode.Mode.MESSAGE or mode == UIMode.Mode.DIALOGUE:
		_pending_toast_title = toast_text
	else:
		# Show immediately
		var anchor: Node2D = null
		if _level_context and _level_context.has_node("Player"):
			anchor = _level_context.get_node("Player")
		show_toast(toast_text, anchor)

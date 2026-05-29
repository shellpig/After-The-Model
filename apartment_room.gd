extends Node2D

const MESSAGES := {
	"bed_bad_sleep": "你心中有事, 根本睡不著...",
	"door_locked": "門上了鎖, 而你發現自己不知道如何打開...",
	"door_opened": "你想起來了。門鎖不是壞了, 是你忘了操作方式。",
	"desk_computer_msg": "螢幕還亮著, 一份新的派工單正自己跳出來, 沒有寄件人。",
	"tape_recorder_msg": "錄音機裡卡著一捲帶子。按下播放, 是首沒人記得的老歌, 雜訊裡有人輕輕跟著哼。",
	"decoder_cube_decoded": "當你戴著無指手套拿起魔術方塊時，指尖的接點突然傳來一陣微弱的電流，方塊的接縫處隨之亮起了一道黯淡的迴路光芒。方塊的結構在微弱的喀噠聲中重新排列——它被解碼了。"
}

const NOTES := {
	"work_ai_cleanup_role": {
		"id": "work_ai_cleanup_role",
		"category": "工作",
		"title": "AI 善後員",
		"body": "派工單一筆一筆自己跳出來, 地址、編號, 註記欄寫著「殘留清除」「記憶體焚毀」。從沒見過發派的人, 只有螢幕那頭簡短的指示, 從不寒暄, 也從不出錯。原來你靠這個過活——收拾 AI 留下的、人們不想再看見的東西。",
		"status": "active"
	},
	"identity_gleaner": {
		"id": "identity_gleaner",
		"category": "身份",
		"title": "拾遺者",
		"body": "牆上整排都是舊帶子, 老歌、舊廣播、不知道誰的留言。這些早該被善後員銷毀的東西, 你卻一捲一捲留了下來。你一邊清除過去, 一邊偷偷把它撿回家。",
		"status": "active"
	},
	"clue_gloves_decoder": {
		"id": "clue_gloves_decoder",
		"category": "線索",
		"title": "不只是手套",
		"body": "這雙手套你戴得很習慣, 習慣到忘了它哪裡不對勁。指尖那圈接點碰到某些東西時, 會有反應。你還想不起它是用來「讀」什麼的——但你的手記得。",
		"status": "active"
	},
	"clue_decoder_cube": {
		"id": "clue_decoder_cube",
		"category": "線索",
		"title": "解碼方塊",
		"body": "一種普遍用於解開設備功能的道具, 性質有點像鑰匙。放入對應的插槽, 就能開啟特定功能。",
		"status": "active"
	}
}

const CONTAINERS := {
	"cabinet_storage": {
		"title": "櫥櫃",
		"cols": 5,
		"rows": 6,
		"skin": "cabinet",
		"panel_position": Vector2(844.0, 64.0)
	},
	"fridge_storage": {
		"title": "冰箱",
		"cols": 5,
		"rows": 2,
		"skin": "fridge",
		"panel_position": Vector2(720.0, 64.0)
	}
}


const MESSAGE_CHARS_PER_SECOND := 6.0
const MESSAGE_PADDING := Vector2(32.0, 20.0)
@onready var prompt_panel: Control = $UI/PromptPanel
@onready var prompt_label: Label = $UI/PromptPanel/MarginContainer/PromptLabel
@onready var message_box: Control = $UI/MessageBox
@onready var message_label: Label = $UI/MessageBox/MarginContainer/MessageLabel
@onready var player: Node2D = $Player
@onready var dual_pane_container: Control = $UI/DualPaneContainer

@onready var ui_overlay: ColorRect = $UI/UIOverlay
@onready var inventory_panel: PanelContainer = $UI/InventoryPanel
@onready var bag_grid: Control = $UI/InventoryPanel/VBoxContainer/BagGrid
@onready var credits_label: Label = $UI/InventoryPanel/VBoxContainer/HBoxContainer/CreditsLabel
@onready var panel_footer_hint: Control = $UI/InventoryPanel/VBoxContainer/PanelFooterHint
@onready var notebook_panel: Control = $UI/NotebookPanel
@onready var item_detail_modal: Control = $UI/ItemDetailModal
@onready var confirm_dialog: Control = $UI/ConfirmDialog

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var message_full_text := ""
var message_elapsed := 0.0
var _last_mode: int = UIMode.Mode.NONE
var _pending_toast_title: String = ""
var _mode_before_message: int = UIMode.Mode.NONE
var _pending_inspect_modal: Dictionary = {}
var _message_just_opened: bool = false

func _ready() -> void:
	_apply_message_box_style()
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

	# Preload containers for Phase 1-D
	GameState.configure_container("cabinet_storage", 30)  # 5 x 6
	GameState.configure_container("fridge_storage", 10)   # 5 x 2

	var _ok_jacket := GameState.seed_container("cabinet_storage", "faded_jacket", 1)
	var _ok_cabinet_food := GameState.seed_container("cabinet_storage", "canned_food", 2)
	var _ok_fridge_food := GameState.seed_container("fridge_storage", "canned_food", 3)
	var _ok_rubik := GameState.seed_container("cabinet_storage", "worn_rubiks_cube", 1)


	# Preload inventory robustly
	var has_item := false
	for slot in GameState.get_inventory():
		if not slot.is_empty():
			has_item = true
			break
	if not has_item:
		GameState.add_item("fingerless_gloves", 1)
		GameState.add_item("old_work_badge", 1)

	# Preload 2 story notes for Phase 2
	GameState.add_knowledge({
		"id": "identity_apartment_is_mine",
		"category": "身份",
		"title": "這裡是我的公寓",
		"body": "你雖然不記得名字, 但這裡的氣味、磨損的痕跡、書桌的擺法...都是你熟悉的。",
		"status": "active"
	})
	GameState.add_knowledge({
		"id": "clue_door_sensor_scratch",
		"category": "線索",
		"title": "門旁感應器的刮痕",
		"body": "門旁的感應器有長期使用的刮痕。看起來是右手手套經常碰過的位置。",
		"status": "active"
	})
	GameState.add_knowledge({
		"id": "clue_long_scroll_test",
		"category": "線索",
		"title": "測試長筆記捲動",
		"body": "這是一篇用來測試右側全文欄 Page Up / Page Down 滾動功能的長筆記。\n第一行：AI 改變了整個世界，留下無盡的殘骸與記憶。\n第二行：善後員在雨夜中漫步，霓虹燈光在積水中折射出破碎的色彩。\n第三行：感應器的深處發出微弱的嗡嗡聲，似乎在訴說著昔日的故事。\n第四行：這間小公寓是你在這個冰冷都市中的唯一庇護所。\n第五行：牆上的 riso 海報已經泛黃，邊角微微捲起。\n第六行：你需要集齊所有的線索，才能想起來大門的密碼鎖開法。\n第七行：右手套上的磨損痕跡，暗示著你過去頻繁的清理工作。\n第八行：門外的警笛聲漸漸遠去，夜雨依然下個不停。\n第九行：這是一篇長筆記，請按下 Page Down 鍵來體驗全文滾動！\n第十行：測試結束，感謝您的配合！",
		"status": "active"
	})

	UIMode.mode_changed.connect(_on_ui_mode_changed)
	panel_footer_hint.set_hints(panel_footer_hint, ["E: 裝備/卸下", "R: 查看", "T: 丟棄", "Esc/I: 關閉"])

	# Phase 1-E: enable item actions for the standalone bag_grid
	if bag_grid.has_method("set_item_actions_enabled"):
		bag_grid.set_item_actions_enabled(true)
	bag_grid.item_action_requested.connect(_on_bag_item_action)
	dual_pane_container.item_action_requested.connect(_on_dual_pane_item_action)

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)

	GameState.item_moved.connect(_on_item_moved)

func _process(_delta: float) -> void:
	_update_message_typewriter(_delta)

	var current_mode := UIMode.get_mode()

	# Layered UI input handling
	if current_mode != UIMode.Mode.NONE:
		# Bug 1 fix: _process poll is not affected by set_input_as_handled; guard explicitly.
		if item_detail_modal.visible and current_mode != UIMode.Mode.MESSAGE:
			return
		if current_mode == UIMode.Mode.CONFIRM:
			return

		if current_mode == UIMode.Mode.INVENTORY:
			if Input.is_action_just_pressed("open_inventory") or Input.is_action_just_pressed("ui_cancel"):
				UIMode.set_mode(UIMode.Mode.NONE)
				return
			if Input.is_action_just_pressed("open_notebook"):
				UIMode.set_mode(UIMode.Mode.NOTEBOOK)
				return
		elif current_mode == UIMode.Mode.NOTEBOOK:
			if Input.is_action_just_pressed("open_notebook") or Input.is_action_just_pressed("ui_cancel"):
				UIMode.set_mode(UIMode.Mode.NONE)
				return
			if Input.is_action_just_pressed("open_inventory"):
				UIMode.set_mode(UIMode.Mode.INVENTORY)
				return
		elif current_mode == UIMode.Mode.MESSAGE:
			if _message_just_opened:
				_message_just_opened = false
				return
			if Input.is_action_just_pressed("interact_primary") or Input.is_action_just_pressed("ui_cancel"):
				if not _pending_inspect_modal.is_empty():
					UIMode.set_mode(_mode_before_message)
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
				elif item_detail_modal.visible:
					UIMode.set_mode(_mode_before_message)
					item_detail_modal.refresh_modal()
				else:
					UIMode.set_mode(UIMode.Mode.NONE)
				return
			if Input.is_action_just_pressed("open_inventory"):
				_pending_inspect_modal.clear()
				UIMode.set_mode(UIMode.Mode.INVENTORY)
				return
			if Input.is_action_just_pressed("open_notebook"):
				_pending_inspect_modal.clear()
				UIMode.set_mode(UIMode.Mode.NOTEBOOK)
				return
		elif current_mode == UIMode.Mode.CONTAINER:
			if Input.is_action_just_pressed("ui_cancel"):
				UIMode.set_mode(UIMode.Mode.NONE)
				return
			if Input.is_action_just_pressed("open_inventory"):
				UIMode.set_mode(UIMode.Mode.INVENTORY)
				return
			if Input.is_action_just_pressed("open_notebook"):
				UIMode.set_mode(UIMode.Mode.NOTEBOOK)
				return
		return # Block world actions when UI is open

	# NONE Mode: process opening keys & world interactions
	if Input.is_action_just_pressed("open_inventory"):
		UIMode.set_mode(UIMode.Mode.INVENTORY)
		return
	if Input.is_action_just_pressed("open_notebook"):
		UIMode.set_mode(UIMode.Mode.NOTEBOOK)
		return

	_refresh_current_interactable()

	if current_interactable == null:
		return

	_position_prompt_above_player()

	if Input.is_action_just_pressed("interact_primary"):
		if CONTAINERS.has(current_interactable.interaction_id):
			UIMode.set_mode(UIMode.Mode.CONTAINER)
		elif not current_interactable.note_id.is_empty():
			var note_id: String = current_interactable.note_id
			if not GameState.has_note(note_id):
				_pending_toast_title = NOTES[note_id].title
			else:
				_pending_toast_title = ""
			GameState.add_knowledge(NOTES[note_id])
			_start_message_typewriter(MESSAGES.get(current_interactable.message_id, ""))
			UIMode.set_mode(UIMode.Mode.MESSAGE)
		else:
			match current_interactable.interaction_id:
				"bed_sleep":
					_start_message_typewriter(MESSAGES.get(current_interactable.message_id, ""))
					UIMode.set_mode(UIMode.Mode.MESSAGE)
				"door_exit":
					var required_knowledge: String = current_interactable.required_knowledge
					var message_id := "door_opened" if GameState.has_knowledge(required_knowledge) else "door_locked"
					_start_message_typewriter(MESSAGES.get(message_id, ""))
					UIMode.set_mode(UIMode.Mode.MESSAGE)

func _on_interactable_entered(interactable: Area2D) -> void:
	if not nearby_interactables.has(interactable):
		nearby_interactables.append(interactable)
	_refresh_current_interactable()

func _on_interactable_exited(interactable: Area2D) -> void:
	nearby_interactables.erase(interactable)
	_refresh_current_interactable()

func _refresh_current_interactable() -> void:
	var closest_interactable := _get_closest_interactable()
	if current_interactable == closest_interactable:
		return

	current_interactable = closest_interactable

	# Only clear/hide panels if we are not in a UI mode
	if UIMode.get_mode() == UIMode.Mode.NONE:
		message_box.visible = false
		_clear_message_typewriter()


	if current_interactable == null:
		prompt_panel.visible = false
	else:
		_update_prompt()

func _get_closest_interactable() -> Area2D:
	var closest_interactable: Area2D = null
	var closest_distance := INF
	var player_position := player.global_position

	for interactable in nearby_interactables:
		if not is_instance_valid(interactable):
			continue

		var distance := player_position.distance_squared_to(_get_interactable_position(interactable))
		if distance < closest_distance:
			closest_distance = distance
			closest_interactable = interactable

	return closest_interactable

func _get_interactable_position(interactable: Area2D) -> Vector2:
	var collision_shape := interactable.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		return collision_shape.global_position

	return interactable.global_position

func _on_ui_mode_changed(new_mode: int) -> void:
	# Bug 4 fix: CONFIRM mode — show dialog but don't touch overlay/panels/dual-pane state
	if new_mode == UIMode.Mode.CONFIRM:
		confirm_dialog.visible = true
		return

	if new_mode == UIMode.Mode.MESSAGE:
		_message_just_opened = true
		if _last_mode != UIMode.Mode.MESSAGE:
			_mode_before_message = _last_mode

	ui_overlay.visible = (new_mode != UIMode.Mode.NONE)

	inventory_panel.visible = (new_mode == UIMode.Mode.INVENTORY)
	dual_pane_container.visible = (new_mode == UIMode.Mode.CONTAINER)
	message_box.visible = (new_mode == UIMode.Mode.MESSAGE)
	notebook_panel.visible = (new_mode == UIMode.Mode.NOTEBOOK)

	if new_mode != UIMode.Mode.MESSAGE:
		_clear_message_typewriter()

	bag_grid.set_input_active(new_mode == UIMode.Mode.INVENTORY)
	notebook_panel.set_input_active(new_mode == UIMode.Mode.NOTEBOOK)

	# Bug 3 fix: only call set_input_active(true) if not already active (guard prevents resetting active_pane)
	if new_mode == UIMode.Mode.CONTAINER and current_interactable != null:
		if not dual_pane_container.is_input_active:
			var c_id: String = current_interactable.interaction_id
			var c_data: Dictionary = CONTAINERS.get(c_id, {})
			var c_slot_count: int = c_data.get("cols", 1) * c_data.get("rows", 1)
			var c_title: String = c_data.get("title", "儲物空間")
			dual_pane_container.set_input_active(true, c_id, c_slot_count, c_title)
		prompt_panel.visible = false
	else:
		if new_mode != UIMode.Mode.CONTAINER:
			dual_pane_container.set_input_active(false)

	if new_mode == UIMode.Mode.INVENTORY:
		var items := GameState.get_inventory()
		bag_grid.initialize_grid(items)
		bag_grid.set_focused_index(0)
		credits_label.text = "Credits: %d" % GameState.get_credits()
		prompt_panel.visible = false
	elif new_mode == UIMode.Mode.MESSAGE:
		prompt_panel.visible = false
	elif new_mode == UIMode.Mode.NOTEBOOK:
		notebook_panel.load_notebook_data()
		prompt_panel.visible = false
	elif new_mode == UIMode.Mode.NONE:
		if _last_mode == UIMode.Mode.MESSAGE and not _pending_toast_title.is_empty():
			FloatingToast.show_toast("已記入筆記：" + _pending_toast_title, player)
		_pending_toast_title = ""
		item_detail_modal.visible = false
		confirm_dialog.visible = false
		_update_prompt()

	if new_mode == UIMode.Mode.INVENTORY or new_mode == UIMode.Mode.NOTEBOOK:
		_pending_toast_title = ""
	_last_mode = new_mode

# ==========================================
# Phase 1-E: Item Action Routing
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
					GameState.add_knowledge(NOTES["clue_gloves_decoder"])
					FloatingToast.show_toast("已記入筆記：" + NOTES["clue_gloves_decoder"].title, player)

				bag_grid.set_input_active(false)
				item_detail_modal.show_modal(instance_id, bag_grid, bag_grid.focused_index, inventory_panel)
		"discard":
			_start_discard_flow(instance_id, item_meta, bag_grid, bag_grid.focused_index)
		"equip_toggle":
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
					GameState.add_knowledge(NOTES["clue_gloves_decoder"])
					FloatingToast.show_toast("已記入筆記：" + NOTES["clue_gloves_decoder"].title, player)

				item_detail_modal.show_modal(instance_id, active_grid, active_idx, anchor_panel)
		"discard":
			_start_discard_flow(instance_id, item_meta, active_grid, active_idx)

func _handle_equip_toggle(instance_id: String, item_meta: Dictionary) -> void:
	if item_meta.get("category", "") != "equipment":
		return

	var item_id: String = item_meta.get("id", "")
	if GameState.is_equipped(instance_id):
		GameState.unequip_by_instance(instance_id)
	else:
		if not GameState.equip(instance_id):
			FloatingToast.show_toast(
				"這類裝備已經滿了，先卸下身上的再裝備新的。",
				inventory_panel
			)
		elif item_id == "fingerless_gloves" and not GameState.has_note("clue_gloves_decoder"):
			GameState.add_knowledge(NOTES["clue_gloves_decoder"])
			FloatingToast.show_toast("已記入筆記：" + NOTES["clue_gloves_decoder"].title, player)

func _start_discard_flow(instance_id: String, item_meta: Dictionary,
						 restore_grid: Control, restore_index: int) -> void:
	var item_name: String = item_meta.get("name", "物品")
	# Finding 2 fix: compute toast_panel BEFORE entering CONFIRM (while UIMode is still INVENTORY or CONTAINER)
	var toast_panel := _get_active_panel()

	if not item_meta.get("discardable", true):
		FloatingToast.show_toast("無法丟棄 " + item_name, toast_panel)
		return
	if GameState.is_equipped(instance_id):
		FloatingToast.show_toast("請先卸下再丟棄", toast_panel)
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
		FloatingToast.show_toast("已丟棄 " + item_name, toast_panel)

# ==========================================
# Helpers
# ==========================================

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

	var max_width: float = 800.0
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	if text_size.x > max_width:
		message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		message_label.custom_minimum_size = Vector2(max_width - MESSAGE_PADDING.x * 2.0, 0.0)
		message_box.size = Vector2(max_width, 0.0)
	else:
		message_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		message_label.custom_minimum_size = Vector2.ZERO
		message_box.size = text_size + MESSAGE_PADDING * 2.0

	message_box.reset_size()

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
		"cabinet_storage", "fridge_storage":
			prompt_label.text = current_interactable.prompt_text
		"bed_sleep", "door_exit":
			prompt_label.text = "E: 關閉訊息" if message_box.visible else current_interactable.prompt_text
		_:
			prompt_label.text = current_interactable.prompt_text

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
		GameState.add_knowledge(NOTES["clue_decoder_cube"])
		_start_message_typewriter(MESSAGES["decoder_cube_decoded"])
		UIMode.set_mode(UIMode.Mode.MESSAGE)

func _on_item_moved(move: Dictionary) -> void:
	var target_container_id: String = move.get("target_container_id", "")
	var item_id: String = move.get("item_id", "")
	var target_instance_id: String = move.get("target_instance_id", "")

	if target_container_id == "player_inventory":
		var item_meta: Dictionary = GameState.ITEMS_DB.get(item_id, {})
		var decodable_to: String = item_meta.get("decodable_to", "")
		if not decodable_to.is_empty() and _player_has_decoding_ability():
			_execute_item_decoding(target_instance_id, decodable_to)

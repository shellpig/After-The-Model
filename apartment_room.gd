extends Node2D

const MESSAGES := {
	"bed_bad_sleep": "你心中有事, 根本睡不著...",
	"door_locked": "門上了鎖, 而你發現自己不知道如何打開...",
	"door_opened": "你想起來了。門鎖不是壞了, 是你忘了操作方式。"
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


const MESSAGE_CHARS_PER_SECOND := 3.0
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

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var message_full_text := ""
var message_elapsed := 0.0

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

	# Preload containers for Phase 1-D
	GameState.configure_container("cabinet_storage", 30)  # 5 x 6
	GameState.configure_container("fridge_storage", 10)   # 5 x 2

	var _ok_jacket := GameState.seed_container("cabinet_storage", "faded_jacket", 1)
	var _ok_cabinet_food := GameState.seed_container("cabinet_storage", "canned_food", 2)
	var _ok_fridge_food := GameState.seed_container("fridge_storage", "canned_food", 3)


	# Preload inventory robustly
	var has_item := false
	for slot in GameState.get_inventory():
		if not slot.is_empty():
			has_item = true
			break
	if not has_item:
		GameState.add_item("fingerless_gloves", 1)
		GameState.add_item("old_work_badge", 1)

	# Preload 3 story notes for Phase 1-C
	GameState.add_knowledge({
		"id": "identity_apartment_is_mine",
		"category": "身份",
		"title": "這裡是我的公寓",
		"body": "你雖然不記得名字, 但這裡的氣味、磨損的痕跡、書桌的擺法...都是你熟悉的。",
		"status": "active"
	})
	GameState.add_knowledge({
		"id": "work_ai_cleanup_role",
		"category": "工作",
		"title": "AI 善後員",
		"body": "你似乎從事 AI 改變世界後的清理工作。但具體是清什麼, 你現在還想不起來。",
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

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)

func _process(_delta: float) -> void:
	_update_message_typewriter(_delta)

	var current_mode := UIMode.get_mode()

	# Layered UI input handling
	if current_mode != UIMode.Mode.NONE:
		if current_mode == UIMode.Mode.INVENTORY:
			if Input.is_action_just_pressed("open_inventory") or Input.is_action_just_pressed("ui_cancel"):
				UIMode.set_mode(UIMode.Mode.NONE)
				return
			if Input.is_action_just_pressed("open_notebook"):
				UIMode.set_mode(UIMode.Mode.NOTEBOOK)
				return
			if Input.is_action_just_pressed("interact_primary") or \
			   Input.is_action_just_pressed("interact_secondary") or \
			   Input.is_action_just_pressed("interact_tertiary"):
				# Swallow E, R, T inputs inside the backpack
				return
		elif current_mode == UIMode.Mode.NOTEBOOK:
			if Input.is_action_just_pressed("open_notebook") or Input.is_action_just_pressed("ui_cancel"):
				UIMode.set_mode(UIMode.Mode.NONE)
				return
			if Input.is_action_just_pressed("open_inventory"):
				UIMode.set_mode(UIMode.Mode.INVENTORY)
				return
		elif current_mode == UIMode.Mode.MESSAGE:
			if Input.is_action_just_pressed("interact_primary") or Input.is_action_just_pressed("ui_cancel"):
				UIMode.set_mode(UIMode.Mode.NONE)
				return
			if Input.is_action_just_pressed("open_inventory"):
				UIMode.set_mode(UIMode.Mode.INVENTORY)
				return
			if Input.is_action_just_pressed("open_notebook"):
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
	ui_overlay.visible = (new_mode != UIMode.Mode.NONE)

	inventory_panel.visible = (new_mode == UIMode.Mode.INVENTORY)
	dual_pane_container.visible = (new_mode == UIMode.Mode.CONTAINER)
	message_box.visible = (new_mode == UIMode.Mode.MESSAGE)
	notebook_panel.visible = (new_mode == UIMode.Mode.NOTEBOOK)

	if new_mode != UIMode.Mode.MESSAGE:
		_clear_message_typewriter()

	bag_grid.set_input_active(new_mode == UIMode.Mode.INVENTORY)
	notebook_panel.set_input_active(new_mode == UIMode.Mode.NOTEBOOK)

	# Centralized dual-pane activate/deactivate (no lingering input grabs)
	if new_mode == UIMode.Mode.CONTAINER and current_interactable != null:
		var c_id: String = current_interactable.interaction_id
		var c_data: Dictionary = CONTAINERS.get(c_id, {})
		var c_slot_count: int = c_data.get("cols", 1) * c_data.get("rows", 1)
		var c_title: String = c_data.get("title", "儲物空間")
		dual_pane_container.set_input_active(true, c_id, c_slot_count, c_title)
		prompt_panel.visible = false
	else:
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
		_update_prompt()


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
		"cabinet_storage", "fridge_storage":
			prompt_label.text = current_interactable.prompt_text
		"bed_sleep", "door_exit":
			prompt_label.text = "E: 關閉訊息" if message_box.visible else current_interactable.prompt_text
		_:
			prompt_label.text = current_interactable.prompt_text

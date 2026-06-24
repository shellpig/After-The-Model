extends CanvasLayer

signal travel_requested(scene_id: String, entry_point_id: String)

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
@onready var photo_viewer: Control = $PhotoViewer


var _last_mode: int = UIMode.Mode.NONE
var _mode_before_message: int = UIMode.Mode.NONE
var _message_just_opened: bool = false
var _level_context: Node = null
var _is_simple_message: bool = false
var _monologue_active: bool = false
var _current_prompt_data: Dictionary = {}
var _audio_echo: AudioStreamPlayer = null
var _main: Node = null

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
	photo_viewer.visible = false
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

	# Setup echo audio player
	_audio_echo = AudioStreamPlayer.new()
	_audio_echo.name = "AudioEcho"
	_audio_echo.volume_db = -6.0
	_audio_echo.finished.connect(_on_echo_audio_finished)
	add_child(_audio_echo)

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
				set_message_page_hint(tr("UI_MSG_CLOSE_HINT") if not _message_on_closed.is_valid() and _pending_inspect_modal.is_empty() else tr("UI_MSG_CONTINUE_HINT"), true)
			
			if Input.is_action_just_pressed("interact_primary") or Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_accept"):
				if not is_message_finished():
					force_finish_message()
					_message_hint_shown = true
					set_message_page_hint(tr("UI_MSG_CLOSE_HINT") if not _message_on_closed.is_valid() and _pending_inspect_modal.is_empty() else tr("UI_MSG_CONTINUE_HINT"), true)
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
		if Input.is_action_just_pressed("ui_cancel"):
			if is_photo_viewer_open():
				close_photo_viewer()
			else:
				close_all_ui()
			return
		if Input.is_action_just_pressed("open_notebook"):
			close_all_ui()
			return
		if Input.is_action_just_pressed("open_inventory"):
			if not is_photo_viewer_open():
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
	prompt_label.text = tr(data.get("prompt_text", ""))
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

func open_photo_viewer(image_path: String, restore_focus_control: Control) -> void:
	if photo_viewer:
		notebook_panel.set_input_active(false)
		photo_viewer.show_photo(image_path, restore_focus_control)

func close_photo_viewer() -> void:
	if photo_viewer:
		photo_viewer.close_photo()

func is_photo_viewer_open() -> bool:
	return photo_viewer != null and photo_viewer.visible

func toggle_echo_audio(audio_path: String) -> void:
	if _audio_echo == null:
		return
	if _audio_echo.playing:
		var current_path = _audio_echo.stream.resource_path if _audio_echo.stream else ""
		_audio_echo.stop()
		if current_path != audio_path:
			var stream = load(audio_path)
			if stream:
				_audio_echo.stream = stream
				_audio_echo.play()
	else:
		var stream = load(audio_path)
		if stream:
			_audio_echo.stream = stream
			_audio_echo.play()
	_sync_bgm_to_echo()

func stop_echo_audio(resume_bgm: bool = true) -> void:
	if _audio_echo != null and _audio_echo.playing:
		_audio_echo.stop()
	# On scene change pass resume_bgm = false: the new scene plays its own BGM,
	# so resuming the old one would be wrong (and play_bgm clears the duck state).
	if resume_bgm:
		_sync_bgm_to_echo()

func _on_echo_audio_finished() -> void:
	_sync_bgm_to_echo()

# Pause the scene BGM while echo audio plays; resume it once nothing is playing.
# Covers every stop path (manual toggle, panel close, track switch, natural end)
# via a single rule keyed on _audio_echo.playing. pause/resume_bgm are idempotent.
func _sync_bgm_to_echo() -> void:
	var main := _get_main()
	if main == null:
		return
	var should_duck := _audio_echo != null and _audio_echo.playing
	if should_duck:
		if main.has_method("pause_bgm"):
			main.pause_bgm()
	elif main.has_method("resume_bgm"):
		main.resume_bgm()
	if main.has_method("duck_ambient"):
		main.duck_ambient(should_duck)

func _get_main() -> Node:
	if _main == null or not is_instance_valid(_main):
		_main = get_tree().root.find_child("Main", true, false)
	return _main


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
	elif current_mode == UIMode.Mode.NOTEBOOK:
		if notebook_panel.has_method("get_media_actions"):
			var media = notebook_panel.get_media_actions()
			if not media.is_empty():
				var actions = []
				if media.has("primary"):
					actions.append("primary")
				if media.has("secondary"):
					actions.append("secondary")
				return {
					"mode": current_mode,
					"available_actions": actions
				}
	return {}

func can_primary_action() -> bool:
	if is_photo_viewer_open():
		return true
	var ctx := get_focused_item_context()
	if ctx.is_empty():
		return false
	if ctx.get("mode") == UIMode.Mode.NOTEBOOK:
		return "primary" in ctx.get("available_actions", [])
	return true

func can_secondary_action() -> bool:
	if is_photo_viewer_open():
		return false
	var ctx := get_focused_item_context()
	if ctx.is_empty():
		return false
	if ctx.get("mode") == UIMode.Mode.NOTEBOOK:
		return "secondary" in ctx.get("available_actions", [])
	return true

func can_tertiary_action() -> bool:
	var ctx := get_focused_item_context()
	if ctx.is_empty():
		return false
	var item_meta: Dictionary = GameState.ITEMS_DB.get(ctx["item_id"], {})
	return item_meta.get("discardable", true) and not GameState.is_equipped(ctx["instance_id"])

func _on_ui_mode_changed(new_mode: int) -> void:
	if _last_mode == UIMode.Mode.NOTEBOOK and new_mode != UIMode.Mode.NOTEBOOK and new_mode != UIMode.Mode.MESSAGE:
		# Leaving the notebook does NOT stop echo audio: it plays out fully and
		# the BGM resumes on its `finished` signal. Only a scene change cuts it
		# short (see Main.transition_to -> stop_echo_audio(false)).
		close_photo_viewer()

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
		show_toast(tr(_pending_toast_title), anchor)
		_pending_toast_title = ""

	_last_mode = new_mode

func _check_and_trigger_endings() -> void:
	if QuestManager.get_status("alley_backrooms_3f") == "completed" and not GameState.get_flag("alley_backrooms_ended", false):
		GameState.set_flag("alley_backrooms_ended", true)
		
		if GameState.get_flag("gave_wan_old_module", false):
			var page1 := tr("UI_OUTRO_ALLEY_END3_PAGE1")
			var page2 := tr("UI_OUTRO_ALLEY_END3_PAGE2")
			show_message(page1, func(): show_message(page2))
		elif QuestManager.get_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false):
			var page1 := tr("UI_OUTRO_ALLEY_END2_PAGE1")
			var page2 := tr("UI_OUTRO_ALLEY_END2_PAGE2")
			show_message(page1, func(): show_message(page2))
		else:
			var page1 := tr("UI_OUTRO_ALLEY_END1_PAGE1")
			var page2 := tr("UI_OUTRO_ALLEY_END1_PAGE2")
			show_message(page1, func(): show_message(page2))

	if QuestManager.get_status("repair_vendor_bot") == "completed" and not GameState.get_flag("repair_vendor_bot_ended", false):
		GameState.set_flag("repair_vendor_bot_ended", true)
		
		var resolution = GameState.get_flag("store_robot_resolution", "")
		if resolution == "gleaned":
			var page1 := tr("UI_OUTRO_STORE_END2_PAGE1")
			var page2 := tr("UI_OUTRO_STORE_END2_PAGE2")
			var page3 := tr("UI_OUTRO_STORE_END2_PAGE3")
			show_message(page1, func(): show_message(page2, func(): show_message(page3)))
		else:
			var page1 := tr("UI_OUTRO_STORE_END1_PAGE1")
			var page2 := tr("UI_OUTRO_STORE_END1_PAGE2")
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

	var max_width: float = 900.0
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	if text_size.x > max_width:
		message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
			show_discard_flow(instance_id, item_meta, bag_grid, bag_grid.focused_index)
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
			show_discard_flow(instance_id, item_meta, active_grid, active_idx)

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
				tr("UI_TOAST_GLOVE_DECRYPT_NO_SPACE"),
				func():
					item_detail_modal.show_modal(instance_id, grid, index, anchor)
			)
			
	show_message(
		tr("UI_TOAST_GLOVE_DECRYPT_SUCCESS"),
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
		show_toast(tr("UI_TOAST_CANNOT_USE_NOW"), toast_panel)

func _handle_equip_toggle(instance_id: String, item_meta: Dictionary) -> void:
	if item_meta.get("category", "") != "equipment":
		return

	var item_id: String = item_meta.get("id", "")
	if GameState.is_equipped(instance_id):
		GameState.unequip_by_instance(instance_id)
	else:
		if not GameState.equip(instance_id):
			show_equip_slot_full_toast(inventory_panel)
		elif item_id == "fingerless_gloves" and not GameState.has_note("clue_gloves_decoder"):
			GameState.add_knowledge(DECODER_NOTES["clue_gloves_decoder"])

func show_equip_slot_full_toast(toast_panel: Control) -> void:
	show_toast(tr("UI_TOAST_EQUIP_SLOT_FULL"), toast_panel)

func show_discard_flow(instance_id: String, item_meta: Dictionary,
						 restore_grid: Control, restore_index: int) -> void:
	var item_name: String = item_meta.get("name", "物品")
	var toast_panel := _get_active_panel()

	if not item_meta.get("discardable", true):
		show_toast(tr("UI_TOAST_CANNOT_DISCARD_FMT") % tr(item_name), toast_panel)
		return
	if GameState.is_equipped(instance_id):
		show_toast(tr("UI_TOAST_UNEQUIP_BEFORE_DISCARD"), toast_panel)
		return

	UIMode.enter_confirm()
	confirm_dialog.show_dialog(
		tr("UI_CONFIRM_DISCARD_FMT") % tr(item_name),
		_on_discard_confirmed.bind(instance_id, item_name, toast_panel),
		restore_grid,
		restore_index
	)

func _on_discard_confirmed(instance_id: String, item_name: String, toast_panel: Control) -> void:
	if GameState.discard_item(instance_id):
		show_toast(tr("UI_TOAST_DISCARDED_FMT") % tr(item_name), toast_panel)

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
	# Determine toast text (uses i18n format keys)
	var toast_text = ""
	if category == "工作":
		toast_text = tr("UI_TOAST_QUEST_UPDATED_FMT" if is_update else "UI_TOAST_QUEST_ADDED_FMT") % tr(title)
	else:
		toast_text = tr("UI_TOAST_NOTE_UPDATED_FMT" if is_update else "UI_TOAST_NOTE_ADDED_FMT") % tr(title)

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

extends PanelContainer

const CATEGORIES = ["身份", "工作", "線索", "殘響", "進度"]

@onready var tab_identity: Button = $VBoxContainer/TabBar/TabIdentity
@onready var tab_work: Button = $VBoxContainer/TabBar/TabWork
@onready var tab_clues: Button = $VBoxContainer/TabBar/TabClues
@onready var tab_echoes: Button = $VBoxContainer/TabBar/TabEchoes
@onready var tab_progress: Button = $VBoxContainer/TabBar/TabProgress
@onready var list_container: ScrollContainer = $VBoxContainer/ContentSplit/ListContainer
@onready var list_vbox: VBoxContainer = $VBoxContainer/ContentSplit/ListContainer/ListVBox
@onready var body_label: RichTextLabel = $VBoxContainer/ContentSplit/BodyLabel
@onready var panel_footer_hint: Label = $VBoxContainer/PanelFooterHint

var is_input_active := false
var active_category_index := 0
var current_list_items := []


func _ready() -> void:
	# Retrieve stylebox dynamically from sibling InventoryPanel to avoid hardcoded color drift
	var sibling_panel = get_parent().get_node_or_null("InventoryPanel") if get_parent() != null else null
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

	add_theme_stylebox_override("panel", panel_style)

	# Expose tab buttons to mouse click
	tab_identity.pressed.connect(func(): _select_tab_index(0))
	tab_work.pressed.connect(func(): _select_tab_index(1))
	tab_clues.pressed.connect(func(): _select_tab_index(2))
	tab_echoes.pressed.connect(func(): _select_tab_index(3))
	tab_progress.pressed.connect(func(): _select_tab_index(4))

	# Format footer hint text
	if panel_footer_hint is PanelFooterHint:
		panel_footer_hint.set_hints(self, [
			"A/D: 切分頁",
			"W/S: 選筆記",
			"I: 背包",
			"Esc/J: 關閉"
		])
	else:
		panel_footer_hint.text = tr("UI_NOTEBOOK_FOOTER_HINT")

	# Connect global state notes updates
	GameState.notes_changed.connect(func():
		if is_input_active:
			load_notebook_data()
	)
	GameState.echo_changed.connect(func(_echo_id: String):
		if is_input_active:
			load_notebook_data()
	)
	set_process_input(false)


func set_input_active(active: bool) -> void:
	is_input_active = active
	set_process_input(active)
	if active:
		active_category_index = _find_first_non_empty_category()

func _find_first_non_empty_category() -> int:
	for i in range(CATEGORIES.size()):
		var category: String = CATEGORIES[i]
		if category == "殘響":
			var has_any = false
			for echo_id in EchoDB.ECHOES:
				if GameState.is_echo_known(echo_id):
					has_any = true
					break
			if has_any:
				return i
		else:
			var notes: Array = GameState.get_notes(category)
			if not notes.is_empty():
				return i
	return 0


func load_notebook_data() -> void:
	# Clear previous list items immediately by removing them from tree
	for child in list_vbox.get_children():
		list_vbox.remove_child(child)
		child.queue_free()

	body_label.text = ""

	_update_tab_styles()

	var category: String = CATEGORIES[active_category_index]
	current_list_items.clear()
	
	if category == "殘響":
		for echo_id in EchoDB.ECHOES:
			if GameState.is_echo_known(echo_id):
				var echo_data = EchoDB.get_echo(echo_id)
				var title = tr(echo_data.get("title", "UI_NOTEBOOK_UNNAMED_ECHO"))
				var collected_count = GameState.echo_progress.get(echo_id, {}).get("collected", []).size()
				var total_segments = EchoDB.get_segment_count(echo_id)
				var sold = GameState.is_echo_sold(echo_id)
				
				var unknown_total = echo_data.get("unknown_total", false)
				var display_title = tr("UI_NOTEBOOK_ECHO_TITLE_FMT") % [title, str(collected_count), ( "?" if unknown_total else str(total_segments) )]
				if sold:
					display_title += " " + tr("UI_NOTEBOOK_SOLD_TAG")
				
				var body_segments = []
				var segments_list = echo_data.get("segments", [])
				for idx in range(segments_list.size()):
					var seg = segments_list[idx]
					var seg_id = seg.get("id", "")
					if GameState.has_echo_segment(echo_id, seg_id):
						body_segments.append(seg.get("text", ""))
					else:
						body_segments.append(tr("UI_NOTEBOOK_SEGMENT_LOCKED_FMT") % (idx + 1))

				if unknown_total:
					body_segments.append("???")

				var body_text = "\n\n".join(body_segments)

				if collected_count == total_segments and not sold:
					if echo_id == "echo_room401_tenant":
						body_text += "\n\n" + tr("UI_NOTEBOOK_MEDIA_PHOTO")
					elif echo_id == "echo_song_rain_doesnt_stop":
						body_text += "\n\n" + tr("UI_NOTEBOOK_MEDIA_SONG")
					elif echo_id == "echo_clerk":
						body_text += "\n\n" + tr("UI_NOTEBOOK_MEDIA_AUDIO")
				
				current_list_items.append({
					"id": echo_id,
					"title": display_title,
					"body": body_text,
					"is_echo": true
				})
	elif category == "進度":
		var summary = GameState.get_progress_summary()
		
		# 1. Overall Progress
		var overall_body = tr("UI_PROGRESS_OVERALL_PCT_FMT") % summary["overall_pct"] + "\n\n"
		overall_body += tr("UI_PROGRESS_SCENE_COUNT_FMT") % [summary["scenes"]["done"], summary["scenes"]["total"]] + "\n"
		overall_body += tr("UI_PROGRESS_NPC_COUNT_FMT") % [summary["npcs"]["done"], summary["npcs"]["total"]] + "\n"
		overall_body += tr("UI_PROGRESS_QUEST_COUNT_FMT") % [summary["quests"]["done"], summary["quests"]["total"]] + "\n"
		overall_body += tr("UI_PROGRESS_ECHO_COUNT_FMT") % [summary["echoes"]["done"], summary["echoes"]["total"]] + "\n"
		overall_body += tr("UI_PROGRESS_ITEMS_COUNT_FMT") % [summary["special"]["done"], summary["special"]["total"]]
		
		current_list_items.append({
			"id": "progress_overall",
			"title": tr("UI_PROGRESS_TOTAL_TITLE"),
			"body": overall_body
		})
		
		# 2. Scenes
		var scenes_body = tr("UI_PROGRESS_SCENES_TITLE_FMT") % [summary["scenes"]["done"], summary["scenes"]["total"]] + "\n\n"
		for item in summary["scenes"]["items"]:
			var name = tr(item["name"]) if item["done"] else "???"
			var check = " [✓]" if item["done"] else ""
			scenes_body += name + check + "\n"
		current_list_items.append({
			"id": "progress_scenes",
			"title": tr("UI_PROGRESS_SCENES_TITLE"),
			"body": scenes_body
		})
		
		# 3. NPCs
		var npcs_body = tr("UI_PROGRESS_NPCS_TITLE_FMT") % [summary["npcs"]["done"], summary["npcs"]["total"]] + "\n\n"
		for item in summary["npcs"]["items"]:
			var name = tr(item["name"]) if item["done"] else "???"
			var check = " [✓]" if item["done"] else ""
			npcs_body += name + check + "\n"
		current_list_items.append({
			"id": "progress_npcs",
			"title": tr("UI_PROGRESS_NPCS_TITLE"),
			"body": npcs_body
		})
		
		# 4. Quests
		var quests_body = tr("UI_PROGRESS_QUESTS_TITLE_FMT") % [summary["quests"]["done"], summary["quests"]["total"]] + "\n\n"
		for item in summary["quests"]["items"]:
			var name = tr(item["name"]) if item["done"] else "???"
			var check = " [✓]" if item["done"] else ""
			quests_body += name + check + "\n"
		current_list_items.append({
			"id": "progress_quests",
			"title": tr("UI_PROGRESS_QUESTS_TITLE"),
			"body": quests_body
		})
		
		# 5. Echoes
		var echoes_body = tr("UI_PROGRESS_ECHOES_TITLE_FMT") % [summary["echoes"]["done"], summary["echoes"]["total"]] + "\n\n"
		for item in summary["echoes"]["items"]:
			var name = tr(item["name"]) if item["done"] else "???"
			var check = " [✓]" if item["done"] else ""
			echoes_body += name + check + "\n"
		current_list_items.append({
			"id": "progress_echoes",
			"title": tr("UI_PROGRESS_ECHOES_TITLE"),
			"body": echoes_body
		})
		
		# 6. Special Items
		var special_body = tr("UI_PROGRESS_SPECIAL_TITLE_FMT") % [summary["special"]["done"], summary["special"]["total"]] + "\n\n"
		for item in summary["special"]["items"]:
			var name = tr(item["name"]) if item["done"] else "???"
			var check = " [✓]" if item["done"] else ""
			special_body += name + check + "\n"
		current_list_items.append({
			"id": "progress_special",
			"title": tr("UI_PROGRESS_SPECIAL_TITLE"),
			"body": special_body
		})
	else:
		current_list_items = GameState.get_notes(category)

	if current_list_items.is_empty():
		var placeholder := Label.new()
		placeholder.text = tr("UI_NOTEBOOK_NO_NOTES") if category != "殘響" else tr("UI_NOTEBOOK_NO_ECHOES")
		placeholder.custom_minimum_size.y = 32
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.add_theme_font_size_override("font_size", 16)
		placeholder.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1.0))
		list_vbox.add_child(placeholder)
		_update_footer_hints({})
	else:
		for i in range(current_list_items.size()):
			var note: Dictionary = current_list_items[i]
			var btn := Button.new()
			btn.text = tr(note.get("title", ""))
			btn.custom_minimum_size.y = 32
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", 16)

			# Apply custom list item stylebox overrides (flat & subtle accent line)
			var btn_style_normal := StyleBoxEmpty.new()
			var btn_style_hover := StyleBoxFlat.new()
			btn_style_hover.bg_color = Color(1.0, 1.0, 1.0, 0.05)
			btn_style_hover.content_margin_left = 8
			var btn_style_focus := StyleBoxFlat.new()
			btn_style_focus.bg_color = Color(1.0, 1.0, 1.0, 0.08)
			btn_style_focus.border_width_left = 3
			btn_style_focus.border_color = Color(0.78, 0.42, 0.20, 1.0)
			btn_style_focus.content_margin_left = 8

			btn.add_theme_stylebox_override("normal", btn_style_normal)
			btn.add_theme_stylebox_override("hover", btn_style_hover)
			btn.add_theme_stylebox_override("pressed", btn_style_focus)
			btn.add_theme_stylebox_override("focus", btn_style_focus)

			btn.focus_mode = Control.FOCUS_ALL

			list_vbox.add_child(btn)

			# Clamp focus horizontally to prevent accidental keyboard escapes
			btn.focus_neighbor_left = btn.get_path()
			btn.focus_neighbor_right = btn.get_path()

			btn.focus_entered.connect(func():
				_on_note_selected(note, i)
				list_container.ensure_control_visible(btn)
			)

		# Grab focus on the first item in the list automatically
		var first_btn := list_vbox.get_child(0) as Button
		if first_btn != null:
			first_btn.grab_focus.call_deferred()

func _on_note_selected(note: Dictionary, index: int) -> void:
	body_label.text = _translate_body(note.get("body", ""))
	var v_scroll := body_label.get_v_scroll_bar()
	if v_scroll != null:
		v_scroll.value = 0

	# Highlight current active item in cream and others in desaturated grey
	for i in range(list_vbox.get_child_count()):
		var child := list_vbox.get_child(i) as Button
		if child != null:
			if i == index:
				child.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84, 1.0))
				child.add_theme_color_override("font_hover_color", Color(0.94, 0.92, 0.84, 1.0))
				child.add_theme_color_override("font_focus_color", Color(0.94, 0.92, 0.84, 1.0))
			else:
				child.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1.0))
				child.add_theme_color_override("font_hover_color", Color(0.75, 0.75, 0.75, 1.0))
				child.add_theme_color_override("font_focus_color", Color(0.75, 0.75, 0.75, 1.0))

	# Echo audio intentionally keeps playing when switching notes; it is only
	# stopped by a scene change or when the track finishes.

	# Update footer hints dynamically
	_update_footer_hints(note)

func _update_footer_hints(note: Dictionary) -> void:
	var hints = [
		"A/D: 切分頁",
		"W/S: 選筆記",
		"I: 背包",
		"Esc/J: 關閉"
	]
	
	if note.get("is_echo", false):
		var echo_id = note.get("id", "")
		if not GameState.is_echo_sold(echo_id):
			var has_image = GameState.is_echo_image_unlocked(echo_id)
			var has_audio = GameState.is_echo_audio_unlocked(echo_id)
			var image_path = GameState.get_echo_image_path(echo_id) if has_image else ""
			var audio_path = GameState.get_echo_audio_path(echo_id) if has_audio else ""
			
			if has_image and has_audio:
				hints.insert(0, "R: 播放錄音")
				hints.insert(0, "E: 看照片")
			elif has_image:
				hints.insert(0, "E: 看照片")
			elif has_audio:
				hints.insert(0, "E: 播放錄音")

	if panel_footer_hint is PanelFooterHint:
		panel_footer_hint.set_hints(self, hints)
	else:
		var text_parts = []
		for h in hints:
			text_parts.append(str(h))
		panel_footer_hint.text = "   ".join(text_parts)

# M2-C：note.body 可能是單一翻譯 key（首次寫入）或多段 "\n\n" 串接（後續 add_knowledge append，
# 例如門解鎖後追加雨夜旁白）。對每一段 tr()，非 key 段為 no-op，鬆綁混合資料。
func _translate_body(raw_body: String) -> String:
	if raw_body.is_empty():
		return ""
	var parts := raw_body.split("\n\n")
	var out: Array = []
	for p in parts:
		out.append(tr(p))
	return "\n\n".join(out)

func _select_tab_index(index: int) -> void:
	if active_category_index == index:
		return
	active_category_index = index
	load_notebook_data()

func _change_tab(direction: int) -> void:
	var new_idx: int = clamp(active_category_index + direction, 0, CATEGORIES.size() - 1)
	_select_tab_index(new_idx)

func set_active_category(category_name: String) -> void:
	var index: int = CATEGORIES.find(category_name)
	if index != -1:
		_select_tab_index(index)

func _update_tab_styles() -> void:
	for i in range(CATEGORIES.size()):
		var tab_btn := _get_tab_button(i)
		if tab_btn == null:
			continue

		if i == active_category_index:
			tab_btn.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84, 1.0))
			tab_btn.add_theme_color_override("font_hover_color", Color(0.94, 0.92, 0.84, 1.0))
			tab_btn.add_theme_color_override("font_focus_color", Color(0.94, 0.92, 0.84, 1.0))

			var style_selected := StyleBoxFlat.new()
			style_selected.bg_color = Color(0.08, 0.10, 0.12, 1.0)
			style_selected.border_width_bottom = 2
			style_selected.border_color = Color(0.78, 0.42, 0.20, 1.0)
			tab_btn.add_theme_stylebox_override("normal", style_selected)
			tab_btn.add_theme_stylebox_override("hover", style_selected)
			tab_btn.add_theme_stylebox_override("pressed", style_selected)
			tab_btn.add_theme_stylebox_override("focus", style_selected)
		else:
			tab_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1.0))
			tab_btn.add_theme_color_override("font_hover_color", Color(0.75, 0.75, 0.75, 1.0))

			var style_unselected := StyleBoxFlat.new()
			style_unselected.bg_color = Color(0, 0, 0, 0)
			tab_btn.add_theme_stylebox_override("normal", style_unselected)
			tab_btn.add_theme_stylebox_override("hover", style_unselected)
			tab_btn.add_theme_stylebox_override("pressed", style_unselected)
			tab_btn.add_theme_stylebox_override("focus", style_unselected)

func _get_tab_button(index: int) -> Button:
	match index:
		0: return tab_identity
		1: return tab_work
		2: return tab_clues
		3: return tab_echoes
		4: return tab_progress
	return null


func get_media_actions() -> Dictionary:
	if active_category_index != 3:
		return {}
	
	var current_focus = get_viewport().gui_get_focus_owner()
	if current_focus != null and current_focus.get_parent() == list_vbox:
		var idx = current_focus.get_index()
		if idx >= 0 and idx < current_list_items.size():
			var note = current_list_items[idx]
			if note.get("is_echo", false):
				var echo_id = note.get("id")
				if not GameState.is_echo_sold(echo_id):
					var has_image = GameState.is_echo_image_unlocked(echo_id)
					var has_audio = GameState.is_echo_audio_unlocked(echo_id)
					var image_path = GameState.get_echo_image_path(echo_id) if has_image else ""
					var audio_path = GameState.get_echo_audio_path(echo_id) if has_audio else ""
					
					if has_image and has_audio:
						return {"primary": "view_photo", "secondary": "play_audio"}
					elif has_image:
						return {"primary": "view_photo"}
					elif has_audio:
						return {"primary": "play_audio"}
	return {}

func idx_valid_for_media() -> bool:
	var current_focus = get_viewport().gui_get_focus_owner()
	if current_focus != null and current_focus.get_parent() == list_vbox:
		var idx = current_focus.get_index()
		return idx >= 0 and idx < current_list_items.size()
	return false

func _input(event: InputEvent) -> void:
	if not is_input_active:
		return

	if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_change_tab(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_change_tab(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		var current_focus = get_viewport().gui_get_focus_owner()
		if current_focus != null and current_focus.get_parent() == list_vbox:
			var idx = current_focus.get_index()
			if idx > 0:
				var target_btn = list_vbox.get_child(idx - 1) as Button
				if target_btn != null:
					target_btn.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		var current_focus = get_viewport().gui_get_focus_owner()
		if current_focus != null and current_focus.get_parent() == list_vbox:
			var idx = current_focus.get_index()
			if idx < list_vbox.get_child_count() - 1:
				var target_btn = list_vbox.get_child(idx + 1) as Button
				if target_btn != null:
					target_btn.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_page_up") or event.is_action_pressed("ui_page_down"):
		# Swallowed to turn off PgUp/PgDn functionality as requested
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact_primary"): # E
		var media = get_media_actions()
		if not media.is_empty():
			var action = media.get("primary", "")
			var current_focus = get_viewport().gui_get_focus_owner()
			if idx_valid_for_media():
				var idx = current_focus.get_index()
				var note = current_list_items[idx]
				var echo_id = note.get("id")
				var echo_data = EchoDB.get_echo(echo_id)
				if action == "view_photo":
					var image_path = GameState.get_echo_image_path(echo_id)
					var game_ui = get_parent()
					if game_ui and game_ui.has_method("open_photo_viewer"):
						game_ui.open_photo_viewer(image_path, current_focus)
						get_viewport().set_input_as_handled()
				elif action == "play_audio":
					var audio_path = GameState.get_echo_audio_path(echo_id)
					var game_ui = get_parent()
					if game_ui and game_ui.has_method("toggle_echo_audio"):
						game_ui.toggle_echo_audio(audio_path)
						get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact_secondary"): # R
		var media = get_media_actions()
		if not media.is_empty():
			var action = media.get("secondary", "")
			var current_focus = get_viewport().gui_get_focus_owner()
			if idx_valid_for_media():
				var idx = current_focus.get_index()
				var note = current_list_items[idx]
				var echo_id = note.get("id")
				var echo_data = EchoDB.get_echo(echo_id)
				if action == "play_audio":
					var audio_path = GameState.get_echo_audio_path(echo_id)
					var game_ui = get_parent()
					if game_ui and game_ui.has_method("toggle_echo_audio"):
						game_ui.toggle_echo_audio(audio_path)
						get_viewport().set_input_as_handled()

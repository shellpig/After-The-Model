extends Control

signal dialogue_finished

@onready var portrait_rect: TextureRect = $PortraitRect
@onready var name_label: Label = $DialogueBox/MarginContainer/VBoxContainer/NameLabel
@onready var text_label: Label = $DialogueBox/MarginContainer/VBoxContainer/TextLabel
@onready var choices_container: VBoxContainer = $DialogueBox/MarginContainer/VBoxContainer/ChoicesContainer
@onready var hint_label: Label = $DialogueBox/MarginContainer/HintLabel

var _runner: DialogueRunner = null
var _current_choices: Array = []
var _focused_choice_idx: int = -1
var _is_input_active: bool = false
var _dialogue_id: String = ""
var _dialogue_full_text := ""
var _dialogue_elapsed := 0.0
const CHARS_PER_SECOND := 12.0

# Speaker key (CSV i18n key used in the "speaker" field of data/dialogue/*.gd trees)
# -> dialogue portrait image path. Looked up per-node in _update_ui() so a single
# tree can mix speakers (e.g. travel_datacenter's menu/prelude nodes have no speaker,
# its confirm nodes are SPEAKER_WAN).
const SPEAKER_PORTRAITS := {
	"SPEAKER_WAN": "res://assets/generated/sprites/wan/dialogue_portrait/wan-dialogue-portrait-20260607-100732/portrait.png",
	"SPEAKER_STORE_ROBOT": "res://assets/generated/sprites/store_robot/dialogue_portrait/store-robot-dialogue-portrait-20260610-202942/portrait.png",
	"SPEAKER_LU_QICHEN": "res://assets/generated/sprites/lu_qichen/dialogue_portrait/lu-qichen-dialogue-portrait-20260613-124451/portrait.png",
	"SPEAKER_CEN": "res://assets/generated/sprites/cen/dialogue_portrait/cen-dialogue-portrait-20260621-141759/portrait.png",
	"SPEAKER_WU": "res://assets/generated/sprites/wu/dialogue_portrait/wu-dialogue-portrait-20260621-143046/portrait.png",
	"SPEAKER_SEVEN": "res://assets/generated/sprites/seven/dialogue_portrait/seven-dialogue-portrait-idle-match-right-20260621-214200/portrait.png",
	"SPEAKER_ADA": "res://assets/generated/sprites/ada/dialogue_portrait/ada-dialogue-portrait-from-concept-20260702-201200/portrait.png",
	"SPEAKER_BODYGUARD": "res://assets/generated/sprites/nightclub_bodyguard/dialogue_portrait/sprite.png",
}

func _ready() -> void:
	visible = false
	# Allow mouse clicks to pass through containers to DialoguePanel for global click advance
	$DialogueBox.mouse_filter = Control.MOUSE_FILTER_PASS
	$DialogueBox/MarginContainer.mouse_filter = Control.MOUSE_FILTER_PASS
	$DialogueBox/MarginContainer/VBoxContainer.mouse_filter = Control.MOUSE_FILTER_PASS
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	text_label.mouse_filter = Control.MOUSE_FILTER_PASS
	choices_container.mouse_filter = Control.MOUSE_FILTER_PASS
	hint_label.mouse_filter = Control.MOUSE_FILTER_PASS
	portrait_rect.mouse_filter = Control.MOUSE_FILTER_PASS

func start_dialogue(dialogue_id: String) -> void:
	_dialogue_id = dialogue_id
	GameState.mark_npc_talked(dialogue_id)
	var tree = DialogueDB.get_tree_for(dialogue_id)
	if tree.is_empty():
		printerr("[DialoguePanel] Dialogue tree not found: ", dialogue_id)
		close_dialogue()
		return

	_runner = DialogueRunner.new()
	_runner.finished.connect(_on_dialogue_finished)
	_runner.start(tree)

	# Portrait is now chosen per-node by speaker key (see _update_portrait_for_current_node);
	# reset here so a dialogue that opens on a no-speaker node doesn't inherit a stale portrait.
	portrait_rect.texture = null

	visible = true
	_is_input_active = true
	_update_ui()

func close_dialogue() -> void:
	# 8-F：對話 effect 帶 open_shop 時，DIALOGUE 正常結束直接切 SHOP（不疊 overlay、不經 NONE）
	var pending_shop_id := ""
	var pending_travel := {}
	if _runner != null:
		pending_shop_id = _runner.pending_shop_id
		if "pending_travel" in _runner:
			pending_travel = _runner.pending_travel
	visible = false
	_is_input_active = false
	_runner = null
	dialogue_finished.emit()
	if not pending_travel.is_empty():
		var gu := get_parent()
		if gu != null and gu.has_signal("travel_requested"):
			gu.travel_requested.emit(pending_travel.get("scene_id", ""), pending_travel.get("entry_point_id", ""))
			return
	if not pending_shop_id.is_empty():
		var gu := get_parent()
		if gu != null and gu.has_method("open_shop"):
			gu.open_shop(pending_shop_id)
			return
	if UIMode.get_mode() == UIMode.Mode.DIALOGUE:
		UIMode.set_mode(UIMode.Mode.NONE)

func _on_dialogue_finished() -> void:
	close_dialogue()

func _update_ui() -> void:
	if _runner == null:
		return

	var curr = _runner.current()
	if curr.is_empty():
		close_dialogue()
		return

	_update_portrait_for_current_node(curr)

	name_label.text = tr(curr.get("speaker", ""))
	_dialogue_full_text = tr(curr.get("text", ""))
	_dialogue_elapsed = 0.0
	text_label.text = ""

	# Clear previous choices
	for child in choices_container.get_children():
		child.queue_free()

	var raw_choices = curr.get("choices", [])
	var sorted_choices = []
	var exit_choices = []
	for c in raw_choices:
		var lbl: String = tr(c.get("label", ""))
		var lbl_low := lbl.to_lower()
		if "離開" in lbl or "离开" in lbl or "leave" in lbl_low or "exit" in lbl_low:
			exit_choices.append(c)
		else:
			sorted_choices.append(c)
	for ec in exit_choices:
		sorted_choices.append(ec)
	_current_choices = sorted_choices
	_focused_choice_idx = -1
	choices_container.visible = false

	if _current_choices.is_empty():
		if curr.get("is_terminal", false):
			hint_label.text = tr("UI_DIALOGUE_CLOSE")
		else:
			hint_label.text = tr("UI_DIALOGUE_CONTINUE")
	else:
		hint_label.text = tr("UI_DIALOGUE_CONTINUE")
		for i in range(_current_choices.size()):
			var choice = _current_choices[i]
			var btn = Button.new()
			btn.text = "  " + tr(choice.get("label", ""))
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.focus_mode = Control.FOCUS_ALL

			# Style the button to match the zine theme
			var empty_style = StyleBoxEmpty.new()
			btn.add_theme_stylebox_override("normal", empty_style)
			btn.add_theme_stylebox_override("hover", empty_style)
			btn.add_theme_stylebox_override("pressed", empty_style)
			btn.add_theme_stylebox_override("focus", empty_style)

			btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.94, 0.92, 0.84, 1.0))
			btn.add_theme_color_override("font_focus_color", Color(0.94, 0.92, 0.84, 1.0))
			btn.add_theme_font_size_override("font_size", 16)

			# Connect focus/hover and click signals
			btn.focus_entered.connect(_on_choice_focused.bind(i, btn))
			btn.focus_exited.connect(_on_choice_unfocused.bind(btn))
			btn.mouse_entered.connect(btn.grab_focus)
			btn.pressed.connect(_on_choice_selected.bind(choice.get("index")))

			choices_container.add_child(btn)

	# Bypass typewriter effect in headless testing environment to avoid test failure due to frame delay
	if DisplayServer.get_name() == "headless":
		_finish_text()

func _update_portrait_for_current_node(curr: Dictionary) -> void:
	var speaker: String = curr.get("speaker", "")
	if speaker.is_empty():
		# No speaker on this node (e.g. a menu/prelude line, or a continuation line
		# right after the same character's line) -- leave whatever portrait is
		# already showing rather than flicker it away.
		return
	if SPEAKER_PORTRAITS.has(speaker):
		var img_path: String = SPEAKER_PORTRAITS[speaker]
		if ResourceLoader.exists(img_path):
			portrait_rect.texture = load(img_path)
		else:
			portrait_rect.texture = null
	else:
		portrait_rect.texture = null

func _on_choice_focused(idx: int, btn: Button) -> void:
	_focused_choice_idx = idx
	btn.text = "> " + tr(_current_choices[idx].get("label", ""))

func _on_choice_unfocused(btn: Button) -> void:
	if btn.text.begins_with("> "):
		btn.text = "  " + btn.text.substr(2)

func _on_choice_selected(raw_idx: int) -> void:
	if _runner:
		_runner.choose(raw_idx)
		_update_ui()

func set_input_active(active: bool) -> void:
	_is_input_active = active
	if active:
		if choices_container.visible and choices_container.get_child_count() > 0:
			var idx = max(0, _focused_choice_idx)
			choices_container.get_child(idx).grab_focus()

func move_focus(dir: int) -> void:
	if not visible or not choices_container.visible or choices_container.get_child_count() == 0:
		return
	var count = choices_container.get_child_count()
	var next_idx = _focused_choice_idx + dir
	next_idx = clamp(next_idx, 0, count - 1)
	if next_idx != _focused_choice_idx:
		choices_container.get_child(next_idx).grab_focus()

func confirm_current() -> void:
	if not visible or _runner == null:
		return
	var curr = _runner.current()
	if curr.is_empty():
		return
	if curr.get("choices", []).is_empty():
		_runner.advance()
		_update_ui()
	else:
		if _focused_choice_idx >= 0 and _focused_choice_idx < _current_choices.size():
			var choice = _current_choices[_focused_choice_idx]
			_on_choice_selected(choice.get("index"))

func _unhandled_input(event: InputEvent) -> void:
	if not _is_input_active or not visible or _runner == null:
		return

	var curr = _runner.current()
	if curr.is_empty():
		return

	if event.is_action_pressed("interact_primary"):
		get_viewport().set_input_as_handled()
		if not _is_text_finished():
			_finish_text()
		else:
			if curr.get("choices", []).is_empty():
				_runner.advance()
				_update_ui()
			else:
				confirm_current()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		move_focus(-1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		move_focus(1)

func _process(delta: float) -> void:
	if not visible or _runner == null:
		return

	if not _dialogue_full_text.is_empty():
		_dialogue_elapsed += delta
		var visible_chars: int = min(_dialogue_full_text.length(), int(floor(_dialogue_elapsed * CHARS_PER_SECOND)))
		if text_label.text.length() != visible_chars:
			text_label.text = _dialogue_full_text.substr(0, visible_chars)
		
		if _is_text_finished():
			_show_choices_if_needed()

func _is_text_finished() -> bool:
	return _dialogue_elapsed * CHARS_PER_SECOND >= _dialogue_full_text.length()

func _finish_text() -> void:
	_dialogue_elapsed = _dialogue_full_text.length() / CHARS_PER_SECOND + 1.0
	text_label.text = _dialogue_full_text
	_show_choices_if_needed()

func _show_choices_if_needed() -> void:
	if not _current_choices.is_empty() and not choices_container.visible:
		choices_container.visible = true
		hint_label.text = tr("UI_DIALOGUE_SELECT_CONFIRM")
		if _is_input_active and choices_container.get_child_count() > 0:
			choices_container.get_child(0).grab_focus()

func _gui_input(event: InputEvent) -> void:
	if not _is_input_active or not visible or _runner == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		var curr = _runner.current()
		if curr.is_empty():
			return

		if not _is_text_finished():
			_finish_text()
		else:
			if curr.get("choices", []).is_empty():
				_runner.advance()
				_update_ui()

extends Control

signal dialogue_finished

@onready var portrait_rect: TextureRect = $PortraitRect
@onready var name_label: Label = $DialogueBox/MarginContainer/VBoxContainer/NameLabel
@onready var text_label: Label = $DialogueBox/MarginContainer/VBoxContainer/TextLabel
@onready var choices_container: VBoxContainer = $DialogueBox/MarginContainer/VBoxContainer/ChoicesContainer

var _runner: DialogueRunner = null
var _current_choices: Array = []
var _focused_choice_idx: int = -1
var _is_input_active: bool = false
var _dialogue_id: String = ""

func _ready() -> void:
	visible = false

func start_dialogue(dialogue_id: String) -> void:
	_dialogue_id = dialogue_id
	var tree = DialogueDB.get_tree_for(dialogue_id)
	if tree.is_empty():
		printerr("[DialoguePanel] Dialogue tree not found: ", dialogue_id)
		close_dialogue()
		return

	_runner = DialogueRunner.new()
	_runner.finished.connect(_on_dialogue_finished)
	_runner.start(tree)

	# Load character portrait dynamically
	if dialogue_id == "wan":
		var img_path = "res://assets/generated/sprites/wan/dialogue_portrait/wan-dialogue-portrait-20260607-100732/portrait.png"
		if FileAccess.file_exists(img_path):
			portrait_rect.texture = load(img_path)
		else:
			portrait_rect.texture = null
	else:
		portrait_rect.texture = null

	visible = true
	_is_input_active = true
	_update_ui()

func close_dialogue() -> void:
	visible = false
	_is_input_active = false
	_runner = null
	dialogue_finished.emit()
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

	name_label.text = curr.get("speaker", "")
	text_label.text = curr.get("text", "")

	# Clear previous choices
	for child in choices_container.get_children():
		child.queue_free()

	_current_choices = curr.get("choices", [])
	_focused_choice_idx = -1

	if _current_choices.is_empty():
		choices_container.visible = false
	else:
		choices_container.visible = true
		for i in range(_current_choices.size()):
			var choice = _current_choices[i]
			var btn = Button.new()
			btn.text = "  " + choice.get("label", "")
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

		# Focus first item in container
		if choices_container.get_child_count() > 0:
			choices_container.get_child(0).grab_focus()

func _on_choice_focused(idx: int, btn: Button) -> void:
	_focused_choice_idx = idx
	btn.text = "> " + _current_choices[idx].get("label", "")

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
		if curr.get("choices", []).is_empty():
			_runner.advance()
			_update_ui()
		else:
			confirm_current()

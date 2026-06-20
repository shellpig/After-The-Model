extends Node
class_name FormatReset

# Phase 13-B: long-press E from behind a stunned machine enemy to format it.
# Attach to the player node.
#
# State flow:
#   idle      → target found         → prompt  ("按住 E：格式化")
#   prompt    → E held               → formatting ("格式化中 [████░░] 60%")
#   formatting → 2s complete         → complete ("格式化完成！" for 1.5s, then hide)
#   any       → release/out/UI open  → idle
#   complete  → timer expired        → idle (prompt won't reappear: enemy is defeated)

const FORMAT_DURATION    := 2.0
const BAR_CELLS          := 10
const COMPLETE_SHOW_TIME := 1.5

var _player: Node2D = null
var _format_t   := 0.0   # accumulates while holding E in format zone
var _complete_t := 0.0   # counts down during "格式化完成！" display

var _canvas: CanvasLayer    = null
var _panel:  PanelContainer = null
var _lbl:    Label          = null

func _ready() -> void:
	_player = get_parent() as Node2D
	_setup_hud()

# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _player == null:
		return

	# --- Completion display (highest priority: ignore all other state) ---
	if _complete_t > 0.0:
		_complete_t -= delta
		if _complete_t <= 0.0:
			_complete_t = 0.0
			_panel.visible = false
		return

	# --- Normal flow ---
	if UIMode.is_world_input_blocked():
		_reset()
		return

	var target := _find_target()
	if target == null:
		_reset()
		return

	_update_pos()

	if not Input.is_action_pressed("interact_primary"):
		_format_t = 0.0
		_lbl.text = "按住 E：格式化"
		_panel.visible = true
		return

	# Holding E — clamp so we always hit exactly 100%.
	_format_t = min(_format_t + delta, FORMAT_DURATION)
	var filled := int(_format_t / FORMAT_DURATION * BAR_CELLS)
	var pct    := int(_format_t / FORMAT_DURATION * 100.0)
	_lbl.text = "格式化中 [%s%s] %d%%" % [
		"█".repeat(filled),
		"░".repeat(BAR_CELLS - filled),
		pct,
	]
	_panel.visible = true

	if _format_t >= FORMAT_DURATION:
		target.defeated()
		_format_t = 0.0
		_lbl.text = "格式化完成！"
		_complete_t = COMPLETE_SHOW_TIME

# ---------------------------------------------------------------------------

# True when a machine enemy in can_format range is present.
# Called by player.gd to block the attack swing (E key priority goes to format).
func has_target() -> bool:
	if _complete_t > 0.0:
		return false  # completion phase: don't block subsequent actions
	if UIMode.is_world_input_blocked():
		return false
	return _find_target() != null

func _find_target() -> Node:
	if _player == null:
		return null
	for enemy in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("can_format") and enemy.can_format(_player.global_position):
			return enemy
	return null

func _reset() -> void:
	_format_t = 0.0
	_panel.visible = false

# Bottom-centre of the 1280×720 viewport (jump_proto fixed resolution).
func _update_pos() -> void:
	_panel.reset_size()
	var ps := _panel.size
	_panel.position = Vector2((1280.0 - ps.x) * 0.5, 636.0 - ps.y * 0.5)

func _setup_hud() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 5
	add_child(_canvas)

	_panel = PanelContainer.new()
	_panel.visible = false
	_canvas.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top",    7)
	margin.add_theme_constant_override("margin_bottom", 7)
	_panel.add_child(margin)

	_lbl = Label.new()
	_lbl.add_theme_font_size_override("font_size", 20)
	_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_lbl.add_theme_constant_override("outline_size", 4)
	_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(_lbl)

# Exposed for headless test access.
func get_format_progress() -> float:
	return _format_t

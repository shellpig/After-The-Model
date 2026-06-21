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

const FORMAT_DURATION    := 3.0
const BAR_CELLS          := 10
const COMPLETE_SHOW_TIME := 1.5
const PROMPT_TEXT_COLOR  := Color(0.94, 0.92, 0.84, 1.0)

# World-space Y offset of the stun-repair label's top edge relative to the
# enemy's global_position. Matches walker_01: label_y(-77) - label_height(28).
const _STUN_LABEL_TOP_Y := -105.0
const _PANEL_GAP        := 20.0

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

	_update_pos(target)

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

func _update_pos(target: Node2D) -> void:
	_panel.reset_size()
	var ps    := _panel.size
	var xform := get_viewport().get_canvas_transform()
	var label_top_screen := xform * (target.global_position + Vector2(0.0, _STUN_LABEL_TOP_Y))
	var enemy_screen_x   := (xform * target.global_position).x
	_panel.position = Vector2(
		enemy_screen_x - ps.x * 0.5,
		label_top_screen.y - _PANEL_GAP - ps.y
	)

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
	_lbl.add_theme_color_override("font_color", PROMPT_TEXT_COLOR)
	_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_lbl.add_theme_constant_override("outline_size", 4)
	_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(_lbl)

# Exposed for headless test access.
func get_format_progress() -> float:
	return _format_t

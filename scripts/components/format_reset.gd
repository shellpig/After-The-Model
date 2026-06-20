extends Node
class_name FormatReset

# Phase 13-B: long-press E from behind a stunned machine enemy to format it.
# Attach to the player node. Checks UIMode, interact_primary held state, and
# the nearest machine enemy's can_format() each frame; accumulates time and
# calls enemy.defeated() when FORMAT_DURATION is reached.
# Releasing, moving out of range, enemy recovering, or UI opening resets progress.
#
# HUD: shows prompt label when can_format is true; shows ASCII-bar progress
# while holding E. Uses a CanvasLayer child so it renders above the world.

const FORMAT_DURATION := 2.0
const BAR_CELLS      := 10

var _player: Node2D = null
var _format_t := 0.0

# HUD nodes — created in _ready(), nil-safe everywhere.
var _canvas:       CanvasLayer = null
var _prompt_lbl:   Label       = null
var _progress_lbl: Label       = null

func _ready() -> void:
	_player = get_parent() as Node2D
	_setup_hud()

# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _player == null:
		return

	if UIMode.is_world_input_blocked():
		_format_t = 0.0
		_show_hud(false, false)
		return

	var target := _find_target()
	if target == null:
		_format_t = 0.0
		_show_hud(false, false)
		return

	# In can_format zone — player not yet holding E: show prompt.
	if not Input.is_action_pressed("interact_primary"):
		_format_t = 0.0
		_show_hud(true, false)
		return

	# Holding E: accumulate and show progress.
	_format_t += delta
	_show_hud(true, true)

	if _format_t >= FORMAT_DURATION:
		target.defeated()
		_format_t = 0.0
		_show_hud(false, false)

# ---------------------------------------------------------------------------

func _find_target() -> Node:
	if _player == null:
		return null
	for enemy in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("can_format") and enemy.can_format(_player.global_position):
			return enemy
	return null

func _show_hud(in_range: bool, formatting: bool) -> void:
	if _canvas == null:
		return
	if formatting:
		_prompt_lbl.visible = false
		_progress_lbl.visible = true
		var filled := int(_format_t / FORMAT_DURATION * BAR_CELLS)
		var empty  := BAR_CELLS - filled
		var pct    := int(_format_t / FORMAT_DURATION * 100.0)
		_progress_lbl.text = "格式化中 [%s%s] %d%%" % [
			"█".repeat(filled),
			"░".repeat(empty),
			pct,
		]
	elif in_range:
		_prompt_lbl.visible = true
		_progress_lbl.visible = false
	else:
		_prompt_lbl.visible   = false
		_progress_lbl.visible = false

func _setup_hud() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 5
	add_child(_canvas)

	# Viewport assumed 1280×720; both labels centered at x=640, near bottom.
	_prompt_lbl = _make_label(
		"按住 E：格式化",
		Vector2(380, 36), Vector2(450, 632),
		Color(0.45, 0.95, 1.0), 21
	)
	_canvas.add_child(_prompt_lbl)
	_prompt_lbl.visible = false

	_progress_lbl = _make_label(
		"",
		Vector2(440, 36), Vector2(420, 632),
		Color(1.0, 0.65, 0.15), 21
	)
	_canvas.add_child(_progress_lbl)
	_progress_lbl.visible = false

func _make_label(txt: String, sz: Vector2, pos: Vector2, col: Color, fsize: int) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.size = sz
	lbl.position = pos
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.02))
	lbl.add_theme_constant_override("outline_size", 5)
	return lbl

# Exposed for headless test access.
func get_format_progress() -> float:
	return _format_t

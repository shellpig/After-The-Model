extends Node
class_name FormatReset

# Phase 13-B: long-press E from behind a stunned machine enemy to format it.
# Attach to the player node. Accumulates interact_primary hold time and calls
# enemy.defeated() at FORMAT_DURATION seconds. Resets on release / out-of-range /
# enemy recovery / UI open.
#
# HUD: PanelContainer + Label, styled and positioned identically to GameUI's
# PromptPanel (font_size 20, black outline, floats above AnimatedSprite2D).
# Priority over other prompts is implicit — jump_proto has no GameUI to conflict.

const FORMAT_DURATION := 2.0

var _player: Node2D     = null
var _format_t := 0.0

var _canvas:     CanvasLayer    = null
var _panel:      PanelContainer = null
var _prompt_lbl: Label          = null

func _ready() -> void:
	_player = get_parent() as Node2D
	_setup_hud()

# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _player == null:
		return

	if UIMode.is_world_input_blocked():
		_format_t = 0.0
		_panel.visible = false
		return

	var target := _find_target()
	if target == null:
		_format_t = 0.0
		_panel.visible = false
		return

	# In can_format zone — update panel position every frame.
	_update_panel_pos()

	if not Input.is_action_pressed("interact_primary"):
		_format_t = 0.0
		_prompt_lbl.text = "按住 E：格式化"
		_panel.visible = true
		return

	# Holding E — accumulate and show progress.
	_format_t += delta
	var pct := int(_format_t / FORMAT_DURATION * 100.0)
	_prompt_lbl.text = "格式化中... %d%%" % pct
	_panel.visible = true

	if _format_t >= FORMAT_DURATION:
		target.defeated()
		_format_t = 0.0
		_panel.visible = false

# ---------------------------------------------------------------------------

func _find_target() -> Node:
	if _player == null:
		return null
	for enemy in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("can_format") and enemy.can_format(_player.global_position):
			return enemy
	return null

# Mirrors GameUI._process prompt positioning:
#   sprite screen pos + Vector2(-width * 0.45, -100 * player_y_scale)
func _update_panel_pos() -> void:
	var anim := _player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim == null:
		return
	_panel.reset_size()
	var sp: Vector2 = anim.get_global_transform_with_canvas().origin
	var ps := _panel.size
	var sf: float = _player.global_scale.y
	_panel.position = sp + Vector2(-ps.x * 0.45, -100.0 * sf)

func _setup_hud() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 5
	add_child(_canvas)

	_panel = PanelContainer.new()
	_panel.visible = false
	_canvas.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_panel.add_child(margin)

	# Match GameUI PromptLabel: font_size 20, black outline, no explicit font_color
	# (lets the project theme supply the same colour as all other prompts).
	_prompt_lbl = Label.new()
	_prompt_lbl.text = "按住 E：格式化"
	_prompt_lbl.add_theme_font_size_override("font_size", 20)
	_prompt_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_prompt_lbl.add_theme_constant_override("outline_size", 4)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(_prompt_lbl)

# For headless test access.
func get_format_progress() -> float:
	return _format_t

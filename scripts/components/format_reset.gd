extends Node
class_name FormatReset

# Phase 13-B: long-press E from behind a stunned machine enemy to format it.
# Attach to the player node. Checks UIMode, interact_primary held state, and
# the nearest machine enemy's can_format() each frame; accumulates time and
# calls enemy.defeated() when FORMAT_DURATION is reached.
# Releasing, moving out of range, enemy recovering, or UI opening resets progress.

const FORMAT_DURATION := 2.0

var _player: Node2D = null
var _format_t := 0.0

func _ready() -> void:
	_player = get_parent() as Node2D

func _process(delta: float) -> void:
	if _player == null:
		return
	if UIMode.is_world_input_blocked():
		_format_t = 0.0
		return
	if not Input.is_action_pressed("interact_primary"):
		_format_t = 0.0
		return
	var target := _find_target()
	if target == null:
		_format_t = 0.0
		return
	_format_t += delta
	if _format_t >= FORMAT_DURATION:
		target.defeated()
		_format_t = 0.0

func _find_target() -> Node:
	if _player == null:
		return null
	for enemy in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("can_format") and enemy.can_format(_player.global_position):
			return enemy
	return null

# For headless test access.
func get_format_progress() -> float:
	return _format_t

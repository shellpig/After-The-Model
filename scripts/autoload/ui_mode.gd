extends Node

signal mode_changed(new_mode: int)

enum Mode { NONE, INVENTORY, CONTAINER, NOTEBOOK, MESSAGE, CONFIRM }

var current_mode: int = Mode.NONE
var _caller_mode: int = Mode.NONE

func get_mode() -> int:
	return current_mode

func set_mode(new_mode: int) -> void:
	if current_mode == new_mode:
		return
	current_mode = new_mode
	mode_changed.emit(current_mode)

func is_world_input_blocked() -> bool:
	return current_mode != Mode.NONE

func enter_confirm() -> void:
	enter_overlay(Mode.CONFIRM)

func exit_confirm() -> void:
	exit_overlay()

func enter_overlay(overlay_mode: int) -> void:
	_caller_mode = current_mode
	current_mode = overlay_mode
	mode_changed.emit(current_mode)

func exit_overlay() -> void:
	current_mode = _caller_mode
	_caller_mode = Mode.NONE
	mode_changed.emit(current_mode)


# res://scenes/actors/rack_sentinel/rack_sentinel.gd
extends MachineEnemy
class_name RackSentinel

# Phase 25-B: machine-type sentinel blocking the datacenter_backup corridor.
# Reuses the Phase 13 machine-enemy contract (can_format via MachineEnemy + FormatReset
# -> defeated()). Only two poses were delivered (idle + horizontal_move), so unlike
# walker_01 there is no separate fall/prone/getup visual: apply_stun just freezes it
# on the idle pose for the stun window, then it resumes patrolling.

@export var min_x := 600.0
@export var max_x := 1200.0
@export var speed := 90.0
@export var ground_y := 690.0
@export var walk_anim := "walk"
@export var idle_anim := "idle"

@export var min_move_time := 1.5
@export var max_move_time := 4.0
@export var min_pause_time := 0.6
@export var max_pause_time := 2.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _dir := -1
var _paused := false
var _timer := 0.0
var _defeated := false
var _stunned := false
var _stun_timer := 0.0

func _ready() -> void:
	add_to_group("enemies")
	position.y = ground_y
	position.x = clamp(position.x, min_x, max_x)
	_start_moving()

func _physics_process(delta: float) -> void:
	if _defeated:
		return
	if _stunned:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			_stunned = false
			_start_moving()
		return
	_patrol(delta)

# --- Public API -----------------------------------------------------------

func is_stunned() -> bool:
	return _stunned

func apply_stun(duration: float) -> void:
	if _defeated or _stunned:
		return
	_stunned = true
	_stun_timer = duration
	anim.play(idle_anim)

func is_defeated() -> bool:
	return _defeated

# Permanently stop the sentinel; stays on scene (no despawn).
func defeated() -> void:
	if _defeated:
		return
	_defeated = true
	_stunned = false
	anim.play(idle_anim)

# --- Patrol ---------------------------------------------------------------

func _patrol(delta: float) -> void:
	_timer -= delta
	if _paused:
		if _timer <= 0.0:
			_start_moving()
		return

	position.x += _dir * speed * delta
	if position.x <= min_x:
		position.x = min_x
		_dir = 1
		_facing = 1
	elif position.x >= max_x:
		position.x = max_x
		_dir = -1
		_facing = -1

	anim.flip_h = _dir > 0

	if _timer <= 0.0:
		_start_pause()

func _start_moving() -> void:
	_paused = false
	_timer = randf_range(min_move_time, max_move_time)
	_facing = _dir
	anim.play(walk_anim)

func _start_pause() -> void:
	_paused = true
	_timer = randf_range(min_pause_time, max_pause_time)
	anim.play(idle_anim)

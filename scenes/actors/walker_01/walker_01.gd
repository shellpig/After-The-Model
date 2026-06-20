extends CharacterBody2D

# Phase 13: walker_01 — AI quadruped mech (first of several AI machine types).
# An attackable/interactable actor: CharacterBody2D + CollisionShape2D like the
# player. Patrols back and forth between min_x..max_x at a modest speed,
# occasionally stopping to idle. The art faces LEFT by default, so flip_h is set
# when moving right (opposite of the player, whose art faces right).

@export var min_x := 600.0
@export var max_x := 1200.0
@export var speed := 90.0            # "not very fast" patrol speed, px/s
@export var ground_y := 690.0        # feet rest on this walk line
@export var walk_anim := "walk"
@export var idle_anim := "idle"

# Random move/pause windows so the stops feel organic rather than metronomic.
@export var min_move_time := 1.5
@export var max_move_time := 4.0
@export var min_pause_time := 0.6
@export var max_pause_time := 2.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _dir := -1            # -1 = left (default art facing), 1 = right
var _paused := false
var _timer := 0.0

func _ready() -> void:
	position.y = ground_y
	position.x = clamp(position.x, min_x, max_x)
	_start_moving()

func _physics_process(delta: float) -> void:
	_timer -= delta

	if _paused:
		if _timer <= 0.0:
			_start_moving()
		return

	position.x += _dir * speed * delta
	if position.x <= min_x:
		position.x = min_x
		_dir = 1
	elif position.x >= max_x:
		position.x = max_x
		_dir = -1

	anim.flip_h = _dir > 0   # art faces left; flip only when heading right

	if _timer <= 0.0:
		_start_pause()

func _start_moving() -> void:
	_paused = false
	_timer = randf_range(min_move_time, max_move_time)
	anim.play(walk_anim)

func _start_pause() -> void:
	_paused = true
	_timer = randf_range(min_pause_time, max_pause_time)
	anim.play(idle_anim)

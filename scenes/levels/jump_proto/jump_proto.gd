extends Node2D

const LOWER_WALK_Y := 690.0
const FALL_GRAVITY := 2200.0  # px/s²

var _player: Node = null
var _ledge: Node = null
var _falling := false
var _fall_vel := 0.0  # downward velocity (px/s), positive = down

func _ready() -> void:
	_player = find_child("Player", true, false)
	_ledge = find_child("LedgeArea", true, false)
	if _player and _player.has_method("snap_to_walk_line"):
		_player.snap_to_walk_line()

# _physics_process runs BEFORE player.gd's _physics_process (parent node order),
# so updating walk_line_y here makes player.gd read the already-advanced value
# when it calls position.y = _walk_y_at(x).
func _physics_process(delta: float) -> void:
	if not _player or not _ledge:
		return

	if _falling:
		_fall_vel += FALL_GRAVITY * delta
		_player.walk_line_y = min(_player.walk_line_y + _fall_vel * delta, LOWER_WALK_Y)
		if _player.walk_line_y >= LOWER_WALK_Y:
			_player.walk_line_y = LOWER_WALK_Y
			_falling = false
			_fall_vel = 0.0
		return

	# Trigger fall when player walks off the upper ledge.
	# Skip while jumping so the arc isn't interrupted mid-air.
	if _player.walk_line_y < LOWER_WALK_Y \
			and not _player.is_jumping() \
			and not _ledge.contains_x(_player.global_position.x):
		_falling = true
		_fall_vel = 0.0

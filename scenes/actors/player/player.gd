extends CharacterBody2D

# Climb-only sprite tuning: scale the sprite down while climbing the ladder.
const CLIMB_SCALE := Vector2(0.73, 0.91)   # x, y 各自縮放
const CLIMB_Y_OFFSET := 0.0   # 縮小後腳若離開梯級，往下推幾 px
const CLIMB_Z_INDEX := 20      # 爬梯時 sprite 疊在前景欄杆(z=10)之上

@export var speed := 260.0
@export var min_x := 80.0
@export var max_x := 1180.0
@export var walk_line_y := 700.0

# Phase 12-A: scripted parabolic jump (no global gravity; arc rides the walk line).
@export var jump_height := 120.0       # arc apex height above the walk line, px
@export var jump_duration := 0.55      # total airtime, seconds
@export var air_speed_scale := 1.0     # horizontal speed in air vs ground
const LEDGE_GRAB_MIN_U := 0.35         # only grab a ledge in the apex window
const LEDGE_GRAB_Y_TOLERANCE := 40.0   # px slack between sprite y and ledge target y
var _jumping := false
var _jump_t := 0.0                      # elapsed airtime
var _jump_base_y := 0.0                 # walk line y at takeoff (ledge must be above this)

# Optional walk-line height profile (sorted by x). Empty = flat walk_line_y.
# Used by uneven walk surfaces (e.g. the sagging fire-escape bridge).
var walk_height_points: Array = []

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# Climb mode variables for Phase 7-F
var climb_mode := false
var climb_speed := 180.0
var climb_min_y := 0.0
var climb_max_y := 0.0
var climb_x := 0.0
var _scene_sprite_position := Vector2.ZERO
var _scene_sprite_scale := Vector2.ONE

func _ready() -> void:
	_scene_sprite_position = anim.position
	_scene_sprite_scale = anim.scale
	anim.play("idle")
	_apply_sprite_transform()
	
	# Add AudioListener2D dynamically so 2D sounds decay relative to the player.
	# Place it at the body center (collision shape) instead of the feet origin so
	# EchoPoints mounted high (desks/walls) stay within audible range. The local
	# offset is auto-scaled by the per-map Player.scale via node inheritance.
	var listener = AudioListener2D.new()
	listener.name = "AudioListener2D"
	var body := $CollisionShape2D
	if body:
		listener.position = body.position
	listener.make_current()
	add_child(listener)

func _physics_process(delta: float) -> void:
	if UIMode.is_world_input_blocked():
		velocity = Vector2.ZERO
		if get_parent().name == "ApartmentRoom" and get_parent().get("_opening_monologue_active"):
			_apply_sprite_transform()
			return
		if _jumping:
			_jumping = false
			_jump_t = 0.0
			position.y = _walk_y_at(position.x)
		anim.play("idle")
		_apply_sprite_transform()
		return

	if climb_mode:
		var v_dir := Input.get_axis("move_up", "move_down")
		position.y += v_dir * climb_speed * delta
		position.y = clamp(position.y, climb_min_y, climb_max_y)
		position.x = climb_x

		if v_dir != 0.0:
			anim.play("climb")
		else:
			anim.play("climb")
			anim.stop()
		_apply_sprite_transform()
		return

	var dir := Input.get_axis("move_left", "move_right")

	# Phase 12-A: takeoff (ground only; no double jump / wall jump).
	if not _jumping and Input.is_action_just_pressed("jump"):
		_jumping = true
		_jump_t = 0.0
		_jump_base_y = _walk_y_at(position.x)

	# Phase 12-A: airborne arc (scripted parabola; keeps horizontal control).
	if _jumping:
		_jump_t += delta
		position.x += dir * speed * air_speed_scale * delta
		position.x = clamp(position.x, min_x, max_x)
		var u := _jump_t / jump_duration
		var landed := false
		if u >= LEDGE_GRAB_MIN_U and _try_grab_ledge():
			landed = true
		elif _jump_t >= jump_duration:
			position.y = _walk_y_at(position.x)
			landed = true
		else:
			position.y = _walk_y_at(position.x) - jump_height * 4.0 * u * (1.0 - u)
		if landed:
			_jumping = false
			_jump_t = 0.0
			if dir != 0.0:
				anim.play("walk")
				anim.flip_h = dir < 0.0
			else:
				anim.play("idle")
		else:
			_play_jump_anim()
			if dir != 0.0:
				anim.flip_h = dir < 0.0
		_apply_sprite_transform()
		return

	position.x += dir * speed * delta
	position.x = clamp(position.x, min_x, max_x)
	position.y = _walk_y_at(position.x)

	if dir != 0.0:
		anim.play("walk")
		anim.flip_h = dir < 0.0
	else:
		anim.play("idle")

	_apply_sprite_transform()

func _apply_sprite_transform() -> void:
	anim.z_index = CLIMB_Z_INDEX if anim.animation == "climb" else 0
	if anim.animation == "prone" or anim.animation == "get_up":
		anim.scale = _scene_sprite_scale * 0.9
		anim.position = _scene_sprite_position + Vector2(0.0, 20.0)
	elif anim.animation == "climb":
		anim.scale = _scene_sprite_scale * CLIMB_SCALE
		anim.position = _scene_sprite_position + Vector2(0.0, CLIMB_Y_OFFSET)
	else:
		anim.scale = _scene_sprite_scale
		anim.position = _scene_sprite_position

# Walk-line y at a given x. Linear interpolation across walk_height_points,
# clamped to the end values outside the profile range. Flat when no profile.
func _walk_y_at(x: float) -> float:
	if walk_height_points.is_empty():
		return walk_line_y
	if x <= walk_height_points[0].x:
		return walk_height_points[0].y
	var last_index := walk_height_points.size() - 1
	if x >= walk_height_points[last_index].x:
		return walk_height_points[last_index].y
	for i in range(last_index):
		var a: Vector2 = walk_height_points[i]
		var b: Vector2 = walk_height_points[i + 1]
		if x >= a.x and x <= b.x:
			return lerp(a.y, b.y, (x - a.x) / (b.x - a.x))
	return walk_line_y

# Snap y onto the current walk line immediately (used after entry / ladder exit).
func snap_to_walk_line() -> void:
	global_position.y = _walk_y_at(global_position.x)

func get_save_x() -> float:
	return global_position.x

func set_save_x(x: float) -> void:
	global_position.x = clamp(x, min_x, max_x)

func get_facing() -> int:
	return -1 if anim.flip_h else 1

func set_facing(f: int) -> void:
	anim.flip_h = (f == -1)

# Climb mode APIs for Phase 7-F
func enter_climb_mode(ladder_x: float, min_y: float, max_y: float) -> void:
	climb_mode = true
	climb_x = ladder_x
	climb_min_y = min_y
	climb_max_y = max_y
	global_position.x = ladder_x
	velocity = Vector2.ZERO

func exit_climb_mode(target_y: float) -> void:
	climb_mode = false
	global_position.y = target_y
	walk_line_y = target_y

func is_climbing() -> bool:
	return climb_mode

# Phase 12-A: jump state query.
func is_jumping() -> bool:
	return _jumping

func _play_jump_anim() -> void:
	if anim.sprite_frames and anim.sprite_frames.has_animation("jump"):
		if anim.animation != "jump":
			anim.play("jump")
	else:
		anim.play("walk")

# Try to snap onto a higher ledge during the apex window. No-op until ledges exist
# (LedgeArea2D + group "ledges" arrive in Phase 12-B). Returns true if grabbed.
func _try_grab_ledge() -> bool:
	for l in get_tree().get_nodes_in_group("ledges"):
		if not (l.has_method("contains_x") and l.has_method("get_target_y")):
			continue
		if not l.contains_x(global_position.x):
			continue
		var ty: float = l.get_target_y()
		if ty < _jump_base_y and abs(global_position.y - ty) <= LEDGE_GRAB_Y_TOLERANCE:
			walk_line_y = ty
			snap_to_walk_line()
			return true
	return false

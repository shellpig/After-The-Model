extends CharacterBody2D

# Climb-only sprite tuning: scale the sprite down while climbing the ladder.
const CLIMB_SCALE := Vector2(0.73, 0.91)   # x, y 各自縮放
const CLIMB_Y_OFFSET := 0.0   # 縮小後腳若離開梯級，往下推幾 px
const CLIMB_Z_INDEX := 20      # 爬梯時 sprite 疊在前景欄杆(z=10)之上

@export var speed := 260.0
@export var min_x := 80.0
@export var max_x := 1180.0
@export var walk_line_y := 700.0

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

func _physics_process(delta: float) -> void:
	if UIMode.is_world_input_blocked():
		velocity = Vector2.ZERO
		if get_parent().name == "ApartmentRoom" and get_parent().get("_opening_monologue_active"):
			_apply_sprite_transform()
			return
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

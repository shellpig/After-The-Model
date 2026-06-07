extends CharacterBody2D

@export var speed := 260.0
@export var min_x := 80.0
@export var max_x := 1180.0
@export var walk_line_y := 700.0

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
	position.y = walk_line_y

	if dir != 0.0:
		anim.play("walk")
		anim.flip_h = dir < 0.0
	else:
		anim.play("idle")

	_apply_sprite_transform()

func _apply_sprite_transform() -> void:
	if anim.animation == "prone" or anim.animation == "get_up":
		anim.scale = _scene_sprite_scale * 0.9
		anim.position = _scene_sprite_position + Vector2(0.0, 20.0)
	else:
		anim.scale = _scene_sprite_scale
		anim.position = _scene_sprite_position

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

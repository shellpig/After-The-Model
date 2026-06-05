extends CharacterBody2D

@export var speed := 260.0
@export var min_x := 80.0
@export var max_x := 1180.0
@export var walk_line_y := 700.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim.play("idle")
	_adjust_sprite_scale()

func _physics_process(delta: float) -> void:
	if UIMode.is_world_input_blocked():
		velocity = Vector2.ZERO
		if get_parent().name == "ApartmentRoom" and get_parent().get("_opening_monologue_active"):
			_adjust_sprite_scale()
			return
		anim.play("idle")
		_adjust_sprite_scale()
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

	_adjust_sprite_scale()

func _adjust_sprite_scale() -> void:
	if anim.animation == "prone" or anim.animation == "get_up":
		anim.scale = Vector2(0.9, 0.9)
		anim.position.y = -164.0 # Shifted down by 20px (default is -184.0)
	else:
		anim.scale = Vector2(1.0, 1.0)
		anim.position.y = -184.0 # Default Y offset

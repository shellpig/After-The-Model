extends CharacterBody2D

@export var speed := 260.0
@export var min_x := 80.0
@export var max_x := 1180.0
@export var walk_line_y := 700.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim.play("idle")

func _physics_process(delta: float) -> void:
	if UIMode.is_world_input_blocked():
		velocity = Vector2.ZERO
		anim.play("idle")
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

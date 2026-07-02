# res://scenes/actors/security_guard/security_guard.gd
extends HumanEnemy
class_name SecurityGuard

# Phase 25-B: minimal human-guard chase AI -- the one genuinely new component this
# phase adds. Walks toward the player's x each physics frame, clamped to the corridor
# bounds. Cannot be formatted or killed (can_format/apply_stun inherited no-op from
# HumanEnemy/EnemyBase). On contact it just shoves the player back for a brief,
# non-punishing stagger via ContactArea -- no combat_loss, no failure state.

@export var speed := 110.0
@export var min_x := 200.0
@export var max_x := 4600.0
@export var ground_y := 690.0
@export var chase_deadzone := 6.0
@export var knockback_distance := 90.0
@export var knockback_stagger_time := 0.5
@export var contact_cooldown := 1.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var contact_area: Area2D = $ContactArea

var _player: CharacterBody2D = null
var _cooldown_t := 0.0

func _ready() -> void:
	add_to_group("enemies")
	position.y = ground_y
	_player = get_parent().get_node_or_null("Player")
	contact_area.body_entered.connect(_on_contact_entered)
	anim.play("idle")

func _physics_process(delta: float) -> void:
	_cooldown_t = max(0.0, _cooldown_t - delta)
	if _player == null or not is_instance_valid(_player):
		return

	var dx: float = _player.global_position.x - global_position.x
	if absf(dx) > chase_deadzone:
		var dir := signf(dx)
		position.x = clamp(position.x + dir * speed * delta, min_x, max_x)
		anim.flip_h = dir < 0.0
		anim.play("walk")
	else:
		anim.play("idle")

func _on_contact_entered(body: Node) -> void:
	if _cooldown_t > 0.0:
		return
	if body != _player:
		return
	_cooldown_t = contact_cooldown
	if body.has_method("apply_knockback"):
		# Push the player away from the guard along x.
		var push_dir := 1.0 if body.global_position.x >= global_position.x else -1.0
		body.apply_knockback(push_dir, knockback_distance, knockback_stagger_time)

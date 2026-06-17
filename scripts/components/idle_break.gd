extends Node

@export var target_path: NodePath = NodePath("../AnimatedSprite2D")
@export var idle_anim: String = "idle"
@export var break_anim: String = "idle_glance"
@export var interval_min: float = 5.0
@export var interval_max: float = 12.0

var _sprite: AnimatedSprite2D
var _timer: Timer

func _ready() -> void:
	_sprite = get_node(target_path) as AnimatedSprite2D
	if not _sprite:
		push_warning("IdleBreak: target_path does not point to an AnimatedSprite2D")
		return
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_sprite.animation_finished.connect(_on_animation_finished)
	_schedule()

func _on_timer_timeout() -> void:
	if _sprite and _sprite.animation == idle_anim:
		_sprite.play(break_anim)

func _on_animation_finished() -> void:
	if _sprite and _sprite.animation == break_anim:
		_sprite.play(idle_anim)
		_schedule()

func _schedule() -> void:
	_timer.start(randf_range(interval_min, interval_max))

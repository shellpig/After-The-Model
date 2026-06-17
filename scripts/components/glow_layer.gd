extends Polygon2D

enum Mode { BREATHING, STUTTER }

@export_enum("BREATHING", "STUTTER") var mode: int = Mode.BREATHING
@export var alpha_min: float = 0.2
@export var alpha_max: float = 0.55
@export var speed: float = 0.8
@export var stutter_off_min: float = 0.04
@export var stutter_off_max: float = 0.18
@export var stutter_on_min: float = 0.6
@export var stutter_on_max: float = 4.5

var _time: float = 0.0
var _stutter_timer: float = 0.0
var _flickering: bool = false

func _ready() -> void:
	if mode == Mode.STUTTER:
		_stutter_timer = randf_range(stutter_on_min, stutter_on_max)
		modulate.a = alpha_max

func _process(delta: float) -> void:
	if mode == Mode.BREATHING:
		_time += delta * speed
		modulate.a = lerp(alpha_min, alpha_max, (sin(_time) + 1.0) * 0.5)
	else:
		_stutter_timer -= delta
		if _stutter_timer <= 0.0:
			_flickering = !_flickering
			_stutter_timer = randf_range(stutter_off_min, stutter_off_max) \
				if _flickering else randf_range(stutter_on_min, stutter_on_max)
		modulate.a = randf_range(0.0, alpha_min * 0.3) if _flickering else alpha_max

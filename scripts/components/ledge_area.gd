extends Area2D
class_name LedgeArea2D

@export var target_walk_y: float = 500.0

func _ready() -> void:
	add_to_group("ledges")

# Returns true if global x falls within this ledge's horizontal span.
# Player jump arc queries this each frame during the apex grab window.
func contains_x(x: float) -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			var shape = child.shape
			if shape is RectangleShape2D:
				var cx: float = global_position.x + child.position.x
				var hw: float = shape.size.x * 0.5
				return x >= cx - hw and x <= cx + hw
	return false

func get_target_y() -> float:
	return target_walk_y

extends Node2D
class_name JumpGap

# Marks an x-interval where there is no walk path.
# The gap is enforced by scene layout (no LedgeArea covers this interval and
# the lower walk line offers no footing on the other side).
# Player must jump over it.
@export var gap_x_min: float = 0.0
@export var gap_x_max: float = 100.0

func is_in_gap(x: float) -> bool:
	return x > gap_x_min and x < gap_x_max

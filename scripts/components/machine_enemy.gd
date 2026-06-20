extends EnemyBase
class_name MachineEnemy

# Phase 13-B: machine-type enemy base. Adds can_format() — returns true only
# when the enemy is stunned AND the player approaches from behind within range.
# Human enemies override can_format() to always return false (Phase 13-C).

@export var format_check_distance := 160.0

# Patrol direction the enemy is currently facing (-1 = left, 1 = right).
# Subclass updates this whenever the walk direction changes.
var _facing := -1

# Returns true when: enemy is stunned (PRONE) + player is on the BACK side
# (opposite to _facing) + within format_check_distance px horizontally.
func can_format(player_pos: Vector2) -> bool:
	if not is_stunned():
		return false
	if is_defeated():
		return false
	var dx: float = player_pos.x - global_position.x
	if abs(dx) > format_check_distance:
		return false
	# Behind = opposite side from where the enemy is looking.
	return (_facing == 1 and dx < 0.0) or (_facing == -1 and dx > 0.0)

# Subclass overrides to permanently stop the machine (stays on scene, no despawn).
func defeated() -> void:
	pass

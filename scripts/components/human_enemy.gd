extends EnemyBase
class_name HumanEnemy

# Phase 13-C: human-type enemy base.
# Human enemies do not have a formatting option (can_format is always false)
# and cannot be killed by the player.

func can_format(_player_pos: Vector2) -> bool:
	return false

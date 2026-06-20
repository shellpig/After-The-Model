extends CharacterBody2D
class_name EnemyBase

# Minimal interface for all enemy types.
# 13-A: machine / human enemies inherit or duck-type these methods.

func is_stunned() -> bool:
	return false

func apply_stun(_duration: float) -> void:
	pass

func is_defeated() -> bool:
	return false

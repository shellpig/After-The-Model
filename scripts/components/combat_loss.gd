extends Area2D
class_name CombatLoss

# Phase 13-D: Universal "combat loss = branch story" component.
# Teleports player to a safe point, sets a flag, and shows a message on active enemy contact.

@export var failure_flag := "combat_proto_failed"
@export var safe_point := Vector2(250.0, 690.0)
@export var message_text := "你被隧道清潔機抓到了。看來必須另尋他路。"
@export var enemy: EnemyBase
# > 0 enables the blackout reset: fade the world to black over this many seconds,
# teleport the player while the screen is dark, hold black, then fade back (each
# phase lasts blackout_seconds). 0 keeps the original instant teleport.
@export var blackout_seconds := 0.0

signal combat_failed

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if enemy == null:
		var parent = get_parent()
		if parent is EnemyBase:
			enemy = parent

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player" and not body.has_method("is_jumping"):
		return
	
	if enemy:
		if enemy.is_stunned() or enemy.is_defeated():
			return
			
	trigger_failure(body)

func trigger_failure(player: Node2D) -> void:
	GameState.set_flag(failure_flag, true)
	combat_failed.emit()

	var level = _find_level_node()

	# Blackout reset (tunnel_combat): darken the world, move the player while it's
	# black, then fade back. UI/message stay lit (separate CanvasLayer). With
	# blackout_seconds == 0 this falls back to the original instant teleport.
	if blackout_seconds > 0.0 and level is CanvasItem:
		_run_blackout_reset(level, player)
	else:
		_teleport_player(player)

	if level and level.has_signal("interaction_requested"):
		level.interaction_requested.emit({
			"type": "message",
			"message_text": message_text
		})

func _run_blackout_reset(level: CanvasItem, player: Node2D) -> void:
	var tween := create_tween()
	tween.tween_property(level, "modulate", Color(0, 0, 0, 1), blackout_seconds)
	tween.tween_callback(_teleport_player.bind(player))
	tween.tween_interval(blackout_seconds)
	tween.tween_property(level, "modulate", Color(1, 1, 1, 1), blackout_seconds)

func _teleport_player(player: Node2D) -> void:
	if player:
		player.global_position = safe_point
		if "walk_line_y" in player:
			player.walk_line_y = safe_point.y

func _find_level_node() -> Node:
	var p := get_parent()
	while p:
		if p.has_signal("interaction_requested"):
			return p
		p = p.get_parent()
	return null

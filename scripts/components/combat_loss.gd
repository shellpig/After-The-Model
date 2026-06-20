extends Area2D
class_name CombatLoss

# Phase 13-D: Universal "combat loss = branch story" component.
# Teleports player to a safe point, sets a flag, and shows a message on active enemy contact.

@export var failure_flag := "combat_proto_failed"
@export var safe_point := Vector2(250.0, 690.0)
@export var message_text := "你被隧道清潔機抓到了。看來必須另尋他路。"
@export var enemy: EnemyBase

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
	if GameState.get_flag(failure_flag, false):
		_teleport_player(player)
		return
		
	GameState.set_flag(failure_flag, true)
	_teleport_player(player)
	
	combat_failed.emit()
	
	var level = _find_level_node()
	if level and level.has_signal("interaction_requested"):
		level.interaction_requested.emit({
			"type": "message",
			"message_text": message_text
		})

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

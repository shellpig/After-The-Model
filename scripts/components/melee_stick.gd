extends Node
class_name MeleeStick

# Player-side melee hit detection for Phase 13-A.
# Attach as a child of the player node. On attack_impact_frame, scans the
# "enemies" group for valid targets (in-range + player facing them) and calls
# apply_stun() on the first hit, then spawns the hit-impact burst.

const HitImpactBurst = preload("res://scripts/components/hit_impact_burst.gd")

# Reach at player scale 1.0; the actual range scales with the player's on-screen
# size (see _on_attack_impact_frame) so it feels consistent across maps that use
# different Player scales (e.g. 1.0 in tunnel_combat, 0.8 in subway).
@export var attack_reach := 250.0
@export var stun_duration := 5.0

var _player: Node2D = null

func _ready() -> void:
	_player = get_parent() as Node2D
	if _player and _player.has_signal("attack_impact_frame"):
		_player.connect("attack_impact_frame", _on_attack_impact_frame)

func _on_attack_impact_frame() -> void:
	if _player == null:
		return
	var facing := 1
	if _player.has_method("get_facing"):
		facing = _player.get_facing()

	# Scale the reach by the player's world scale so a swing covers the same
	# proportion of the character regardless of the map's Player scale.
	var reach := attack_reach * absf(_player.global_scale.x)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_method("apply_stun"):
			continue
		if enemy.has_method("is_stunned") and enemy.is_stunned():
			continue
		var dx: float = enemy.global_position.x - _player.global_position.x
		if abs(dx) > reach:
			continue
		# Player must face the enemy: dx > 0 → face right (1), dx < 0 → face left (-1)
		if not ((dx > 0.0 and facing == 1) or (dx < 0.0 and facing == -1)):
			continue
		enemy.apply_stun(stun_duration)
		if enemy.has_method("flash_white"):
			enemy.flash_white()
		var hit_sound := ""
		if enemy.has_method("get_hit_sound"):
			hit_sound = enemy.get_hit_sound()
		_spawn_impact(enemy, hit_sound)
		break  # one hit per swing

func _spawn_impact(enemy: Node2D, hit_sound: String = "") -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	var burst := HitImpactBurst.new()
	if not hit_sound.is_empty():
		burst.hit_sound_path = hit_sound
	root.add_child(burst)
	burst.global_position = Vector2(
		(_player.global_position.x + enemy.global_position.x) * 0.5,
		enemy.global_position.y - 120.0
	)

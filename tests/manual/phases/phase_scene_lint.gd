extends "res://tests/manual/phases/test_phases_base.gd"

const EXEMPT_SCENES := []

func _run_phase_scene_lint() -> void:
	print("--- Scene Lint: SCENES player structure guard ---")

	var main_script_scene_lint = load("res://scenes/main/main.gd")
	var scenes_scene_lint: Dictionary = main_script_scene_lint.SCENES
	var checked_count_scene_lint := 0

	for scene_id_scene_lint in scenes_scene_lint.keys():
		if EXEMPT_SCENES.has(scene_id_scene_lint):
			continue

		var scene_config_scene_lint: Dictionary = scenes_scene_lint[scene_id_scene_lint]
		var scene_path_scene_lint: String = scene_config_scene_lint.get("path", "")
		if scene_path_scene_lint.is_empty():
			printerr("FAIL Scene Lint: scene '", scene_id_scene_lint, "' is missing a path in SCENES.")
			get_tree().quit(1)
			return

		var packed_scene_lint = load(scene_path_scene_lint) as PackedScene
		if packed_scene_lint == null:
			printerr("FAIL Scene Lint: could not load scene '", scene_id_scene_lint, "' at ", scene_path_scene_lint)
			get_tree().quit(1)
			return

		var instance_scene_lint = packed_scene_lint.instantiate()
		if instance_scene_lint == null:
			printerr("FAIL Scene Lint: could not instantiate scene '", scene_id_scene_lint, "' at ", scene_path_scene_lint)
			get_tree().quit(1)
			return

		var player_scene_lint = instance_scene_lint.find_child("Player", true, false)
		if player_scene_lint == null:
			instance_scene_lint.free()
			printerr("FAIL Scene Lint: scene '", scene_id_scene_lint, "' is missing Player.")
			get_tree().quit(1)
			return

		var anim_scene_lint = player_scene_lint.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if anim_scene_lint == null:
			instance_scene_lint.free()
			printerr("FAIL Scene Lint: scene '", scene_id_scene_lint, "' Player is missing AnimatedSprite2D.")
			get_tree().quit(1)
			return

		if anim_scene_lint.sprite_frames == null:
			instance_scene_lint.free()
			printerr("FAIL Scene Lint: scene '", scene_id_scene_lint, "' Player/AnimatedSprite2D has no sprite_frames.")
			get_tree().quit(1)
			return

		if not "idle_anim" in player_scene_lint:
			instance_scene_lint.free()
			printerr("FAIL Scene Lint: scene '", scene_id_scene_lint, "' Player is missing idle_anim export.")
			get_tree().quit(1)
			return

		var idle_anim_scene_lint: String = player_scene_lint.idle_anim
		if not anim_scene_lint.sprite_frames.has_animation(idle_anim_scene_lint):
			instance_scene_lint.free()
			printerr("FAIL Scene Lint: scene '", scene_id_scene_lint, "' Player/AnimatedSprite2D lacks idle_anim animation '", idle_anim_scene_lint, "'.")
			get_tree().quit(1)
			return

		var collision_scene_lint = player_scene_lint.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision_scene_lint == null:
			instance_scene_lint.free()
			printerr("FAIL Scene Lint: scene '", scene_id_scene_lint, "' Player is missing CollisionShape2D.")
			get_tree().quit(1)
			return

		if collision_scene_lint.shape == null:
			instance_scene_lint.free()
			printerr("FAIL Scene Lint: scene '", scene_id_scene_lint, "' Player/CollisionShape2D has no shape.")
			get_tree().quit(1)
			return

		checked_count_scene_lint += 1
		instance_scene_lint.free()

	print("PASS Scene Lint: ", checked_count_scene_lint, " SCENES entries verified for Player structure.")
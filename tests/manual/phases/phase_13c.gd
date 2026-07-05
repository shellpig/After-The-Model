extends "res://tests/manual/phases/phase_13d.gd"

func _run_phase_13c() -> void:
	# ===================== Phase 13-C: human enemy skeleton =====================
	print("--- Phase 13-C: human enemy skeleton ---")

	var human_enemy_script = load("res://scripts/components/human_enemy.gd")
	if human_enemy_script == null:
		printerr("FAIL 13-C: could not load human_enemy.gd!")
		get_tree().quit(1)
		return
	print("PASS 13-C: human_enemy.gd loads.")

	var human_inst = CharacterBody2D.new()
	human_inst.set_script(human_enemy_script)
	add_child(human_inst)
	await get_tree().process_frame

	if not human_inst.has_method("can_format"):
		printerr("FAIL 13-C: HumanEnemy missing can_format() method!")
		get_tree().quit(1)
		return
	print("PASS 13-C: HumanEnemy has can_format() method.")

	if human_inst.can_format(Vector2(0.0, 0.0)):
		printerr("FAIL 13-C: HumanEnemy.can_format() must always return false!")
		get_tree().quit(1)
		return
	print("PASS 13-C: HumanEnemy.can_format() returns false.")

	# Test that hitting it with melee does not defeat it
	if human_inst.is_defeated():
		printerr("FAIL 13-C: HumanEnemy must not start in defeated state!")
		get_tree().quit(1)
		return

	# Apply stun to verify base enemy_base compliance
	human_inst.apply_stun(5.0)
	if human_inst.is_stunned():
		printerr("FAIL 13-C: HumanEnemy should not be stunned (apply_stun is no-op)!")
		get_tree().quit(1)
		return
	print("PASS 13-C: HumanEnemy apply_stun is no-op.")

	if human_inst.is_defeated():
		printerr("FAIL 13-C: HumanEnemy must not be defeated after stun!")
		get_tree().quit(1)
		return
	print("PASS 13-C: HumanEnemy is not defeated after stun.")

	human_inst.queue_free()
	await get_tree().process_frame

	print("PASS: Phase 13-C human enemy skeleton verified.")


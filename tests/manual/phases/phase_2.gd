extends "res://tests/manual/phases/phase_1d.gd"

func _run_phase_2() -> void:
	# Verify work_ai_cleanup_role is NOT preloaded in Phase 2
	if GameState.has_note("work_ai_cleanup_role"):
		printerr("FAIL: Story note work_ai_cleanup_role is preloaded, but it must NOT be preloaded!")
		get_tree().quit(1)
		return
	print("PASS: Story note work_ai_cleanup_role is NOT preloaded.")

	# Verify door unlock method is NOT preloaded
	if GameState.has_knowledge("identity_door_unlock_method"):
		printerr("FAIL: Door unlock method identity_door_unlock_method is preloaded, but it must NOT be preloaded!")
		get_tree().quit(1)
		return
	print("PASS: Door unlock method is NOT preloaded.")


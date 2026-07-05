extends "res://tests/manual/phases/phase_3c.gd"

func _run_phase_1e() -> void:
	# 7. Verify UIMode Phase 1-E CONFIRM APIs
	print("Verifying UIMode CONFIRM APIs (Phase 1-E)...")
	if not UIMode.has_method("enter_confirm") or not UIMode.has_method("exit_confirm"):
		printerr("FAIL: UIMode lacks enter_confirm / exit_confirm!")
		get_tree().quit(1)
		return
	print("PASS: UIMode CONFIRM APIs verified.")

	# 8. Verify GameState Phase 1-E APIs
	print("Verifying GameState Phase 1-E APIs...")
	if not GameState.has_method("unequip_by_instance") or not GameState.has_method("discard_item"):
		printerr("FAIL: GameState lacks unequip_by_instance / discard_item!")
		get_tree().quit(1)
		return
	print("PASS: GameState Phase 1-E APIs verified.")


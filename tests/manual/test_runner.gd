extends "res://tests/manual/phases/phase_1abc.gd"

func _ready() -> void:
	LocaleManager.set_locale("zh_TW")
	print("==================================================")
	print("RUNNING INTEGRATION VERIFICATION FOR UI MODE & BACKPACK")
	print("==================================================")

	await _run_phase_1abc()
	await get_tree().process_frame

	await _run_phase_2()
	await get_tree().process_frame

	await _run_phase_1d()
	await get_tree().process_frame

	await _run_phase_1e()
	await get_tree().process_frame

	await _run_phase_3c()
	await get_tree().process_frame

	await _run_phase_4a()
	await get_tree().process_frame

	await _run_phase_10a()
	await get_tree().process_frame

	await _run_phase_10b()
	await get_tree().process_frame

	await _run_phase_10c()
	await get_tree().process_frame

	await _run_phase_10d()
	await get_tree().process_frame

	await _run_phase_4e()
	await get_tree().process_frame

	await _run_phase_5a()
	await get_tree().process_frame

	await _run_phase_7b()
	await get_tree().process_frame

	await _run_phase_5b()
	await get_tree().process_frame

	await _run_phase_6a()
	await get_tree().process_frame

	await _run_phase_6b()
	await get_tree().process_frame

	await _run_phase_6de()
	await get_tree().process_frame

	await _run_phase_7a()
	await get_tree().process_frame

	await _run_phase_7c()
	await get_tree().process_frame

	await _run_phase_7d()
	await get_tree().process_frame

	await _run_phase_7g()
	await get_tree().process_frame

	await _run_phase_7h()
	await get_tree().process_frame

	await _run_phase_7i()
	await get_tree().process_frame

	await _run_phase_7j()
	await get_tree().process_frame

	await _run_phase_8a()
	await get_tree().process_frame

	await _run_phase_8b()
	await get_tree().process_frame

	await _run_phase_8c()
	await get_tree().process_frame

	await _run_phase_8d()
	await get_tree().process_frame

	await _run_phase_8e()
	await get_tree().process_frame

	# ============================================================
	await _run_phase_8f()
	await get_tree().process_frame

	await _run_phase_8g()
	await get_tree().process_frame

	await _run_phase_8h()
	await get_tree().process_frame

	await _run_phase_9a()
	await get_tree().process_frame

	await _run_phase_9b()
	await get_tree().process_frame

	await _run_phase_9c()
	await get_tree().process_frame

	await _run_phase_9d()
	await get_tree().process_frame

	await _run_phase_9e()
	await get_tree().process_frame

	await _run_phase_9f()
	await get_tree().process_frame

	await _run_phase_9g()
	await get_tree().process_frame

	await _run_phase_9h()
	await get_tree().process_frame

	await _run_phase_11()
	await get_tree().process_frame

	await _run_phase_12a()
	await get_tree().process_frame

	await _run_phase_12b()
	await get_tree().process_frame

	await _run_phase_12c()
	await get_tree().process_frame

	await _run_phase_13ab()
	await get_tree().process_frame

	await _run_phase_13c()
	await get_tree().process_frame

	await _run_phase_13d()
	await get_tree().process_frame

	await _run_phase_13f()
	await get_tree().process_frame

	await _run_phase_14a()
	await get_tree().process_frame

	await _run_phase_14b()
	await get_tree().process_frame

	await _run_phase_14c()
	await get_tree().process_frame

	await _run_phase_14d()
	await get_tree().process_frame

	await _run_phase_17a()
	await get_tree().process_frame

	await _run_phase_17b()
	await get_tree().process_frame

	await _run_phase_17c()
	await get_tree().process_frame

	await _run_phase_18()
	await get_tree().process_frame

	await _run_phase_19a()
	await get_tree().process_frame

	await _run_phase_19b()
	await get_tree().process_frame

	await _run_phase_19c()
	await get_tree().process_frame

	await _run_phase_m1()
	await get_tree().process_frame

	await _run_phase_m2a()
	await get_tree().process_frame

	await _run_phase_m2b()
	await get_tree().process_frame

	await _run_phase_m2c()
	await get_tree().process_frame

	await _run_phase_m2d()
	await get_tree().process_frame

	await _run_phase_m2e()
	await get_tree().process_frame

	await _run_phase_20()
	await get_tree().process_frame

	await _run_phase_21a()
	await get_tree().process_frame

	await _run_phase_21b()
	await get_tree().process_frame

	await _run_phase_21c()
	await get_tree().process_frame

	await _run_phase_21d()
	await get_tree().process_frame

	await _run_phase_21e()
	await get_tree().process_frame

	await _run_phase_21f()
	await get_tree().process_frame

	await _run_phase_23a()
	await get_tree().process_frame

	await _run_phase_23b()
	await get_tree().process_frame

	await _run_phase_23c()
	await get_tree().process_frame

	await _run_phase_23d()
	await get_tree().process_frame

	await _run_phase_24a()
	await get_tree().process_frame

	await _run_phase_24b()
	await get_tree().process_frame

	await _run_phase_24c()
	await get_tree().process_frame

	await _run_phase_25a()
	await get_tree().process_frame

	await _run_phase_25b()
	await get_tree().process_frame

	await _run_phase_25c()
	await get_tree().process_frame

	await _run_phase_26a()
	await get_tree().process_frame

	await _run_phase_26b()
	await get_tree().process_frame

	await _run_phase_26c()
	await get_tree().process_frame

	await _run_phase_26d()
	await get_tree().process_frame

	await _run_phase_26e()
	await get_tree().process_frame

	await _run_phase_27a()
	await get_tree().process_frame

	await _run_phase_27b()
	await get_tree().process_frame

	await _run_phase_27c()
	await get_tree().process_frame

	await _run_phase_27d()
	await get_tree().process_frame

	await _run_phase_28a()
	await get_tree().process_frame

	await _run_phase_28bc()
	await get_tree().process_frame

	await _run_phase_28d()
	await get_tree().process_frame

	await _run_phase_29()
	await get_tree().process_frame

	await _run_phase_30a()
	await get_tree().process_frame

	await _run_phase_30b()
	await get_tree().process_frame

	await _run_phase_30c()
	await get_tree().process_frame

	await _run_phase_scene_lint()
	await get_tree().process_frame

	print("==================================================")
	print("ALL INTEGRATION VERIFICATIONS PASSED SUCCESSFULLY!")
	print("==================================================")


	# Defer quit so that this ready function can return and pop stack frame, clearing references
	get_tree().call_deferred("quit", 0)


extends "res://tests/manual/phases/phase_30c.gd"

func _run_phase_30b() -> void:
	# ===================== Phase 30-B: 全主線脊椎回歸測試 =====================
	print("--- Phase 30-B: 全主線脊椎回歸測試 ---")
	await _run_mainline_spine_phase30("reclaim")
	await _run_mainline_spine_phase30("protect_not_b")
	await _run_mainline_spine_phase30("protect_b")
	await _run_mainline_spine_phase30("expose_a")
	await _run_mainline_spine_phase30("expose_b")
	await _run_mainline_spine_phase30("expose_c")
	print("PASS 30-B: All 6 mainline spine endings regression test cases verified.")


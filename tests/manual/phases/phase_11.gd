extends "res://tests/manual/phases/phase_12a.gd"

func _run_phase_11() -> void:
	# Phase 11 — Trust/Trace 雙軸 + 清洗（地基）
	# ============================================================
	print("Verifying Phase 11 Trust/Trace foundation...")
	# 乾淨起點（Phase 11 為本檔最後一段，reset 不影響後續，只剩 instance cleanup）
	GameState.reset_for_new_game()

	# 11-A：trace 預設 0 + add_trace / get_trace（正負皆可）
	if GameState.get_trace() != 0:
		printerr("FAIL 11-A: trace should default to 0 after reset! Got: ", GameState.get_trace())
		get_tree().quit(1)
		return
	GameState.add_trace(5)
	GameState.add_trace(-2)
	if GameState.get_trace() != 3:
		printerr("FAIL 11-A: add_trace accumulation wrong! Expected 3, got: ", GameState.get_trace())
		get_tree().quit(1)
		return
	GameState.add_trace(0)
	if GameState.get_trace() != 3:
		printerr("FAIL 11-A: add_trace(0) must be a no-op!")
		get_tree().quit(1)
		return

	# 11-A：trace 進 to_save_dict、load_save_dict 還原
	var p11_sd = GameState.to_save_dict()
	if not p11_sd.has("trace") or p11_sd["trace"] != 3:
		printerr("FAIL 11-A: to_save_dict missing/wrong trace! Got: ", p11_sd.get("trace", "MISSING"))
		get_tree().quit(1)
		return
	GameState.add_trace(100)
	GameState.load_save_dict(p11_sd)
	if GameState.get_trace() != 3:
		printerr("FAIL 11-A: load_save_dict did not restore trace! Got: ", GameState.get_trace())
		get_tree().quit(1)
		return

	# 11-A：向後相容——舊存檔無 trace 鍵時應回 0
	var p11_legacy = GameState.to_save_dict()
	p11_legacy.erase("trace")
	GameState.load_save_dict(p11_legacy)
	if GameState.get_trace() != 0:
		printerr("FAIL 11-A: load_save_dict without 'trace' key should default trace to 0!")
		get_tree().quit(1)
		return

	# 11-A：reset 歸零
	GameState.add_trace(9)
	GameState.reset_for_new_game()
	if GameState.get_trace() != 0:
		printerr("FAIL 11-A: reset_for_new_game did not zero trace!")
		get_tree().quit(1)
		return

	# 11-B：Trust adapter 接 affinity_<target>
	GameState.add_int("affinity_wan", 4)
	if GameState.get_trust("wan") != 4:
		printerr("FAIL 11-B: get_trust('wan') should equal affinity_wan! Got: ", GameState.get_trust("wan"))
		get_tree().quit(1)
		return
	if GameState.get_trust("wan") != int(GameState.get_flag("affinity_wan", 0)):
		printerr("FAIL 11-B: get_trust must mirror affinity flag!")
		get_tree().quit(1)
		return
	if GameState.get_trust("nobody") != 0:
		printerr("FAIL 11-B: get_trust for unknown target should default to 0!")
		get_tree().quit(1)
		return

	# 11-C：賣殘響 → Trace↓（集中在 sell_echo）
	GameState.reset_for_new_game()
	GameState.record_full_echo("echo_room401_tenant")
	if not GameState.is_echo_complete("echo_room401_tenant"):
		printerr("FAIL 11-C setup: echo_room401_tenant should be complete after record_full_echo!")
		get_tree().quit(1)
		return
	var p11_trace_before = GameState.get_trace()
	if not GameState.sell_echo("echo_room401_tenant"):
		printerr("FAIL 11-C: sell_echo should succeed on completed unsold echo!")
		get_tree().quit(1)
		return
	if GameState.get_trace() >= p11_trace_before:
		printerr("FAIL 11-C: selling an echo must lower trace! before=", p11_trace_before, " after=", GameState.get_trace())
		get_tree().quit(1)
		return

	# 11-C：通用 add_trace 對話 effect op（未來「留」↑ /「還」用）
	GameState.reset_for_new_game()
	var p11_runner := DialogueRunner.new()
	var p11_tree := {
		"start": {
			"speaker": "test",
			"text": "trace effect node",
			"effect": [{ "op": "add_trace", "value": 7 }]
		}
	}
	p11_runner.start(p11_tree)
	if GameState.get_trace() != 7:
		printerr("FAIL 11-C: add_trace dialogue effect op did not apply! Got: ", GameState.get_trace())
		get_tree().quit(1)
		return
	p11_runner = null

	# 收尾：還原乾淨狀態
	GameState.reset_for_new_game()
	print("PASS: Phase 11 Trust/Trace foundation verified (trace axis + trust adapter + sell/effect hooks).")

	# ============================================================

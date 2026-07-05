extends "res://tests/manual/phases/phase_5b.gd"

func _run_phase_5a() -> void:
	# 13. Verify GameState Story Flags API & DialogueRunner Pure Logic (Phase 5-A)
	print("Verifying GameState Story Flags APIs...")
	GameState.story_flags.clear()
	GameState.set_flag("test_flag_bool", true)
	if not GameState.has_flag("test_flag_bool") or GameState.get_flag("test_flag_bool") != true:
		printerr("FAIL: GameState set_flag / get_flag for boolean failed!")
		get_tree().quit(1)
		return

	GameState.add_int("test_flag_int", 5)
	if GameState.get_flag("test_flag_int") != 5:
		printerr("FAIL: GameState add_int failed!")
		get_tree().quit(1)
		return

	GameState.add_int("test_flag_int", -2)
	if GameState.get_flag("test_flag_int") != 3:
		printerr("FAIL: GameState add_int delta accumulation failed!")
		get_tree().quit(1)
		return

	if not GameState.has_flag("test_flag_int"):
		printerr("FAIL: GameState has_flag for non-zero int failed!")
		get_tree().quit(1)
		return

	GameState.set_flag("test_flag_int", 0)
	if GameState.has_flag("test_flag_int"):
		printerr("FAIL: GameState has_flag for zero int should be false!")
		get_tree().quit(1)
		return

	print("PASS: GameState Story Flags APIs verified.")

	print("Verifying DialogueDB lookup...")
	DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	wan_tree = DialogueDB.get_tree_for("wan")
	if wan_tree.is_empty() or not wan_tree.has("start"):
		printerr("FAIL: DialogueDB could not fetch wan tree!")
		get_tree().quit(1)
		return
	print("PASS: DialogueDB lookup verified.")

	print("Verifying DialogueRunner flow simulation (First Meet)...")
	runner = DialogueRunner.new()
	GameState.story_flags.clear()
	runner.start(wan_tree)

	var curr = runner.current()
	if tr(curr.get("speaker")) != "晚" or not tr(curr.get("text")).contains("新面孔"):
		printerr("FAIL: DialogueRunner start should route to first_meet! Got text: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	var choices = curr.get("choices")
	if choices.size() != 3:
		printerr("FAIL: first_meet should have 3 choices, got: ", choices.size())
		get_tree().quit(1)
		return

	# Choose option 1: "妳是誰？" -> who
	var idx_who = -1
	for choice in choices:
		if tr(choice.get("label")).contains("誰"):
			idx_who = choice.get("index")
			break
	if idx_who != 1:
		printerr("FAIL: who choice index should be 1, got: ", idx_who)
		get_tree().quit(1)
		return

	runner.choose(idx_who)
	curr = runner.current()
	if not tr(curr.get("text")).contains("名字？"):
		printerr("FAIL: should go to 'who' node! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	if not GameState.has_flag("knows_wan_name"):
		printerr("FAIL: knows_wan_name flag was not set upon entering 'who' node!")
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if not tr(curr.get("text")).contains("那塊招牌"):
		printerr("FAIL: should advance to 'watch' node! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	choices = curr.get("choices")
	if choices.size() != 2:
		printerr("FAIL: watch node should have 2 choices, got: ", choices.size())
		get_tree().quit(1)
		return

	# Choose option 0: "我也撿這種東西。" -> kin
	var idx_kin = -1
	for choice in choices:
		if tr(choice.get("label")).contains("撿"):
			idx_kin = choice.get("index")
			break
	if idx_kin != 0:
		printerr("FAIL: kin choice index should be 0, got: ", idx_kin)
		get_tree().quit(1)
		return

	runner.choose(idx_kin)
	curr = runner.current()
	if not tr(curr.get("text")).contains("同類"):
		printerr("FAIL: should go to 'kin' node! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	if GameState.get_flag("affinity_wan") != 1 or not GameState.get_flag("met_wan"):
		printerr("FAIL: kin effects not applied correctly!")
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if not tr(curr.get("text")).contains("有意思的"):
		printerr("FAIL: should advance to 'end_warm' node! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	if not curr.get("is_terminal"):
		printerr("FAIL: end_warm should be a terminal node!")
		get_tree().quit(1)
		return

	var finished_signal_status = {"emitted": false}
	runner.finished.connect(func(): finished_signal_status["emitted"] = true)
	runner.advance()
	if not finished_signal_status["emitted"]:
		printerr("FAIL: DialogueRunner should emit finished on terminal node advance!")
		get_tree().quit(1)
		return

	print("PASS: DialogueRunner flow simulation (First Meet) verified.")

	print("Verifying DialogueRunner flow simulation (Retalk & Intel Gate Locked)...")
	# met_wan is true, affinity_wan is 1
	runner.start(wan_tree)
	curr = runner.current()
	if not tr(curr.get("text")).contains("又是你"):
		printerr("FAIL: start should route to retalk since met_wan is true! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	choices = curr.get("choices")
	var idx_news = -1
	for choice in choices:
		if tr(choice.get("label")).contains("消息"):
			idx_news = choice.get("index")
			break
	if idx_news != 1:
		printerr("FAIL: news choice index should be 1, got: ", idx_news)
		get_tree().quit(1)
		return

	runner.choose(idx_news)
	curr = runner.current()
	if not tr(curr.get("text")).contains("我又不是 AI 客服"):
		printerr("FAIL: should route to intel_locked since affinity_wan < 2! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	if GameState.get_flag("affinity_wan") != 2:
		printerr("FAIL: intel_locked effect affinity_wan += 1 failed!")
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if not tr(curr.get("text")).contains("死掉的招牌"):
		printerr("FAIL: should advance to 'end_cold'! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return
	if not curr.get("is_terminal"):
		printerr("FAIL: end_cold should be terminal!")
		get_tree().quit(1)
		return

	print("PASS: DialogueRunner flow simulation (Retalk & Intel Gate Locked) verified.")

	print("Verifying DialogueRunner flow simulation (Retalk & Intel Gate Unlocked)...")
	# met_wan is true, affinity_wan is now 2
	runner.start(wan_tree)
	curr = runner.current()
	choices = curr.get("choices")

	runner.choose(idx_news)
	curr = runner.current()
	if not tr(curr.get("text")).contains("想聽好料"):
		printerr("FAIL: should route to intel since affinity_wan >= 2! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	# start_quest should trigger, check quest status
	if QuestManager.get_status("alley_backrooms_3f") != "active":
		printerr("FAIL: start_quest effect failed to start 'alley_backrooms_3f' quest!")
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if not tr(curr.get("text")).contains("有意思的"):
		printerr("FAIL: should advance to 'end_warm'! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return


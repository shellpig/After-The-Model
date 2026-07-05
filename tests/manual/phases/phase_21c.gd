extends "res://tests/manual/phases/phase_21d.gd"

func _run_phase_21c() -> void:
	# ===================== Phase 21-C: 收束碎片「黑戶藏身方式」 =====================
	print("--- Phase 21-C: 收束碎片「黑戶藏身方式」 ---")

	# 1. 驗證節點存在與屬性
	var back_inst_21c = load("res://scenes/levels/nightclub/nightclub_back.tscn").instantiate()
	var mem_area_21c = back_inst_21c.find_child("MemoryFragmentArea", true, false)
	if mem_area_21c == null:
		printerr("FAIL 21-C: MemoryFragmentArea node not found in nightclub_back.tscn!")
		get_tree().quit(1)
		return

	if mem_area_21c.fragment_flag != "mem_frag_hideout" or mem_area_21c.message_id != "mem_frag_hideout" or mem_area_21c.require_flag != "echo_linfei":
		printerr("FAIL 21-C: MemoryFragmentArea attributes incorrect!")
		get_tree().quit(1)
		return

	# 2. 驗證 STORY_MESSAGES 鍵存在且翻譯合規（不含禁字「林霏」）
	if not GameState.STORY_MESSAGES.has("mem_frag_hideout"):
		printerr("FAIL 21-C: STORY_MESSAGES missing 'mem_frag_hideout'!")
		get_tree().quit(1)
		return

	var forbidden_check_21c = "林霏"
	for lang in ["zh_TW", "zh_CN", "en"]:
		LocaleManager.set_locale(lang)
		var tr_text = tr("MSG_MEM_FRAG_HIDEOUT")
		if tr_text == "MSG_MEM_FRAG_HIDEOUT":
			printerr("FAIL 21-C: MSG_MEM_FRAG_HIDEOUT translation missing for lang: ", lang)
			get_tree().quit(1)
			return
		if forbidden_check_21c in tr_text:
			printerr("FAIL 21-C: STORY_MESSAGES for 'mem_frag_hideout' contains forbidden word '林霏' for lang: ", lang)
			get_tree().quit(1)
			return
	LocaleManager.set_locale("zh_TW")

	# 3. 模擬觸發：未滿 6 段殘響時進區，旗標不應該被設為 true
	GameState.reset_for_new_game()
	# 採集 5 段
	for i in range(1, 6):
		GameState.collect_echo_segment("echo_linfei", "s%d" % i)

	# 模擬 player body entered 訊號
	var player_node_21c = back_inst_21c.find_child("Player", true, false)
	mem_area_21c._on_body_entered(player_node_21c)
	if GameState.get_flag("mem_frag_hideout", false):
		printerr("FAIL 21-C: mem_frag_hideout triggered before linfei echo is complete!")
		get_tree().quit(1)
		return

	# 4. 模擬觸發：滿 6 段殘響後進區，成功觸發，設 flag
	# 採集第 6 段以集滿
	GameState.collect_echo_segment("echo_linfei", "s6")

	# 接聽事件以確定有發出 interaction_requested 訊號
	var interaction_received_21c = {"message_text": ""}
	back_inst_21c.interaction_requested.connect(func(data):
		interaction_received_21c["message_text"] = data.get("message_text", "")
	)

	mem_area_21c._on_body_entered(player_node_21c)
	if not GameState.get_flag("mem_frag_hideout", false):
		printerr("FAIL 21-C: mem_frag_hideout not triggered after linfei echo complete!")
		get_tree().quit(1)
		return

	if interaction_received_21c["message_text"] == "":
		printerr("FAIL 21-C: interaction_requested signal not correctly emitted on trigger!")
		get_tree().quit(1)
		return

	# 5. 二次進區不重觸
	interaction_received_21c["message_text"] = ""
	mem_area_21c._on_body_entered(player_node_21c)
	if interaction_received_21c["message_text"] != "":
		printerr("FAIL 21-C: MemoryFragmentArea triggered repeatedly!")
		get_tree().quit(1)
		return

	# 6. 存讀檔 persistence round-trip
	var save_data_21c = SaveSystem.capture("nightclub_back", 800.0)
	GameState.reset_for_new_game()
	if GameState.get_flag("mem_frag_hideout", false):
		printerr("FAIL 21-C: mem_frag_hideout flag not reset on new game!")
		get_tree().quit(1)
		return

	SaveSystem.apply(save_data_21c)
	if not GameState.get_flag("mem_frag_hideout", false):
		printerr("FAIL 21-C: mem_frag_hideout flag not restored after load!")
		get_tree().quit(1)
		return

	back_inst_21c.free()
	print("PASS: Phase 21-C linfei memory fragment hideout verified.")


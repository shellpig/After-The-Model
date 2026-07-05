extends "res://tests/manual/phases/phase_7c.gd"

func _run_phase_7a() -> void:
	# 18. Verify Phase 7-A QuestManager & QuestState
	print("Verifying Phase 7-A QuestManager & QuestState...")

	# Reset state first
	GameState.reset_for_new_game()

	# Verify initial state
	if QuestManager.get_status("alley_backrooms_3f") != "":
		printerr("FAIL: Initial quest status should be empty string!")
		get_tree().quit(1)
		return
	if QuestManager.get_step("alley_backrooms_3f") != "":
		printerr("FAIL: Initial quest step should be empty string!")
		get_tree().quit(1)
		return

	# Start quest
	var start_ok = QuestManager.start("alley_backrooms_3f")
	if not start_ok:
		printerr("FAIL: Failed to start quest 'alley_backrooms_3f'!")
		get_tree().quit(1)
		return
	if not GameState.has_active_quest("alley_backrooms_3f"):
		printerr("FAIL: GameState has_active_quest returned false after start!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "active":
		printerr("FAIL: Quest status is not 'active' after start!")
		get_tree().quit(1)
		return
	if QuestManager.get_step("alley_backrooms_3f") != "started":
		printerr("FAIL: Quest step is not 'started' after start!")
		get_tree().quit(1)
		return

	# Verify note sync
	var notes_started = GameState.get_notes("工作")
	if notes_started.size() != 1:
		printerr("FAIL: Work notes count is not 1! Got: ", notes_started.size())
		get_tree().quit(1)
		return
	var work_note = notes_started[0]
	if work_note.get("id") != "quest_alley_backrooms_3f":
		printerr("FAIL: Work note id is wrong! Got: ", work_note.get("id"))
		get_tree().quit(1)
		return
	if not "「晚」提到暗巷三樓" in _tr_body(work_note.get("body", "")):
		printerr("FAIL: Work note body for started state is wrong! Got: ", _tr_body(work_note.get("body")))
		get_tree().quit(1)
		return
	print("PASS: Quest start and initial note sync verified.")

	# Advance quest
	var adv_ok = QuestManager.advance("alley_backrooms_3f", "checked_alley", {"checked": true})
	if not adv_ok:
		printerr("FAIL: Failed to advance quest 'alley_backrooms_3f' to 'checked_alley'!")
		get_tree().quit(1)
		return
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step is not 'checked_alley' after advance!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("alley_backrooms_3f", "checked"):
		printerr("FAIL: Quest flag 'checked' was not set!")
		get_tree().quit(1)
		return

	# Verify advanced note body
	var notes_checked = GameState.get_notes("工作")
	if notes_checked.size() != 1:
		printerr("FAIL: Work notes count after advance is not 1!")
		get_tree().quit(1)
		return
	if not "去後巷看過了" in _tr_body(notes_checked[0].get("body", "")):
		printerr("FAIL: Work note body for checked_alley state is wrong! Got: ", _tr_body(notes_checked[0].get("body")))
		get_tree().quit(1)
		return
	print("PASS: Quest advance and note updating verified.")

	# Verify invalid step transition
	var adv_invalid = QuestManager.advance("alley_backrooms_3f", "nonexistent_step")
	if adv_invalid:
		printerr("FAIL: Advancing to nonexistent step should fail!")
		get_tree().quit(1)
		return
	print("PASS: Invalid quest step transition correctly blocked.")

	# Verify Quest states are NOT stored in GameState.knowledge (should remain empty)
	if GameState.knowledge.has("quest_alley_backrooms_3f"):
		printerr("FAIL: Quest notes must not be stored in GameState.knowledge!")
		get_tree().quit(1)
		return
	print("PASS: Quest status is not saved in knowledge database.")

	# Complete quest
	var complete_ok = QuestManager.complete("alley_backrooms_3f")
	if not complete_ok:
		printerr("FAIL: Failed to complete quest!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status is not 'completed' after complete()!")
		get_tree().quit(1)
		return
	var notes_completed = GameState.get_notes("工作")
	if notes_completed[0].get("status") != "completed":
		printerr("FAIL: Work note status was not updated to completed!")
		get_tree().quit(1)
		return
	if not "已將「早期" in _tr_body(notes_completed[0].get("body", "")):
		printerr("FAIL: Work note body for completed status is wrong! Got: ", _tr_body(notes_completed[0].get("body")))
		get_tree().quit(1)
		return
	print("PASS: Quest completion and note status update verified.")

	# Verify Save/Load Serialization of quest_states
	var save_dict = GameState.to_save_dict()
	if not save_dict.has("quest_states"):
		printerr("FAIL: Save dictionary is missing 'quest_states' key!")
		get_tree().quit(1)
		return
	var saved_quest_state = save_dict["quest_states"].get("alley_backrooms_3f", {})
	if saved_quest_state.get("status") != "completed":
		printerr("FAIL: Saved quest status is wrong! Got: ", saved_quest_state.get("status"))
		get_tree().quit(1)
		return

	# Reset state and restore from save dict
	GameState.reset_for_new_game()
	if QuestManager.get_status("alley_backrooms_3f") != "":
		printerr("FAIL: Quest states not cleared after reset_for_new_game!")
		get_tree().quit(1)
		return

	GameState.load_save_dict(save_dict)
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest states not restored correctly from load_save_dict!")
		get_tree().quit(1)
		return
	print("PASS: Quest states serialization and restoration verified.")


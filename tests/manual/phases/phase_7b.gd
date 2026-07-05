extends "res://tests/manual/phases/phase_7a.gd"

func _run_phase_7b() -> void:
	# Additional Phase 7-B Verification: test new dialogue tree conditions (quest_status, quest_step, has_item)
	print("Verifying Phase 7-B Condition Evaluation...")
	# 1. Test condition: type = quest_status, op = ==, value = active
	var test_cond_active = {"type": "quest_status", "quest_id": "alley_backrooms_3f", "op": "==", "value": "active"}
	if not runner._eval_condition(test_cond_active):
		printerr("FAIL: Condition quest_status=active should evaluate to true!")
		get_tree().quit(1)
		return

	# 2. Test condition: type = quest_step, op = ==, value = checked_alley (not reached yet)
	var test_cond_checked = {"type": "quest_step", "quest_id": "alley_backrooms_3f", "op": "==", "value": "checked_alley"}
	if runner._eval_condition(test_cond_checked):
		printerr("FAIL: Condition quest_step=checked_alley should evaluate to false!")
		get_tree().quit(1)
		return

	# 3. Test condition: type = has_item, item_id = canned_food, op = ==, value = true (not owned yet)
	var test_cond_item = {"type": "has_item", "item_id": "canned_food", "op": "==", "value": true}
	if runner._eval_condition(test_cond_item):
		printerr("FAIL: Condition has_item=true should evaluate to false when item is not owned!")
		get_tree().quit(1)
		return

	# Add item and verify has_item condition
	GameState.add_item("canned_food", 1)
	if not runner._eval_condition(test_cond_item):
		printerr("FAIL: Condition has_item=true should evaluate to true after adding item!")
		get_tree().quit(1)
		return

	# Clean up item
	GameState.remove_item("canned_food", 1)

	# 4. Test condition array (AND evaluation)
	var test_cond_arr = [
		{"type": "quest_status", "quest_id": "alley_backrooms_3f", "op": "==", "value": "active"},
		{"type": "quest_step", "quest_id": "alley_backrooms_3f", "op": "==", "value": "started"}
	]
	if not runner._eval_condition(test_cond_arr):
		printerr("FAIL: Condition array AND evaluation failed!")
		get_tree().quit(1)
		return

	# Verify retalk with active quest routes to intel_already_given
	runner.start(wan_tree)
	var curr = runner.current()
	var idx_news_retalk = -1
	for ch in curr.get("choices"):
		if tr(ch.get("label")) == "有新消息嗎？":
			idx_news_retalk = ch.get("index")
			break

	runner.choose(idx_news_retalk)
	curr = runner.current()
	if not tr(curr.get("text")).contains("不是跟你說過了"):
		printerr("FAIL: retalk news with active quest should route to 'intel_already_given'! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return
	print("PASS: retalk news with active quest routing verified.")

	print("PASS: DialogueRunner flow simulation (Retalk & Intel Gate Unlocked) verified.")


extends "res://tests/manual/phases/phase_13ab.gd"

func _run_phase_12c() -> void:
	# ===================== Phase 12-C: BtnJump 觸控按鈕 =====================
	print("--- Phase 12-C: TouchControls BtnJump ---")

	var btn_jump_node = TouchControls.get_node_or_null("Control/Actions/BtnJump")
	if not btn_jump_node:
		printerr("FAIL: BtnJump not found at Control/Actions/BtnJump in TouchControls!")
		get_tree().quit(1)
		return
	if not btn_jump_node is Button:
		printerr("FAIL: BtnJump is not a Button!")
		get_tree().quit(1)
		return

	# BtnJump should have button_down connections (set by _bind_button)
	if btn_jump_node.button_down.get_connections().is_empty():
		printerr("FAIL: BtnJump has no button_down connections (not bound to jump action)!")
		get_tree().quit(1)
		return

	# BtnJump 世界模式可見
	UIMode.set_mode(UIMode.Mode.NONE)
	TouchControls.touch_buttons_enabled = true
	TouchControls._update_dynamic_button_visibility()
	if not btn_jump_node.visible:
		printerr("FAIL: BtnJump should be visible in UIMode.NONE!")
		get_tree().quit(1)
		return

	# BtnJump 面板模式隱藏
	for panel_mode in [UIMode.Mode.INVENTORY, UIMode.Mode.DIALOGUE, UIMode.Mode.SHOP]:
		UIMode.set_mode(panel_mode)
		TouchControls._update_dynamic_button_visibility()
		if btn_jump_node.visible:
			printerr("FAIL: BtnJump should be hidden in mode ", panel_mode)
			get_tree().quit(1)
			return

	# 恢復 NONE
	UIMode.set_mode(UIMode.Mode.NONE)
	TouchControls.touch_buttons_enabled = false
	TouchControls._update_dynamic_button_visibility()

	print("PASS: Phase 12-C BtnJump exists, bound, visible in NONE, hidden in panels.")


extends "res://tests/manual/phases/phase_14a.gd"

func _run_phase_13f() -> void:
	# ===================== Phase 13-F: BtnAttack 觸控按鈕 =====================
	print("--- Phase 13-F: TouchControls BtnAttack ---")

	var btn_attack_node = TouchControls.get_node_or_null("Control/Actions/BtnAttack")
	if not btn_attack_node:
		printerr("FAIL: BtnAttack not found at Control/Actions/BtnAttack in TouchControls!")
		get_tree().quit(1)
		return
	if not btn_attack_node is Button:
		printerr("FAIL: BtnAttack is not a Button!")
		get_tree().quit(1)
		return

	# BtnAttack should have button_down connections (set by _bind_button)
	if btn_attack_node.button_down.get_connections().is_empty():
		printerr("FAIL: BtnAttack has no button_down connections (not bound to attack action)!")
		get_tree().quit(1)
		return

	# BtnAttack 世界模式可見
	UIMode.set_mode(UIMode.Mode.NONE)
	TouchControls.touch_buttons_enabled = true
	TouchControls._update_dynamic_button_visibility()
	if not btn_attack_node.visible:
		printerr("FAIL: BtnAttack should be visible in UIMode.NONE!")
		get_tree().quit(1)
		return

	# BtnAttack 面板模式隱藏
	for panel_mode in [UIMode.Mode.INVENTORY, UIMode.Mode.DIALOGUE, UIMode.Mode.SHOP]:
		UIMode.set_mode(panel_mode)
		TouchControls._update_dynamic_button_visibility()
		if btn_attack_node.visible:
			printerr("FAIL: BtnAttack should be hidden in mode ", panel_mode)
			get_tree().quit(1)
			return

	# 恢復 NONE
	UIMode.set_mode(UIMode.Mode.NONE)
	TouchControls.touch_buttons_enabled = false
	TouchControls._update_dynamic_button_visibility()

	print("PASS: Phase 13-F BtnAttack exists, bound, visible in NONE, hidden in panels.")


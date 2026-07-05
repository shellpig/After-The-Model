extends "res://tests/manual/phases/phase_4a.gd"

func _run_phase_3c() -> void:
	# 9. Verify TouchControls Autoload & Platform Detection (Phase 3-C)
	print("Verifying TouchControls Autoload & Platform Detection...")
	var touch_controls = get_node_or_null("/root/TouchControls")
	if not touch_controls:
		printerr("FAIL: TouchControls autoload not found at /root/TouchControls!")
		get_tree().quit(1)
		return

	# Since this test runs on Windows (PC), is_pc_platform must be true
	if not touch_controls.is_pc_platform:
		printerr("FAIL: TouchControls.is_pc_platform should be true on Windows PC!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls.is_pc_platform is true on Windows PC.")

	# On PC, touch buttons should be disabled by default
	if touch_controls.touch_buttons_enabled:
		printerr("FAIL: TouchControls.touch_buttons_enabled should be false by default on PC!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls.touch_buttons_enabled is false by default on PC.")

	# On PC, BtnToggle should be visible by default in NONE mode
	ui_instance.set_monologue_active(false)
	UIMode.set_mode(UIMode.Mode.NONE)
	touch_controls._update_dynamic_button_visibility()
	var btn_toggle = touch_controls.get_node_or_null("Control/BtnToggle")
	if not btn_toggle:
		printerr("FAIL: Control/BtnToggle node not found in TouchControls!")
		get_tree().quit(1)
		return
	if not btn_toggle.visible:
		printerr("FAIL: BtnToggle should be visible by default on PC in world mode!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls BtnToggle visibility and default state verified.")

	# 9.1 Verify TouchControls Safe Area Dynamic Fitting
	print("Verifying TouchControls Safe Area dynamic adaptation...")
	var control_node = touch_controls.get_node_or_null("Control")
	if not control_node:
		printerr("FAIL: TouchControls/Control node not found!")
		get_tree().quit(1)
		return

	# Since this test runs on Windows (PC), offsets must be strictly 0
	if control_node.offset_left != 0 or control_node.offset_top != 0 or control_node.offset_right != 0 or control_node.offset_bottom != 0:
		printerr("FAIL: TouchControls/Control offsets must be strictly 0 on PC desktop platform!")
		printerr("Actual offsets: Left=%d, Top=%d, Right=%d, Bottom=%d" % [control_node.offset_left, control_node.offset_top, control_node.offset_right, control_node.offset_bottom])
		get_tree().quit(1)
		return
	print("PASS: TouchControls Safe Area dynamic offsets validated (strictly 0 on PC desktop).")


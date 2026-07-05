extends "res://tests/manual/phases/phase_7b.gd"

func _run_phase_6de() -> void:
	# 17. Verify Phase 6-D & 6-E GUI components (TitleScreen & PauseMenu)
	print("Verifying Phase 6-D & 6-E Title Screen, Pause Menu, & Save/Load UI...")

	# Verify TitleScreen Isolation
	var title_scene = load("res://scenes/ui/title_screen.tscn")
	if not title_scene:
		printerr("FAIL: Could not load title_screen.tscn!")
		get_tree().quit(1)
		return

	var title_instance = title_scene.instantiate()
	main_instance.add_child(title_instance)
	if not TouchControls.force_hidden:
		printerr("FAIL: Title Screen did not trigger TouchControls force_hidden = true!")
		get_tree().quit(1)
		return
	print("PASS: Title Screen TouchControls isolation verified.")

	title_instance.queue_free()
	TouchControls.set_force_hidden(false)

	# Verify PauseMenu integration inside GameUI
	var game_ui = main_instance.get_node("GameUI")
	var pause_menu = game_ui.get_node("PauseMenu")
	if not pause_menu:
		printerr("FAIL: PauseMenu not found under GameUI!")
		get_tree().quit(1)
		return

	# Trigger pause menu
	UIMode.set_mode(UIMode.Mode.NONE)
	game_ui.open_pause_menu()
	if UIMode.get_mode() != UIMode.Mode.PAUSE:
		printerr("FAIL: open_pause_menu() did not switch UIMode to PAUSE!")
		get_tree().quit(1)
		return
	if not pause_menu.visible:
		printerr("FAIL: PauseMenu node was not made visible in PAUSE mode!")
		get_tree().quit(1)
		return
	print("PASS: PauseMenu opening and UIMode.PAUSE verified.")

	# Check TouchControls visibility in PAUSE mode
	TouchControls.touch_buttons_enabled = true
	TouchControls._update_dynamic_button_visibility()
	if not TouchControls.get_node("Control/DPad").visible:
		printerr("FAIL: DPad should be visible in PAUSE mode for UI focus navigation!")
		get_tree().quit(1)
		return
	if TouchControls.get_node("Control/Actions").visible or TouchControls.get_node("Control/Menus").visible:
		printerr("FAIL: Actions/Menus should be hidden in PAUSE mode!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls visibility in PAUSE mode verified.")

	# Reset touch_buttons_enabled
	TouchControls.touch_buttons_enabled = false

	# Test Resume option
	pause_menu._on_resume_pressed()
	if UIMode.get_mode() != UIMode.Mode.NONE or pause_menu.visible:
		printerr("FAIL: Resume did not exit PAUSE mode or hide PauseMenu!")
		get_tree().quit(1)
		return
	print("PASS: PauseMenu Resume verified.")

	# Test Slot List rendering inside PauseMenu
	game_ui.open_pause_menu()
	pause_menu._on_save_pressed()
	var slot_list = pause_menu.get_node("SaveSlotList")
	if not slot_list or not slot_list.visible:
		printerr("FAIL: SaveSlotList was not displayed after clicking Save!")
		get_tree().quit(1)
		return

	# Verify list slot contents (7 buttons populated)
	var slots = slot_list.get_node("Panel/VBoxContainer/SlotsVBox")
	var buttons_count := 0
	for child in slots.get_children():
		if child is Button:
			buttons_count += 1
	if buttons_count != 7:
		printerr("FAIL: SaveSlotList did not contain exactly 7 slots! Got: ", buttons_count)
		get_tree().quit(1)
		return

	# Verify slot 1 text is populated (we saved to it in 6-A/6-B)
	var slot1_btn = slots.get_child(0) as Button
	if "空白" in slot1_btn.text or slot1_btn.text.is_empty():
		printerr("FAIL: Slot 1 should display active save metadata, got text: ", slot1_btn.text)
		get_tree().quit(1)
		return
	print("PASS: SaveSlotList metadata population verified.")

	# Verify ConfirmDialog Overwrite & Title Return behavior (Guard against Button restore crashes & UIMode exit issues)
	var confirm_dialog = game_ui.get_node("ConfirmDialog")
	if not confirm_dialog:
		printerr("FAIL: ConfirmDialog not found inside GameUI!")
		get_tree().quit(1)
		return

	# 1. Overwrite confirm simulation (triggers ConfirmDialog, restores to Slot Button)
	slot_list._on_slot_button_pressed(1) # Slot 1 is active, should trigger overwrite warning
	if UIMode.get_mode() != UIMode.Mode.CONFIRM or not confirm_dialog.visible:
		printerr("FAIL: Overwriting active slot did not open ConfirmDialog!")
		get_tree().quit(1)
		return

	# Simulate Cancel: close_dialog should restore state to PAUSE without crashing on Button restore
	confirm_dialog.close_dialog()
	if UIMode.get_mode() != UIMode.Mode.PAUSE or confirm_dialog.visible:
		printerr("FAIL: Cancel overwrite did not return UIMode to PAUSE!")
		get_tree().quit(1)
		return
	print("PASS: Overwrite confirmation Cancel & UIMode restore verified.")

	# Simulate Confirm: confirm execution should perform save and return back to PAUSE (single exit_confirm)
	slot_list._on_slot_button_pressed(1)
	if confirm_dialog._on_confirm.is_valid():
		confirm_dialog._on_confirm.call()
	confirm_dialog.close_dialog()
	if UIMode.get_mode() != UIMode.Mode.PAUSE:
		printerr("FAIL: Confirming overwrite did not return UIMode back to PAUSE (got mode: ", UIMode.get_mode(), ")")
		get_tree().quit(1)
		return
	print("PASS: Overwrite confirmation Confirm & single exit_confirm verified.")

	# 2. Return to Title confirmation simulation (triggers ConfirmDialog, restores to btn_title)
	pause_menu._on_title_pressed()
	if UIMode.get_mode() != UIMode.Mode.CONFIRM or not confirm_dialog.visible:
		printerr("FAIL: Clicking Return to Title did not show ConfirmDialog!")
		get_tree().quit(1)
		return

	# Simulate Cancel: should return to PAUSE
	confirm_dialog.close_dialog()
	if UIMode.get_mode() != UIMode.Mode.PAUSE or confirm_dialog.visible:
		printerr("FAIL: Cancelling Title return did not restore UIMode to PAUSE!")
		get_tree().quit(1)
		return
	print("PASS: Title return confirmation Cancel & UIMode restore verified.")

	# Close pause menu
	UIMode.set_mode(UIMode.Mode.NONE)


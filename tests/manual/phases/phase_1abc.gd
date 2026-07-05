extends "res://tests/manual/phases/phase_2.gd"

func _run_phase_1abc() -> void:
	# 1. Verify Autoload Configuration
	print("Checking UIMode autoload...")
	var autoload_exists = ProjectSettings.has_setting("autoload/UIMode")
	if not autoload_exists:
		printerr("FAIL: UIMode not found in ProjectSettings autoload!")
		get_tree().quit(1)
		return
	print("PASS: UIMode registered in autoload.")

	# 2. Verify InputMap Actions
	print("Checking InputMap actions...")
	var actions = ["open_inventory", "open_notebook", "ui_cancel",
	               "ui_page_up", "ui_page_down",
	               "move_left", "move_right", "move_up", "move_down"]
	for action in actions:
		if not InputMap.has_action(action):
			printerr("FAIL: InputMap action '" + action + "' is missing!")
			get_tree().quit(1)
			return
		print("PASS: InputMap action '" + action + "' exists.")


	# 3. Load & Instantiate apartment_room.tscn
	print("Loading res://scenes/levels/apartment/apartment_room.tscn...")
	room_scene = load("res://scenes/levels/apartment/apartment_room.tscn")
	if not room_scene:
		printerr("FAIL: Could not load apartment_room.tscn!")
		get_tree().quit(1)
		return
	print("PASS: apartment_room.tscn loaded successfully.")

	room_instance = room_scene.instantiate()

	# Instantiate GameUI so that apartment_room.gd can retrieve its UI references
	ui_scene = load("res://scenes/ui/game_ui.tscn")
	ui_instance = ui_scene.instantiate()
	add_child(ui_instance)
	print("PASS: game_ui.tscn instantiated in scene tree.")

	add_child(room_instance)
	print("PASS: apartment_room.tscn instantiated in scene tree.")

	# 4. Verify Relative Node Paths
	print("Verifying UI node structures inside GameUI...")
	var ui_nodes = {
		"UIOverlay": "UIOverlay",
		"NotebookPanel": "NotebookPanel",
		"DualPaneContainer": "DualPaneContainer",
		"InventoryPanel": "InventoryPanel",
		"BagGrid": "InventoryPanel/VBoxContainer/BagGrid",
		"CreditsLabel": "InventoryPanel/VBoxContainer/HBoxContainer/CreditsLabel",
		"PanelFooterHint": "InventoryPanel/VBoxContainer/PanelFooterHint",
		"ItemDetailModal": "ItemDetailModal",
		"ConfirmDialog": "ConfirmDialog"
	}

	for node_name in ui_nodes:
		var path: String = ui_nodes[node_name]
		var node = ui_instance.get_node_or_null(path)
		if not node:
			printerr("FAIL: UI node '" + node_name + "' not found at path: " + path)
			get_tree().quit(1)
			return
		print("PASS: Node '" + node_name + "' exists at '" + path + "'.")

		# Extra properties verification
		if node_name == "UIOverlay":
			var overlay = node as ColorRect
			if overlay.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				printerr("FAIL: UIOverlay mouse_filter is not MOUSE_FILTER_IGNORE!")
				get_tree().quit(1)
				return
			print("PASS: UIOverlay mouse_filter set to IGNORE.")
		elif node_name == "NotebookPanel":
			var panel = node as Control
			if panel.custom_minimum_size != Vector2(880, 560):
				printerr("FAIL: NotebookPanel custom_minimum_size is not 880x560! Got: ", panel.custom_minimum_size)
				get_tree().quit(1)
				return
			print("PASS: NotebookPanel custom minimum size is 880x560.")
		elif node_name == "InventoryPanel":
			var panel = node as PanelContainer
			if panel.custom_minimum_size != Vector2(368, 256):
				printerr("FAIL: InventoryPanel custom_minimum_size is not 368x256! Got: ", panel.custom_minimum_size)
				get_tree().quit(1)
				return
			print("PASS: InventoryPanel custom minimum size is 368x256.")

	# 4b. Verify Story Preloads (Relaxed Contains Checks)
	print("Verifying preloaded story notes (relaxed)...")
	var categories_to_check = {
		"身份": "identity_apartment_is_mine",
		"線索": "clue_door_sensor_scratch"
	}
	for cat in categories_to_check:
		var expected_id: String = categories_to_check[cat]
		var notes = GameState.get_notes(cat)
		var found = false
		for note in notes:
			if note.get("id") == expected_id:
				found = true
				break
		if not found:
			printerr("FAIL: Story note with ID '" + expected_id + "' was not preloaded in category '" + cat + "'!")
			get_tree().quit(1)
			return
		print("PASS: Story note '" + expected_id + "' preloaded.")


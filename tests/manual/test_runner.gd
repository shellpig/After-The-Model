extends Node

func _ready() -> void:
	print("==================================================")
	print("RUNNING INTEGRATION VERIFICATION FOR UI MODE & BACKPACK")
	print("==================================================")
	
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
	var actions = ["open_inventory", "open_notebook", "ui_cancel"]
	for action in actions:
		if not InputMap.has_action(action):
			printerr("FAIL: InputMap action '" + action + "' is missing!")
			get_tree().quit(1)
			return
		print("PASS: InputMap action '" + action + "' exists.")
		
	# 3. Load & Instantiate apartment_room.tscn
	print("Loading res://apartment_room.tscn...")
	var room_scene = load("res://apartment_room.tscn")
	if not room_scene:
		printerr("FAIL: Could not load apartment_room.tscn!")
		get_tree().quit(1)
		return
	print("PASS: apartment_room.tscn loaded successfully.")
	
	var room_instance = room_scene.instantiate()
	add_child(room_instance)
	print("PASS: apartment_room.tscn instantiated in scene tree.")
	
	# 4. Verify Relative Node Paths
	print("Verifying UI node structures inside Room...")
	var ui_nodes = {
		"UIOverlay": "UI/UIOverlay",
		"InventoryPanel": "UI/InventoryPanel",
		"BagGrid": "UI/InventoryPanel/VBoxContainer/BagGrid",
		"CreditsLabel": "UI/InventoryPanel/VBoxContainer/HBoxContainer/CreditsLabel",
		"PanelFooterHint": "UI/InventoryPanel/VBoxContainer/PanelFooterHint"
	}
	
	for node_name in ui_nodes:
		var path: String = ui_nodes[node_name]
		var node = room_instance.get_node_or_null(path)
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
		elif node_name == "InventoryPanel":
			var panel = node as PanelContainer
			if panel.custom_minimum_size != Vector2(368, 256):
				printerr("FAIL: InventoryPanel custom_minimum_size is not 368x256! Got: ", panel.custom_minimum_size)
				get_tree().quit(1)
				return
			print("PASS: InventoryPanel custom minimum size is 368x256.")
			
	# 5. Verify ITEMS_DB icon paths on disk
	print("Verifying ITEMS_DB icon paths...")
	var items = GameState.ITEMS_DB
	for item_id in items:
		var meta: Dictionary = items[item_id]
		var icon_path: String = meta.get("icon_path", "")
		if icon_path.is_empty():
			printerr("FAIL: Item '" + item_id + "' is missing icon_path!")
			get_tree().quit(1)
			return
		
		var file_exists = FileAccess.file_exists(icon_path)
		if not file_exists:
			printerr("FAIL: Icon file for '" + item_id + "' does not exist at path: " + icon_path)
			get_tree().quit(1)
			return
		print("PASS: Icon file for '" + item_id + "' exists at '" + icon_path + "'.")
		
	# 6. Verify UIMode clean APIs
	print("Verifying UIMode API presence...")
	if not UIMode.has_method("get_mode") or not UIMode.has_method("set_mode") or not UIMode.has_method("is_world_input_blocked"):
		printerr("FAIL: UIMode lacks get_mode, set_mode, or is_world_input_blocked API!")
		get_tree().quit(1)
		return
	print("PASS: UIMode APIs verified.")
	
	print("==================================================")
	print("ALL INTEGRATION VERIFICATIONS PASSED SUCCESSFULLY!")
	print("==================================================")
	get_tree().quit(0)

extends "res://tests/manual/phases/phase_1e.gd"

func _run_phase_1d() -> void:
	# Verify Phase 1-D container seeding
	print("Verifying Phase 1-D container seeding...")

	var cabinet_slots = GameState.get_container("cabinet_storage")
	if cabinet_slots.size() != 30:
		printerr("FAIL: cabinet_storage should have 30 slots, got %d" % cabinet_slots.size())
		get_tree().quit(1)
		return
	print("PASS: cabinet_storage has 30 slots.")

	var fridge_slots = GameState.get_container("fridge_storage")
	if fridge_slots.size() != 10:
		printerr("FAIL: fridge_storage should have 10 slots, got %d" % fridge_slots.size())
		get_tree().quit(1)
		return
	print("PASS: fridge_storage has 10 slots.")

	# After scene _ready, cabinet should contain faded_jacket + 2 canned_food, fridge should contain 3 canned_food
	var found_jacket := false
	for slot in cabinet_slots:
		if not slot.is_empty() and slot.get("item_id") == "faded_jacket":
			found_jacket = true
			break
	if not found_jacket:
		printerr("FAIL: faded_jacket not seeded into cabinet_storage")
		get_tree().quit(1)
		return
	print("PASS: faded_jacket seeded into cabinet_storage.")


	# 4c. Verify UI Sibling Drawing Z-Order
	print("Verifying UI sibling drawing Z-Order...")
	var children = ui_instance.get_children()
	var overlay_idx = children.find(ui_instance.get_node("UIOverlay"))
	var notebook_idx = children.find(ui_instance.get_node("NotebookPanel"))
	var dual_pane_idx = children.find(ui_instance.get_node("DualPaneContainer"))
	var inventory_idx = children.find(ui_instance.get_node("InventoryPanel"))
	var modal_idx = children.find(ui_instance.get_node_or_null("ItemDetailModal"))
	var confirm_idx = children.find(ui_instance.get_node_or_null("ConfirmDialog"))
	if overlay_idx == -1 or notebook_idx == -1 or dual_pane_idx == -1 or inventory_idx == -1 or modal_idx == -1 or confirm_idx == -1:
		printerr("FAIL: Sibling nodes not found in UI children list!")
		get_tree().quit(1)
		return
	if not (overlay_idx < notebook_idx and notebook_idx < dual_pane_idx and dual_pane_idx < inventory_idx
			and inventory_idx < modal_idx and modal_idx < confirm_idx):
		printerr("FAIL: UI sibling Z-order is wrong! Expected overlay < notebook < dual_pane < inventory < modal < confirm.")
		get_tree().quit(1)
		return
	print("PASS: UI sibling Z-order correct (Overlay -> Notebook -> DualPane -> Inventory -> Modal -> Confirm).")


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


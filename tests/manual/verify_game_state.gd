extends SceneTree

var GameState: Node

var credits_signal_count = 0
var last_credits_signal_val = -1
var inventory_signal_count = 0
var container_signal_count = 0
var last_container_signal_id = ""

func _init() -> void:
	print("==================================================")
	print("Starting GameState Core Singleton Headless Test Suite")
	print("==================================================")
	
	# Instantiate GameState autoload manually for headless -s execution
	GameState = load("res://scripts/autoload/game_state.gd").new()
	root.add_child(GameState)
	
	# Force ready initialization since SceneTree is not yet running
	GameState._ready()
	
	# Connect signals
	GameState.credits_changed.connect(_on_credits_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.container_changed.connect(_on_container_changed)
	
	run_tests()
	
	# Clean up manually added node
	GameState.queue_free()
	quit()

func run_tests() -> void:
	test_credits_api()
	test_knowledge_and_notes_deduplication()
	test_count_validation_checks()
	test_inventory_stacking_and_sorting()
	test_deep_copy_integrity()
	test_dynamic_external_container_and_unified_move()
	test_direction_restrictions()
	test_atomic_move_verification()
	test_signal_emitters_verification()
	
	print("\n==================================================")
	print("ALL ASSERTIONS PASSED SUCCESSFULLY! GameState is 100% Correct.")
	print("==================================================")

func _on_credits_changed(val: int) -> void:
	credits_signal_count += 1
	last_credits_signal_val = val

func _on_inventory_changed() -> void:
	inventory_signal_count += 1

func _on_container_changed(id: String) -> void:
	container_signal_count += 1
	last_container_signal_id = id

# 1. Credits API Verification
func test_credits_api() -> void:
	print("Running Test 1: Credits API Verification...")
	GameState.set_credits(100)
	assert(GameState.get_credits() == 100, "Credits should be set to 100")
	assert(credits_signal_count == 1, "credits_changed should be emitted once")
	assert(last_credits_signal_val == 100, "Signal value should be 100")
	
	GameState.set_credits(-50)
	assert(GameState.get_credits() == 0, "Credits below 0 should clamp to 0")
	assert(credits_signal_count == 2, "credits_changed should be emitted twice")
	assert(last_credits_signal_val == 0, "Signal value should be 0")
	
	# No-op setting shouldn't fire signal
	GameState.set_credits(0)
	assert(credits_signal_count == 2, "credits_changed should not be emitted for no-op")
	print("  -> Passed.")

# 2. Knowledge / Notes Deduplication
func test_knowledge_and_notes_deduplication() -> void:
	print("Running Test 2: Knowledge / Notes Deduplication...")
	var note1 = {
		"id": "door_locked_note",
		"category": "線索",
		"title": "冰箱便條",
		"body": "冰箱上貼著開鎖方法。",
		"status": "active"
	}
	GameState.add_knowledge(note1)
	assert(GameState.has_knowledge("door_locked_note") == false, "線索 category should not trigger knowledge auto-unlock")
	assert(GameState.get_notes("線索").size() == 1, "Should have 1 線索 note")
	
	# Overwrite by ID
	var note1_updated = {
		"id": "door_locked_note",
		"category": "線索",
		"title": "冰箱便條",
		"body": "更新：冰箱上貼著開鎖方法，寫著先戴手套。",
		"status": "active"
	}
	GameState.add_knowledge(note1_updated)
	var notes = GameState.get_notes("線索")
	assert(notes.size() == 1, "Should still have 1 note after update (deduplicated)")
	assert(notes[0].get("body") == "更新：冰箱上貼著開鎖方法，寫著先戴手套。", "Note body should be updated in-place")
	
	# "身份" auto-unlocks knowledge
	var note2 = {
		"id": "identity_door_unlock_method",
		"category": "身份",
		"title": "大門開鎖知識",
		"body": "你想起大門怎麼開了。",
		"status": "active"
	}
	GameState.add_knowledge(note2)
	assert(GameState.has_knowledge("identity_door_unlock_method") == true, "身份 category should automatically trigger knowledge auto-unlock")
	assert(GameState.get_notes("身份").size() == 1, "Should have 1 身份 note")
	print("  -> Passed.")

# 3. Count Validation Checks
func test_count_validation_checks() -> void:
	print("Running Test 3: Count Validation Checks...")
	var original_inv = GameState.get_inventory()
	
	# add_item with invalid counts
	var success_add1 = GameState.add_item("canned_food", 0)
	var success_add2 = GameState.add_item("canned_food", -5)
	assert(success_add1 == false, "add_item with count 0 should return false")
	assert(success_add2 == false, "add_item with count -5 should return false")
	
	# remove_item with invalid counts
	var success_rem1 = GameState.remove_item("canned_food", 0)
	var success_rem2 = GameState.remove_item("canned_food", -5)
	assert(success_rem1 == false, "remove_item with count 0 should return false")
	assert(success_rem2 == false, "remove_item with count -5 should return false")
	
	# Confirm inventory remains unmodified
	assert(GameState.get_inventory() == original_inv, "Inventory should be completely unmodified")
	print("  -> Passed.")

# 4. Inventory Stacking & Sorting
func test_inventory_stacking_and_sorting() -> void:
	print("Running Test 4: Inventory Stacking & Sorting...")
	
	# Canned food is stackable, max_stack = 5
	# Fingerless gloves is not stackable, slot = hand
	# Old work badge is not stackable, slot = ""
	
	# Add canned_food x3
	var success1 = GameState.add_item("canned_food", 3)
	assert(success1 == true, "Should successfully add 3 canned food")
	
	var inv = GameState.get_inventory()
	# Check if slot 0 has canned_food x3
	assert(inv[0].get("item_id") == "canned_food", "First item should be canned_food")
	assert(inv[0].get("quantity") == 3, "Canned food quantity should be 3")
	
	# Add canned_food x3 more (should merge up to 5, and start a second stack of 1)
	var success2 = GameState.add_item("canned_food", 3)
	assert(success2 == true, "Should successfully add 3 more canned food")
	
	inv = GameState.get_inventory()
	# Check first stack is full (5)
	assert(inv[0].get("item_id") == "canned_food", "First stack should be canned_food")
	assert(inv[0].get("quantity") == 5, "First stack should have quantity 5")
	# Check second stack has 1
	assert(inv[1].get("item_id") == "canned_food", "Second stack should be canned_food")
	assert(inv[1].get("quantity") == 1, "Second stack should have quantity 1")
	
	# Add fingerless_gloves
	var success3 = GameState.add_item("fingerless_gloves", 1)
	assert(success3 == true, "Should successfully add fingerless gloves")
	
	# Add old_work_badge
	var success4 = GameState.add_item("old_work_badge", 1)
	assert(success4 == true, "Should successfully add old work badge")
	
	inv = GameState.get_inventory()
	# Verify alphabetical grouping of non-equipped items:
	# "canned_food" (5), "canned_food" (1), "fingerless_gloves" (1), "old_work_badge" (1)
	assert(inv[0].get("item_id") == "canned_food" and inv[0].get("quantity") == 5, "Alphabetical check slot 0")
	assert(inv[1].get("item_id") == "canned_food" and inv[1].get("quantity") == 1, "Alphabetical check slot 1")
	assert(inv[2].get("item_id") == "fingerless_gloves", "Alphabetical check slot 2")
	assert(inv[3].get("item_id") == "old_work_badge", "Alphabetical check slot 3")
	
	# Equip fingerless gloves (should sort to the TOP)
	var gloves_instance_id = inv[2].get("instance_id")
	var equip_success = GameState.equip(gloves_instance_id)
	assert(equip_success == true, "Equip should succeed")
	
	inv = GameState.get_inventory()
	# Fingerless gloves is now equipped, so it must be sorted to the very top (slot 0)!
	assert(inv[0].get("item_id") == "fingerless_gloves", "Equipped item should move to slot 0")
	assert(inv[1].get("item_id") == "canned_food" and inv[1].get("quantity") == 5, "Slot 1 check")
	assert(inv[2].get("item_id") == "canned_food" and inv[2].get("quantity") == 1, "Slot 2 check")
	assert(inv[3].get("item_id") == "old_work_badge", "Slot 3 check")
	
	# Test atomic side-effect: attempt to remove 2 gloves (should fail, and should NOT unequip the 1 glove)
	var remove_fail = GameState.remove_item("fingerless_gloves", 2)
	assert(remove_fail == false, "Attempting to remove 2 gloves should fail since we only have 1")
	var final_equip = GameState.get_equipment()
	assert(final_equip["hand"].has(gloves_instance_id) == true, "Glove must remain equipped after failed remove operation (atomicity check)")
	
	print("  -> Passed.")

# 5. Deep Copy Integrity
func test_deep_copy_integrity() -> void:
	print("Running Test 5: Deep Copy Integrity...")
	
	var inv_copy = GameState.get_inventory()
	# Modify the copy
	inv_copy[0]["item_id"] = "hacked_item"
	inv_copy[0]["quantity"] = 9999
	
	# Verify that the actual singleton inventory remains completely untouched
	var actual_inv = GameState.get_inventory()
	assert(actual_inv[0].get("item_id") == "fingerless_gloves", "Singleton inventory should not mutate from outer modification")
	assert(actual_inv[0].get("quantity") == 1, "Singleton inventory quantity should remain intact")
	
	var equip_copy = GameState.get_equipment()
	equip_copy["hand"].append("hacked_id")
	var actual_equip = GameState.get_equipment()
	assert(actual_equip["hand"].has("hacked_id") == false, "Singleton equipment should not mutate from outer dictionary modification")
	print("  -> Passed.")

# 6. Minimal External Container & Unified Move
func test_dynamic_external_container_and_unified_move() -> void:
	print("Running Test 6: Minimal External Container & Unified Move...")
	
	# Configure fridge storage (5x2 = 10 slots)
	GameState.configure_container("fridge_storage", 10)
	var fridge = GameState.get_container("fridge_storage")
	assert(fridge.size() == 10, "Fridge should be configured with 10 slots")
	assert(fridge[0] == {}, "Fridge slots should be initialized empty")
	
	# Move 1 unit of canned_food (stack of 5) from player backpack to fridge
	var inv = GameState.get_inventory()
	var canned_food_instance_id = ""
	for slot in inv:
		if not slot.is_empty() and slot.get("item_id") == "canned_food" and slot.get("quantity") == 5:
			canned_food_instance_id = slot.get("instance_id")
			break
			
	assert(not canned_food_instance_id.is_empty(), "Canned food slot should be found")
	
	# Execute transfer (backpack -> fridge)
	var move_success1 = GameState.move_one_item_to("fridge_storage", canned_food_instance_id)
	assert(move_success1 == true, "Move to fridge should succeed")
	
	# Check source inventory (backpack should now have 4 canned food in that slot)
	inv = GameState.get_inventory()
	# The slot quantity should have decreased to 4
	var found_qty = -1
	for slot in inv:
		if not slot.is_empty() and slot.get("instance_id") == canned_food_instance_id:
			found_qty = slot.get("quantity", -1)
			break
	assert(found_qty == 4, "Backpack stack count should decrease from 5 to 4")
	
	# Check target container (fridge should now contain 1 canned food)
	fridge = GameState.get_container("fridge_storage")
	assert(fridge[0].get("item_id") == "canned_food", "Fridge should have canned_food in slot 0")
	assert(fridge[0].get("quantity") == 1, "Fridge canned_food quantity should be 1")
	var fridge_canned_food_instance_id = fridge[0].get("instance_id")
	
	# Execute transfer BACK (fridge -> backpack: target_container_id == "player_inventory")
	var move_success2 = GameState.move_one_item_to("player_inventory", fridge_canned_food_instance_id)
	assert(move_success2 == true, "Move back to backpack should succeed")
	
	# Check fridge (fridge should now be empty)
	fridge = GameState.get_container("fridge_storage")
	assert(fridge[0] == {}, "Fridge should be empty again")
	
	# Check backpack (should have merged back to the stack of 4, making it 5 again)
	inv = GameState.get_inventory()
	found_qty = -1
	for slot in inv:
		if not slot.is_empty() and slot.get("instance_id") == canned_food_instance_id:
			found_qty = slot.get("quantity", -1)
			break
	assert(found_qty == 5, "Backpack stack count should return to 5 after merge")
	print("  -> Passed.")

# 7. Directional Transfer Restrictions
func test_direction_restrictions() -> void:
	print("Running Test 7: Directional Transfer Restrictions...")
	
	# Configure cabinet storage (5x6 = 30 slots)
	GameState.configure_container("cabinet_storage", 30)
	
	# Setup: Put 1 canned food in fridge
	var inv = GameState.get_inventory()
	var canned_food_instance_id = ""
	for slot in inv:
		if not slot.is_empty() and slot.get("item_id") == "canned_food" and slot.get("quantity") == 5:
			canned_food_instance_id = slot.get("instance_id")
			break
			
	var move_success1 = GameState.move_one_item_to("fridge_storage", canned_food_instance_id)
	assert(move_success1 == true, "Set up: move item to fridge")
	
	# Get the item's instance ID in fridge
	var fridge = GameState.get_container("fridge_storage")
	var fridge_instance_id = fridge[0].get("instance_id")
	
	# Attempt container-to-container transfer (fridge_storage -> cabinet_storage)
	var move_success2 = GameState.move_one_item_to("cabinet_storage", fridge_instance_id)
	assert(move_success2 == false, "Container-to-container transfers must immediately fail")
	
	# Verify item remains in fridge
	fridge = GameState.get_container("fridge_storage")
	assert(fridge[0].get("item_id") == "canned_food", "Item must remain in fridge")
	
	# Return it back to backpack to clean up
	GameState.move_one_item_to("player_inventory", fridge_instance_id)
	print("  -> Passed.")

# 8. Atomic Move Verification
func test_atomic_move_verification() -> void:
	print("Running Test 8: Atomic Move Verification...")
	
	# Configure a tiny container of size 1
	GameState.configure_container("tiny_storage", 1)
	
	# Fill tiny_storage with an old_work_badge
	var inv = GameState.get_inventory()
	var badge_instance_id = ""
	for slot in inv:
		if not slot.is_empty() and slot.get("item_id") == "old_work_badge":
			badge_instance_id = slot.get("instance_id")
			break
	
	assert(not badge_instance_id.is_empty(), "Badge must be found")
	var move_success1 = GameState.move_one_item_to("tiny_storage", badge_instance_id)
	assert(move_success1 == true, "Fill tiny_storage with badge should succeed")
	
	# Get canned_food instance ID in inventory
	inv = GameState.get_inventory()
	var canned_food_instance_id = ""
	for slot in inv:
		if not slot.is_empty() and slot.get("item_id") == "canned_food":
			canned_food_instance_id = slot.get("instance_id")
			break
			
	# Check original source quantities
	var prev_qty = -1
	for slot in inv:
		if not slot.is_empty() and slot.get("instance_id") == canned_food_instance_id:
			prev_qty = slot.get("quantity", -1)
			break
	assert(prev_qty == 5, "Initial backpack quantity should be 5")
	
	# Attempt to move canned_food into the full tiny_storage
	var move_success2 = GameState.move_one_item_to("tiny_storage", canned_food_instance_id)
	assert(move_success2 == false, "Move to full target must fail atomicity check")
	
	# Verify that neither the source nor target was modified
	inv = GameState.get_inventory()
	var final_qty = -1
	for slot in inv:
		if not slot.is_empty() and slot.get("instance_id") == canned_food_instance_id:
			final_qty = slot.get("quantity", -1)
			break
	assert(final_qty == 5, "Backpack quantity must remain exactly 5 (no partial reduction)")
	
	var tiny = GameState.get_container("tiny_storage")
	assert(tiny[0].get("item_id") == "old_work_badge", "Target must still only contain the old_work_badge")
	print("  -> Passed.")

# 9. Signal Emitters Verification
func test_signal_emitters_verification() -> void:
	print("Running Test 9: Signal Emitters Verification...")
	
	# Reset counters
	inventory_signal_count = 0
	container_signal_count = 0
	last_container_signal_id = ""
	
	# Get canned_food instance ID
	var inv = GameState.get_inventory()
	var canned_food_instance_id = ""
	for slot in inv:
		if not slot.is_empty() and slot.get("item_id") == "canned_food":
			canned_food_instance_id = slot.get("instance_id")
			break
			
	# Move backpack -> fridge_storage (emits inventory_changed and container_changed("fridge_storage"))
	var success1 = GameState.move_one_item_to("fridge_storage", canned_food_instance_id)
	assert(success1 == true, "Move to fridge should succeed")
	assert(inventory_signal_count == 1, "inventory_changed should be emitted once")
	assert(container_signal_count == 1, "container_changed should be emitted once")
	assert(last_container_signal_id == "fridge_storage", "Signal payload should be target 'fridge_storage'")
	
	# Reset counters
	inventory_signal_count = 0
	container_signal_count = 0
	
	# Get the instance ID in fridge
	var fridge = GameState.get_container("fridge_storage")
	var fridge_instance_id = fridge[0].get("instance_id")
	
	# Move fridge_storage -> backpack (emits inventory_changed and container_changed("fridge_storage"))
	var success2 = GameState.move_one_item_to("player_inventory", fridge_instance_id)
	assert(success2 == true, "Move back to backpack should succeed")
	assert(inventory_signal_count == 1, "inventory_changed should be emitted once")
	assert(container_signal_count == 1, "container_changed should be emitted once")
	assert(last_container_signal_id == "fridge_storage", "Signal payload should be source 'fridge_storage'")
	print("  -> Passed.")

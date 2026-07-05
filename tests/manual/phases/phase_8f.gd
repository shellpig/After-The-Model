extends "res://tests/manual/phases/phase_8g.gd"

func _run_phase_8f() -> void:
	# Phase 8-F: 買賣系統核心 + ShopPanel + UIMode.SHOP
	# ============================================================
	print("Verifying Phase 8-F: commerce core, ShopPanel & UIMode.SHOP...")

	inv_backup_8f = GameState.inventory.duplicate(true)
	credits_backup_8f = GameState.get_credits()

	# ---- Test 1: item value / sell math / is_sellable ----
	if GameState.get_item_value("canned_food") != 20 or GameState.get_sell_value("canned_food") != 10:
		printerr("FAIL 8-F: canned_food value/sell_value math wrong! Got: ", GameState.get_item_value("canned_food"), "/", GameState.get_sell_value("canned_food"))
		get_tree().quit(1)
		return
	if GameState.get_sell_value("nutrition_bar_synth_orange") != 6:
		printerr("FAIL 8-F: nutrition bar sell_value should be floor(12*0.5)=6! Got: ", GameState.get_sell_value("nutrition_bar_synth_orange"))
		get_tree().quit(1)
		return
	if GameState.get_sell_value("worn_rubiks_cube") != 0 or GameState.is_sellable("worn_rubiks_cube"):
		printerr("FAIL 8-F: value=1 item must floor to 0 and be unsellable!")
		get_tree().quit(1)
		return
	if GameState.is_sellable("old_work_badge"):
		printerr("FAIL 8-F: key_item must not be sellable!")
		get_tree().quit(1)
		return
	if GameState.is_sellable("clerk_echo_recording"):
		printerr("FAIL 8-F: sellable=false item must not be sellable!")
		get_tree().quit(1)
		return
	if not GameState.is_sellable("canned_food") or not GameState.is_sellable("faded_jacket"):
		printerr("FAIL 8-F: valued non-key items should be sellable!")
		get_tree().quit(1)
		return
	print("PASS 8-F: item value / sell math / is_sellable rules verified.")

	# ---- Test 2: shop stock lazy-init + refresh ----
	GameState.shop_states.clear()
	var stock_8f: Dictionary = GameState.get_shop_stock("convenience_store")
	if stock_8f.get("canned_food", {}).get("price", 0) != 40 or stock_8f.get("canned_food", {}).get("stock", 0) != 10:
		printerr("FAIL 8-F: convenience_store canned_food catalog should lazy-init to price 40 / stock 10! Got: ", stock_8f)
		get_tree().quit(1)
		return
	if stock_8f.get("nutrition_bar_synth_orange", {}).get("price", 0) != 25:
		printerr("FAIL 8-F: nutrition bar price should be 25!")
		get_tree().quit(1)
		return
	if not GameState.shop_states.has("convenience_store"):
		printerr("FAIL 8-F: shop_states should hold lazy-inited stock!")
		get_tree().quit(1)
		return
	if not GameState.get_shop_stock("no_such_shop").is_empty():
		printerr("FAIL 8-F: unknown shop_id should return empty stock!")
		get_tree().quit(1)
		return
	print("PASS 8-F: shop stock lazy-init verified.")

	# ---- Test 3: buy_item atomic + failure reasons ----
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.set_credits(100)

	if not GameState.buy_item("convenience_store", "canned_food"):
		printerr("FAIL 8-F: buy_item should succeed with credits/stock/space!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 60 or not GameState.has_item("canned_food", 1):
		printerr("FAIL 8-F: buy should cost 40 credits and grant item! credits: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: buy should deduct shop stock to 9!")
		get_tree().quit(1)
		return

	GameState.set_credits(10)
	var can_8f: Dictionary = GameState.can_buy("convenience_store", "canned_food")
	if can_8f.get("ok", true) or can_8f.get("reason", "") != "not_enough_credits":
		printerr("FAIL 8-F: can_buy should report not_enough_credits! Got: ", can_8f)
		get_tree().quit(1)
		return
	if GameState.buy_item("convenience_store", "canned_food"):
		printerr("FAIL 8-F: buy_item must fail without credits!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 10 or GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: failed buy must not change credits/stock!")
		get_tree().quit(1)
		return

	GameState.shop_states["convenience_store"]["nutrition_bar_synth_orange"]["stock"] = 0
	can_8f = GameState.can_buy("convenience_store", "nutrition_bar_synth_orange")
	if can_8f.get("ok", true) or can_8f.get("reason", "") != "out_of_stock":
		printerr("FAIL 8-F: can_buy should report out_of_stock! Got: ", can_8f)
		get_tree().quit(1)
		return
	if GameState.buy_item("convenience_store", "nutrition_bar_synth_orange"):
		printerr("FAIL 8-F: buy_item must fail when out of stock!")
		get_tree().quit(1)
		return

	# 背包滿：add_item 失敗時整筆不動
	GameState.set_credits(500)
	for i in range(GameState.inventory_slots):
		GameState.inventory[i] = {
			"instance_id": GameState.generate_instance_id(),
			"item_id": "canned_food",
			"quantity": 5
		}
	if GameState.buy_item("convenience_store", "canned_food"):
		printerr("FAIL 8-F: buy_item must fail when bag is full!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 500 or GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: bag-full buy must not change credits/stock!")
		get_tree().quit(1)
		return
	print("PASS 8-F: buy_item atomic behavior & failure reasons verified.")

	# ---- Test 4: sell_item by instance_id ----
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.set_credits(100)
	GameState.add_item("canned_food", 2)
	var sell_iid_8f := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "canned_food":
			sell_iid_8f = slot.get("instance_id", "")
			break
	if not GameState.sell_item(sell_iid_8f):
		printerr("FAIL 8-F: sell_item should succeed for sellable owned item!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 110:
		printerr("FAIL 8-F: selling canned_food should add 10 credits! Got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if not GameState.has_item("canned_food", 1) or GameState.has_item("canned_food", 2):
		printerr("FAIL 8-F: sell count 1 should leave exactly 1 unit!")
		get_tree().quit(1)
		return
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: selling must NOT restock the shop!")
		get_tree().quit(1)
		return
	if GameState.sell_item(sell_iid_8f, 5):
		printerr("FAIL 8-F: selling more than the focused slot holds must fail!")
		get_tree().quit(1)
		return

	# 多 instance：只賣焦點格那一格
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("faded_jacket", 1)
	GameState.add_item("faded_jacket", 1)
	var jacket_iids_8f := []
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "faded_jacket":
			jacket_iids_8f.append(slot.get("instance_id", ""))
	if jacket_iids_8f.size() != 2:
		printerr("FAIL 8-F: expected two jacket instances! Got: ", jacket_iids_8f.size())
		get_tree().quit(1)
		return
	if not GameState.sell_item(jacket_iids_8f[1]):
		printerr("FAIL 8-F: selling the second jacket instance should succeed!")
		get_tree().quit(1)
		return
	var remaining_iid_8f := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "faded_jacket":
			remaining_iid_8f = slot.get("instance_id", "")
	if remaining_iid_8f != jacket_iids_8f[0]:
		printerr("FAIL 8-F: sell-by-instance must keep the non-focused instance! Got: ", remaining_iid_8f)
		get_tree().quit(1)
		return

	# 已裝備不可賣（不自動卸下），卸下後可賣
	GameState.equip(remaining_iid_8f)
	if GameState.sell_item(remaining_iid_8f):
		printerr("FAIL 8-F: equipped item must not be sellable!")
		get_tree().quit(1)
		return
	if not GameState.is_equipped(remaining_iid_8f):
		printerr("FAIL 8-F: failed sell must not unequip the item!")
		get_tree().quit(1)
		return
	GameState.unequip_by_instance(remaining_iid_8f)
	if not GameState.sell_item(remaining_iid_8f):
		printerr("FAIL 8-F: unequipped jacket should be sellable!")
		get_tree().quit(1)
		return

	# 不可賣物
	GameState.add_item("old_work_badge", 1)
	var badge_iid_8f := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "old_work_badge":
			badge_iid_8f = slot.get("instance_id", "")
	if GameState.sell_item(badge_iid_8f):
		printerr("FAIL 8-F: key_item must not be sellable via sell_item!")
		get_tree().quit(1)
		return
	GameState.remove_item("old_work_badge", 1)
	print("PASS 8-F: sell_item by instance, equipped guard & unsellable rules verified.")

	# ---- Test 5: shop_states save/load round-trip + reset ----
	var save_dict_8f: Dictionary = GameState.to_save_dict()
	if not save_dict_8f.has("shop_states") or save_dict_8f["shop_states"]["convenience_store"]["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: to_save_dict must carry shop_states with mutated stock!")
		get_tree().quit(1)
		return
	GameState.refresh_shop_stock("convenience_store")
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 10:
		printerr("FAIL 8-F: refresh_shop_stock should reset stock from catalog!")
		get_tree().quit(1)
		return
	GameState.load_save_dict(save_dict_8f)
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9 \
			or GameState.get_shop_stock("convenience_store")["nutrition_bar_synth_orange"]["stock"] != 0:
		printerr("FAIL 8-F: load_save_dict must restore mutated shop stock!")
		get_tree().quit(1)
		return
	GameState.reset_for_new_game()
	if not GameState.shop_states.is_empty():
		printerr("FAIL 8-F: reset_for_new_game must clear shop_states!")
		get_tree().quit(1)
		return
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 10:
		printerr("FAIL 8-F: after reset, shop stock should lazy-init fresh from catalog!")
		get_tree().quit(1)
		return
	print("PASS 8-F: shop_states save/load round-trip & reset verified.")

	# ---- Test 6: GameUI open_shop / ShopPanel buy & sell / close ----
	GameState.set_credits(100)
	ui_instance.open_shop("convenience_store")
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.SHOP or not ui_instance.is_shop_open():
		printerr("FAIL 8-F: open_shop should enter UIMode.SHOP with panel open!")
		get_tree().quit(1)
		return
	var shop_panel_8f = ui_instance.shop_panel
	if not shop_panel_8f.visible or shop_panel_8f.shop_id != "convenience_store":
		printerr("FAIL 8-F: ShopPanel should be visible with shop_id set!")
		get_tree().quit(1)
		return
	if shop_panel_8f._buy_rows.size() != 2:
		printerr("FAIL 8-F: buy pane should list 2 catalog items! Got: ", shop_panel_8f._buy_rows.size())
		get_tree().quit(1)
		return

	# 左欄 E 買入（焦點預設第一列 canned_food）
	ui_instance.shop_confirm()
	if not GameState.has_item("canned_food", 1) or GameState.get_credits() != 60:
		printerr("FAIL 8-F: shop_confirm on buy pane should buy canned_food! credits: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: panel buy should deduct stock!")
		get_tree().quit(1)
		return

	# 切右欄賣出剛買的罐頭
	ui_instance.shop_switch_pane(1)
	if shop_panel_8f.active_pane != "sell":
		printerr("FAIL 8-F: shop_switch_pane(1) should focus sell pane!")
		get_tree().quit(1)
		return
	ui_instance.shop_confirm()
	if GameState.has_item("canned_food", 1) or GameState.get_credits() != 70:
		printerr("FAIL 8-F: sell pane confirm should sell focused canned_food for 10! credits: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: panel sell must not restock the shop!")
		get_tree().quit(1)
		return

	# 關店回 NONE 無殘留
	ui_instance.close_all_ui()
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.NONE or ui_instance.is_shop_open() or shop_panel_8f.visible:
		printerr("FAIL 8-F: closing shop should return to NONE with panel hidden!")
		get_tree().quit(1)
		return
	print("PASS 8-F: GameUI open_shop, panel buy/sell routing & close verified.")

	# ---- Test 7: 修好後機器人招呼結尾開店；修好前不開 ----
	var robot_tree_8f = DialogueDB.get_tree_for("store_robot")
	for greet_node_8f in ["repaired_reset", "repaired_gleaned"]:
		var effects_8f: Array = robot_tree_8f[greet_node_8f].get("effect", [])
		var has_open_shop_8f := false
		for eff in effects_8f:
			if eff.get("op", "") == "open_shop" and eff.get("value", "") == "convenience_store":
				has_open_shop_8f = true
		if not has_open_shop_8f:
			printerr("FAIL 8-F: " + greet_node_8f + " must carry open_shop effect!")
			get_tree().quit(1)
			return

	# 修好前（babble）：無 pending shop
	gate_runner_8f = DialogueRunner.new()
	gate_runner_8f.start(robot_tree_8f, "start")
	if gate_runner_8f._current_node_id != "babble_intro" or gate_runner_8f.pending_shop_id != "":
		printerr("FAIL 8-F: pre-repair robot dialogue must not pend a shop! Got: ", gate_runner_8f._current_node_id)
		get_tree().quit(1)
		return

	# 修好後：DIALOGUE 正常結束 → 直接切 SHOP
	GameState.set_flag("vendor_bot_repaired", true)
	GameState.set_flag("store_robot_resolution", "reset")
	ui_instance.start_dialogue("store_robot")
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.DIALOGUE:
		printerr("FAIL 8-F: start_dialogue should enter DIALOGUE mode first!")
		get_tree().quit(1)
		return
	ui_instance.dialogue_confirm()
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.SHOP or not ui_instance.is_shop_open():
		printerr("FAIL 8-F: repaired greeting end should hand off to UIMode.SHOP! Got mode: ", UIMode.get_mode())
		get_tree().quit(1)
		return
	if shop_panel_8f.shop_id != "convenience_store":
		printerr("FAIL 8-F: handed-off shop should be convenience_store!")
		get_tree().quit(1)
		return
	ui_instance.close_all_ui()
	await get_tree().process_frame
	print("PASS 8-F: repaired greeting opens shop; pre-repair dialogue does not.")

	# ============================================================

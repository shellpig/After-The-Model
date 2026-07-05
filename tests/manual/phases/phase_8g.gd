extends "res://tests/manual/phases/phase_8h.gd"

func _run_phase_8g() -> void:
	# Phase 8-G: 迷你飲料商店 + 多商店資料化
	# ============================================================
	print("Verifying Phase 8-G: street_vending & data-driven multi-shop...")

	var entrance_scene_8g = load("res://scenes/levels/apartment_entrance.tscn")
	var entrance_instance_8g = entrance_scene_8g.instantiate()
	add_child(entrance_instance_8g)
	await get_tree().process_frame

	var vending_area_8g = entrance_instance_8g.get_node_or_null("Interactables/VendingMachineArea")
	if vending_area_8g == null or vending_area_8g.interaction_id != "vending_machine":
		printerr("FAIL 8-G: VendingMachineArea missing or interaction_id is not vending_machine!")
		get_tree().quit(1)
		return

	var vending_emit_data_8g = {}
	var temp_callable_8g = func(data):
		vending_emit_data_8g.clear()
		vending_emit_data_8g.merge(data)
	entrance_instance_8g.interaction_requested.connect(temp_callable_8g)

	# 1. 修好前：只給前導訊息，不開店
	GameState.story_flags.erase("vendor_bot_repaired")
	GameState.story_flags.erase("talked_outside_vendor")
	entrance_instance_8g.current_interactable = vending_area_8g
	entrance_instance_8g._trigger_interaction()
	if vending_emit_data_8g.get("type") != "message" or not GameState.get_flag("talked_outside_vendor", false):
		printerr("FAIL 8-G: pre-repair vending machine interaction must emit message and set talked_outside_vendor! Got: ", vending_emit_data_8g)
		get_tree().quit(1)
		return

	# 2. 修好後：直接開 ShopPanel (street_vending)
	vending_emit_data_8g.clear()
	GameState.set_flag("vendor_bot_repaired", true)
	entrance_instance_8g._trigger_interaction()
	if vending_emit_data_8g.get("type") != "shop" or vending_emit_data_8g.get("shop_id") != "street_vending":
		printerr("FAIL 8-G: post-repair vending machine interaction must emit shop with street_vending! Got: ", vending_emit_data_8g)
		get_tree().quit(1)
		return

	entrance_instance_8g.interaction_requested.disconnect(temp_callable_8g)
	entrance_instance_8g.queue_free()
	await get_tree().process_frame
	print("PASS 8-G: post-repair vending machine direct shop launch verified.")

	# 3. 庫存獨立性與多商店資料化
	GameState.shop_states.clear()
	var cs_stock_8g = GameState.get_shop_stock("convenience_store")
	var sv_stock_8g = GameState.get_shop_stock("street_vending")

	if cs_stock_8g.is_empty() or sv_stock_8g.is_empty():
		printerr("FAIL 8-G: failed to lazy-init shop stocks!")
		get_tree().quit(1)
		return

	if not sv_stock_8g.has("synth_cola") or sv_stock_8g["synth_cola"].get("stock", 0) != 5:
		printerr("FAIL 8-G: street_vending synth_cola stock must be 5! Got: ", sv_stock_8g)
		get_tree().quit(1)
		return

	# 買飲料
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.set_credits(100)

	if not GameState.buy_item("street_vending", "synth_cola"):
		printerr("FAIL 8-G: buy_item from street_vending failed!")
		get_tree().quit(1)
		return

	if GameState.get_credits() != 70 or GameState.get_shop_stock("street_vending")["synth_cola"]["stock"] != 4:
		printerr("FAIL 8-G: buy_item did not update street_vending stock/credits properly!")
		get_tree().quit(1)
		return

	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 10:
		printerr("FAIL 8-G: buy_item from street_vending must NOT affect convenience_store stock!")
		get_tree().quit(1)
		return
	print("PASS 8-G: street_vending and convenience_store stocks are independent.")

	# 4. 存讀檔與新遊戲重設
	var save_dict_8g = GameState.to_save_dict()
	if not save_dict_8g.has("shop_states") \
			or save_dict_8g["shop_states"]["street_vending"]["synth_cola"]["stock"] != 4 \
			or save_dict_8g["shop_states"]["convenience_store"]["canned_food"]["stock"] != 10:
		printerr("FAIL 8-G: to_save_dict failed to serialize multiple shop states correctly!")
		get_tree().quit(1)
		return

	# 重置
	GameState.reset_for_new_game()
	if not GameState.shop_states.is_empty():
		printerr("FAIL 8-G: reset_for_new_game should clear shop_states!")
		get_tree().quit(1)
		return

	# 讀檔
	GameState.load_save_dict(save_dict_8g)
	if GameState.get_shop_stock("street_vending")["synth_cola"]["stock"] != 4 \
			or GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 10:
		printerr("FAIL 8-G: load_save_dict failed to restore multiple shop states correctly!")
		get_tree().quit(1)
		return
	print("PASS 8-G: multi-shop save/load and reset verified.")

	# ============================================================

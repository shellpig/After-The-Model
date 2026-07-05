extends "res://tests/manual/phases/phase_9b.gd"

func _run_phase_9a() -> void:
	# Phase 9-A: 殘響資料模型 + 筆記「殘響」分頁 + 店員殘響回寫
	# ============================================================
	print("Verifying Phase 9-A: Echo Database, GameState integration, and Notebook tab...")

	# 1. EchoDB basic checks
	if not EchoDB.has_echo("echo_clerk") or not EchoDB.has_echo("echo_room401_tenant") or not EchoDB.has_echo("echo_song_rain_doesnt_stop") or not EchoDB.has_echo("echo_lu_family"):
		printerr("FAIL 9-A: EchoDB missing standard echoes!")
		get_tree().quit(1)
		return
	if EchoDB.get_segment_count("echo_clerk") != 1 or EchoDB.get_segment_count("echo_room401_tenant") != 3:
		printerr("FAIL 9-A: EchoDB segment counts incorrect!")
		get_tree().quit(1)
		return
	print("PASS 9-A: EchoDB registry verified.")

	# Backup current game state
	var inv_backup_9a = GameState.inventory.duplicate(true)
	var credits_backup_9a = GameState.get_credits()
	var echo_progress_backup_9a = GameState.echo_progress.duplicate(true)
	var story_flags_backup_9a = GameState.story_flags.duplicate(true)

	# Clean slate
	GameState.reset_for_new_game()
	if not GameState.echo_progress.is_empty():
		printerr("FAIL 9-A: reset_for_new_game should clear echo_progress!")
		get_tree().quit(1)
		return

	# 2. collect_echo_segment & queries
	if GameState.is_echo_known("echo_room401_tenant") or GameState.is_echo_complete("echo_room401_tenant"):
		printerr("FAIL 9-A: Echo should not be known or complete before collection!")
		get_tree().quit(1)
		return

	# Collect first segment
	if not GameState.collect_echo_segment("echo_room401_tenant", "s1"):
		printerr("FAIL 9-A: collect_echo_segment should return true for first collection!")
		get_tree().quit(1)
		return
	if not GameState.is_echo_known("echo_room401_tenant"):
		printerr("FAIL 9-A: Echo should be known after collecting 1 segment!")
		get_tree().quit(1)
		return
	if GameState.is_echo_complete("echo_room401_tenant"):
		printerr("FAIL 9-A: Echo should not be complete with only 1/3 segments!")
		get_tree().quit(1)
		return

	# Collect duplicate segment (should return false)
	if GameState.collect_echo_segment("echo_room401_tenant", "s1"):
		printerr("FAIL 9-A: collect_echo_segment should return false for duplicate collection!")
		get_tree().quit(1)
		return

	# Collect remaining segments
	if not GameState.collect_echo_segment("echo_room401_tenant", "s2") or not GameState.collect_echo_segment("echo_room401_tenant", "s3"):
		printerr("FAIL 9-A: collect_echo_segment failed on new segments!")
		get_tree().quit(1)
		return
	if not GameState.is_echo_complete("echo_room401_tenant"):
		printerr("FAIL 9-A: Echo should be complete after collecting all segments!")
		get_tree().quit(1)
		return
	print("PASS 9-A: collect_echo_segment and completion checks verified.")

	# 3. sell_echo
	var old_credits_9a = GameState.get_credits()
	if GameState.is_echo_sold("echo_room401_tenant"):
		printerr("FAIL 9-A: Echo should not be sold yet!")
		get_tree().quit(1)
		return
	if not GameState.sell_echo("echo_room401_tenant"):
		printerr("FAIL 9-A: sell_echo should succeed on completed unsold echo!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != old_credits_9a + 200:
		printerr("FAIL 9-A: sell_echo did not reward correct credits! Got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if not GameState.is_echo_sold("echo_room401_tenant"):
		printerr("FAIL 9-A: Echo should be flagged as sold after selling!")
		get_tree().quit(1)
		return
	if GameState.sell_echo("echo_room401_tenant"):
		printerr("FAIL 9-A: sell_echo should fail on already sold echo!")
		get_tree().quit(1)
		return
	print("PASS 9-A: sell_echo rewards and guards verified.")

	# 4. record_full_echo
	GameState.record_full_echo("echo_song_rain_doesnt_stop")
	if not GameState.is_echo_complete("echo_song_rain_doesnt_stop") or GameState.is_echo_sold("echo_song_rain_doesnt_stop"):
		printerr("FAIL 9-A: record_full_echo should complete the echo without selling it!")
		get_tree().quit(1)
		return
	print("PASS 9-A: record_full_echo verified.")

	# 5. Serialization and backfill on save/load
	var save_dict_9a = GameState.to_save_dict()
	if not save_dict_9a.has("echo_progress"):
		printerr("FAIL 9-A: to_save_dict missing echo_progress!")
		get_tree().quit(1)
		return
	if not save_dict_9a["echo_progress"].has("echo_room401_tenant") or not save_dict_9a["echo_progress"]["echo_room401_tenant"]["sold"]:
		printerr("FAIL 9-A: serialized echo_progress has incorrect state!")
		get_tree().quit(1)
		return

	# Reset and load
	GameState.reset_for_new_game()
	GameState.load_save_dict(save_dict_9a)
	if not GameState.is_echo_complete("echo_room401_tenant") or not GameState.is_echo_sold("echo_room401_tenant"):
		printerr("FAIL 9-A: load_save_dict failed to restore echo states!")
		get_tree().quit(1)
		return
	if not GameState.is_echo_complete("echo_song_rain_doesnt_stop"):
		printerr("FAIL 9-A: load_save_dict failed to restore completed echo!")
		get_tree().quit(1)
		return
	print("PASS 9-A: save/load round-trip of echo progress verified.")

	# 6. Clerk echo resolution hook backfill
	GameState.reset_for_new_game()
	if GameState.is_echo_known("echo_clerk"):
		printerr("FAIL 9-A: clerk echo should not be known in a new game initially!")
		get_tree().quit(1)
		return

	# Setting resolution to reset -> should NOT backfill clerk echo
	GameState.set_flag("store_robot_resolution", "reset")
	if GameState.is_echo_known("echo_clerk"):
		printerr("FAIL 9-A: store_robot_resolution='reset' should not backfill clerk echo!")
		get_tree().quit(1)
		return

	# Setting resolution to gleaned -> should backfill clerk echo
	GameState.set_flag("store_robot_resolution", "gleaned")
	if not GameState.is_echo_complete("echo_clerk"):
		printerr("FAIL 9-A: store_robot_resolution='gleaned' should backfill and complete clerk echo!")
		get_tree().quit(1)
		return

	# Testing backfill during load_save_dict (old save files)
	GameState.reset_for_new_game()
	GameState.story_flags["store_robot_resolution"] = "gleaned"
	if GameState.is_echo_known("echo_clerk"):
		printerr("FAIL 9-A: direct bypass should not trigger backfill until load/capture!")
		get_tree().quit(1)
		return
	var save_dict_old_9a = GameState.to_save_dict()
	GameState.reset_for_new_game()
	GameState.load_save_dict(save_dict_old_9a)
	if not GameState.is_echo_complete("echo_clerk"):
		printerr("FAIL 9-A: load_save_dict should backfill clerk echo for gleaned resolution saves!")
		get_tree().quit(1)
		return
	print("PASS 9-A: clerk echo resolution hook and backfilling verified.")

	# 7. Notebook UI projections
	var ui_scene_9a = load("res://scenes/ui/game_ui.tscn")
	var ui_instance_9a = ui_scene_9a.instantiate()
	add_child(ui_instance_9a)
	await get_tree().process_frame

	var notebook_panel_9a = ui_instance_9a.get_node_or_null("NotebookPanel")
	if notebook_panel_9a == null:
		printerr("FAIL 9-A: NotebookPanel missing from GameUI!")
		get_tree().quit(1)
		return

	# Set up mock echoes
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_clerk", "s1")
	GameState.collect_echo_segment("echo_room401_tenant", "s1")
	GameState.collect_echo_segment("echo_room401_tenant", "s3")
	GameState.record_full_echo("echo_song_rain_doesnt_stop")
	GameState.sell_echo("echo_song_rain_doesnt_stop")

	notebook_panel_9a.set_input_active(true)
	notebook_panel_9a.active_category_index = 0
	notebook_panel_9a._select_tab_index(3)
	await get_tree().process_frame


	var list_buttons_9a = notebook_panel_9a.list_vbox.get_children()
	if list_buttons_9a.size() != 3:
		printerr("FAIL 9-A: Expected 3 buttons in the list! Got: ", list_buttons_9a.size())
		get_tree().quit(1)
		return

	var clerk_btn: Button = list_buttons_9a[0]
	var tenant_btn: Button = list_buttons_9a[1]
	var song_btn: Button = list_buttons_9a[2]

	if not clerk_btn.text.contains("店員的殘響") or not clerk_btn.text.contains("1/1"):
		printerr("FAIL 9-A: Clerk button text incorrect! Got: ", clerk_btn.text)
		get_tree().quit(1)
		return
	if not tenant_btn.text.contains("401") or not tenant_btn.text.contains("2/3"):
		printerr("FAIL 9-A: Tenant button text incorrect! Got: ", tenant_btn.text)
		get_tree().quit(1)
		return
	if not song_btn.text.contains("雨還沒停") or not song_btn.text.contains("3/3") or not song_btn.text.contains("已售出"):
		printerr("FAIL 9-A: Song button text incorrect! Got: ", song_btn.text)
		get_tree().quit(1)
		return

	# Verify Body Projection via focus trigger
	tenant_btn.grab_focus()
	await get_tree().process_frame

	var body_txt: String = notebook_panel_9a.body_label.text
	if not body_txt.contains("租約通知單") or not body_txt.contains("段落 2：????") or not body_txt.contains("生活照"):
		printerr("FAIL 9-A: Body text for partially known echo is incorrect! Got: ", body_txt)
		get_tree().quit(1)
		return

	# Cleanup GameUI instance
	ui_instance_9a.free()
	print("PASS 9-A: Notebook UI projection and tab selection verified.")

	# Restore game state backup
	GameState.reset_for_new_game()
	GameState.inventory = inv_backup_9a
	GameState.set_credits(credits_backup_9a)
	GameState.echo_progress = echo_progress_backup_9a
	GameState.story_flags = story_flags_backup_9a
	GameState.inventory_changed.emit()
	await get_tree().process_frame


	# ============================================================

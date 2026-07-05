extends "res://tests/manual/phases/phase_9f.gd"

func _run_phase_9e() -> void:
	# Phase 9-E Verification
	# ----------------------------------------------------
	print("Running 9-E Integration tests...")

	# Reset state
	GameState.reset_for_new_game()

	var db_echoes: Dictionary = EchoDB.ECHOES
	var db_tenant: Dictionary = db_echoes["echo_room401_tenant"]
	var db_clerk: Dictionary = db_echoes["echo_clerk"]

	# Open Notebook
	UIMode.set_mode(UIMode.Mode.NOTEBOOK)
	# Switch to "殘響" (index 3)
	ui_instance.notebook_panel._select_tab_index(3)
	await get_tree().process_frame

	# 1. Uncollected Echoes: should have no media footer hints
	# Collect s1 of echo_room401_tenant so it shows up in list but is incomplete (1/3)
	GameState.collect_echo_segment("echo_room401_tenant", "s1")
	ui_instance.notebook_panel.load_notebook_data()
	await get_tree().process_frame

	var notebook_list = ui_instance.notebook_panel.list_vbox
	var note_button_401 = notebook_list.get_child(0) as Button
	note_button_401.grab_focus()
	await get_tree().process_frame

	var actions_uncollected = ui_instance.notebook_panel.get_media_actions()
	if not actions_uncollected.is_empty():
		printerr("FAIL 9-E: Incomplete Echo should not have media actions, got: ", actions_uncollected)
		get_tree().quit(1)
		return

	# 2. Image-only Echo: collect all segments for echo_room401_tenant
	GameState.collect_echo_segment("echo_room401_tenant", "s2")
	GameState.collect_echo_segment("echo_room401_tenant", "s3")
	# Set a valid image path dynamically to avoid load errors
	db_tenant["image_path"] = "res://assets/generated/maps/alley_backrooms_3f/alley-backrooms-3f-stage-preview.png"

	ui_instance.notebook_panel.load_notebook_data()
	await get_tree().process_frame
	note_button_401 = notebook_list.get_child(0) as Button
	note_button_401.grab_focus()
	await get_tree().process_frame

	var actions_image_only = ui_instance.notebook_panel.get_media_actions()
	if actions_image_only.get("primary") != "view_photo" or actions_image_only.has("secondary"):
		printerr("FAIL 9-E: Completed image-only Echo should have primary action 'view_photo' and no secondary action! Got: ", actions_image_only)
		get_tree().quit(1)
		return

	if not ui_instance.can_primary_action() or ui_instance.can_secondary_action():
		printerr("FAIL 9-E: Completed image-only Echo action visibility flags are wrong!")
		get_tree().quit(1)
		return

	# Verify footer hints contain "E: 看照片"
	var footer_text = ui_instance.notebook_panel.panel_footer_hint.text
	if not "E: 看照片" in footer_text:
		printerr("FAIL 9-E: Footer hint for image-only Echo should contain 'E: 看照片', got: ", footer_text)
		get_tree().quit(1)
		return

	# 3. Audio-only Echo: collect all segments for echo_clerk
	GameState.collect_echo_segment("echo_clerk", "s1")

	ui_instance.notebook_panel.load_notebook_data()
	await get_tree().process_frame
	var note_button_clerk: Button = null
	for child in notebook_list.get_children():
		if child is Button and child.text.contains("店員"):
			note_button_clerk = child
			break
	if note_button_clerk == null:
		printerr("FAIL 9-E: Could not find clerk echo in notebook list!")
		get_tree().quit(1)
		return

	note_button_clerk.grab_focus()
	await get_tree().process_frame

	var actions_audio_only = ui_instance.notebook_panel.get_media_actions()
	if actions_audio_only.get("primary") != "play_audio" or actions_audio_only.has("secondary"):
		printerr("FAIL 9-E: Completed audio-only Echo should have primary action 'play_audio' and no secondary action! Got: ", actions_audio_only)
		get_tree().quit(1)
		return

	if not ui_instance.can_primary_action() or ui_instance.can_secondary_action():
		printerr("FAIL 9-E: Completed audio-only Echo action visibility flags are wrong!")
		get_tree().quit(1)
		return

	# Verify footer hints contain "E: 播放錄音"
	footer_text = ui_instance.notebook_panel.panel_footer_hint.text
	if not "E: 播放錄音" in footer_text:
		printerr("FAIL 9-E: Footer hint for audio-only Echo should contain 'E: 播放錄音', got: ", footer_text)
		get_tree().quit(1)
		return

	# 4. Both Image and Audio Echo
	# Temporarily give echo_clerk an image path as well
	db_clerk["image_path"] = "res://assets/generated/maps/alley_backrooms_3f/alley-backrooms-3f-stage-preview.png"
	ui_instance.notebook_panel.load_notebook_data()
	await get_tree().process_frame

	for child in notebook_list.get_children():
		if child is Button and child.text.contains("店員"):
			note_button_clerk = child
			break
	note_button_clerk.grab_focus()
	await get_tree().process_frame

	var actions_both = ui_instance.notebook_panel.get_media_actions()
	if actions_both.get("primary") != "view_photo" or actions_both.get("secondary") != "play_audio":
		printerr("FAIL 9-E: Completed both-media Echo should have primary 'view_photo' and secondary 'play_audio'! Got: ", actions_both)
		get_tree().quit(1)
		return

	if not ui_instance.can_primary_action() or not ui_instance.can_secondary_action():
		printerr("FAIL 9-E: Completed both-media Echo action visibility flags are wrong!")
		get_tree().quit(1)
		return

	footer_text = ui_instance.notebook_panel.panel_footer_hint.text
	if not "E: 看照片" in footer_text or not "R: 播放錄音" in footer_text:
		printerr("FAIL 9-E: Footer hints for both-media Echo should contain 'E: 看照片' and 'R: 播放錄音', got: ", footer_text)
		get_tree().quit(1)
		return

	# Clean up clerk image path
	db_clerk.erase("image_path")

	# 5. Sold Echo: sell echo_room401_tenant and check hints
	GameState.sell_echo("echo_room401_tenant")
	ui_instance.notebook_panel.load_notebook_data()
	await get_tree().process_frame

	for child in notebook_list.get_children():
		if child is Button and child.text.contains("401"):
			note_button_401 = child
			break
	note_button_401.grab_focus()
	await get_tree().process_frame

	var actions_sold = ui_instance.notebook_panel.get_media_actions()
	if not actions_sold.is_empty():
		printerr("FAIL 9-E: Sold Echo should not have media actions, got: ", actions_sold)
		get_tree().quit(1)
		return

	footer_text = ui_instance.notebook_panel.panel_footer_hint.text
	if "看照片" in footer_text or "播放錄音" in footer_text:
		printerr("FAIL 9-E: Footer hints for sold Echo should not contain media hints, got: ", footer_text)
		get_tree().quit(1)
		return

	# Restore original database values
	db_tenant["image_path"] = "res://assets/images/echoes/echo_room401_tenant.png"
	db_clerk["audio_path"] = "res://assets/audio/echoes/echo_clerk.ogg"

	# 6. Photo Viewer Overlay & Focus/Input active transitions
	# Give clerk a valid image temporarily again to test viewing
	db_clerk["image_path"] = "res://assets/generated/maps/alley_backrooms_3f/alley-backrooms-3f-stage-preview.png"
	GameState.echo_progress["echo_clerk"]["sold"] = false
	ui_instance.notebook_panel.load_notebook_data()
	await get_tree().process_frame

	for child in notebook_list.get_children():
		if child is Button and child.text.contains("店員"):
			note_button_clerk = child
			break
	note_button_clerk.grab_focus()
	await get_tree().process_frame

	if not ui_instance.notebook_panel.is_input_active:
		printerr("FAIL 9-E: Notebook panel input should be active initially!")
		get_tree().quit(1)
		return

	ui_instance.open_photo_viewer("res://assets/generated/maps/alley_backrooms_3f/alley-backrooms-3f-stage-preview.png", note_button_clerk)

	if not ui_instance.is_photo_viewer_open():
		printerr("FAIL 9-E: Photo viewer should be open!")
		get_tree().quit(1)
		return
	if ui_instance.notebook_panel.is_input_active:
		printerr("FAIL 9-E: Notebook panel input should be inactive when photo viewer is open!")
		get_tree().quit(1)
		return

	if not ui_instance.can_primary_action() or ui_instance.can_secondary_action():
		printerr("FAIL 9-E: Action visibility flags when photo viewer is open are incorrect!")
		get_tree().quit(1)
		return

	ui_instance.close_photo_viewer()

	if ui_instance.is_photo_viewer_open():
		printerr("FAIL 9-E: Photo viewer should be closed!")
		get_tree().quit(1)
		return
	if not ui_instance.notebook_panel.is_input_active:
		printerr("FAIL 9-E: Notebook panel input should be active after photo viewer is closed!")
		get_tree().quit(1)
		return

	db_clerk.erase("image_path")

	# 7. Audio Playback Toggling & Interruption Cases
	note_button_clerk.grab_focus()
	await get_tree().process_frame
	var test_audio = "res://assets/audio/echoes/echo_song_rain_doesnt_stop.mp3"

	var ambient_bus_idx_9e := AudioServer.get_bus_index("Ambient")
	ui_instance.toggle_echo_audio(test_audio)
	if not ui_instance._audio_echo.playing:
		printerr("FAIL 9-E: Audio echo player should be playing after toggle on!")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.35).timeout
	if ambient_bus_idx_9e != -1:
		var ducked_db := AudioServer.get_bus_volume_db(ambient_bus_idx_9e)
		# Lowered, not silenced (Phase 10-A spec: "壓低，不全靜") — must be clearly
		# quieter than baseline but nowhere near the old near-mute -80dB mistake.
		if ducked_db >= -1.0 or ducked_db <= -40.0:
			printerr("FAIL 10-A: Ambient bus should be lowered (not silenced) while echo audio plays! Got: ", ducked_db)
			get_tree().quit(1)
			return

	ui_instance.toggle_echo_audio(test_audio)
	if ui_instance._audio_echo.playing:
		printerr("FAIL 9-E: Audio echo player should be stopped after toggle off!")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.35).timeout
	if ambient_bus_idx_9e != -1 and AudioServer.get_bus_volume_db(ambient_bus_idx_9e) < -1.0:
		printerr("FAIL 10-A: Ambient bus should fade back to baseline after echo audio stops!")
		get_tree().quit(1)
		return

	# Case A: Selection change does NOT stop audio
	ui_instance.toggle_echo_audio(test_audio)
	# focus 401
	for child in notebook_list.get_children():
		if child is Button and child.text.contains("401"):
			note_button_401 = child
			break
	note_button_401.grab_focus()
	await get_tree().process_frame
	if not ui_instance._audio_echo.playing:
		printerr("FAIL 9-E: Changing selected item should NOT stop audio playback!")
		get_tree().quit(1)
		return
	ui_instance.stop_echo_audio()

	# Case B: Tab change does NOT stop audio
	for child in notebook_list.get_children():
		if child is Button and child.text.contains("店員"):
			note_button_clerk = child
			break
	note_button_clerk.grab_focus()
	await get_tree().process_frame
	ui_instance.toggle_echo_audio(test_audio)
	ui_instance.notebook_panel._select_tab_index(0)
	await get_tree().process_frame
	if not ui_instance._audio_echo.playing:
		printerr("FAIL 9-E: Changing notebook tab should NOT stop audio playback!")
		get_tree().quit(1)
		return
	ui_instance.stop_echo_audio()

	# Case C: Closing notebook does NOT stop audio (it plays out fully in background)
	ui_instance.notebook_panel._select_tab_index(3)
	await get_tree().process_frame
	for child in notebook_list.get_children():
		if child is Button and child.text.contains("店員"):
			note_button_clerk = child
			break
	note_button_clerk.grab_focus()
	await get_tree().process_frame
	ui_instance.toggle_echo_audio(test_audio)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	if not ui_instance._audio_echo.playing:
		printerr("FAIL 9-E: Closing notebook mode should NOT stop audio playback!")
		get_tree().quit(1)
		return

	# Stop echo audio manually to clean up for subsequent tests
	ui_instance.stop_echo_audio()

	GameState.reset_for_new_game()
	print("PASS 9-E: Dynamic media control hints, photo viewer overlay input gating, and audio interruption behavior verified.")

	# ----------------------------------------------------

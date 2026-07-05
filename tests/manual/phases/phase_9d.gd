extends "res://tests/manual/phases/phase_9e.gd"

func _run_phase_9d() -> void:
	# Phase 9-D Verification
	# ----------------------------------------------------
	print("Running 9-D Integration tests...")

	# Instantiate EchoPoint
	var EchoPointClass = load("res://scripts/components/echo_point.gd")
	var ep = EchoPointClass.new()
	ep.echo_id = "echo_room401_tenant"
	ep.segment_id = "s1"
	add_child(ep)
	if ep.audio_player.stream == null:
		printerr("FAIL 9-D: EchoPoint proximity stream should be configured!")
		get_tree().quit(1)
		return
	if not ep.audio_player.stream is AudioStreamMP3:
		printerr("FAIL 9-D: EchoPoint proximity stream should use echo_presence_loop.mp3!")
		get_tree().quit(1)
		return
	var slot_sfx_stream := load("res://assets/sound/slot_electromagnetic.wav") as AudioStreamWAV
	if slot_sfx_stream and slot_sfx_stream.loop_mode != 0:
		printerr("FAIL 9-D: EchoPoint should not mutate slot_electromagnetic.wav into a loop!")
		get_tree().quit(1)
		return

	# Reset state
	GameState.reset_for_new_game()

	# 1. Verification of Gating & Proximity Sound Playback
	# Under Case A: glove not equipped, should be inactive
	ep._update_active_state()
	if ep.active:
		printerr("FAIL 9-D: EchoPoint should be inactive when gleaner_gloves is not equipped!")
		get_tree().quit(1)
		return
	if ep.audio_player.playing:
		printerr("FAIL 9-D: Proximity sound should not play when inactive!")
		get_tree().quit(1)
		return

	# Equip gleaner_gloves
	GameState.add_item("gleaner_gloves", 1)
	var gleaner_id := ""
	for slot in GameState.get_inventory():
		if not slot.is_empty() and slot.get("item_id") == "gleaner_gloves":
			gleaner_id = slot.get("instance_id", "")
			break
	GameState.equip(gleaner_id)

	# Update state, should become active
	ep._update_active_state()
	if not ep.active:
		printerr("FAIL 9-D: EchoPoint should be active when gleaner_gloves is equipped!")
		get_tree().quit(1)
		return
	if not ep.audio_player.playing:
		printerr("FAIL 9-D: Proximity sound should play when active!")
		get_tree().quit(1)
		return

	# 2. Verification of Proximity Dwell Timer (Static Player detection)
	var mock_player = CharacterBody2D.new()
	mock_player.name = "Player"
	mock_player.global_position = Vector2(0, 0)
	add_child(mock_player)

	var sig_tracker = {"entered": false, "exited": false}
	ep.player_entered.connect(func(_x): sig_tracker["entered"] = true)
	ep.player_exited.connect(func(_x): sig_tracker["exited"] = true)

	# Enter area
	ep._on_body_entered(mock_player)
	if not ep.player_inside:
		printerr("FAIL 9-D: player_inside should be true after entering body!")
		get_tree().quit(1)
		return

	# Process 0.5s (static), entered should not be emitted yet
	ep._process(0.5)
	if sig_tracker["entered"] or ep.dwell_timer != 0.5:
		printerr("FAIL 9-D: Dwell timer should accumulate but not trigger before 1 second!")
		get_tree().quit(1)
		return

	# Process 0.6s (total 1.1s static), entered should be emitted
	ep._process(0.6)
	if not sig_tracker["entered"] or not ep.has_emitted_entered:
		printerr("FAIL 9-D: player_entered should be emitted after 1 second of static dwell!")
		get_tree().quit(1)
		return

	# Simulate player movement (position change)
	mock_player.global_position = Vector2(20, 20)
	ep._process(0.1)
	if not sig_tracker["exited"] or ep.has_emitted_entered or ep.dwell_timer != 0.0:
		printerr("FAIL 9-D: player_exited should be emitted immediately upon player movement!")
		get_tree().quit(1)
		return

	# 3. Verification of collection mechanics
	# Return player to static and let it dwell for 1.1 seconds again
	sig_tracker["entered"] = false
	ep.last_player_position = mock_player.global_position
	ep._process(0.5)
	ep._process(0.6)
	if not sig_tracker["entered"] or not ep.has_emitted_entered:
		printerr("FAIL 9-D: failed to re-dwell player!")
		get_tree().quit(1)
		return

	# Call collect()
	ep.collect()
	var collect_sfx := get_tree().root.find_child("EchoCollectSFX", true, false)
	if collect_sfx == null or not collect_sfx is AudioStreamPlayer:
		printerr("FAIL 9-D: collect() should spawn EchoCollectSFX!")
		get_tree().quit(1)
		return
	if not (collect_sfx as AudioStreamPlayer).stream is AudioStreamMP3:
		printerr("FAIL 9-D: collect() should use echo_collect.mp3!")
		get_tree().quit(1)
		return
	collect_sfx.queue_free()

	# Verify GameState segment registered
	if not GameState.has_echo_segment("echo_room401_tenant", "s1"):
		printerr("FAIL 9-D: collect() did not register segment in GameState!")
		get_tree().quit(1)
		return

	# Verify EchoPoint deactivated automatically
	if ep.active:
		printerr("FAIL 9-D: EchoPoint should become inactive after collection!")
		get_tree().quit(1)
		return
	if ep.audio_player.playing:
		printerr("FAIL 9-D: Proximity sound should stop playing after collection!")
		get_tree().quit(1)
		return

	# Cleanup mock instances
	ep.free()
	mock_player.free()
	print("PASS 9-D: Proximity loop playback, static timer gating, and collection mechanics verified.")

	# ----------------------------------------------------

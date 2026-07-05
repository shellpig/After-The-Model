extends "res://tests/manual/phases/phase_13c.gd"

func _run_phase_13ab() -> void:
	# ===================== Phase 13-A: attack action + stun API =====================
	print("--- Phase 13-A: attack action + walker_01 stun API ---")

	if not InputMap.has_action("attack"):
		printerr("FAIL 13-A: InputMap action 'attack' is missing!")
		get_tree().quit(1)
		return
	print("PASS 13-A: InputMap action 'attack' exists.")

	var enemy_base_script = load("res://scripts/components/enemy_base.gd")
	if enemy_base_script == null:
		printerr("FAIL 13-A: could not load enemy_base.gd!")
		get_tree().quit(1)
		return
	print("PASS 13-A: enemy_base.gd loads.")

	var melee_stick_script = load("res://scripts/components/melee_stick.gd")
	if melee_stick_script == null:
		printerr("FAIL 13-A: could not load melee_stick.gd!")
		get_tree().quit(1)
		return
	print("PASS 13-A: melee_stick.gd loads.")

	var walker_scene_13 = load("res://scenes/actors/walker_01/walker_01.tscn")
	if walker_scene_13 == null:
		printerr("FAIL 13-A: could not load walker_01.tscn!")
		get_tree().quit(1)
		return
	var walker_inst_13 = walker_scene_13.instantiate()
	add_child(walker_inst_13)
	await get_tree().process_frame

	if not walker_inst_13.has_method("is_stunned"):
		printerr("FAIL 13-A: walker_01 missing is_stunned() method!")
		get_tree().quit(1)
		return
	if not walker_inst_13.has_method("apply_stun"):
		printerr("FAIL 13-A: walker_01 missing apply_stun() method!")
		get_tree().quit(1)
		return
	print("PASS 13-A: walker_01 has is_stunned() and apply_stun().")

	if "hp" in walker_inst_13:
		printerr("FAIL 13-A: walker_01 must not have 'hp' field (stun-only, no damage)!")
		get_tree().quit(1)
		return
	print("PASS 13-A: walker_01 has no 'hp' field.")

	if walker_inst_13.is_stunned():
		printerr("FAIL 13-A: walker_01 must not start in stunned state!")
		get_tree().quit(1)
		return
	print("PASS 13-A: is_stunned() == false in initial patrol state.")

	if not walker_inst_13.is_in_group("enemies"):
		printerr("FAIL 13-A: walker_01 must be in group 'enemies'!")
		get_tree().quit(1)
		return
	print("PASS 13-A: walker_01 is in group 'enemies'.")

	# Stun state machine: apply_stun -> FALL -> PRONE (is_stunned true)
	walker_inst_13.fall_time = 0.01
	var sched_13a: Array[float] = [99.0]
	walker_inst_13.repair_schedule = sched_13a
	walker_inst_13.apply_stun(99.0)
	for _f13 in range(10):
		await get_tree().process_frame
	if not walker_inst_13.is_stunned():
		printerr("FAIL 13-A: after apply_stun() + fall_time, is_stunned() must be true (PRONE)!")
		get_tree().quit(1)
		return
	print("PASS 13-A: is_stunned() == true in PRONE (self-repair window).")

	walker_inst_13.queue_free()
	await get_tree().process_frame

	# player has is_attacking(), signals, and MeleeStick child
	var p13_room_scene = load("res://scenes/levels/apartment/apartment_room.tscn")
	if p13_room_scene == null:
		printerr("FAIL 13-A: could not load apartment_room.tscn for player check!")
		get_tree().quit(1)
		return
	var p13_room = p13_room_scene.instantiate()
	add_child(p13_room)
	await get_tree().process_frame

	var p13_player = p13_room.find_child("Player", true, false)
	if p13_player == null:
		printerr("FAIL 13-A: Player not found in apartment_room!")
		get_tree().quit(1)
		return
	if not p13_player.has_method("is_attacking"):
		printerr("FAIL 13-A: player missing is_attacking() method!")
		get_tree().quit(1)
		return
	if not p13_player.has_signal("attack_impact_frame"):
		printerr("FAIL 13-A: player missing 'attack_impact_frame' signal!")
		get_tree().quit(1)
		return
	if not p13_player.has_signal("attack_completed"):
		printerr("FAIL 13-A: player missing 'attack_completed' signal!")
		get_tree().quit(1)
		return
	if not p13_player.has_node("MeleeStick"):
		printerr("FAIL 13-A: player missing MeleeStick child node!")
		get_tree().quit(1)
		return
	if not "attack_sound_path" in p13_player:
		printerr("FAIL 13-A: player missing 'attack_sound_path' property!")
		get_tree().quit(1)
		return
	if p13_player.attack_sound_path != "res://assets/sound/A_heavy_melee_weapon.mp3":
		printerr("FAIL 13-A: player 'attack_sound_path' is incorrect: ", p13_player.attack_sound_path)
		get_tree().quit(1)
		return
	if not FileAccess.file_exists(p13_player.attack_sound_path):
		printerr("FAIL 13-A: player 'attack_sound_path' file does not exist: ", p13_player.attack_sound_path)
		get_tree().quit(1)
		return
	print("PASS 13-A: player has is_attacking(), attack signals, MeleeStick, and valid attack_sound_path.")

	p13_room.queue_free()
	await get_tree().process_frame

	print("PASS: Phase 13-A attack action + stun API verified.")

	# -------------------------------------------------------------------------
	print("--- Phase 13-B: can_format + format_reset ---")

	var walker_scene_13b = load("res://scenes/actors/walker_01/walker_01.tscn")
	if walker_scene_13b == null:
		printerr("FAIL 13-B: could not load walker_01.tscn!")
		get_tree().quit(1)
		return
	var walker_13b = walker_scene_13b.instantiate()
	walker_13b.min_x = 0.0
	walker_13b.max_x = 2000.0
	walker_13b.fall_time = 0.01
	var sched_13b: Array[float] = [99.0]
	walker_13b.repair_schedule = sched_13b
	add_child(walker_13b)
	await get_tree().process_frame
	walker_13b.global_position = Vector2(500.0, 400.0)

	# can_format() method must exist
	if not walker_13b.has_method("can_format"):
		printerr("FAIL 13-B: walker_01 missing can_format() method!")
		get_tree().quit(1)
		return
	print("PASS 13-B: walker_01 has can_format() method.")

	# defeated() method must exist
	if not walker_13b.has_method("defeated"):
		printerr("FAIL 13-B: walker_01 missing defeated() method!")
		get_tree().quit(1)
		return
	print("PASS 13-B: walker_01 has defeated() method.")

	# Not stunned → can_format false regardless of position
	if walker_13b.can_format(Vector2(600.0, 400.0)):
		printerr("FAIL 13-B: can_format() must be false when not stunned!")
		get_tree().quit(1)
		return
	print("PASS 13-B: can_format() == false when not stunned.")

	# Enter stun (PRONE) state
	# 25-B 起敵人 _physics_process 在 UIMode != NONE 時凍結；先確保前置為 NONE，
	# 否則前面測試殘留的 UI mode 會擋住 FALL -> PRONE 狀態機推進。
	UIMode.set_mode(UIMode.Mode.NONE)
	walker_13b.apply_stun(99.0)
	for _f13b in range(10):
		await get_tree().process_frame
	if not walker_13b.is_stunned():
		printerr("FAIL 13-B: walker not stunned; cannot test can_format position logic!")
		get_tree().quit(1)
		return

	# Force facing right so tests are deterministic (_facing = 1 → behind = left side)
	walker_13b._facing = 1
	var behind_pos := Vector2(420.0, 400.0)   # dx = -80: behind, within 160
	var front_pos  := Vector2(580.0, 400.0)   # dx = +80: front, within 160
	var too_far    := Vector2(330.0, 400.0)   # dx = -170: behind but > 160px

	if walker_13b.can_format(front_pos):
		printerr("FAIL 13-B: can_format() must be false when player is in front!")
		get_tree().quit(1)
		return
	print("PASS 13-B: can_format() == false when player is in front (same side as facing).")

	if not walker_13b.can_format(behind_pos):
		printerr("FAIL 13-B: can_format() must be true when stunned + behind + within 160px!")
		get_tree().quit(1)
		return
	print("PASS 13-B: can_format() == true when stunned + player behind + within range.")

	if walker_13b.can_format(too_far):
		printerr("FAIL 13-B: can_format() must be false when player is beyond format_check_distance!")
		get_tree().quit(1)
		return
	print("PASS 13-B: can_format() == false when player behind but too far (> 160px).")

	# defeated() sets is_defeated = true and machine stays on scene
	walker_13b.defeated()
	await get_tree().process_frame
	if not walker_13b.is_defeated():
		printerr("FAIL 13-B: is_defeated() must be true after defeated() is called!")
		get_tree().quit(1)
		return
	if not is_instance_valid(walker_13b):
		printerr("FAIL 13-B: machine must remain on scene after defeated() (no despawn)!")
		get_tree().quit(1)
		return
	var walker_13b_anim = walker_13b.get_node_or_null("AnimatedSprite2D")
	if walker_13b_anim == null or walker_13b_anim.animation != "formatted":
		printerr("FAIL 13-B: defeated walker_01 must switch to formatted animation!")
		get_tree().quit(1)
		return
	print("PASS 13-B: defeated() → is_defeated() true; machine stays on scene.")

	# defeated() is idempotent (calling twice must not crash)
	walker_13b.defeated()
	await get_tree().process_frame
	print("PASS 13-B: defeated() is idempotent (double call safe).")

	# can_format returns false on a defeated machine (stopped, not to be formatted again)
	# is_stunned() may still be true (frozen in prone), but defeated guard takes priority
	# in practice the format_reset checks is_instance_valid and calling defeated() again is no-op
	# Verify player has FormatReset child
	walker_13b.queue_free()
	await get_tree().process_frame

	var jump_proto_scene_13b = load("res://scenes/levels/jump_proto/jump_proto.tscn")
	if jump_proto_scene_13b == null:
		printerr("FAIL 13-B: could not load jump_proto.tscn!")
		get_tree().quit(1)
		return
	var jump_proto_13b = jump_proto_scene_13b.instantiate()
	add_child(jump_proto_13b)
	await get_tree().process_frame
	var jump_walker_13b = jump_proto_13b.find_child("Walker01", true, false)
	var jump_walker_anim_13b = jump_walker_13b.get_node_or_null("AnimatedSprite2D") if jump_walker_13b else null
	if jump_walker_anim_13b == null or jump_walker_anim_13b.sprite_frames == null or not jump_walker_anim_13b.sprite_frames.has_animation("formatted"):
		printerr("FAIL 13-B: jump_proto Walker01 missing formatted animation!")
		get_tree().quit(1)
		return
	jump_walker_13b.defeated()
	await get_tree().process_frame
	if jump_walker_anim_13b.animation != "formatted":
		printerr("FAIL 13-B: jump_proto Walker01 must show formatted animation after defeated()!")
		get_tree().quit(1)
		return
	jump_proto_13b.queue_free()
	await get_tree().process_frame
	print("PASS 13-B: jump_proto Walker01 uses formatted animation after defeated().")

	var p13b_room_scene = load("res://scenes/levels/apartment/apartment_room.tscn")
	if p13b_room_scene == null:
		printerr("FAIL 13-B: could not load apartment_room.tscn for FormatReset check!")
		get_tree().quit(1)
		return
	var p13b_room = p13b_room_scene.instantiate()
	add_child(p13b_room)
	await get_tree().process_frame
	var p13b_player = p13b_room.find_child("Player", true, false)
	if p13b_player == null:
		printerr("FAIL 13-B: Player not found in apartment_room!")
		get_tree().quit(1)
		return
	if not p13b_player.has_node("FormatReset"):
		printerr("FAIL 13-B: Player missing FormatReset child node!")
		get_tree().quit(1)
		return
	print("PASS 13-B: Player has FormatReset child node.")

	var fmt_node = p13b_player.get_node("FormatReset")
	if not fmt_node.has_method("get_format_progress"):
		printerr("FAIL 13-B: FormatReset missing get_format_progress() method!")
		get_tree().quit(1)
		return
	if fmt_node.get_format_progress() != 0.0:
		printerr("FAIL 13-B: FormatReset.get_format_progress() must start at 0.0!")
		get_tree().quit(1)
		return
	print("PASS 13-B: FormatReset starts at progress 0.0.")

	p13b_room.queue_free()
	await get_tree().process_frame

	print("PASS: Phase 13-B format (can_format + defeated + FormatReset) verified.")


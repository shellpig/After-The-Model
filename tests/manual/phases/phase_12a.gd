extends "res://tests/manual/phases/phase_12b.gd"

func _run_phase_12a() -> void:
	# Phase 12-A: 跳躍地基（jump action + player 拋物弧 + 不退化）
	# ============================================================
	if not InputMap.has_action("jump"):
		printerr("FAIL 12-A: InputMap action 'jump' is missing!")
		get_tree().quit(1)
		return
	print("PASS 12-A: InputMap action 'jump' exists.")

	GameState.reset_for_new_game()
	UIMode.set_mode(UIMode.Mode.NONE)
	var p12_scene = load("res://scenes/levels/apartment/apartment_room.tscn")
	if p12_scene == null:
		printerr("FAIL 12-A: could not load apartment_room.tscn for jump test!")
		get_tree().quit(1)
		return
	var p12_inst = p12_scene.instantiate()
	add_child(p12_inst)
	await get_tree().process_frame

	var p12_player = p12_inst.get_node_or_null("Player")
	if p12_player == null:
		for c in p12_inst.get_children():
			if c.has_method("is_jumping"):
				p12_player = c
				break
	if p12_player == null or not p12_player.has_method("is_jumping"):
		printerr("FAIL 12-A: player exposing is_jumping() not found!")
		get_tree().quit(1)
		return
	print("PASS 12-A: player exposes is_jumping().")

	for prop in ["jump_height", "jump_duration", "air_speed_scale"]:
		if p12_player.get(prop) == null:
			printerr("FAIL 12-A: player missing jump param '%s'!" % prop)
			get_tree().quit(1)
			return
	print("PASS 12-A: jump params exist (jump_height / jump_duration / air_speed_scale).")

	var p12_anim = p12_player.get_node_or_null("AnimatedSprite2D")
	if p12_anim == null or p12_anim.sprite_frames == null or not p12_anim.sprite_frames.has_animation("jump"):
		printerr("FAIL 12-A: SpriteFrames missing 'jump' animation!")
		get_tree().quit(1)
		return
	if p12_anim.sprite_frames.get_animation_loop("jump"):
		printerr("FAIL 12-A: 'jump' animation must be non-looping (loop=false)!")
		get_tree().quit(1)
		return
	print("PASS 12-A: 'jump' animation present and non-looping.")

	# 起跳 → 滯空（離開 walk line）→ 落回 walk line；驗證座標 / climb 不退化
	UIMode.set_mode(UIMode.Mode.NONE)
	p12_player.snap_to_walk_line()
	var p12_x_before: float = p12_player.get_save_x()
	var p12_walk_y: float = p12_player._walk_y_at(p12_player.global_position.x)
	if p12_player.is_jumping():
		printerr("FAIL 12-A: player must not start in jumping state!")
		get_tree().quit(1)
		return
	Input.action_press("jump")
	p12_player._physics_process(1.0 / 60.0)
	Input.action_release("jump")
	if not p12_player.is_jumping():
		printerr("FAIL 12-A: player did not enter jump state after 'jump' pressed!")
		get_tree().quit(1)
		return
	if p12_player.global_position.y >= p12_walk_y:
		printerr("FAIL 12-A: airborne player should be above walk line! y=", p12_player.global_position.y, " walk_y=", p12_walk_y)
		get_tree().quit(1)
		return
	var p12_guard := 0
	while p12_player.is_jumping() and p12_guard < 600:
		p12_player._physics_process(1.0 / 60.0)
		p12_guard += 1
	if p12_player.is_jumping():
		printerr("FAIL 12-A: jump never landed within airtime!")
		get_tree().quit(1)
		return
	if abs(p12_player.global_position.y - p12_player._walk_y_at(p12_player.global_position.x)) > 1.0:
		printerr("FAIL 12-A: after landing, player not back on walk line!")
		get_tree().quit(1)
		return
	if p12_player.get_save_x() != p12_x_before:
		printerr("FAIL 12-A: stationary jump changed save-x! before=", p12_x_before, " after=", p12_player.get_save_x())
		get_tree().quit(1)
		return
	if p12_player.is_climbing():
		printerr("FAIL 12-A: jump must not engage climb_mode!")
		get_tree().quit(1)
		return
	print("PASS 12-A: takeoff -> airborne -> land keeps walk-line / save-x / climb invariants.")

	# 無二段跳：空中再次按 jump 不重啟拋物弧（_jump_t 持續累加，不歸零）
	Input.action_press("jump")
	p12_player._physics_process(1.0 / 60.0)
	Input.action_release("jump")
	if not p12_player.is_jumping():
		printerr("FAIL 12-A: jump did not start for double-jump check!")
		get_tree().quit(1)
		return
	for _i in range(5):
		p12_player._physics_process(1.0 / 60.0)
	var p12_t1: float = p12_player._jump_t
	Input.action_press("jump")
	p12_player._physics_process(1.0 / 60.0)
	Input.action_release("jump")
	var p12_t2: float = p12_player._jump_t
	if p12_t2 <= p12_t1:
		printerr("FAIL 12-A: double jump restarted the arc! t1=", p12_t1, " t2=", p12_t2)
		get_tree().quit(1)
		return
	print("PASS 12-A: no double-jump (airborne jump press does not restart arc).")
	p12_guard = 0
	while p12_player.is_jumping() and p12_guard < 600:
		p12_player._physics_process(1.0 / 60.0)
		p12_guard += 1

	p12_inst.free()
	await get_tree().process_frame
	p12_scene = null
	GameState.reset_for_new_game()
	UIMode.set_mode(UIMode.Mode.NONE)
	print("PASS: Phase 12-A jump foundation verified.")


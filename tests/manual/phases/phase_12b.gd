extends "res://tests/manual/phases/phase_12c.gd"

func _run_phase_12b() -> void:
	# ===================== Phase 12-B: Platform components + jump_proto =====================
	print("--- Phase 12-B: ledge_area / jump_gap / jump_proto ---")

	var p12b_scene = load("res://scenes/levels/jump_proto/jump_proto.tscn")
	if not p12b_scene:
		printerr("FAIL 12-B: Could not load jump_proto.tscn!")
		get_tree().quit(1)
		return
	print("PASS 12-B: jump_proto.tscn loaded.")

	var p12b_inst = p12b_scene.instantiate()
	add_child(p12b_inst)
	await get_tree().process_frame

	# LedgeArea node + API
	var ledge_node = p12b_inst.find_child("LedgeArea", true, false)
	if not ledge_node:
		printerr("FAIL 12-B: LedgeArea node not found in jump_proto!")
		get_tree().quit(1)
		return
	if not ledge_node.has_method("contains_x"):
		printerr("FAIL 12-B: LedgeArea missing contains_x() method!")
		get_tree().quit(1)
		return
	if not ledge_node.has_method("get_target_y"):
		printerr("FAIL 12-B: LedgeArea missing get_target_y() method!")
		get_tree().quit(1)
		return
	print("PASS 12-B: LedgeArea has contains_x() and get_target_y() APIs.")

	# contains_x logic: center should be inside, x=0 should be outside
	var ledge_cx: float = ledge_node.global_position.x
	if not ledge_node.contains_x(ledge_cx):
		printerr("FAIL 12-B: contains_x(center=", ledge_cx, ") returned false!")
		get_tree().quit(1)
		return
	if ledge_node.contains_x(0.0):
		printerr("FAIL 12-B: contains_x(0) returned true — ledge spans entire viewport!")
		get_tree().quit(1)
		return
	print("PASS 12-B: contains_x() inside/outside logic correct.")

	# get_target_y must be above the player's starting walk line (lower y = higher on screen)
	var ledge_ty: float = ledge_node.get_target_y()
	var p12b_player = p12b_inst.find_child("Player", true, false)
	var lower_walk_y: float = p12b_player.walk_line_y if p12b_player else 690.0
	if ledge_ty >= lower_walk_y:
		printerr("FAIL 12-B: ledge target_y (", ledge_ty, ") must be above lower walk line (", lower_walk_y, ")!")
		get_tree().quit(1)
		return
	print("PASS 12-B: ledge target_y (", ledge_ty, ") is above lower walk line (", lower_walk_y, ").")

	# LedgeArea must be in group "ledges" (player grabs via this group)
	if not ledge_node.is_in_group("ledges"):
		printerr("FAIL 12-B: LedgeArea is not in group 'ledges'!")
		get_tree().quit(1)
		return
	print("PASS 12-B: LedgeArea is in group 'ledges'.")

	# GapMarker node + properties
	var gap_node = p12b_inst.find_child("GapMarker", true, false)
	if not gap_node:
		printerr("FAIL 12-B: GapMarker node not found in jump_proto!")
		get_tree().quit(1)
		return
	if not ("gap_x_min" in gap_node and "gap_x_max" in gap_node):
		printerr("FAIL 12-B: GapMarker missing gap_x_min/gap_x_max properties!")
		get_tree().quit(1)
		return
	print("PASS 12-B: GapMarker has gap_x_min/gap_x_max properties.")

	p12b_inst.queue_free()
	await get_tree().process_frame
	p12b_scene = null
	print("PASS: Phase 12-B platform components + jump_proto verified.")


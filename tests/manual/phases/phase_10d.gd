extends "res://tests/manual/phases/phase_11.gd"

func _run_phase_10d() -> void:
	# 10-D. Verify NpcWan AnimatedSprite2D and IdleBreak node
	print("Verifying Phase 10-D NpcWan idle break...")
	var npc_wan_anim = street_instance.get_node_or_null("Interactables/NpcWan/AnimatedSprite2D")
	if not npc_wan_anim:
		printerr("FAIL 10-D: NpcWan/AnimatedSprite2D not found!")
		get_tree().quit(1)
		return
	if not npc_wan_anim.sprite_frames \
			or not npc_wan_anim.sprite_frames.has_animation("idle") \
			or not npc_wan_anim.sprite_frames.has_animation("idle_glance"):
		printerr("FAIL 10-D: NpcWan AnimatedSprite2D missing 'idle' or 'idle_glance' animation!")
		get_tree().quit(1)
		return
	var idle_break_node = street_instance.get_node_or_null("Interactables/NpcWan/IdleBreak")
	if not idle_break_node:
		printerr("FAIL 10-D: NpcWan/IdleBreak node not found!")
		get_tree().quit(1)
		return
	print("PASS: Phase 10-D NpcWan AnimatedSprite2D and IdleBreak verified.")


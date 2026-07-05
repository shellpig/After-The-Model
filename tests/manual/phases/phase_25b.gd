extends "res://tests/manual/phases/phase_25c.gd"

func _run_phase_25b() -> void:
	# ===================== Phase 25-B: 戰鬥③（低階保全，跑到門） =====================
	print("--- Phase 25-B: 戰鬥③ 混合敵人 + 跑到門 ---")

	var backup_scene_phase25b = load("res://scenes/levels/datacenter_backup/datacenter_backup.tscn")
	var backup_inst_phase25b = backup_scene_phase25b.instantiate()
	add_child(backup_inst_phase25b)
	await get_tree().process_frame

	var sentinel_phase25b = backup_inst_phase25b.find_child("RackSentinel", true, false)
	if sentinel_phase25b == null:
		printerr("FAIL 25-B: datacenter_backup missing RackSentinel node!")
		get_tree().quit(1)
		return
	print("PASS 25-B: datacenter_backup has RackSentinel node.")

	var guard_phase25b = backup_inst_phase25b.find_child("SecurityGuard", true, false)
	if guard_phase25b == null:
		printerr("FAIL 25-B: datacenter_backup missing SecurityGuard node!")
		get_tree().quit(1)
		return
	print("PASS 25-B: datacenter_backup has SecurityGuard node.")

	var backup_player_phase25b = backup_inst_phase25b.find_child("Player", true, false)
	if backup_player_phase25b == null or not backup_player_phase25b.combat_mode:
		printerr("FAIL 25-B: datacenter_backup Player must have combat_mode == true!")
		get_tree().quit(1)
		return
	print("PASS 25-B: datacenter_backup Player has combat_mode == true.")

	# 1. 機器哨兵：is_stunned/apply_stun/can_format 沿用 Phase 13 machine 契約
	if sentinel_phase25b.is_stunned():
		printerr("FAIL 25-B: RackSentinel must not start stunned!")
		get_tree().quit(1)
		return
	if not sentinel_phase25b.is_in_group("enemies"):
		printerr("FAIL 25-B: RackSentinel must be in group 'enemies'!")
		get_tree().quit(1)
		return

	sentinel_phase25b.apply_stun(5.0)
	if not sentinel_phase25b.is_stunned():
		printerr("FAIL 25-B: RackSentinel should be stunned after apply_stun()!")
		get_tree().quit(1)
		return

	sentinel_phase25b._facing = 1 # facing right
	var behind_pos_phase25b: Vector2 = sentinel_phase25b.global_position + Vector2(-50.0, 0.0)
	var front_pos_phase25b: Vector2 = sentinel_phase25b.global_position + Vector2(50.0, 0.0)
	if not sentinel_phase25b.can_format(behind_pos_phase25b):
		printerr("FAIL 25-B: RackSentinel.can_format() must be true when stunned + player behind!")
		get_tree().quit(1)
		return
	if sentinel_phase25b.can_format(front_pos_phase25b):
		printerr("FAIL 25-B: RackSentinel.can_format() must be false when player is in front (same side as facing)!")
		get_tree().quit(1)
		return
	print("PASS 25-B: RackSentinel.can_format() true behind while stunned, false in front.")

	sentinel_phase25b.defeated()
	if not sentinel_phase25b.is_defeated():
		printerr("FAIL 25-B: RackSentinel.defeated() must set is_defeated() true!")
		get_tree().quit(1)
		return
	if sentinel_phase25b.can_format(behind_pos_phase25b):
		printerr("FAIL 25-B: a defeated RackSentinel must not be re-formattable!")
		get_tree().quit(1)
		return
	print("PASS 25-B: RackSentinel.defeated() clears via format_reset contract, stays cleared.")

	# 2. 人類保全：can_format 恆 false、apply_stun no-op（不可殺 / 不可格式化）
	if guard_phase25b.can_format(guard_phase25b.global_position + Vector2(-50.0, 0.0)):
		printerr("FAIL 25-B: SecurityGuard.can_format() must always return false!")
		get_tree().quit(1)
		return
	guard_phase25b.apply_stun(5.0)
	if guard_phase25b.is_stunned() or guard_phase25b.is_defeated():
		printerr("FAIL 25-B: SecurityGuard must never be stunned or defeated (apply_stun is no-op)!")
		get_tree().quit(1)
		return
	if not guard_phase25b.is_in_group("enemies"):
		printerr("FAIL 25-B: SecurityGuard must be in group 'enemies'!")
		get_tree().quit(1)
		return
	print("PASS 25-B: SecurityGuard can_format()==false and apply_stun() is a no-op.")

	# 3. 人類保全最小追擊：朝玩家 x 移動（唯一新做的 AI）
	# 敵人 _physics_process 在 UIMode != NONE 時凍結；先確保前置為 NONE。
	UIMode.set_mode(UIMode.Mode.NONE)
	guard_phase25b.global_position = Vector2(3300.0, 800.0)
	backup_player_phase25b.global_position = Vector2(2800.0, 800.0)
	var guard_x_before_phase25b: float = guard_phase25b.global_position.x
	guard_phase25b._physics_process(0.5)
	if not (guard_phase25b.global_position.x < guard_x_before_phase25b):
		printerr("FAIL 25-B: SecurityGuard should chase toward a player x that is to its left!")
		get_tree().quit(1)
		return
	print("PASS 25-B: SecurityGuard minimal chase AI moves toward the player's x.")

	# 4. 碰撞 = knockback / stagger，無失敗態（不設任何 combat_loss 旗標 / 不 Game Over）
	backup_player_phase25b.global_position = Vector2(2800.0, 690.0)
	backup_player_phase25b.walk_line_y = 690.0
	if backup_player_phase25b.is_staggered():
		printerr("FAIL 25-B: Player should not start staggered!")
		get_tree().quit(1)
		return
	var px_before_phase25b: float = backup_player_phase25b.global_position.x
	guard_phase25b._on_contact_entered(backup_player_phase25b)
	if not backup_player_phase25b.is_staggered():
		printerr("FAIL 25-B: SecurityGuard contact should stagger the player!")
		get_tree().quit(1)
		return
	if backup_player_phase25b.global_position.x == px_before_phase25b:
		printerr("FAIL 25-B: SecurityGuard contact should knock the player back along x!")
		get_tree().quit(1)
		return
	print("PASS 25-B: SecurityGuard contact staggers + knocks back the player (no failure flag).")

	# 4b. UI 開啟（背包 / 筆記等）時保全凍結，不得追擊位移（比照 player 的 UIMode 凍結）
	UIMode.set_mode(UIMode.Mode.INVENTORY)
	guard_phase25b.global_position = Vector2(3300.0, 800.0)
	backup_player_phase25b.global_position = Vector2(2800.0, 690.0)
	var guard_x_ui_frozen_phase25b: float = guard_phase25b.global_position.x
	guard_phase25b._physics_process(0.5)
	if guard_phase25b.global_position.x != guard_x_ui_frozen_phase25b:
		printerr("FAIL 25-B: SecurityGuard must freeze (no chase) while a UI mode is open!")
		get_tree().quit(1)
		return
	UIMode.set_mode(UIMode.Mode.NONE)
	print("PASS 25-B: SecurityGuard freezes while UI is open (no chase displacement).")

	# 4c. knockback 直接取消跳躍 / 攻擊狀態（stagger 結束後不得隱形續播弧線 / 揮擊）
	backup_player_phase25b._staggered = false
	backup_player_phase25b._stagger_t = 0.0
	backup_player_phase25b._jumping = true
	backup_player_phase25b._jump_t = 0.2
	backup_player_phase25b._attacking = true
	backup_player_phase25b._attack_t = 0.3
	backup_player_phase25b.apply_knockback(1.0, 90.0, 0.5)
	if backup_player_phase25b.is_jumping() or backup_player_phase25b.is_attacking():
		printerr("FAIL 25-B: apply_knockback must cancel in-flight jump / attack state!")
		get_tree().quit(1)
		return
	if not backup_player_phase25b.is_staggered():
		printerr("FAIL 25-B: apply_knockback should still stagger the player when cancelling jump / attack!")
		get_tree().quit(1)
		return
	backup_player_phase25b._staggered = false
	backup_player_phase25b._stagger_t = 0.0
	print("PASS 25-B: apply_knockback cancels in-flight jump / attack state.")

	# 5. 勝利條件：抵達右端門 x → 轉場核心（沿用既有 exit_to_core interactable，見 25-A）
	var exit_to_core_phase25b = backup_inst_phase25b.get_node("Interactables/ExitToCoreArea")
	backup_inst_phase25b.current_interactable = exit_to_core_phase25b
	var captured_win_trans_phase25b: Dictionary = {}
	backup_inst_phase25b.scene_transition_requested.connect(func(scene_id, entry_point_id, payload):
		captured_win_trans_phase25b.merge({"scene": scene_id, "entry": entry_point_id}, true)
	)
	backup_inst_phase25b._trigger_interaction()
	if captured_win_trans_phase25b.get("scene", "") != "datacenter_backup_core" or captured_win_trans_phase25b.get("entry", "") != "from_backup":
		printerr("FAIL 25-B: reaching the right-end door must transition to datacenter_backup_core:from_backup regardless of enemy state!")
		get_tree().quit(1)
		return
	print("PASS 25-B: reaching the right-end door wins the corridor (no kill requirement).")

	# 6. 禁存：戰鬥廊道 can_save_here=false（沿用 7-F 慣例，25-A 已設）
	if SaveSystem.can_save_here:
		printerr("FAIL 25-B: datacenter_backup must keep can_save_here == false during combat!")
		get_tree().quit(1)
		return
	print("PASS 25-B: datacenter_backup keeps can_save_here == false.")

	backup_inst_phase25b.free()
	await get_tree().process_frame

	# 6b. 離開戰鬥廊道進核心：can_save_here 恢復 true（core _ready 設定）
	var core_save_inst_phase25b = load("res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn").instantiate()
	add_child(core_save_inst_phase25b)
	await get_tree().process_frame
	if not SaveSystem.can_save_here:
		printerr("FAIL 25-B: entering datacenter_backup_core must restore can_save_here == true!")
		get_tree().quit(1)
		return
	print("PASS 25-B: datacenter_backup_core restores can_save_here == true.")
	core_save_inst_phase25b.free()
	await get_tree().process_frame

	# 7. 非戰鬥場景：attack 無副作用（combat_mode 預設 false，apartment 房間攻擊鍵不觸發攻擊）
	var apt_main_phase25b = load("res://scenes/main/main.tscn").instantiate()
	add_child(apt_main_phase25b)
	await get_tree().process_frame
	apt_main_phase25b.transition_to("apartment", "wake_bed")
	await get_tree().process_frame
	var apt_player_phase25b = apt_main_phase25b.find_child("Player", true, false)
	if apt_player_phase25b == null or apt_player_phase25b.combat_mode:
		printerr("FAIL 25-B: apartment Player must keep combat_mode == false (non-combat scene)!")
		get_tree().quit(1)
		return
	apt_player_phase25b._attacking = false
	Input.action_press("attack")
	apt_player_phase25b._physics_process(0.016)
	Input.action_release("attack")
	if apt_player_phase25b.is_attacking():
		printerr("FAIL 25-B: attack must have no effect outside a combat_mode scene!")
		get_tree().quit(1)
		return
	print("PASS 25-B: attack has no effect in a non-combat scene.")
	if is_instance_valid(apt_main_phase25b):
		apt_main_phase25b.free()
	await get_tree().process_frame

	print("PASS: Phase 25-B combat corridor (machine sentinel + human guard chase + run-to-door win + no failure state) verified.")


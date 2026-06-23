# res://scenes/levels/tunnel_combat/tunnel_combat.gd
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

const CAMERA_HALF_WIDTH := 640.0
const CAMERA_Y := 536.0 # 896 - 360
const MAP_WIDTH := 4768.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var walker: CharacterBody2D = $Walker01
@onready var loot_box: Area2D = $Interactables/LootBoxArea

var current_interactable: Area2D = null
var nearby_interactables: Array[Area2D] = []
var _entry_point_id: String = "from_settlement"
var _entry_payload: Dictionary = {}

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	_entry_point_id = entry_point_id if not entry_point_id.is_empty() else "from_settlement"
	_entry_payload = payload.duplicate(true)

func set_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	prepare_entry_point(entry_point_id, payload)
	var spawn := $SpawnPoints.get_node_or_null(_entry_point_id) as Marker2D
	if spawn != null:
		player.global_position = spawn.global_position
	player.anim.play("combat_idle")
	_update_camera()

func _ready() -> void:
	SaveSystem.can_save_here = false
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.has_method("play_bgm"):
		main.play_bgm("res://assets/bgm/The Deleted Still Breathe.mp3")

	for interactable in $Interactables.get_children():
		interactable.player_entered.connect(_on_interactable_entered)
		interactable.player_exited.connect(_on_interactable_exited)
	
	player.anim.play("combat_idle")
	_refresh_current_interactable()

func _process(delta: float) -> void:
	_update_camera()

	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	_refresh_current_interactable()

	# Poll walker defeated state to set game state flag
	if is_instance_valid(walker) and walker.is_defeated():
		if not GameState.get_flag("tunnel_machine_defeated", false):
			GameState.set_flag("tunnel_machine_defeated", true)
			_refresh_current_interactable() # prompt changes from examine to loot

	if DisplayServer.get_name() == "headless":
		if current_interactable != null and Input.is_action_just_pressed("interact_primary"):
			_trigger_interaction()

func _unhandled_input(event: InputEvent) -> void:
	if UIMode.get_mode() != UIMode.Mode.NONE:
		return

	_refresh_current_interactable()
	if current_interactable == null:
		return

	if event.is_action_pressed("interact_primary"):
		get_viewport().set_input_as_handled()
		_trigger_interaction()

func _trigger_interaction() -> void:
	match current_interactable.interaction_id:
		"exit_to_settlement":
			scene_transition_requested.emit("underground_settlement_right", "from_deep_tunnel", {})
		"loot_box":
			if not GameState.get_flag("tunnel_machine_defeated", false):
				interaction_requested.emit({
					"type": "message",
					"message_text": "清潔機還在運轉，此時強行靠近太危險了。"
				})
			elif GameState.has_item("childcare_supply_receipt"):
				interaction_requested.emit({
					"type": "message",
					"message_text": "失物物流箱裡只剩下一堆廢棄包裝和被壓扁的鐵罐。"
				})
			else:
				# Attempt to add childcare_supply_receipt
				if GameState.add_item("childcare_supply_receipt"):
					interaction_requested.emit({
						"type": "message",
						"message_text": "你在雜亂的物流箱夾層中，翻到了一張沾有油漬的單據。\n上面印著模糊的代碼，這大概就是你要找的遺物了。\n（獲得了「兒少照護補給回執」。）"
					})
				else:
					# Backpack is full
					interaction_requested.emit({
						"type": "toast",
						"message_text": "背包空間不足，無法放入。"
					})

func _update_camera() -> void:
	if camera == null:
		return
	camera.global_position = Vector2(
		clamp(player.global_position.x, CAMERA_HALF_WIDTH, MAP_WIDTH - CAMERA_HALF_WIDTH),
		CAMERA_Y
	)

func _on_interactable_entered(interactable: Area2D) -> void:
	if not nearby_interactables.has(interactable):
		nearby_interactables.append(interactable)
	_refresh_current_interactable()

func _on_interactable_exited(interactable: Area2D) -> void:
	nearby_interactables.erase(interactable)
	_refresh_current_interactable()

func _refresh_current_interactable() -> void:
	var closest_interactable := _get_closest_interactable()
	if current_interactable == closest_interactable:
		return

	current_interactable = closest_interactable

	if current_interactable == null:
		current_interactable_changed.emit({})
	else:
		var prompt = current_interactable.prompt_text
		if current_interactable.interaction_id == "loot_box":
			if not GameState.get_flag("tunnel_machine_defeated", false):
				prompt = "E: █ 查看失物物流箱"
			elif GameState.has_item("childcare_supply_receipt"):
				prompt = "E: █ 查看空箱子"
			else:
				prompt = "E: █ 搜索失物物流箱"
		current_interactable_changed.emit({
			"prompt_text": prompt
		})

func _get_closest_interactable() -> Area2D:
	var closest_interactable: Area2D = null
	var closest_distance := INF
	var player_position := player.global_position

	for interactable in nearby_interactables:
		if not is_instance_valid(interactable):
			continue

		var distance := player_position.distance_squared_to(_get_interactable_position(interactable))
		if distance < closest_distance:
			closest_distance = distance
			closest_interactable = interactable

	return closest_interactable

func _get_interactable_position(interactable: Area2D) -> Vector2:
	var collision_shape := interactable.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		return collision_shape.global_position

	return interactable.global_position

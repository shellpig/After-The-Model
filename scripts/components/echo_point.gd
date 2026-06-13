# res://scripts/components/echo_point.gd
extends Area2D

signal player_entered(interactable: Area2D)
signal player_exited(interactable: Area2D)

@export var echo_id: String
@export var segment_id: String
@export var prompt_text: String = "E: █ 採集殘響"

var interaction_id: String = "collect_echo"
var message_id: String = ""
var note_id: String = ""
var dialogue_id: String = ""

var active: bool = false
var dwell_timer: float = 0.0
var player_inside: bool = false
var player_node: Node2D = null
var last_player_position: Vector2 = Vector2.ZERO
var has_emitted_entered: bool = false

var audio_player: AudioStreamPlayer2D = null

const PRESENCE_LOOP_PATH := "res://assets/sound/echo_presence_loop.mp3"
const COLLECT_SFX_PATH := "res://assets/sound/echo_collect.mp3"

func _ready() -> void:
	# Configure Area2D collision properties
	collision_layer = 0
	collision_mask = 1 # Match player layer
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create and setup AudioStreamPlayer2D
	audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "NoisePlayer2D"
	var noise_stream = load(PRESENCE_LOOP_PATH)
	if noise_stream:
		noise_stream = noise_stream.duplicate()
		if "loop" in noise_stream:
			noise_stream.loop = true
		elif noise_stream is AudioStreamWAV:
			noise_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		audio_player.stream = noise_stream
	audio_player.max_distance = 200.0
	audio_player.attenuation = 2.0
	audio_player.volume_db = 2.0
	audio_player.autoplay = false
	add_child(audio_player)
	
	# Connect GameState signals for state re-evaluation
	if GameState.has_signal("equipment_changed"):
		GameState.equipment_changed.connect(_update_active_state)
	if GameState.has_signal("echo_changed"):
		GameState.echo_changed.connect(func(_id): _update_active_state())
	if GameState.has_signal("inventory_changed"):
		GameState.inventory_changed.connect(_update_active_state)
		
	_update_active_state()

func _update_active_state() -> void:
	var was_active = active
	var is_equipped = GameState.is_item_equipped("gleaner_gloves")
	var is_collected = GameState.has_echo_segment(echo_id, segment_id)
	
	active = is_equipped and not is_collected
	
	if active != was_active:
		if active:
			monitoring = true
			monitorable = true
			if audio_player and not audio_player.playing:
				audio_player.play()
		else:
			monitoring = false
			monitorable = false
			if audio_player and audio_player.playing:
				audio_player.stop()
			
			# Clean up prompt/state immediately if we deactivate
			dwell_timer = 0.0
			player_inside = false
			player_node = null
			if has_emitted_entered:
				player_exited.emit(self)
				has_emitted_entered = false
		queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	if body.name == "Player":
		player_inside = true
		player_node = body
		last_player_position = body.global_position
		dwell_timer = 0.0

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = false
		player_node = null
		dwell_timer = 0.0
		if has_emitted_entered:
			player_exited.emit(self)
			has_emitted_entered = false

func _process(delta: float) -> void:
	if not active:
		return
		
	queue_redraw()
	
	if player_inside and is_instance_valid(player_node):
		var is_static = true
		# Check movement inputs
		if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or \
		   Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
			is_static = false
		# Check exact position changes
		if last_player_position.distance_squared_to(player_node.global_position) > 0.01:
			is_static = false
			
		last_player_position = player_node.global_position
		
		if is_static:
			dwell_timer += delta
			if dwell_timer >= 1.0 and not has_emitted_entered:
				player_entered.emit(self)
				has_emitted_entered = true
		else:
			dwell_timer = 0.0
			if has_emitted_entered:
				player_exited.emit(self)
				has_emitted_entered = false

func _unhandled_input(event: InputEvent) -> void:
	if not active or not has_emitted_entered:
		return
		
	var level = get_parent().get_parent()
	if level and level.get("current_interactable") == self:
		if event.is_action_pressed("interact_primary"):
			get_viewport().set_input_as_handled()
			collect()

func collect() -> void:
	if not active:
		return
		
	# Perform atomic state change
	var success = GameState.collect_echo_segment(echo_id, segment_id)
	if not success:
		return
		
	# Play collection success SFX
	var sfx = AudioStreamPlayer.new()
	sfx.name = "EchoCollectSFX"
	sfx.stream = load(COLLECT_SFX_PATH)
	sfx.volume_db = 4.0
	get_tree().root.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	
	# Show notification toast
	var echo_data = EchoDB.get_echo(echo_id)
	var title = echo_data.get("title", "未知殘響")
	var collected_count = GameState.get_collected_segment_count(echo_id)
	var total_count = EchoDB.get_segment_count(echo_id)
	var toast_text = "殘響已記錄：%s (%d/%d)" % [title, collected_count, total_count]
	
	var main = get_tree().root.find_child("Main", true, false)
	var game_ui = main.get_node("GameUI") if main else null
	if game_ui and game_ui.has_method("show_toast"):
		game_ui.show_toast(toast_text)
	else:
		FloatingToast.show_toast(toast_text)
		
	# Clean up interaction status
	if has_emitted_entered:
		player_exited.emit(self)
		has_emitted_entered = false
		
	_update_active_state()

func _draw() -> void:
	if not active:
		return
		
	# Draw pulsing amber/orange micro-glow (faded amber signature color)
	var glow_color = Color(0.78, 0.42, 0.20, 0.8)
	draw_circle(Vector2.ZERO, 6.0, glow_color)
	
	# Outer pulsing ring
	var time = Time.get_ticks_msec() / 1000.0
	var pulse = fmod(time, 1.5) / 1.5 # 0.0 to 1.0
	var radius = 6.0 + pulse * 24.0
	var alpha = 1.0 - pulse
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.78, 0.42, 0.20, alpha * 0.6), 1.5)

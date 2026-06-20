extends CharacterBody2D

# Phase 13: walker_01 — AI quadruped mech (first of several AI machine types).
# An attackable/interactable actor: CharacterBody2D + CollisionShape2D like the
# player. Patrols back and forth between min_x..max_x at a modest speed,
# occasionally stopping to idle. The art faces LEFT by default, so flip_h is set
# when moving right (opposite of the player, whose art faces right).
#
# Phase 13 (knockdown): when the player swings an attack while standing next to
# the walker and facing it, the walker plays fall -> prone (self-repair, 5s,
# 0%->100% text above its head) -> getup -> idle 3s -> resume patrol. It ignores
# further hits and stays put for the whole sequence.

@export var min_x := 600.0
@export var max_x := 1200.0
@export var speed := 90.0            # "not very fast" patrol speed, px/s
@export var ground_y := 690.0        # feet rest on this walk line
@export var walk_anim := "walk"
@export var idle_anim := "idle"

# Random move/pause windows so the stops feel organic rather than metronomic.
@export var min_move_time := 1.5
@export var max_move_time := 4.0
@export var min_pause_time := 0.6
@export var max_pause_time := 2.0

# Knockdown sequence -------------------------------------------------------
@export var fall_anim := "fall"
@export var prone_anim := "prone"
@export var getup_anim := "getup"
@export var fall_time := 0.6          # fall clip length, s
@export var prone_repair_time := 5.0  # self-repair 0%->100% duration, s
@export var getup_time := 0.6         # getup clip length, s
@export var recover_idle_time := 3.0  # idle hold after getup before walking, s
@export var attack_reach := 200.0     # melee range (px, center-to-center)
@export var label_y := -77.0          # repair text bottom edge (node-local y);
                                      # ~17px above the prone robot's top (~-60)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

enum State { PATROL, FALL, PRONE, GETUP, RECOVER_IDLE }

var _state := State.PATROL
var _dir := -1            # -1 = left (default art facing), 1 = right
var _paused := false
var _timer := 0.0
var _player: Node = null
var _label: Label = null

func _ready() -> void:
	position.y = ground_y
	position.x = clamp(position.x, min_x, max_x)
	_build_repair_label()
	_start_moving()

# Resolve (and cache) the player on first use. Looking it up lazily instead of in
# _ready avoids a scene-setup ordering window where the sibling isn't yet found.
func _get_player() -> Node:
	if _player == null or not is_instance_valid(_player):
		if get_parent():
			_player = get_parent().find_child("Player", true, false)
	return _player

func _physics_process(delta: float) -> void:
	match _state:
		State.PATROL:
			_patrol(delta)
		State.FALL:
			_tick_timed(delta, State.PRONE)
		State.PRONE:
			_tick_prone(delta)
		State.GETUP:
			_tick_timed(delta, State.RECOVER_IDLE)
		State.RECOVER_IDLE:
			_tick_timed(delta, State.PATROL)

# --- Patrol --------------------------------------------------------------
func _patrol(delta: float) -> void:
	if _check_player_hit():
		_enter_fall()
		return

	_timer -= delta
	if _paused:
		if _timer <= 0.0:
			_start_moving()
		return

	position.x += _dir * speed * delta
	if position.x <= min_x:
		position.x = min_x
		_dir = 1
	elif position.x >= max_x:
		position.x = max_x
		_dir = -1

	anim.flip_h = _dir > 0   # art faces left; flip only when heading right

	if _timer <= 0.0:
		_start_pause()

func _start_moving() -> void:
	_state = State.PATROL
	_paused = false
	_timer = randf_range(min_move_time, max_move_time)
	anim.play(walk_anim)

func _start_pause() -> void:
	_paused = true
	_timer = randf_range(min_pause_time, max_pause_time)
	anim.play(idle_anim)

# --- Hit detection -------------------------------------------------------
# Hit when the player is mid-attack, within melee reach, and facing the walker.
func _check_player_hit() -> bool:
	var p := _get_player()
	if p == null or not p.has_method("is_attacking"):
		return false
	if not p.is_attacking():
		return false
	var dx: float = p.global_position.x - global_position.x   # walker -> player offset
	if abs(dx) > attack_reach:
		return false
	var facing := 1
	if p.has_method("get_facing"):
		facing = p.get_facing()
	# dx < 0: player is left of walker -> must face right (1) to reach it.
	# dx > 0: player is right of walker -> must face left (-1).
	return (dx < 0.0 and facing == 1) or (dx > 0.0 and facing == -1)

# --- Knockdown sequence --------------------------------------------------
func _enter_fall() -> void:
	_state = State.FALL
	_timer = fall_time
	_play_if_present(fall_anim)

# Advance a fixed-duration state, then enter `next`.
func _tick_timed(delta: float, next: int) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_enter_state(next)

func _tick_prone(delta: float) -> void:
	_timer -= delta
	var pct := int(round(100.0 * clamp(1.0 - _timer / prone_repair_time, 0.0, 1.0)))
	_label.text = "自行修復中...... %d%%" % pct
	if _timer <= 0.0:
		_enter_state(State.GETUP)

func _enter_state(next: int) -> void:
	match next:
		State.PRONE:
			_state = State.PRONE
			_timer = prone_repair_time
			_play_if_present(prone_anim)
			_label.visible = true
			_label.text = "自行修復中...... 0%"
		State.GETUP:
			_state = State.GETUP
			_timer = getup_time
			_label.visible = false
			_play_if_present(getup_anim)
		State.RECOVER_IDLE:
			_state = State.RECOVER_IDLE
			_timer = recover_idle_time
			anim.play(idle_anim)
		State.PATROL:
			_start_moving()

func _play_if_present(name: String) -> void:
	if anim.sprite_frames and anim.sprite_frames.has_animation(name):
		anim.play(name)

func _build_repair_label() -> void:
	var box := Vector2(420.0, 28.0)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05))
	_label.add_theme_constant_override("outline_size", 5)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.size = box
	# label_y is the text's bottom edge; bottom-align so it stays put as font tweaks.
	_label.position = Vector2(-box.x / 2.0, label_y - box.y)
	_label.z_index = 50
	_label.visible = false
	add_child(_label)

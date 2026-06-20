extends MachineEnemy

# Phase 13-A/B: walker_01 — AI quadruped mech (first of several AI machine types).
# Patrols back and forth between min_x..max_x. On apply_stun(), enters the
# fall -> prone (self-repair) -> getup -> recover_idle -> patrol sequence.
# Hit detection is handled externally by MeleeStick on the player.
# Phase 13-B: extends MachineEnemy; _facing updated on direction changes;
# defeated() permanently stops the machine in prone (stays on scene, no despawn).

@export var min_x := 600.0
@export var max_x := 1200.0
@export var speed := 90.0
@export var ground_y := 690.0
@export var walk_anim := "walk"
@export var idle_anim := "idle"

@export var min_move_time := 1.5
@export var max_move_time := 4.0
@export var min_pause_time := 0.6
@export var max_pause_time := 2.0

@export var fall_anim := "fall"
@export var prone_anim := "prone"
@export var getup_anim := "getup"
@export var formatted_anim := "formatted"
@export var fall_time := 0.6
@export var prone_repair_time := 5.0
@export var getup_time := 0.6
@export var recover_idle_time := 3.0
@export var attack_reach := 200.0
@export var label_y := -77.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

enum State { PATROL, FALL, PRONE, GETUP, RECOVER_IDLE }

var _state := State.PATROL
var _dir := -1
var _paused := false
var _timer := 0.0
var _label: Label = null
var _defeated := false
var _white_mat: ShaderMaterial = null

func _ready() -> void:
	add_to_group("enemies")
	position.y = ground_y
	position.x = clamp(position.x, min_x, max_x)
	_build_repair_label()
	_build_white_mat()
	_start_moving()

func _physics_process(delta: float) -> void:
	if _defeated:
		return  # frozen on scene after defeated()
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

# --- Public API -----------------------------------------------------------

func is_stunned() -> bool:
	return _state == State.PRONE

func apply_stun(_duration: float) -> void:
	if _state == State.PATROL or _state == State.RECOVER_IDLE:
		_enter_fall()

func _build_white_mat() -> void:
	var s := Shader.new()
	s.code = "shader_type canvas_item;\nvoid fragment() { vec4 c = texture(TEXTURE, UV); COLOR = vec4(1.0, 1.0, 1.0, c.a); }"
	_white_mat = ShaderMaterial.new()
	_white_mat.shader = s

func flash_white() -> void:
	anim.material = _white_mat
	await get_tree().create_timer(2.0 / 60.0).timeout
	anim.material = null

func is_defeated() -> bool:
	return _defeated

# Phase 13-B: permanently stop the machine; stays on scene (no despawn, no explosion).
func defeated() -> void:
	if _defeated:
		return
	_defeated = true
	_label.visible = false
	if anim.sprite_frames and anim.sprite_frames.has_animation(formatted_anim):
		anim.play(formatted_anim)
	else:
		_play_if_present(prone_anim)

# --- Patrol ---------------------------------------------------------------

func _patrol(delta: float) -> void:
	_timer -= delta
	if _paused:
		if _timer <= 0.0:
			_start_moving()
		return

	position.x += _dir * speed * delta
	if position.x <= min_x:
		position.x = min_x
		_dir = 1
		_facing = 1
	elif position.x >= max_x:
		position.x = max_x
		_dir = -1
		_facing = -1

	anim.flip_h = _dir > 0

	if _timer <= 0.0:
		_start_pause()

func _start_moving() -> void:
	_state = State.PATROL
	_paused = false
	_timer = randf_range(min_move_time, max_move_time)
	_facing = _dir
	anim.play(walk_anim)

func _start_pause() -> void:
	_paused = true
	_timer = randf_range(min_pause_time, max_pause_time)
	anim.play(idle_anim)

# --- Knockdown sequence ---------------------------------------------------

func _enter_fall() -> void:
	_state = State.FALL
	_timer = fall_time
	_play_if_present(fall_anim)

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
	_label.position = Vector2(-box.x / 2.0, label_y - box.y)
	_label.z_index = 50
	_label.visible = false
	add_child(_label)

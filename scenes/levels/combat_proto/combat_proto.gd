extends Node2D

signal interaction_requested(data: Dictionary)

const FALL_GRAVITY := 2200.0  # px/s²

var _player: Node = null
var _ledge: Node = null
var _falling := false
var _fall_vel := 0.0  # downward velocity (px/s), positive = down
# Ground walk line the player falls back to. Captured from the Player's
# scene-set walk_line_y at startup so the floor follows the scene, not a constant.
var _ground_y := 690.0

func _ready() -> void:
	_player = find_child("Player", true, false)
	_ledge = find_child("LedgeArea", true, false)
	if _player:
		_ground_y = _player.walk_line_y
		if _player.has_method("snap_to_walk_line"):
			_player.snap_to_walk_line()

	# Fallback: if run independently, instantiate GameUI to support MessageBox popups.
	var has_game_ui = false
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "Main" or child.find_child("GameUI", true, false) != null:
			has_game_ui = true
			break
	if not has_game_ui:
		var ui_scene = load("res://scenes/ui/game_ui.tscn")
		if ui_scene:
			var ui_inst = ui_scene.instantiate()
			add_child(ui_inst)
			interaction_requested.connect(func(data):
				if data.get("type") == "message":
					ui_inst.show_message(data.get("message_text", ""), data.get("on_closed", Callable()), data.get("note_title", ""))
			)

# _physics_process runs BEFORE player.gd's _physics_process (parent node order),
# so updating walk_line_y here makes player.gd read the already-advanced value
# when it calls position.y = _walk_y_at(x).
func _physics_process(delta: float) -> void:
	if not _player or not _ledge:
		return

	if _falling:
		_fall_vel += FALL_GRAVITY * delta
		_player.walk_line_y = min(_player.walk_line_y + _fall_vel * delta, _ground_y)
		if _player.walk_line_y >= _ground_y:
			_player.walk_line_y = _ground_y
			_falling = false
			_fall_vel = 0.0
		return

	# Trigger fall when player walks off the upper ledge.
	# Skip while jumping so the arc isn't interrupted mid-air.
	if _player.walk_line_y < _ground_y \
			and not _player.is_jumping() \
			and not _ledge.contains_x(_player.global_position.x):
		_falling = true
		_fall_vel = 0.0

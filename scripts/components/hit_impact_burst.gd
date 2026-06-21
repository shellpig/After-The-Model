extends Node2D

const DEFAULT_TEXTURE_PATH := "res://assets/generated/sprites/hit_impact_burst/clang/hit-impact-burst-clang.png"
const SHAKE_OFFSETS := [10.0, -6.0, 7.0, -4.0, 4.0, -2.0, 0.0]
const SHAKE_DURATIONS := [0.05, 0.07, 0.07, 0.08, 0.08, 0.08, 0.07]

@export var texture: Texture2D
@export var texture_scale := 0.45
@export var hit_sound_path: String = ""

var _sprite: Sprite2D

func _ready() -> void:
	z_index = 80
	_build_sprite()
	_play()
	_play_hit_sound()

func _play_hit_sound() -> void:
	if not hit_sound_path.is_empty() and ResourceLoader.exists(hit_sound_path):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.stream = load(hit_sound_path)
		add_child(sfx_player)
		sfx_player.play()

func _build_sprite() -> void:
	_sprite = Sprite2D.new()
	if texture == null:
		texture = load(DEFAULT_TEXTURE_PATH)
	_sprite.texture = texture
	_sprite.centered = true
	_sprite.scale = Vector2(texture_scale, texture_scale)
	add_child(_sprite)

func _play() -> void:
	_play_camera_shake()
	scale = Vector2(0.1, 0.1)
	modulate.a = 1.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.16)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(0.6, 0.6), 0.34)
	tween.tween_interval(0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)

func _play_camera_shake() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var base_offset := camera.offset
	var tween := camera.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for i in range(SHAKE_OFFSETS.size()):
		tween.tween_property(camera, "offset", base_offset + Vector2(0.0, SHAKE_OFFSETS[i]), SHAKE_DURATIONS[i])

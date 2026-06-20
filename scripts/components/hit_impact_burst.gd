extends Node2D

const DEFAULT_TEXTURE_PATH := "res://assets/generated/sprites/hit_impact_burst/clang/hit-impact-burst-clang.png"

@export var texture: Texture2D
@export var texture_scale := 0.45

var _sprite: Sprite2D

func _ready() -> void:
	z_index = 80
	_build_sprite()
	_play()

func _build_sprite() -> void:
	_sprite = Sprite2D.new()
	if texture == null:
		texture = load(DEFAULT_TEXTURE_PATH)
	_sprite.texture = texture
	_sprite.centered = true
	_sprite.scale = Vector2(texture_scale, texture_scale)
	add_child(_sprite)

func _play() -> void:
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

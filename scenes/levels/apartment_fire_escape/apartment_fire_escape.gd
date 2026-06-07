# res://scenes/levels/apartment_fire_escape/apartment_fire_escape.gd
extends Node2D

signal current_interactable_changed(data: Dictionary)
signal interaction_requested(data: Dictionary)
signal scene_transition_requested(scene_id: String, entry_point_id: String, payload: Dictionary)

func prepare_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	pass

func set_entry_point(entry_point_id: String, payload: Dictionary = {}) -> void:
	pass

extends Area2D

signal player_entered(interactable: Area2D)
signal player_exited(interactable: Area2D)

@export var interaction_id := ""
@export var prompt_text := ""
@export var message_id := ""
@export var required_knowledge := ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_entered.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_exited.emit(self)

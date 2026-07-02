extends Area2D
class_name NpcAutoDialogueArea

signal player_entered(interactable: Area2D)
signal player_exited(interactable: Area2D)

@export var dialogue_id: String = ""
@export var seen_flag: String = ""
@export var require_flag: String = ""

# Dummy properties to prevent attribute errors if queried by level
var prompt_text: String = ""
var interaction_id: String = ""
var note_id: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	if UIMode.current_mode != UIMode.Mode.NONE:
		return

	if GameState.get_flag(seen_flag, false):
		return

	if require_flag != "" and not GameState.get_flag(require_flag, false):
		return

	var node = get_parent()
	var signal_emitted = false
	while node != null:
		if node.has_signal("interaction_requested"):
			node.emit_signal("interaction_requested", {
				"type": "dialogue",
				"dialogue_id": dialogue_id
			})
			signal_emitted = true
			break
		node = node.get_parent()

	if not signal_emitted:
		push_warning("NpcAutoDialogueArea: No ancestor with signal 'interaction_requested' found.")

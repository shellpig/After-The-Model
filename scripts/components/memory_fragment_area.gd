extends Area2D
class_name MemoryFragmentArea

signal player_entered(interactable: Area2D)
signal player_exited(interactable: Area2D)

@export var fragment_flag: String = "mem_frag_linfei_1"
@export var message_id: String = "mem_frag_linfei_1"

# Dummy properties to prevent attribute errors if queried by level
var prompt_text: String = ""
var interaction_id: String = ""
var dialogue_id: String = ""
var note_id: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	
	if GameState.get_flag(fragment_flag, false):
		return
		
	if UIMode.current_mode != UIMode.Mode.NONE:
		return
		
	GameState.set_flag(fragment_flag, true)
	
	var text = GameState.STORY_MESSAGES.get(message_id, "")
	var node = get_parent()
	var signal_emitted = false
	while node != null:
		if node.has_signal("interaction_requested"):
			node.emit_signal("interaction_requested", {
				"type": "message",
				"message_text": text
			})
			signal_emitted = true
			break
		node = node.get_parent()
		
	if not signal_emitted:
		push_warning("MemoryFragmentArea: No ancestor with signal 'interaction_requested' found.")

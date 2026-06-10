# Dialogue Runner Logic
# File: res://scripts/dialogue/dialogue_runner.gd

class_name DialogueRunner
extends RefCounted

signal finished

var _tree: Dictionary = {}
var _current_node_id: String = ""

func start(tree: Dictionary, start_node := "start") -> void:
	_tree = tree
	_enter_node(start_node)

func current() -> Dictionary:
	if _current_node_id.is_empty() or not _tree.has(_current_node_id):
		return {}

	var node = _tree[_current_node_id]
	var filtered_choices := []

	if node.has("choices") and node["choices"] is Array:
		var raw_choices: Array = node["choices"]
		for i in range(raw_choices.size()):
			var choice = raw_choices[i]
			if choice is Dictionary:
				var cond = choice.get("condition", {})
				if cond.is_empty() or _eval_condition(cond):
					filtered_choices.append({
						"label": choice.get("label", ""),
						"index": i
					})

	var is_terminal = filtered_choices.is_empty() and not node.has("goto")

	return {
		"speaker": node.get("speaker", ""),
		"text": node.get("text", ""),
		"choices": filtered_choices,
		"is_terminal": is_terminal
	}

func choose(choice_index: int) -> void:
	if _current_node_id.is_empty() or not _tree.has(_current_node_id):
		return

	var node = _tree[_current_node_id]
	if not node.has("choices") or not (node["choices"] is Array):
		return

	var raw_choices: Array = node["choices"]
	if choice_index < 0 or choice_index >= raw_choices.size():
		return

	var choice = raw_choices[choice_index]
	if not (choice is Dictionary):
		return

	# Apply choice effects
	if choice.has("effect") and choice["effect"] is Array:
		for eff in choice["effect"]:
			if eff is Dictionary:
				if not _apply_effect(eff):
					printerr("[DialogueRunner] Choice effect failed to apply, aborting remaining effects.")
					break

	# Resolve goto and enter next node
	var next_id = _resolve_goto(choice.get("goto"))
	if not next_id.is_empty():
		_enter_node(next_id)

func advance() -> void:
	if _current_node_id.is_empty() or not _tree.has(_current_node_id):
		return

	var node = _tree[_current_node_id]
	var curr = current()

	# If choices are present, we cannot advance without making a choice
	if not curr.get("choices", []).is_empty():
		return

	if curr.get("is_terminal", false):
		finished.emit()
		return

	if node.has("goto"):
		var next_id = _resolve_goto(node.get("goto"))
		if not next_id.is_empty():
			_enter_node(next_id)

func _enter_node(node_id: String) -> void:
	_current_node_id = node_id
	if not _tree.has(node_id):
		printerr("[DialogueRunner] Node not found: ", node_id)
		return

	var node = _tree[node_id]

	# Routing node detection (only goto, no text/speaker)
	var speaker = node.get("speaker", "")
	var text = node.get("text", "")
	if speaker.is_empty() and text.is_empty() and node.has("goto"):
		var next_id = _resolve_goto(node.get("goto"))
		if not next_id.is_empty():
			_enter_node(next_id)
			return

	# Apply node effects
	if node.has("effect") and node["effect"] is Array:
		for eff in node["effect"]:
			if eff is Dictionary:
				if not _apply_effect(eff):
					printerr("[DialogueRunner] Node effect failed to apply, aborting remaining effects.")
					break

func _eval_condition(cond) -> bool:
	if cond is Array:
		for sub_cond in cond:
			if sub_cond is Dictionary:
				if not _eval_condition_dict(sub_cond):
					return false
		return true
	elif cond is Dictionary:
		return _eval_condition_dict(cond)
	return true

func _eval_condition_dict(cond: Dictionary) -> bool:
	if cond.is_empty():
		return true
	
	var type = cond.get("type", "story_flag")
	var op = cond.get("op", "==")
	var target_val = cond.get("value")
	
	var current_val
	
	match type:
		"quest_status":
			var quest_id = cond.get("quest_id", "")
			current_val = QuestManager.get_status(quest_id)
		"quest_step":
			var quest_id = cond.get("quest_id", "")
			current_val = QuestManager.get_step(quest_id)
		"has_item":
			var item_id = cond.get("item_id", "")
			var count = cond.get("count", 1)
			current_val = GameState.has_item(item_id, count)
		"has_note":
			var note_id = cond.get("note_id", "")
			if note_id.is_empty():
				note_id = cond.get("value", "")
			current_val = GameState.has_note(note_id)
			if target_val == null:
				target_val = true
		"quest_flag":
			var quest_id = cond.get("quest_id", "")
			var key = cond.get("key", "")
			current_val = QuestManager.get_flag(quest_id, key, false)
		"story_flag", _:
			var flag = cond.get("flag", "")
			if flag.is_empty():
				return true
			current_val = GameState.get_flag(flag, 0)

	match op:
		"==":
			if current_val is bool and target_val is int:
				return current_val == (target_val != 0)
			if current_val is int and target_val is bool:
				return (current_val != 0) == target_val
			return current_val == target_val
		"!=":
			if current_val is bool and target_val is int:
				return current_val != (target_val != 0)
			if current_val is int and target_val is bool:
				return (current_val != 0) != target_val
			return current_val != target_val
		">":
			return current_val > target_val
		"<":
			return current_val < target_val
		">=":
			return current_val >= target_val
		"<=":
			return current_val <= target_val
		_:
			return false

func _resolve_goto(goto_value) -> String:
	if goto_value is String:
		return goto_value
	elif goto_value is Array:
		for route in goto_value:
			if route is Dictionary:
				var cond = route.get("condition", {})
				if cond.is_empty() or _eval_condition(cond):
					return route.get("target", "")
	return ""

func _apply_effect(eff: Dictionary) -> bool:
	var op = eff.get("op", "")
	match op:
		"set_flag":
			var key = eff.get("key", "")
			var val = eff.get("value")
			GameState.set_flag(key, val)
			return true
		"add_int":
			var key = eff.get("key", "")
			var delta = eff.get("value", 0)
			GameState.add_int(key, delta)
			return true
		"set_quest_flag":
			var quest_id = eff.get("quest_id", "")
			var key = eff.get("key", "")
			var val = eff.get("value")
			return QuestManager.set_flag(quest_id, key, val)
		"start_quest":
			var val = eff.get("value", "")
			return QuestManager.start(val)
		"add_gleaner_lead":
			var val = eff.get("value", "")
			print("[DialogueRunner] add_gleaner_lead: ", val)
			return true
		"remove_item":
			var item_id = eff.get("item_id", "")
			var count = eff.get("value", 1)
			return GameState.remove_item(item_id, count)
		"add_item":
			var item_id = eff.get("item_id", "")
			var count = eff.get("value", 1)
			return GameState.add_item(item_id, count)
		"add_note":
			var note = eff.get("note", {})
			if note is Dictionary and not note.is_empty():
				GameState.add_knowledge(note)
			return true
		"complete_quest":
			var val = eff.get("value", "")
			return QuestManager.complete(val)
		"add_credits":
			var amount = eff.get("value", 0)
			GameState.add_credits(amount)
			return true
		_:
			print("[DialogueRunner] Unknown effect op: ", op)
			return true

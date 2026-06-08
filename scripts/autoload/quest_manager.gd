# scripts/autoload/quest_manager.gd
extends Node

signal quest_started(quest_id: String)
signal quest_advanced(quest_id: String, step: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)

const QuestDB = preload("res://data/quests/quest_db.gd")

func start(quest_id: String) -> bool:
	var current_status = get_status(quest_id)
	if current_status == "active" or current_status == "completed":
		return true
	
	var quest_data = QuestDB.get_quest_data(quest_id)
	if quest_data == null:
		return false
	
	var state = {
		"status": "active",
		"step": "started",
		"flags": {}
	}
	GameState.set_quest_state(quest_id, state)
	sync_work_note(quest_id)
	quest_started.emit(quest_id)
	return true

func advance(quest_id: String, step: String, flags := {}) -> bool:
	var state = GameState.get_quest_state(quest_id)
	if state.is_empty() or state.get("status", "") != "active":
		return false
	
	var quest_data = QuestDB.get_quest_data(quest_id)
	if quest_data == null:
		return false
	
	if not quest_data.STEPS.has(step):
		return false
	
	state["step"] = step
	var current_flags = state.get("flags", {})
	for k in flags:
		current_flags[k] = flags[k]
	state["flags"] = current_flags
	
	GameState.set_quest_state(quest_id, state)
	sync_work_note(quest_id)
	quest_advanced.emit(quest_id, step)
	return true

func complete(quest_id: String) -> bool:
	var state = GameState.get_quest_state(quest_id)
	if state.is_empty() or state.get("status", "") != "active":
		return false
	
	state["status"] = "completed"
	GameState.set_quest_state(quest_id, state)
	sync_work_note(quest_id)
	quest_completed.emit(quest_id)
	return true

func fail(quest_id: String) -> bool:
	var state = GameState.get_quest_state(quest_id)
	if state.is_empty() or state.get("status", "") != "active":
		return false
	
	state["status"] = "failed"
	GameState.set_quest_state(quest_id, state)
	sync_work_note(quest_id)
	quest_failed.emit(quest_id)
	return true

func get_status(quest_id: String) -> String:
	var state = GameState.get_quest_state(quest_id)
	return state.get("status", "")

func get_step(quest_id: String) -> String:
	var state = GameState.get_quest_state(quest_id)
	return state.get("step", "")

func get_flag(quest_id: String, key: String, default_value = false):
	var state = GameState.get_quest_state(quest_id)
	var flags = state.get("flags", {})
	return flags.get(key, default_value)

func set_flag(quest_id: String, key: String, value) -> bool:
	var state = GameState.get_quest_state(quest_id)
	if state.is_empty() or state.get("status", "") != "active":
		return false
	var flags = state.get("flags", {})
	flags[key] = value
	state["flags"] = flags
	GameState.set_quest_state(quest_id, state)
	return true

func sync_work_note(quest_id: String) -> void:
	var quest_data = QuestDB.get_quest_data(quest_id)
	if quest_data == null:
		return
	
	var status = get_status(quest_id)
	var step = get_step(quest_id)
	
	var note_payload = {}
	if status == "completed" or status == "failed":
		if status == "completed" and "HAS_COMPLETED_NOTE_RESOLVER" in quest_data:
			note_payload = quest_data.resolve_completed_note()
		elif quest_data.WORK_NOTES_BY_STATUS.has(status):
			note_payload = quest_data.WORK_NOTES_BY_STATUS[status]
	else:
		if quest_data.WORK_NOTES_BY_STEP.has(step):
			note_payload = quest_data.WORK_NOTES_BY_STEP[step]
	
	if not note_payload.is_empty():
		GameState.add_knowledge(note_payload)

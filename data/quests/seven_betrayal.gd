# data/quests/seven_betrayal.gd
# Phase 24-A：七號背叛任務資料
const QUEST_ID := "seven_betrayal"
const WORK_NOTE_ID := "quest_seven_betrayal"
const TRACE_BETRAYAL_THRESHOLD := 3

const STEPS := {
	"started": {}
}

const WORK_NOTES_BY_STEP := {
	"started": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_SEVEN_BETRAYAL_STEP_STARTED_TITLE",
		"body": "QUEST_SEVEN_BETRAYAL_STEP_STARTED_BODY",
		"status": "active"
	}
}

const WORK_NOTES_BY_STATUS := {
	"failed": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_SEVEN_BETRAYAL_STATUS_FAILED_TITLE",
		"body": "QUEST_SEVEN_BETRAYAL_STATUS_FAILED_BODY",
		"status": "failed"
	}
}

const HAS_COMPLETED_NOTE_RESOLVER := true

const WORK_NOTES_COMPLETED := {
	"stopped_full": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_SEVEN_BETRAYAL_COMPLETED_FULL_TITLE",
		"body": "QUEST_SEVEN_BETRAYAL_COMPLETED_FULL_BODY",
		"status": "completed"
	},
	"stopped_partial": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_SEVEN_BETRAYAL_COMPLETED_PARTIAL_TITLE",
		"body": "QUEST_SEVEN_BETRAYAL_COMPLETED_PARTIAL_BODY",
		"status": "completed"
	},
	"peace_branch_d": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_SEVEN_BETRAYAL_COMPLETED_PEACE_TITLE",
		"body": "QUEST_SEVEN_BETRAYAL_COMPLETED_PEACE_BODY",
		"status": "completed"
	}
}

static func get_betrayal_branch() -> String:
	var got_warning := GameState.get_trust("wu") >= 2 or GameState.get_trust("cen") >= 2
	var trace_high := GameState.get_trace() >= TRACE_BETRAYAL_THRESHOLD
	if trace_high and not got_warning:
		return "stopped_partial"
	else:
		return "stopped_full"

static func resolve_betrayal_results() -> void:
	var branch = get_betrayal_branch()
	if branch == "stopped_partial":
		GameState.set_flag("seven_stopped_partial", true)
		GameState.set_flag("cen_voiceprint_exposed", true)
		GameState.add_int("affinity_seven", -1)
		GameState.add_int("affinity_wu", -1)
	else:
		GameState.set_flag("seven_stopped_full", true)
		GameState.add_int("affinity_seven", -2)
	GameState.set_flag("seven_betrayal_pending", false)
	QuestManager.complete("seven_betrayal")

static func resolve_completed_note() -> Dictionary:
	if GameState.get_flag("seven_peace_branch_d", false):
		return WORK_NOTES_COMPLETED["peace_branch_d"]
	elif GameState.get_flag("seven_stopped_partial", false):
		return WORK_NOTES_COMPLETED["stopped_partial"]
	elif GameState.get_flag("seven_stopped_full", false):
		return WORK_NOTES_COMPLETED["stopped_full"]
	else:
		var branch = get_betrayal_branch()
		return WORK_NOTES_COMPLETED[branch]

# data/quests/alley_backrooms_3f.gd
const QUEST_ID := "alley_backrooms_3f"
const WORK_NOTE_ID := "quest_alley_backrooms_3f"

const STEPS := {
	"started": {},
	"checked_alley": {},
	"found_activation_box": {},
}

const WORK_NOTES_BY_STEP := {
	"started": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_ALLEY_BACKROOMS_3F_STEP_STARTED_TITLE",
		"body": "QUEST_ALLEY_BACKROOMS_3F_STEP_STARTED_BODY",
		"status": "active",
	},
	"checked_alley": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_ALLEY_BACKROOMS_3F_STEP_CHECKED_ALLEY_TITLE",
		"body": "QUEST_ALLEY_BACKROOMS_3F_STEP_CHECKED_ALLEY_BODY",
		"status": "active",
	},
	"found_activation_box": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_ALLEY_BACKROOMS_3F_STEP_FOUND_ACTIVATION_BOX_TITLE",
		"body": "QUEST_ALLEY_BACKROOMS_3F_STEP_FOUND_ACTIVATION_BOX_BODY",
		"status": "active",
	},
}

const WORK_NOTES_BY_STATUS := {
	"completed": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_ALLEY_BACKROOMS_3F_STATUS_COMPLETED_TITLE",
		"body": "QUEST_ALLEY_BACKROOMS_3F_STATUS_COMPLETED_BODY",
		"status": "completed",
	},
	"failed": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_ALLEY_BACKROOMS_3F_STATUS_FAILED_TITLE",
		"body": "QUEST_ALLEY_BACKROOMS_3F_STATUS_FAILED_BODY",
		"status": "failed",
	},
}

const HAS_COMPLETED_NOTE_RESOLVER := true

const WORK_NOTES_COMPLETED := {
	"plain": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_ALLEY_BACKROOMS_3F_COMPLETED_PLAIN_TITLE",
		"body": "QUEST_ALLEY_BACKROOMS_3F_COMPLETED_PLAIN_BODY",
		"status": "completed",
	},
	"kept_module": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_ALLEY_BACKROOMS_3F_COMPLETED_KEPT_MODULE_TITLE",
		"body": "QUEST_ALLEY_BACKROOMS_3F_COMPLETED_KEPT_MODULE_BODY",
		"status": "completed",
	},
	"gave_module": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_ALLEY_BACKROOMS_3F_COMPLETED_GAVE_MODULE_TITLE",
		"body": "QUEST_ALLEY_BACKROOMS_3F_COMPLETED_GAVE_MODULE_BODY",
		"status": "completed",
	},
}

static func resolve_completed_note() -> Dictionary:
	if GameState.get_flag("gave_wan_old_module", false):
		return WORK_NOTES_COMPLETED["gave_module"]
	elif QuestManager.get_flag(QUEST_ID, "found_old_ai_authorization_module", false):
		return WORK_NOTES_COMPLETED["kept_module"]
	else:
		return WORK_NOTES_COMPLETED["plain"]

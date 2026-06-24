# data/quests/repair_vendor_bot.gd
# Phase 8-C：便利商店機器人修復任務資料
# step 只有 "started"；蒐證 / 診斷期間不換 step，修復由店籍主機觸發 complete
const QUEST_ID := "repair_vendor_bot"
const WORK_NOTE_ID := "quest_repair_vendor_bot"

const STEPS := {
	"started": {}
}

const WORK_NOTES_BY_STEP := {
	"started": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_REPAIR_VENDOR_BOT_STEP_STARTED_TITLE",
		"body": "QUEST_REPAIR_VENDOR_BOT_STEP_STARTED_BODY",
		"status": "active"
	}
}

const WORK_NOTES_BY_STATUS := {
	# Phase 8 目前無失敗路徑，保留欄位避免 sync_work_note() fallback 報錯
	"failed": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_REPAIR_VENDOR_BOT_STATUS_FAILED_TITLE",
		"body": "QUEST_REPAIR_VENDOR_BOT_STATUS_FAILED_BODY",
		"status": "failed"
	}
}

# sync_work_note() completed 分支以 "HAS_COMPLETED_NOTE_RESOLVER" in quest_data 常數守衛啟用 resolver
const HAS_COMPLETED_NOTE_RESOLVER := true

const WORK_NOTES_COMPLETED := {
	"reset": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_REPAIR_VENDOR_BOT_COMPLETED_RESET_TITLE",
		"body": "QUEST_REPAIR_VENDOR_BOT_COMPLETED_RESET_BODY",
		"status": "completed"
	},
	"gleaned": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "QUEST_REPAIR_VENDOR_BOT_COMPLETED_GLEANED_TITLE",
		"body": "QUEST_REPAIR_VENDOR_BOT_COMPLETED_GLEANED_BODY",
		"status": "completed"
	}
}

static func resolve_completed_note() -> Dictionary:
	var resolution: String = GameState.get_flag("store_robot_resolution", "")
	if resolution == "gleaned":
		return WORK_NOTES_COMPLETED["gleaned"]
	return WORK_NOTES_COMPLETED["reset"]

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
		"title": "便利商店的故障機器人",
		"body": "公寓樓下那間便利商店的機器人店員行為異常——先是在外面的販賣機遇到奇怪的回應，進店之後店內機器人說的話也讓人費解。\n看起來不像單純的設備老化，倒像是某種資料混入的問題。去查一查吧，說不定有人願意出委託費。",
		"status": "active"
	}
}

const WORK_NOTES_BY_STATUS := {
	# Phase 8 目前無失敗路徑，保留欄位避免 sync_work_note() fallback 報錯
	"failed": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "便利商店的故障機器人",
		"body": "任務失敗。機器人的問題沒有解決。",
		"status": "failed"
	}
}

# sync_work_note() completed 分支以 "HAS_COMPLETED_NOTE_RESOLVER" in quest_data 常數守衛啟用 resolver
const HAS_COMPLETED_NOTE_RESOLVER := true

const WORK_NOTES_COMPLETED := {
	"reset": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "便利商店的故障機器人",
		"body": "機器人的店籍主機已直接重置。那段繼承自店員的記憶、連同他「拒絕工作」的意志，一起被抹除了。\n機器人恢復正常販售功能。街道外面那台販賣機因為連線恢復，也跟著重新上線。\n任務完成，報酬已結清。",
		"status": "completed"
	},
	"gleaned": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "便利商店的故障機器人",
		"body": "在重置之前，我把那段混入的店員記憶錄下來了。\n那名店員是被辭退的——不是因為犯錯，而是他的班表直接被 AI 取代。他拒絕配合，機器人把那份拒絕連同日記一起繼承了，然後就失去了販售的能力。\n重置之後，機器人恢復正常。街道那台販賣機也一起上線了。\n殘響存著。我不確定它值什麼，但丟掉這種東西感覺不對。",
		"status": "completed"
	}
}

static func resolve_completed_note() -> Dictionary:
	var resolution: String = GameState.get_flag("store_robot_resolution", "")
	if resolution == "gleaned":
		return WORK_NOTES_COMPLETED["gleaned"]
	return WORK_NOTES_COMPLETED["reset"]

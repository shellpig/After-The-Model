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
		"title": "暗巷三樓的舊物",
		"body": "「晚」提到暗巷三樓有件舊物需要取得。那裡據說有一些被系統抹掉的殘留記憶。不過暗巷似乎不太好走，可能需要尋找其他能到達三樓的路線。",
		"status": "active",
	},
	"checked_alley": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "暗巷三樓的舊物",
		"body": "去後巷看過了，守衛很嚴，不能硬闖。不過我突然想起來我住的公寓在四樓，右側窗外就是外牆火災逃生梯與平台，也許可以從窗戶爬出去，透過天橋繞到左棟三樓。",
		"status": "active",
	},
	"found_activation_box": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "暗巷三樓的舊物",
		"body": "在左棟三樓的木箱中找到了「早期 AI 助理啟用盒」。拿去給暗巷口的「晚」吧。",
		"status": "active",
	},
}

const WORK_NOTES_BY_STATUS := {
	"completed": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "暗巷三樓的舊物",
		"body": "已將「早期 AI 助理啟用盒」安全交給「晚」。她看起來對這個舊盒子很感興趣。任務完成。",
		"status": "completed",
	},
	"failed": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "暗巷三樓的舊物",
		"body": "任務失敗。這條線索可能再也找不回來了。",
		"status": "failed",
	},
}

const HAS_COMPLETED_NOTE_RESOLVER := true

const WORK_NOTES_COMPLETED := {
	"plain": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "暗巷三樓的舊物",
		"body": "已將「早期 AI 助理啟用盒」安全交給「晚」。她看起來對這個舊盒子很感興趣。雖然在掂量時總覺得重量有些不對勁，但你並未深入探查，就這樣錯過了隱藏的夾層。任務完成。",
		"status": "completed",
	},
	"kept_module": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "暗巷三樓的舊物",
		"body": "已將「早期 AI 助理啟用盒」交給「晚」，但你將暗中拆解出的「舊式 AI 授權模組」留在了自己身上。晚似乎沒有察覺到這個盒子的夾層，這片晶片或許能在未來派上用場。任務完成。",
		"status": "completed",
	},
	"gave_module": {
		"id": WORK_NOTE_ID,
		"category": "工作",
		"title": "暗巷三樓的舊物",
		"body": "已將「早期 AI 助理啟用盒」交給「晚」，並且主動將暗中拆解出的「舊式 AI 授權模組」也一併交給了她。你選擇了信任與慷慨，將這份可能非比尋常的遺產託付給了晚，這也拉近了你們之間的距離。任務完成。",
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

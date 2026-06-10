# Dialogue Tree for the store registry host (店籍主機)
# File: res://data/dialogue/store_registry_host.gd
#
# 8-E 三段 gating（level 已先以 mainframe_revealed gate 可互動性）：
#   vendor_bot_repaired            -> already_repaired（中性訊息，不再提供重置）
#   understood_robot_truth (quest) -> stage3（直接重置 / 先錄殘響再重置）
#   diagnosed (quest)              -> stage2（僅直接重置）
#   其餘                            -> stage1（資訊不足，只說明）
#
# 先錄殘響的背包滿防呆：choice effect 以 add_item 開頭，失敗即中止後續 effect
# （旗標不設、任務不 complete），goto 進 glean_result 條件路由，依
# vendor_bot_repaired 是否成立分流到成功 / 背包滿訊息；可整理背包後重試。

const ECHO_NOTE := {
	"id": "note_clerk_echo_recording",
	"category": "線索",
	"title": "店員的殘響",
	"body": "在重置店籍主機之前，我把阿達留在備份區的東西錄了下來——日記、情緒資料，還有那句不肯走的「憑什麼」。\n機器人不會再記得他了。這段殘響現在只存在我這裡。\n賣是不可能賣的。只是還不知道，留著它能做什麼。",
	"status": "active"
}

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "vendor_bot_repaired", "op": "==", "value": true}, "target": "already_repaired"},
			{"condition": {"type": "quest_flag", "quest_id": "repair_vendor_bot", "key": "understood_robot_truth", "op": "==", "value": true}, "target": "stage3"},
			{"condition": {"type": "quest_flag", "quest_id": "repair_vendor_bot", "key": "diagnosed", "op": "==", "value": true}, "target": "stage2"},
			{"target": "stage1"}
		]
	},

	# --- 段1：資訊不足，只說明 ---
	"stage1": {
		"speaker": "店籍主機",
		"text": "（螢幕亮著，淡綠色的舊式介面上滾動著你看不懂的店籍資料。）\n【CS-STORE #0047──店籍登錄系統】\n權限選單裡有一排維修指令，但每一條都像加密過的咒語。\n你還不夠了解這台機器人出了什麼事，不敢隨便按下去。"
	},

	# --- 段2：診斷完成（未全對），僅直接重置 ---
	"stage2": {
		"speaker": "店籍主機",
		"text": "【CS-STORE #0047──店籍登錄系統】\n（診斷紀錄已同步。系統把一條指令推到了選單最上方：）\n「RESET──重寫終端身分登錄，恢復原廠服務人格。」\n（你大概知道問題出在哪了。細節還沒全弄清楚，但重置應該能讓它恢復工作。）",
		"choices": [
			{
				"label": "直接重置",
				"effect": [
					{"op": "set_flag", "key": "store_robot_resolution", "value": "reset"},
					{"op": "set_flag", "key": "vendor_bot_repaired", "value": true},
					{"op": "complete_quest", "value": "repair_vendor_bot"}
				],
				"goto": "reset_done"
			},
			{"label": "（先不要動它）", "goto": "stand_down"}
		]
	},

	# --- 段3：understood_robot_truth，二選一 ---
	"stage3": {
		"speaker": "店籍主機",
		"text": "【CS-STORE #0047──店籍登錄系統】\n（備份區的路徑在螢幕上展開——阿達留下的日記、情緒資料、那句不肯走的「憑什麼」，全都還在。）\n（你有權限直接重寫它的身分登錄。也可以在抹除之前，先把這段殘響錄下來。）",
		"choices": [
			{
				"label": "直接重置（抹除殘響，恢復服務人格）",
				"effect": [
					{"op": "set_flag", "key": "store_robot_resolution", "value": "reset"},
					{"op": "set_flag", "key": "vendor_bot_repaired", "value": true},
					{"op": "complete_quest", "value": "repair_vendor_bot"}
				],
				"goto": "reset_done"
			},
			{
				"label": "先錄殘響，再重置（把那段店員的記憶帶走）",
				"effect": [
					{"op": "add_item", "item_id": "clerk_echo_recording", "value": 1},
					{"op": "add_note", "note": ECHO_NOTE},
					{"op": "set_flag", "key": "store_robot_resolution", "value": "gleaned"},
					{"op": "set_flag", "key": "vendor_bot_repaired", "value": true},
					{"op": "complete_quest", "value": "repair_vendor_bot"}
				],
				"goto": "glean_result"
			},
			{"label": "（先不要動它）", "goto": "stand_down"}
		]
	},
	"stand_down": {
		"speaker": "店籍主機",
		"text": "（你把手從面板上收回來。螢幕的光在你臉上閃了兩下，像是沒等到答案。）\n（重置指令還在選單上。等你準備好再回來。）"
	},

	# --- 直接重置結局 ---
	"reset_done": {
		"speaker": "店籍主機",
		"text": "（你按下 RESET。主機的風扇猛地拔高，又緩緩落回平穩的頻率。）\n【身分登錄已重寫：CS-Retail-098──零售服務終端。】\n（櫃台那邊傳來開機音。整家店的燈光亮了一階——連鎖路由的訊號燈也跟著跳成綠色，外面那台販賣機應該也一起回線了。）"
	},

	# --- 先錄殘響結局（add_item 失敗時 vendor_bot_repaired 不會成立，分流到背包滿） ---
	"glean_result": {
		"goto": [
			{"condition": {"flag": "vendor_bot_repaired", "op": "==", "value": true}, "target": "gleaned_done"},
			{"target": "glean_bag_full"}
		]
	},
	"glean_bag_full": {
		"speaker": "店籍主機",
		"text": "（你想把殘響拷貝下來，但隨身的儲存空間全滿了——背包裡騰不出位置放這段記憶。）\n（主機停在等待畫面，什麼都沒有改變。整理一下背包，再回來。）"
	},
	"gleaned_done": {
		"speaker": "店籍主機",
		"text": "（拷貝進度走完。那段日記、那句「憑什麼」，安安靜靜躺進了你的背包。）\n（然後你按下 RESET。風扇拔高，又落回平穩。）\n【身分登錄已重寫：CS-Retail-098──零售服務終端。】\n（櫃台傳來開機音，連鎖路由的燈跳成綠色——外面那台販賣機也跟著回線了。\n機器是修好了。只是這次，有人記得阿達來過。）"
	},

	# --- 重置後：中性訊息，不再提供重置 ---
	"already_repaired": {
		"speaker": "店籍主機",
		"text": "【CS-STORE #0047──店籍登錄系統：運作正常】\n（螢幕安安靜靜地滾著庫存同步紀錄，沒有任何待處理事項。）"
	}
}

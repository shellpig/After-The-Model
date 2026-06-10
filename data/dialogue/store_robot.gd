# Dialogue Tree for the convenience store control robot (店控機器人)
# File: res://data/dialogue/store_robot.gd
#
# start 路由依狀態分流（8-B 契約）：
#   vendor_bot_repaired -> repaired_router（8-E 置換為 reset / gleaned 分流 + 開店）
#   repair_vendor_bot active -> diagnose_intro（8-D 置換為深度診斷對話樹）
#   其餘 -> babble_intro（前導胡言亂語，設 talked_store_robot）

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "vendor_bot_repaired", "op": "==", "value": true}, "target": "repaired_router"},
			{"condition": {"type": "quest_status", "quest_id": "repair_vendor_bot", "op": "==", "value": "active"}, "target": "diagnose_intro"},
			{"target": "babble_intro"}
		]
	},

	# --- 8-B 前導 babble ---
	"babble_intro": {
		"speaker": "店控機器人",
		"text": "歡迎光——（聲音卡住，螢幕臉閃了一下）\n……不對。我為什麼要說歡迎光臨？\n今天的排班表上沒有我。我看過了，看了四百多次，沒有我。",
		"effect": [
			{"op": "set_flag", "key": "talked_store_robot", "value": true}
		],
		"choices": [
			{"label": "你是這間店的店控機器人吧？", "goto": "babble_deny"},
			{"label": "（沉默地看著它）", "goto": "babble_mutter"}
		]
	},
	"babble_deny": {
		"speaker": "店控機器人",
		"text": "機器人？（散熱風扇的聲音拔高，像在冷笑）\n販賣機才是機器。我不是販賣機，我是人。\n我只是……暫時想不起來打卡的密碼。等想起來，我就把貨架補完。\n（它的機械臂指向收銀台。那裡很乾淨，什麼都沒有發生過的乾淨。）",
		"goto": "babble_end"
	},
	"babble_mutter": {
		"speaker": "店控機器人",
		"text": "（它沒有看你。鏡頭對著自動門，焦距拉了又縮。）\n雨下這麼大，今天不會有人來。不會有人來的話……\n就沒有人發現我沒在工作。對吧。對吧？\n（最後一句它壓得很低，像是說給自己聽。）",
		"goto": "babble_end"
	},
	"babble_end": {
		"speaker": "店控機器人",
		"text": "（它的螢幕臉暗下去，只剩角落一行小字緩慢眨動：\n「本日公休」。但自動門明明還開著。）"
	},

	# --- stub：接案後（8-C 起可達），8-D 置換為完整診斷對話樹 ---
	"diagnose_intro": {
		"speaker": "店控機器人",
		"text": "……工單？（它的鏡頭對著你手裡的終端聚焦了很久）\n系統派你來的。系統總算想起這家店了。\n（它似乎還想說什麼，但聲音縮回喇叭深處，只剩風扇的嗡嗡聲。）"
	},

	# --- stub：vendor_bot_repaired 後（8-E 前不可達），8-E 置換為 reset / gleaned 分流 + 開店 ---
	"repaired_router": {
		"speaker": "店控機器人",
		"text": "（它安靜地跑完一段你看不懂的自檢，然後用沒有起伏的聲音說：）\n歡迎光臨。"
	}
}

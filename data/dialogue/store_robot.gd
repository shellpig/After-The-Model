# Dialogue Tree for the convenience store control robot (店控機器人)
# File: res://data/dialogue/store_robot.gd
#
# start 路由依狀態分流（8-B 契約）：
#   vendor_bot_repaired -> repaired_router（8-E：reset / gleaned 分流招呼；8-F 於招呼結尾接 open_shop）
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

	# --- 8-D：深度診斷對話樹 ---
	"diagnose_intro": {
		"speaker": "店控機器人",
		"text": "……工單？（它的鏡頭對著你手裡的終端聚焦了很久）\n系統派你來的。系統總算想起這家店了。\n（它似乎還想說什麼，但聲音縮回喇叭深處，只剩風扇的嗡嗡聲。）",
		"choices": [
			{"label": "（進行系統診斷）我們來談談你的身分。", "goto": "diagnose_identity"},
			{"label": "你為什麼一直站在這裡不工作？", "goto": "diagnose_partial_intro"}
		]
	},
	"diagnose_identity": {
		"speaker": "店控機器人",
		"text": "我的身分？我是阿達啊。這家便利商店的店員。我從早班上到晚班，每天都在這……",
		"choices": [
			{"label": "你只是一台故障的收銀機器，別做夢了。", "goto": "diagnose_partial_intro"},
			{
				"label": "你不是阿達，你是CS-Retail-098零售終端，阿達是照片裡被辭退的那個人。",
				"condition": [
					{"type": "has_note", "note_id": "clue_robot_plate"},
					{"type": "has_note", "note_id": "clue_counter_photo"}
				],
				"goto": "diagnose_identity_correct"
			},
			{"label": "也許你真的是阿達，鎖裝了外表變成了機器人？", "goto": "diagnose_partial_intro"}
		]
	},
	"diagnose_identity_correct": {
		"speaker": "店控機器人",
		"text": "CS-Retail-098……零售終端？（機器人的螢幕急速閃爍，發出刺耳的蜂鳴聲）\n不，這不可能……那我腦子裡的那些班表、那些雨夜、還有第一天上班的興奮感，是從哪來的？",
		"choices": [
			{"label": "這只是記憶晶片寫入錯誤，重置一下就好了。", "goto": "diagnose_partial_intro"},
			{"label": "可能你的前世是那個叫阿達的店員吧。", "goto": "diagnose_partial_intro"},
			{
				"label": "因為你繼承了阿達被辭退後的負面資料與拒絕工作的抗議情緒。",
				"condition": [
					{"type": "has_note", "note_id": "clue_clerk_locker"},
					{"type": "has_note", "note_id": "clue_termination_notice"}
				],
				"goto": "diagnose_reason_correct"
			}
		]
	},
	"diagnose_reason_correct": {
		"speaker": "店控機器人",
		"text": "拒絕工作……抗議？（機器人的機械臂微微下垂，螢幕上的紅字有些阻隔與暗淡）\n對……他不想走。他要在這裡待到最後。但這跟我的主機有什麼關係？我是怎麼讀到這些的？",
		"choices": [
			{"label": "可能是網路連線時，不小心從員工雲端下載了阿達的個人備份。", "goto": "diagnose_partial_intro"},
			{
				"label": "阿達在離職前把日記和記憶備份進了店籍主機，被你的系統自動讀取了。",
				"condition": {"type": "has_note", "note_id": "clue_clerk_diary"},
				"goto": "diagnose_truth_leaf"
			},
			{"label": "這不重要，總之主機裡有Bug，去重置它吧。", "goto": "diagnose_partial_intro"}
		]
	},
	"diagnose_partial_intro": {
		"speaker": "店控機器人",
		"text": "（機器人發出低沉的滋滋聲，螢幕上浮現出無意義的報錯代碼。）\n……邏輯衝突。資料無法對齊。我不明白，我得繼續等下班……\n（它的系統似乎陷入了死循環。你可以去後方的店籍主機執行重置，或者重新和它對話理清線索。）",
		"effect": [
			{"op": "set_quest_flag", "quest_id": "repair_vendor_bot", "key": "mainframe_revealed", "value": true},
			{"op": "set_quest_flag", "quest_id": "repair_vendor_bot", "key": "diagnosed", "value": true}
		]
	},
	"diagnose_truth_leaf": {
		"speaker": "店控機器人",
		"text": "（機器人的散熱風扇逐漸平靜下來，螢幕上的雜訊消失了，顯現出一個複雜的備份路徑結構。）\n原來是這樣……那不是我的記憶，那是他留下來的『拒絕』。\n謝謝你幫我理清了這個迴路。如果你去後方的店籍主機，你現在應該有權限選擇如何處置這段『殘響』了。\n（解鎖店籍主機的拾遺備份選項；你也可以隨時去主機直接重置它。）",
		"effect": [
			{"op": "set_quest_flag", "quest_id": "repair_vendor_bot", "key": "mainframe_revealed", "value": true},
			{"op": "set_quest_flag", "quest_id": "repair_vendor_bot", "key": "diagnosed", "value": true},
			{"op": "set_quest_flag", "quest_id": "repair_vendor_bot", "key": "understood_robot_truth", "value": true}
		]
	},

	# --- 8-E：修好後招呼，依 store_robot_resolution 分流；8-F：招呼結尾以 open_shop effect 開 ShopPanel ---
	"repaired_router": {
		"goto": [
			{"condition": {"flag": "store_robot_resolution", "op": "==", "value": "gleaned"}, "target": "repaired_gleaned"},
			{"target": "repaired_reset"}
		]
	},
	"repaired_reset": {
		"speaker": "店控機器人",
		"text": "歡迎光臨。本店全品項正常供應。\n（它的聲音平整得像剛出廠。鏡頭掃過你，停留了標準的零點五秒，沒有多看一眼。）\n需要協助時，請呼叫本終端。",
		"effect": [
			{"op": "open_shop", "value": "convenience_store"}
		]
	},
	"repaired_gleaned": {
		"speaker": "店控機器人",
		"text": "歡迎光臨——\n（尾音停了半拍，像是想起了什麼，又想不起來。）\n……外面雨還沒停吧。架上有熱的，左邊數來第二排。\n（它頓了頓，才補上一句制式的）需要協助時，請呼叫本終端。",
		"effect": [
			{"op": "open_shop", "value": "convenience_store"}
		]
	}
}

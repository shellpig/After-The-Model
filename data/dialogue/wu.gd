# Dialogue Tree for Wu
# File: res://data/dialogue/wu.gd

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "met_wu", "op": "==", "value": true}, "target": "retalk"},
			{"target": "first_meet"}
		]
	},

	"first_meet": {
		"speaker": "伍姐",
		"text": "別站光裡，擋著我看線路。……新面孔。能走到這底下，命還算硬。",
		"choices": [
			{"label": "這些機器都是妳修的？", "goto": "repairer"},
			{"label": "這套淨水、發電，這些能讓人混過檢查的東西——是誰弄起來的？", "goto": "maker"},
			{"label": "（離開）", "goto": "leave"}
		]
	},

	"repairer": {
		"speaker": "伍姐",
		"text": "電力、淨水、誰家暖燈不亮——都歸我。以前我修地面那座城，後來城不要我了，我就下來修這座沒人要的。機器不會問你有沒有身份，比人強。",
		"effect": [
			{"op": "set_flag", "key": "met_wu", "value": true},
			{"op": "add_int", "key": "affinity_wu", "value": 1}
		],
		"goto": "end_cold"
	},

	"maker": {
		"speaker": "伍姐",
		"text": "（手停了半秒）……有過一個人。腦子活，手也黑。這套東西一半是她搭起來的。別把她想得太乾淨——她不是好人，只是比我們晚一點壞掉。名字？她自己把自己關掉了。知道了，對你沒好處。",
		"effect": [
			{"op": "set_flag", "key": "met_wu", "value": true},
			{"op": "set_flag", "key": "knows_settlement_had_maker", "value": true},
			{"op": "add_int", "key": "affinity_wu", "value": 1}
		],
		"goto": "end_cold"
	},

	"end_cold": {
		"speaker": "伍姐",
		"text": "想知道更多？多搬兩趟水、多修兩盞燈再說。這底下，沒人靠一張嘴活著。"
	},

	"retalk": {
		"speaker": "伍姐",
		"text": "（抬眼瞥你一下，又低回機器）來了。手別閒著，幫我扶一下這管子——還是你只會問問題？",
		"choices": [
			{
				"label": "（搭把手）",
				"effect": [
					{"op": "add_int", "key": "affinity_wu", "value": 1}
				],
				"goto": "end_cold"
			},
			{
				"label": "再說說那個建立這裡的人。",
				"condition": {"flag": "knows_settlement_had_maker", "op": "==", "value": true},
				"goto": "ask_maker_more"
			},
			{"label": "（離開）", "goto": "leave"}
		]
	},

	"ask_maker_more": {
		"speaker": "伍姐",
		"text": "她的事，知道太多對你沒好處。我只告訴你一件：她最後不是被抓走的，是自己把自己關掉的。至於為什麼，去問還活著的人——我不替死人講話。"
	},

	"leave": {
		"speaker": "伍姐",
		"text": "（她沒再說話，轉過身繼續用扳手敲擊發電機的外殼。）"
	}
}

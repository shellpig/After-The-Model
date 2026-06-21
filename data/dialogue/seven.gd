# Dialogue Tree for Seven
# File: res://data/dialogue/seven.gd

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "met_seven", "op": "==", "value": true}, "target": "retalk"},
			{"target": "first_meet"}
		]
	},

	"first_meet": {
		"speaker": "七號",
		"text": "……你也是躲下來的。",
		"choices": [
			{"label": "你是誰？", "goto": "ask_who"},
			{"label": "你不像會躲的人。", "goto": "hook"},
			{"label": "（保持距離）", "goto": "leave"}
		]
	},

	"ask_who": {
		"speaker": "七號",
		"text": "大家叫我七號。名字早被刷掉了，留個編號剛好。我不交朋友，你也別指望我幫你。",
		"goto": "hook"
	},

	"hook": {
		"speaker": "七號",
		"text": "躲？（低笑一聲，沒有溫度）你們可以一直躲。我不行。我有一個名字……還掛在上面。別問了，問了你也幫不上。",
		"effect": [
			{"op": "set_flag", "key": "met_seven", "value": true},
			{"op": "set_flag", "key": "seven_hinted_name_topside", "value": true}
		],
		"goto": "end_cold"
	},

	"end_cold": {
		"speaker": "七號",
		"text": "（他不再看你，目光沉進更深的隧道口那團黑裡。）"
	},

	"retalk": {
		"speaker": "七號",
		"text": "還是你。……我說過，我不交朋友。（頓）但你要真往更深的地方去，小心。那底下的東西不講話，只清場。",
		"choices": [
			{
				"label": "你那個『掛在上面的名字』……",
				"condition": {"flag": "seven_hinted_name_topside", "op": "==", "value": true},
				"goto": "ask_name"
			},
			{"label": "（離開）", "goto": "leave"}
		]
	},

	"ask_name": {
		"speaker": "七號",
		"text": "（眼神一冷）我說了，別問。……等你哪天也丟了個非找回不可的人，你就懂了。現在，滾。"
	},

	"leave": {
		"speaker": "七號",
		"text": "（他別過臉，雙臂抱胸，重新靠回牆邊，不再理會你。）"
	}
}

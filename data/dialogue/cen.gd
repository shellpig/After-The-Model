# Dialogue Tree for Cen
# File: res://data/dialogue/cen.gd

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "met_cen", "op": "==", "value": true}, "target": "retalk"},
			{"target": "first_meet"}
		]
	},

	"first_meet": {
		"speaker": "小岑",
		"text": "新來的？地面上掉下來的吧——看你那身還算乾淨就知道。……站遠點，這是我的地盤。",
		"choices": [
			{"label": "我不是來搶地盤的。", "goto": "intro"},
			{"label": "你一個人住這？", "goto": "ask_about_living"},
			{"label": "（你感覺口袋被碰了一下）手放規矩點。", "goto": "pickpocket_caught"}
		]
	},

	"ask_about_living": {
		"speaker": "小岑",
		"text": "關你屁事。……有人罩著，行了吧。",
		"goto": "intro"
	},

	"pickpocket_caught": {
		"speaker": "小岑",
		"text": "（手一縮，臉不紅）切，反應挺快。你那點破爛我還看不上。手快一點才不會餓死——你懂個屁。",
		"effect": [
			{"op": "set_flag", "key": "met_cen", "value": true}
		]
	},

	"intro": {
		"speaker": "小岑",
		"text": "叫我小岑。別到處亂傳。……我這條嗓子，是有人幫我弄成『聽起來像活人』的，檢查機器才放我過。所以別給我惹事，我輸不起。",
		"effect": [
			{"op": "set_flag", "key": "met_cen", "value": true},
			{"op": "add_int", "key": "affinity_cen", "value": 1}
		],
		"goto": "end_warm"
	},

	"end_warm": {
		"speaker": "小岑",
		"text": "行了，沒事別來煩我。……真撿到吃的，分我一口，我不介意。"
	},

	"retalk": {
		"speaker": "小岑",
		"text": "又是你。……沒偷你東西，真的。有事說事，別老盯著我看。",
		"choices": [
			{
				"label": "來看看你。",
				"effect": [
					{"op": "add_int", "key": "affinity_cen", "value": 1}
				],
				"goto": "end_warm"
			},
			{"label": "（離開）", "goto": "leave"}
		]
	},

	"leave": {
		"speaker": "小岑",
		"text": "（他哼了一聲，轉頭擺弄手裡的小零件，不再搭理你。）"
	}
}

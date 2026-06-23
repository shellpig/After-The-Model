# Dialogue Tree for Wan
# File: res://data/dialogue/wan.gd

const TREE := {
	"start": {
		"goto": [
			{
				"condition": [
					{"flag": "mem_frag_linfei_1", "op": "==", "value": true},
					{"flag": "wan_noticed_daze", "op": "==", "value": false}
				],
				"target": "wan_daze_hook"
			},
			{"condition": {"flag": "gave_wan_old_module", "op": "==", "value": true}, "target": "retalk_close"},
			{"condition": {"flag": "met_wan", "op": "==", "value": true}, "target": "retalk"},
			{"target": "first_meet"}
		]
	},

	"wan_daze_hook": {
		"speaker": "晚",
		"text": "（她話說到一半停住，盯著你看。）\n喂。你剛剛跑哪去了？人在這，眼神不在。\n……我見過那種眼神。在那些快被刪乾淨的人臉上。\n（她別過頭，聲音輕下來。）算了。你要是想不起來，我也不替你想。",
		"effect": [
			{"op": "set_flag", "key": "wan_noticed_daze", "value": true}
		],
		"goto": "wan_post_daze_routing"
	},

	"wan_post_daze_routing": {
		"goto": [
			{"condition": {"flag": "gave_wan_old_module", "op": "==", "value": true}, "target": "retalk_close"},
			{"condition": {"flag": "met_wan", "op": "==", "value": true}, "target": "retalk"},
			{"target": "first_meet"}
		]
	},
	"first_meet": {
		"speaker": "晚",
		"text": "喲，新面孔。從那盞燈底下、那棟漏水的破樓鑽出來的？\n我還以為那裡只剩生鏽的管線——\n沒想到還養著你這種、看得順眼的。",
		"choices": [
			{"label": "妳在看什麼？", "goto": "watch"},
			{"label": "妳是誰？", "goto": "who"},
			{"label": "（別開眼）", "goto": "flee"}
		]
	},
	"watch": {
		"speaker": "晚",
		"text": "那塊招牌。以前整夜亮著，現在燈死得只剩幾個字——\n『DEAD SHO』。（笑）一家斷氣的店，\n招牌偏偏拼得出『死』。這城市的幽默感，黑得很。\n我啊——專看這種快要不存在的東西。\n（斜你一眼）偶爾，也看看快要心動的東西。",
		"choices": [
			{"label": "我也撿這種東西。", "goto": "kin"},
			{"label": "想跟妳打聽點消息。", "goto": "intel_gate"}
		]
	},
	"who": {
		"speaker": "晚",
		"text": "名字？這年頭名字比指紋還不值錢。\n……晚。記這個字就好，剩下的，\n等你哪天值得了，我再一個字一個字給你。",
		"effect": [
			{"op": "set_flag", "key": "knows_wan_name", "value": true}
		],
		"goto": "watch"
	},
	"kin": {
		"speaker": "晚",
		"text": "喔——同類。那你該懂，\n撿回來的不是垃圾，是還沒被刪乾淨的人。\n（壓低聲）你這種人，我可不常遇到。",
		"effect": [
			{"op": "add_int", "key": "affinity_wan", "value": 1},
			{"op": "set_flag", "key": "met_wan", "value": true}
		],
		"goto": "end_warm"
	},
	"intel_gate": {
		"goto": [
			{"condition": {"type": "quest_status", "quest_id": "alley_backrooms_3f", "op": "==", "value": "completed"}, "target": "intel_already_done"},
			{"condition": {"type": "quest_status", "quest_id": "alley_backrooms_3f", "op": "==", "value": "active"}, "target": "intel_already_given"},
			{"condition": {"flag": "affinity_wan", "op": ">=", "value": 2}, "target": "intel"},
			{"target": "intel_locked"}
		]
	},
	"intel": {
		"speaker": "晚",
		"text": "想聽好料？……算了，看在你這張臉的份上。\n巷子再往裡，那排後門堆雜物的舊樓，\n三樓搬空了，老住戶走得急，東西沒帶乾淨。\n晚了，就被收破爛的 AI 鏟平嘍。",
		"effect": [
			{"op": "start_quest", "value": "alley_backrooms_3f"}
		],
		"goto": "end_warm"
	},
	"intel_already_given": {
		"speaker": "晚",
		"text": "不是跟你說過了？後巷那棟舊樓的三樓。\n趕緊去翻翻看，不然晚了就被 AI 鏟成白地了。",
		"goto": "end_warm"
	},
	"intel_already_done": {
		"speaker": "晚",
		"text": "之前那個啟用盒挺有意思的。\n等我有空研究出什麼花樣，再跟你分享。",
		"goto": "end_warm"
	},
	"intel_locked": {
		"speaker": "晚",
		"text": "消息？（笑）我又不是 AI 客服，\n憑你一句話就掏心掏肺。\n多來幾趟，讓我覺得你值得——再說。",
		"effect": [
			{"op": "add_int", "key": "affinity_wan", "value": 1},
			{"op": "set_flag", "key": "met_wan", "value": true}
		],
		"goto": "end_cold"
	},
	"end_warm": {
		"speaker": "晚",
		"text": "下次撿到有意思的，記得拿來給我看。\n……我是說東西。也不一定只是東西。"
	},
	"end_cold": {
		"speaker": "晚",
		"text": "（她又轉回去盯那塊死掉的招牌，留你一個側臉。）"
	},
	"flee": {
		"speaker": "晚",
		"text": "（她在你背後輕笑：「跑什麼，我又不咬人——除非你想。」）"
	},
	"retalk": {
		"speaker": "晚",
		"text": "又是你。（瞥一眼右邊還在抽風的販賣機）\n那台破機器又卡了，等下八成是你的活。\n……不急？那就先陪我站會兒。",
		"choices": [
			{
				"label": "來看看妳。",
				"effect": [
					{"op": "add_int", "key": "affinity_wan", "value": 1}
				],
				"goto": "end_warm"
			},
			{"label": "有新消息嗎？", "goto": "intel_gate"},
			{"label": "（離開）", "goto": "flee"},
			{
				"label": "我找到那個啟用盒了。",
				"condition": [
					{"type": "quest_status", "quest_id": "alley_backrooms_3f", "op": "==", "value": "active"},
					{"type": "quest_step", "quest_id": "alley_backrooms_3f", "op": "==", "value": "found_activation_box"},
					{"type": "has_item", "item_id": "early_ai_assistant_activation_box", "op": "==", "value": true}
				],
				"goto": "alley_backrooms_turn_in"
			},
			{
				"label": "我撿到一張育兒照護回執。",
				"condition": {
					"type": "has_item", "item_id": "childcare_supply_receipt", "op": "==", "value": true
				},
				"goto": "sell_receipt"
			}
		]
	},
	"alley_backrooms_turn_in": {
		"goto": [
			{"condition": {"type": "has_item", "item_id": "old_ai_authorization_module", "op": "==", "value": true}, "target": "turn_in_found_module"},
			{"target": "turn_in_plain"}
		]
	},
	"turn_in_found_module": {
		"speaker": "晚",
		"text": "（接過啟用盒，拿在手裡轉了一圈，抬眼看你）\n謝啦，這東西保存得比我想的還好。\n……怎麼？看你這眼神，底下還藏了什麼寶貝不成？",
		"choices": [
			{"label": "（只把啟用盒交給她，那塊模組留在自己口袋裡）", "goto": "turn_in_plain"},
			{"label": "（連盒子夾層裡那塊舊模組，也一起遞過去）", "goto": "turn_in_full"}
		]
	},
	"turn_in_plain": {
		"speaker": "晚",
		"text": "開玩笑的啦。謝了，這是給你的報酬，數好了。\n（她對你眨了眨眼，把一小疊信用點塞進你手裡）\n下次再撈到好東西，可別忘了我。",
		"effect": [
			{"op": "remove_item", "item_id": "early_ai_assistant_activation_box", "value": 1},
			{"op": "add_credits", "value": 500},
			{"op": "complete_quest", "value": "alley_backrooms_3f"}
		],
		"goto": "end_warm"
	},
	"turn_in_full": {
		"speaker": "晚",
		"text": "（她接過卡片模組，愣了一下，隨即有些不可置信地看著你）\n……舊式授權晶片？你還真把夾層翻開了，而且……連這個也捨得給我？\n（笑意深了些，把一整疊信用點拍在你手裡）\n夠大方。這份人情，我記下了。",
		"effect": [
			{"op": "remove_item", "item_id": "early_ai_assistant_activation_box", "value": 1},
			{"op": "remove_item", "item_id": "old_ai_authorization_module", "value": 1},
			{"op": "add_credits", "value": 1000},
			{"op": "add_int", "key": "affinity_wan", "value": 2},
			{"op": "set_flag", "key": "gave_wan_old_module", "value": true},
			{"op": "complete_quest", "value": "alley_backrooms_3f"}
		],
		"goto": "end_warm"
	},
	"retalk_close": {
		"speaker": "晚",
		"text": "喲，你來啦。今天雨下得特別大，\n要不要進來雨棚擠擠？不收你鋪租。\n……還是說，你又帶了什麼能讓我驚訝的小玩意兒？",
		"choices": [
			{
				"label": "陪妳站會兒。",
				"effect": [
					{"op": "add_int", "key": "affinity_wan", "value": 1}
				],
				"goto": "end_close"
			},
			{"label": "有新消息嗎？", "goto": "intel_gate"},
			{"label": "（離開）", "goto": "flee_close"},
			{
				"label": "我撿到一張育兒照護回執。",
				"condition": {
					"type": "has_item", "item_id": "childcare_supply_receipt", "op": "==", "value": true
				},
				"goto": "sell_receipt"
			}
		]
	},
	"end_close": {
		"speaker": "晚",
		"text": "那就安靜點，別把雨聲吵醒了。\n（她往旁邊挪了挪，肩膀若有似無地碰了你一下。）"
	},
	"flee_close": {
		"speaker": "晚",
		"text": "走啦？路滑，可別一腳踩進排水溝裡了——我可不想去撈你。"
	},
	"sell_receipt": {
		"speaker": "晚",
		"text": "（拿過回執翻看）\n這種回執沒什麼價。除非你知道上面的代碼是誰的。……你要賣？隨你便。",
		"choices": [
			{"label": "（將回執賣給她）", "goto": "do_sell_receipt"},
			{"label": "（還是先留著吧）", "goto": "end_warm"}
		]
	},
	"do_sell_receipt": {
		"speaker": "晚",
		"text": "好吧。拿著，這是折給你的小錢。這張破紙我就收下了。",
		"effect": [
			{"op": "remove_item", "item_id": "childcare_supply_receipt", "value": 1},
			{"op": "add_credits", "value": 200},
			{"op": "add_trace", "value": -1},
			{"op": "add_int", "key": "affinity_wan", "value": -1},
			{"op": "set_flag", "key": "peace_line_locked", "value": true}
		],
		"goto": "end_warm"
	}
}

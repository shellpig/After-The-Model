# Dialogue Tree for the collector Lu Qichen (鹿其琛)
# File: res://data/dialogue/lu_qichen.gd

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "met_lu", "op": "==", "value": true}, "target": "entry_to_hub"},
			{"target": "first_meet"}
		]
	},

	"entry_to_hub": {
		"goto": [
			{
				"condition": [
					{"flag": "mem_frag_linfei_1", "op": "==", "value": true},
					{"flag": "lu_hinted_topside", "op": "==", "value": false}
				],
				"target": "lu_daze_hook"
			},
			{"target": "hub"}
		]
	},

	"lu_daze_hook": {
		"speaker": "鹿其琛",
		"text": "你身上有股味道。不是雨，也不是這條街的——是上面的。你是從上面下來的吧？我隨口說說。不得不下來的人，各有各的理由。……我記得那條街最左邊，那座地鐵站已經停運很久了，不過，很多無路可走的人都會去那裡碰碰運氣。",
		"effect": [
			{"op": "set_flag", "key": "lu_hinted_topside", "value": true}
		],
		"goto": "hub"
	},

	"first_meet": {
		"speaker": "鹿其琛",
		"text": "（一個簡約考究的中年男子坐在沉重的木長桌後。他穿著一件款式老舊但裁剪精細的毛呢外套，一柄黑檀木手杖靠在桌邊。）\n新面孔。很少有清理工會走到我這來。誰跟你提起過我？",
		"effect": [
			{"op": "set_flag", "key": "met_lu", "value": true}
		],
		"choices": [
			{"label": "聽說這裡有個收舊電子玩意的『鹿三爺』。", "goto": "first_meet_reply"},
			{"label": "我只是隨便逛逛。", "goto": "first_meet_brush_off"}
		]
	},
	"first_meet_reply": {
		"speaker": "鹿其琛",
		"text": "三爺……（他扯了扯嘴角，露出一點疲憊的自嘲）\n街上那些人隨便喊的，不用當真。我叫鹿其琛。\n我只收在外面找不到的舊東西。紙本、磁帶、舊晶片……被系統當成垃圾抹掉的那些。",
		"goto": "entry_to_hub"
	},
	"first_meet_brush_off": {
		"speaker": "鹿其琛",
		"text": "隨便逛逛能走到這來，看來你的直覺很靈敏，清理工。\n我是鹿其琛。進了這扇門，就別只當自己是個來清垃圾的。我只收被系統當成垃圾抹掉的『舊回憶』。",
		"goto": "entry_to_hub"
	},

	"hub": {
		"speaker": "鹿其琛",
		"text": "說吧，今天帶了什麼？還是只是想在這暖和一下？",
		"choices": [
			{
				"label": "出示在公寓找到的老舊探測模組",
				"condition": [
					{"type": "has_item", "item_id": "old_probe_module"},
					{"type": "has_item", "item_id": "fingerless_gloves"},
					{"flag": "gleaner_gloves_installed", "op": "==", "value": false}
				],
				"goto": "appraise"
			},
			{
				"label": "給他看我的收藏",
				"goto": "sell_gate"
			},
			{
				"label": "關於這個房間的陳設……",
				"goto": "chat_about_room"
			},
			{
				"label": "離開",
				"goto": "exit"
			}
		]
	},

	"appraise": {
		"speaker": "鹿其琛",
		"text": "（他接過模組，原本平淡的眼神突然亮了起來。他用指腹撫過外殼的刮痕，對著燈光端詳接點）\n這是……早期 AI 清理熱潮前的『感應式探測模組』！這東西起碼有十五年歷史了。\n那時候系統還沒現在這麼封閉，舊架構的數位殘留是可以在空氣中感知到的。這東西就是用來抓那些『殘響』的。",
		"choices": [
			{"label": "殘響？那是什麼？", "goto": "appraise_explain"},
			{"label": "這東西能裝在我的工作手套上嗎？", "goto": "appraise_gloves"}
		]
	},
	"appraise_explain": {
		"speaker": "鹿其琛",
		"text": "被抹除的記憶。AI 被重置時、資料庫被格式化時，總有一些沒清乾淨的數位殘渣，會附在硬體或電線的磁場裡。\n如果裝備了探測手套，你就能感知到它們。只要在殘響附近站一會兒，手套的迴路就能幫你把記憶碎片採集起來。",
		"goto": "appraise_gloves"
	},
	"appraise_gloves": {
		"speaker": "鹿其琛",
		"text": "你的手套食指改過接點？拿來，我能幫你把這模組嵌進去。\n（他轉身從抽屜拿出幾樣精細工具，在燈光下專注地拆開模組，將細如髮絲的導線接入手套內側。他的動作極快且熟練）\n好了。現在它是一雙『拾遺手套』了。",
		"effect": [
			{"op": "install_module"}
		],
		"goto": "appraise_instructions"
	},
	"appraise_instructions": {
		"speaker": "鹿其琛",
		"text": "裝備它。在外面走動時，如果附近有被抹除的記憶，手套會亮起微光，你還會聽到電磁雜訊的干擾聲。\n在雜訊最強的點上『靜止站立一秒』，手套就能收錄那段殘響。\n如果你集滿了整條殘響，可以拿來賣給我。或者……",
		"choices": [
			{"label": "或者什麼？", "goto": "appraise_return_hint"},
			{"label": "我知道了，成交。", "goto": "hub"}
		]
	},
	"appraise_return_hint": {
		"speaker": "鹿其琛",
		"text": "或者……把它們『還』給原主。有些東西不是用錢可以衡量的。不過，這條街現在已經沒有原主可以還了。等以後地鐵通了，也許你會懂。\n總之，先去幫我把附近街區的記憶找回來吧。",
		"goto": "hub"
	},

	"chat_about_room": {
		"speaker": "鹿其琛",
		"text": "（他環顧四周疊滿古老實體物品的架子）\n這些是鹿家曾經的收藏。轉移到系統上時遺失了九成，只剩下這些搶救回來的實體原件。\n系統說實體是累贅。但我總覺得，看得見、摸得到的東西，被忘記的速度會慢一些。",
		"goto": "hub"
	},

	"sell_gate": {
		"goto": [
			{"condition": [{"type": "echo_complete", "value": "echo_clerk"}, {"type": "echo_unsold", "value": "echo_clerk"}], "target": "sell_menu"},
			{"condition": [{"type": "echo_complete", "value": "echo_room401_tenant"}, {"type": "echo_unsold", "value": "echo_room401_tenant"}], "target": "sell_menu"},
			{"condition": [{"type": "echo_complete", "value": "echo_song_rain_doesnt_stop"}, {"type": "echo_unsold", "value": "echo_song_rain_doesnt_stop"}], "target": "sell_menu"},
			{"target": "sell_empty"}
		]
	},
	"sell_empty": {
		"speaker": "鹿其琛",
		"text": "你手頭還沒有集滿的殘響。殘缺的故事是不值錢的，清理工。\n戴上『拾遺手套』，去那些系統清理過的地方聽聽看吧。",
		"goto": "hub"
	},
	
	"sell_menu": {
		"speaker": "鹿其琛",
		"text": "喔？看來你確實找到了一些完整的記憶。你想把哪一段交給我？",
		"choices": [
			{
				"label": "交付《店員的殘響》（阿達的記憶）",
				"condition": [
					{"type": "echo_complete", "value": "echo_clerk"},
					{"type": "echo_unsold", "value": "echo_clerk"}
				],
				"goto": "sell_clerk"
			},
			{
				"label": "交付《401的前住戶》",
				"condition": [
					{"type": "echo_complete", "value": "echo_room401_tenant"},
					{"type": "echo_unsold", "value": "echo_room401_tenant"}
				],
				"goto": "sell_room401"
			},
			{
				"label": "交付《雨還沒停》（那首消失的老歌）",
				"condition": [
					{"type": "echo_complete", "value": "echo_song_rain_doesnt_stop"},
					{"type": "echo_unsold", "value": "echo_song_rain_doesnt_stop"}
				],
				"goto": "sell_song"
			},
			{
				"label": "返回",
				"goto": "hub"
			}
		]
	},

	"sell_clerk": {
		"speaker": "鹿其琛",
		"text": "（他聽完這段音訊殘響，長久地沉默著，最後發出一聲輕嘆）\n『阿達』……這個人我認得。他是那家店全自動化前最後的人類店員。他的這份不甘心，確實很有他的風格。你想把這段記憶賣給我嗎？",
		"choices": [
			{
				"label": "賣給他",
				"effect": [
					{"op": "sell_echo", "value": "echo_clerk"}
				],
				"goto": "sell_clerk_sold"
			},
			{
				"label": "先自己留著",
				"goto": "sell_menu"
			}
		]
	},
	"sell_clerk_sold": {
		"speaker": "鹿其琛",
		"text": "很好，這份殘響我收下了。\n（獲得了 300 credits。）",
		"goto": "sell_done"
	},
	"sell_room401": {
		"speaker": "鹿其琛",
		"text": "（他摩挲著手杖的把手，看著顯現的舊照片）\n這是在401室住過的那家人。他們被強制遷走那天也是個雨夜。這些照片，記錄了他們在這個冰冷街區裡曾擁有過的溫暖。很有價值的檔案。你想把這段記憶賣給我嗎？",
		"choices": [
			{
				"label": "賣給他",
				"effect": [
					{"op": "sell_echo", "value": "echo_room401_tenant"}
				],
				"goto": "sell_room401_sold"
			},
			{
				"label": "先自己留著",
				"goto": "sell_menu"
			}
		]
	},
	"sell_room401_sold": {
		"speaker": "鹿其琛",
		"text": "很好，這份殘響我收下了。\n（獲得了 200 credits。）",
		"goto": "sell_done"
	},
	"sell_song": {
		"speaker": "鹿其琛",
		"text": "（聽著古老的電子旋律在雜訊中流淌，他閉上眼睛，手指跟著節奏輕點）\n《雨還沒停》……那時候街頭巷尾隨處可聽見這首歌。自從串流資料庫被統一清理後，就再也沒聽到了。你能把它拼湊完整，真是不簡單。你想把這段記憶賣給我嗎？",
		"choices": [
			{
				"label": "賣給他",
				"effect": [
					{"op": "sell_echo", "value": "echo_song_rain_doesnt_stop"}
				],
				"goto": "sell_song_sold"
			},
			{
				"label": "先自己留著",
				"goto": "sell_menu"
			}
		]
	},
	"sell_song_sold": {
		"speaker": "鹿其琛",
		"text": "很好，這份殘響我收下了。\n（獲得了 150 credits。）",
		"goto": "sell_done"
	},
	"sell_done": {
		"speaker": "鹿其琛",
		"text": "感謝你的回報。還有其他收穫嗎？",
		"goto": "sell_gate"
	},

	"exit": {
		"speaker": "鹿其琛",
		"text": "慢走。記得戴好手套，這雨一時半刻是停不了的。"
	}
}

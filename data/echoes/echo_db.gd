# res://data/echoes/echo_db.gd
# Static registry for the game's echoes (残响资料库)
class_name EchoDB


static var ECHOES := {
	"echo_clerk": {
		"title": "店員的殘響",
		"segments": [
			{
				"id": "s1",
				"text": "在重置店籍主機之前，我把阿達留在備份區的東西錄了下來——日記、情緒資料，還有那句不肯走的「憑什麼」。\n機器人不會再記得他了。這段殘響現在只存在我這裡。\n賣是不可能賣的。只是還不知道，留著它能做什麼。"
			}
		],
		"audio_path": "res://assets/audio/echoes/echo_clerk.ogg",
		"sell_price": 300,
		"comment": "阿達那孩子……我認得他。他在便利商店做了五年，最後被一個零售終端取代了。這段錄音，是他最後留下來的體溫。"
	},
	"echo_room401_tenant": {
		"title": "401 的前住戶",
		"segments": [
			{
				"id": "s1",
				"text": "舊的租約通知單。上面寫著401室，租戶姓名被黑色墨水粗暴地塗黑了。只剩下一行字：『請於本月底前完成全自動化合約更新，否則將視為自願放棄續租權。』"
			},
			{
				"id": "s2",
				"text": "牆角斑駁的塗鴉，看起來是用噴漆寫的：『我不在乎自動管家，我只要我的舊鄰居。』筆跡已經被雨水沖刷得模糊不清。"
			},
			{
				"id": "s3",
				"text": "一張撕角的生活照，背景是個溫馨的小客廳。一個老人抱著一隻老貓坐在沙發上，背後是用膠帶貼在牆上的字條：『這不是升級，這是驅逐。』"
			}
		],
		"image_path": "res://assets/images/echoes/echo_room401_tenant.png",
		"sell_price": 200,
		"comment": "401室的人啊……我記得他們被遷走那天，雨下得比今天還大。系統說全自動化大樓不需要有溫度的房客。"
	},
	"echo_song_rain_doesnt_stop": {
		"title": "雨還沒停",
		"segments": [
			{
				"id": "s1",
				"text": "『雨還沒停，街上的燈已經熄了。』這是一首曾經在平民區街頭隨處能聽到的老歌旋律。沒有花哨的電子合成，只有簡單的木吉他。"
			},
			{
				"id": "s2",
				"text": "『你在無人便利店裡避雨，看著自動清潔機把你的影子擦掉。』歌詞裡記錄著這個城市最平凡的深夜風景。"
			},
			{
				"id": "s3",
				"text": "『我們在霓虹下告別，你說你下週就要去富人區當助理，此後再無音訊。』這首歌已經從所有的官方串流庫中被清理乾淨了。"
			}
		],
		"audio_path": "res://assets/audio/echoes/echo_song_rain_doesnt_stop.mp3",
		"sell_price": 150,
		"comment": "這首歌……以前地鐵口常有流浪歌手自彈自唱。自從地鐵治安清理把他們趕走後，就再也沒聽到了。這段旋律值這個價。"
	},
	"echo_lu_family": {
		"title": "鹿家記事",
		"unknown_total": true,
		"segments": [
			{
				"id": "s1",
				"text": "日記的備份片段：『老三（其琛）又把那些沒用的舊相機搬回來了。大哥說這些垃圾只會佔地方，連二手市場都不要。可我知道，他只是想留住母親拍照時的樣子。』"
			}
		],
		"sell_price": 0,
		"comment": "（這是關於鹿其琛過去的記憶，他不收、也不談。）"
	},
	"echo_settlement_erased": {
		"title": "被抹除的住戶",
		"segments": [
			{
				"id": "s1",
				"text": "一個模糊的語音備忘錄：『老趙，聽說明天大篩查的名單裡有我們……把水槽下面的舊硬碟藏好，那裡面有小岑他們之前的出生登記，就算系統不認，我們也得記得他們來過。』"
			},
			{
				"id": "s2",
				"text": "一張印著模糊指紋的表格碎片，標題是《非註冊人口格式化名冊》。表格大部分已經被水漬暈開，但仍能看清最底部的印章：『完工，確認無殘留。』"
			}
		],
		"sell_price": 250,
		"comment": "被抹除的人啊……這個名字在戶政數據庫裡連個括號都沒留下，但他的備忘錄卻保存在這塊生鏽的硬碟裡。收下吧，這是他的墓碑。"
	}
}

static func get_echo(echo_id: String) -> Dictionary:
	return ECHOES.get(echo_id, {})

static func get_segment_count(echo_id: String) -> int:
	var echo = get_echo(echo_id)
	if echo.is_empty():
		return 0
	return echo.get("segments", []).size()

static func has_echo(echo_id: String) -> bool:
	return ECHOES.has(echo_id)

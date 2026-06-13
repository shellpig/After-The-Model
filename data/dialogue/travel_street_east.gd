# Dialogue Tree for the temporary travel menu at the right end of the street (街道最右端「離開街區」)
# File: res://data/dialogue/travel_street_east.gd

const TREE := {
	"start": {
		"speaker": "",
		"text": "你要離開目前街區嗎？",
		"choices": [
			{
				"label": "前往收藏家的店",
				"goto": "travel_to_shop"
			},
			{
				"label": "取消",
				"goto": "end"
			}
		]
	},
	"travel_to_shop": {
		"speaker": "",
		"text": "（你向高架橋下的陰暗巷口走去。高處的懸浮霓虹在雨水中被折射成扭曲的斑斕色帶。越過這道邊界，是一片你未曾涉足的老舊里街……）",
		"effect": [
			{"op": "travel", "scene_id": "collector_shop", "entry_point_id": "from_street"}
		]
	},
	"end": {
		"speaker": "",
		"text": "（你決定先留在這條街上。）"
	}
}

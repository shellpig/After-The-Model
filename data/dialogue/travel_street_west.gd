# Dialogue Tree for the temporary travel menu at the left end of the street (街道最左端「前往地鐵站」)
# File: res://data/dialogue/travel_street_west.gd

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "lu_hinted_topside", "op": "==", "value": true}, "target": "menu"},
			{"target": "locked"}
		]
	},
	"locked": {
		"speaker": "",
		"text": "（這座地鐵站已經停運很久了，入口處拉著警戒線，無法進入。）"
	},
	"menu": {
		"speaker": "",
		"text": "你要離開目前街區嗎？",
		"choices": [
			{
				"label": "前往地鐵站",
				"goto": "travel_to_subway"
			},
			{
				"label": "取消",
				"goto": "end"
			}
		]
	},
	"travel_to_subway": {
		"speaker": "",
		"text": "（你沿著街區邊緣往下走。霓虹和雨聲被高架橋吞掉，地鐵入口像一個還沒關上的傷口，等著你進去。）",
		"effect": [
			{"op": "travel", "scene_id": "subway_station", "entry_point_id": "from_street"}
		]
	},
	"end": {
		"speaker": "",
		"text": "（你決定先留在這條街上。）"
	}
}

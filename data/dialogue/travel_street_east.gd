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
				"label": "前往地鐵站",
				"condition": {"flag": "lu_hinted_topside", "op": "==", "value": true},
				"goto": "travel_to_subway"
			},
			{
				"label": "取消",
				"goto": "end"
			}
		]
	},
	"travel_to_shop": {
		"speaker": "",
		"text": "（你沿著高架橋下的斑駁小徑前行。越過喧囂的邊界，霓虹漸遠，古老的青磚圍牆沿著道路延伸。在那扇爬滿常春藤的鐵花大門後，便是那座歷史悠久的家族老宅……）",
		"effect": [
			{"op": "travel", "scene_id": "collector_shop", "entry_point_id": "from_street"}
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

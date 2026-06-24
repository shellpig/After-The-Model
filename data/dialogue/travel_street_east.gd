# Dialogue Tree for the temporary travel menu at the right end of the street (街道最右端「離開街區」)
# File: res://data/dialogue/travel_street_east.gd

const TREE := {
	"start": {
		"speaker": "",
		"text": "DLG_TRAVEL_STREET_EAST_START_TEXT",
		"choices": [
			{
				"label": "DLG_TRAVEL_STREET_EAST_START_CHOICE0",
				"goto": "travel_to_shop"
			},
			{
				"label": "DLG_TRAVEL_STREET_EAST_START_CHOICE1",
				"goto": "end"
			}
		]
	},
	"travel_to_shop": {
		"speaker": "",
		"text": "DLG_TRAVEL_STREET_EAST_TRAVEL_TO_SHOP_TEXT",
		"effect": [
			{"op": "travel", "scene_id": "collector_shop", "entry_point_id": "from_street"}
		]
	},
	"end": {
		"speaker": "",
		"text": "DLG_TRAVEL_STREET_EAST_END_TEXT"
	}
}

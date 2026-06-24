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
		"text": "DLG_TRAVEL_STREET_WEST_LOCKED_TEXT"
	},
	"menu": {
		"speaker": "",
		"text": "DLG_TRAVEL_STREET_WEST_MENU_TEXT",
		"choices": [
			{
				"label": "DLG_TRAVEL_STREET_WEST_MENU_CHOICE0",
				"goto": "travel_to_subway"
			},
			{
				"label": "DLG_TRAVEL_STREET_WEST_MENU_CHOICE1",
				"goto": "end"
			}
		]
	},
	"travel_to_subway": {
		"speaker": "",
		"text": "DLG_TRAVEL_STREET_WEST_TRAVEL_TO_SUBWAY_TEXT",
		"effect": [
			{"op": "travel", "scene_id": "subway_station", "entry_point_id": "from_street"}
		]
	},
	"end": {
		"speaker": "",
		"text": "DLG_TRAVEL_STREET_WEST_END_TEXT"
	}
}

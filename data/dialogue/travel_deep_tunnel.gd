# Dialogue Tree for the deep tunnel travel menu (深隧道口兩去處選單)
# File: res://data/dialogue/travel_deep_tunnel.gd

const TREE := {
	"start": {
		"speaker": "",
		"text": "DLG_TRAVEL_DEEP_TUNNEL_START_TEXT",
		"choices": [
			{
				"label": "DLG_TRAVEL_DEEP_TUNNEL_START_CHOICE0",
				"goto": "travel_to_combat"
			},
			{
				"label": "DLG_TRAVEL_DEEP_TUNNEL_START_CHOICE1",
				"goto": "travel_to_chase"
			},
			{
				"label": "DLG_TRAVEL_DEEP_TUNNEL_START_CHOICE2",
				"goto": "end"
			}
		]
	},
	"travel_to_combat": {
		"speaker": "",
		"text": "DLG_TRAVEL_DEEP_TUNNEL_TRAVEL_TO_COMBAT_TEXT",
		"effect": [
			{"op": "travel", "scene_id": "tunnel_combat", "entry_point_id": "from_settlement"}
		]
	},
	"travel_to_chase": {
		"speaker": "",
		"text": "DLG_TRAVEL_DEEP_TUNNEL_TRAVEL_TO_CHASE_TEXT",
		"effect": [
			{"op": "travel", "scene_id": "tunnel_chase", "entry_point_id": "from_settlement"}
		]
	},
	"end": {
		"speaker": "",
		"text": "DLG_TRAVEL_DEEP_TUNNEL_END_TEXT"
	}
}

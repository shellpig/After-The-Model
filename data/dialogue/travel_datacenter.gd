# Dialogue Tree for the "AI 資料中心" travel destination at nightclub_entrance (Phase 25-A)
# File: res://data/dialogue/travel_datacenter.gd
# Gate = passed_nightclub_security AND (seven_peace_branch_d OR seven_stopped_full OR seven_stopped_partial)
# Reads only existing terminal flags from Phase 20/24; adds no new story flags.

const TREE := {
	"start": {
		"goto": [
			{
				"condition": [
					{"flag": "passed_nightclub_security", "op": "==", "value": true},
					{"flag": "seven_peace_branch_d", "op": "==", "value": true}
				],
				"target": "menu"
			},
			{
				"condition": [
					{"flag": "passed_nightclub_security", "op": "==", "value": true},
					{"flag": "seven_stopped_full", "op": "==", "value": true}
				],
				"target": "menu"
			},
			{
				"condition": [
					{"flag": "passed_nightclub_security", "op": "==", "value": true},
					{"flag": "seven_stopped_partial", "op": "==", "value": true}
				],
				"target": "menu"
			},
			{"target": "locked"}
		]
	},
	"locked": {
		"speaker": "",
		"text": "DLG_TRAVEL_DATACENTER_LOCKED_TEXT"
	},
	"menu": {
		"speaker": "",
		"text": "DLG_TRAVEL_DATACENTER_MENU_TEXT",
		"choices": [
			{
				"label": "DLG_TRAVEL_DATACENTER_MENU_CHOICE0",
				"goto": "wan_flavor"
			},
			{
				"label": "DLG_TRAVEL_DATACENTER_MENU_CHOICE1",
				"goto": "end"
			}
		]
	},
	"wan_flavor": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_TRAVEL_DATACENTER_WAN_FLAVOR_TEXT",
		"goto": "travel_to_datacenter"
	},
	"travel_to_datacenter": {
		"speaker": "",
		"text": "DLG_TRAVEL_DATACENTER_TRAVEL_TEXT",
		"effect": [
			{"op": "travel", "scene_id": "datacenter_entrance", "entry_point_id": "from_nightclub"}
		]
	},
	"end": {
		"speaker": "",
		"text": "DLG_TRAVEL_DATACENTER_END_TEXT"
	}
}

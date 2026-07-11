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
					{"flag": "seven_peace_branch_d", "op": "==", "value": true},
					{"flag": "datacenter_travel_committed", "op": "==", "value": true}
				],
				"target": "menu_repeat"
			},
			{
				"condition": [
					{"flag": "passed_nightclub_security", "op": "==", "value": true},
					{"flag": "seven_stopped_full", "op": "==", "value": true},
					{"flag": "datacenter_travel_committed", "op": "==", "value": true}
				],
				"target": "menu_repeat"
			},
			{
				"condition": [
					{"flag": "passed_nightclub_security", "op": "==", "value": true},
					{"flag": "seven_stopped_partial", "op": "==", "value": true},
					{"flag": "datacenter_travel_committed", "op": "==", "value": true}
				],
				"target": "menu_repeat"
			},
			{
				"condition": [
					{"flag": "passed_nightclub_security", "op": "==", "value": true},
					{"flag": "seven_peace_branch_d", "op": "==", "value": true}
				],
				"target": "menu_peace"
			},
			{
				"condition": [
					{"flag": "passed_nightclub_security", "op": "==", "value": true},
					{"flag": "seven_stopped_full", "op": "==", "value": true}
				],
				"target": "menu_track"
			},
			{
				"condition": [
					{"flag": "passed_nightclub_security", "op": "==", "value": true},
					{"flag": "seven_stopped_partial", "op": "==", "value": true}
				],
				"target": "menu_track"
			},
			{"target": "locked"}
		]
	},
	"locked": {
		"speaker": "",
		"text": "DLG_TRAVEL_DATACENTER_LOCKED_TEXT"
	},
	"menu_peace": {
		"speaker": "",
		"text": "DLG_TRAVEL_DATACENTER_MENU_PEACE_TEXT",
		"effect": [
			{
				"op": "add_note",
				"note": {
					"id": "note_datacenter_route",
					"category": "工作",
					"title": "NOTE_DATACENTER_ROUTE_TITLE",
					"body": "NOTE_DATACENTER_ROUTE_BODY",
					"status": "active"
				}
			}
		],
		"choices": [
			{
				"label": "DLG_TRAVEL_DATACENTER_MENU_CHOICE0",
				"goto": "branch_selector"
			},
			{
				"label": "DLG_TRAVEL_DATACENTER_MENU_CHOICE1",
				"goto": "end"
			}
		]
	},
	"menu_track": {
		"speaker": "",
		"text": "DLG_TRAVEL_DATACENTER_MENU_TEXT",
		"effect": [
			{
				"op": "add_note",
				"note": {
					"id": "note_datacenter_route",
					"category": "工作",
					"title": "NOTE_DATACENTER_ROUTE_TITLE",
					"body": "NOTE_DATACENTER_ROUTE_BODY",
					"status": "active"
				}
			}
		],
		"choices": [
			{
				"label": "DLG_TRAVEL_DATACENTER_MENU_CHOICE0",
				"goto": "branch_selector"
			},
			{
				"label": "DLG_TRAVEL_DATACENTER_MENU_CHOICE1",
				"goto": "end"
			}
		]
	},
	"branch_selector": {
		"goto": [
			{
				"condition": {"flag": "seven_peace_branch_d", "op": "==", "value": true},
				"target": "prelude_d"
			},
			{
				"condition": {"flag": "seven_stopped_full", "op": "==", "value": true},
				"target": "prelude_a"
			},
			{
				"condition": {"flag": "seven_stopped_partial", "op": "==", "value": true},
				"target": "prelude_b"
			}
		]
	},
	"prelude_d": {
		"speaker": "",
		"text": "DLG_TRAVEL_DATACENTER_PRELUDE_D_TEXT",
		"goto": "confirm_by_wan_d"
	},
	"prelude_a": {
		"speaker": "",
		"text": "DLG_TRAVEL_DATACENTER_PRELUDE_A_TEXT",
		"goto": "confirm_by_wan_track"
	},
	"prelude_b": {
		"speaker": "",
		"text": "DLG_TRAVEL_DATACENTER_PRELUDE_B_TEXT",
		"goto": "confirm_by_wan_track"
	},
	"confirm_by_wan_d": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_TRAVEL_DATACENTER_CONFIRM_D_TEXT",
		"choices": [
			{
				"label": "DLG_TRAVEL_DATACENTER_CONFIRM_CHOICE0",
				"effect": [
					{"op": "set_flag", "key": "datacenter_travel_committed", "value": true}
				],
				"goto": "travel_to_datacenter"
			},
			{
				"label": "DLG_TRAVEL_DATACENTER_CONFIRM_CHOICE1",
				"goto": "end"
			}
		]
	},
	"confirm_by_wan_track": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_TRAVEL_DATACENTER_CONFIRM_TRACK_TEXT",
		"choices": [
			{
				"label": "DLG_TRAVEL_DATACENTER_CONFIRM_CHOICE0",
				"effect": [
					{"op": "set_flag", "key": "datacenter_travel_committed", "value": true}
				],
				"goto": "travel_to_datacenter"
			},
			{
				"label": "DLG_TRAVEL_DATACENTER_CONFIRM_CHOICE1",
				"goto": "end"
			}
		]
	},
	"menu_repeat": {
		"speaker": "",
		"text": "DLG_TRAVEL_DATACENTER_MENU_REPEAT_TEXT",
		"choices": [
			{
				"label": "DLG_TRAVEL_DATACENTER_MENU_CHOICE0",
				"goto": "travel_to_datacenter"
			},
			{
				"label": "DLG_TRAVEL_DATACENTER_MENU_CHOICE1",
				"goto": "end"
			}
		]
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

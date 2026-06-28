# Dialogue Tree for Cen
# File: res://data/dialogue/cen.gd

const TREE := {
	"start": {
		"goto": [
			{
				"condition": [
					{"flag": "met_cen", "op": "==", "value": true},
					{"flag": "affinity_cen", "op": ">=", "value": 2},
					{"flag": "heard_cen_warning", "op": "!=", "value": true}
				],
				"target": "warning"
			},
			{"condition": {"flag": "met_cen", "op": "==", "value": true}, "target": "retalk"},
			{"target": "first_meet"}
		]
	},

	"warning": {
		"speaker": "SPEAKER_CEN",
		"text": "DLG_CEN_WARNING_TEXT",
		"effect": [
			{"op": "set_flag", "key": "heard_cen_warning", "value": true}
		],
		"goto": "retalk"
	},

	"first_meet": {
		"speaker": "SPEAKER_CEN",
		"text": "DLG_CEN_FIRST_MEET_TEXT",
		"choices": [
			{"label": "DLG_CEN_FIRST_MEET_CHOICE0", "goto": "intro"},
			{"label": "DLG_CEN_FIRST_MEET_CHOICE1", "goto": "ask_about_living"},
			{"label": "DLG_CEN_FIRST_MEET_CHOICE2", "goto": "pickpocket_caught"}
		]
	},

	"ask_about_living": {
		"speaker": "SPEAKER_CEN",
		"text": "DLG_CEN_ASK_ABOUT_LIVING_TEXT",
		"goto": "intro"
	},

	"pickpocket_caught": {
		"speaker": "SPEAKER_CEN",
		"text": "DLG_CEN_PICKPOCKET_CAUGHT_TEXT",
		"effect": [
			{"op": "set_flag", "key": "met_cen", "value": true}
		]
	},

	"intro": {
		"speaker": "SPEAKER_CEN",
		"text": "DLG_CEN_INTRO_TEXT",
		"effect": [
			{"op": "set_flag", "key": "met_cen", "value": true},
			{"op": "add_int", "key": "affinity_cen", "value": 1}
		],
		"goto": "end_warm"
	},

	"end_warm": {
		"speaker": "SPEAKER_CEN",
		"text": "DLG_CEN_END_WARM_TEXT"
	},

	"retalk": {
		"speaker": "SPEAKER_CEN",
		"text": "DLG_CEN_RETALK_TEXT",
		"choices": [
			{
				"label": "DLG_CEN_RETALK_CHOICE0",
				"effect": [
					{"op": "add_int", "key": "affinity_cen", "value": 1}
				],
				"goto": "end_warm"
			},
			{"label": "DLG_CEN_RETALK_CHOICE1", "goto": "leave"}
		]
	},

	"leave": {
		"speaker": "SPEAKER_CEN",
		"text": "DLG_CEN_LEAVE_TEXT"
	}
}

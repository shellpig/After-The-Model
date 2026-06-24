# Dialogue Tree for Seven
# File: res://data/dialogue/seven.gd

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "met_seven", "op": "==", "value": true}, "target": "retalk"},
			{"target": "first_meet"}
		]
	},

	"first_meet": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_FIRST_MEET_TEXT",
		"choices": [
			{"label": "DLG_SEVEN_FIRST_MEET_CHOICE0", "goto": "ask_who"},
			{"label": "DLG_SEVEN_FIRST_MEET_CHOICE1", "goto": "hook"},
			{"label": "DLG_SEVEN_FIRST_MEET_CHOICE2", "goto": "leave"}
		]
	},

	"ask_who": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_ASK_WHO_TEXT",
		"goto": "hook"
	},

	"hook": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_HOOK_TEXT",
		"effect": [
			{"op": "set_flag", "key": "met_seven", "value": true},
			{"op": "set_flag", "key": "seven_hinted_name_topside", "value": true}
		],
		"goto": "end_cold"
	},

	"end_cold": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_END_COLD_TEXT"
	},

	"retalk": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_RETALK_TEXT",
		"choices": [
			{
				"label": "DLG_SEVEN_RETALK_CHOICE0",
				"condition": {"flag": "seven_hinted_name_topside", "op": "==", "value": true},
				"goto": "ask_name"
			},
			{"label": "DLG_SEVEN_CONDITION_CHOICE0", "goto": "leave"}
		]
	},

	"ask_name": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_ASK_NAME_TEXT"
	},

	"leave": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_LEAVE_TEXT"
	}
}

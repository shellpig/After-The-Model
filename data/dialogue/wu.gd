# Dialogue Tree for Wu
# File: res://data/dialogue/wu.gd

const TREE := {
	"start": {
		"goto": [
			{
				"condition": [
					{"flag": "met_wu", "op": "==", "value": true},
					{"flag": "affinity_wu", "op": ">=", "value": 2},
					{"flag": "heard_wu_warning", "op": "!=", "value": true}
				],
				"target": "warning"
			},
			{"condition": {"flag": "met_wu", "op": "==", "value": true}, "target": "retalk"},
			{"target": "first_meet"}
		]
	},

	"warning": {
		"speaker": "SPEAKER_WU",
		"text": "DLG_WU_WARNING_TEXT",
		"effect": [
			{"op": "set_flag", "key": "heard_wu_warning", "value": true}
		],
		"goto": "retalk"
	},

	"first_meet": {
		"speaker": "SPEAKER_WU",
		"text": "DLG_WU_FIRST_MEET_TEXT",
		"choices": [
			{"label": "DLG_WU_FIRST_MEET_CHOICE0", "goto": "repairer"},
			{"label": "DLG_WU_FIRST_MEET_CHOICE1", "goto": "maker"},
			{"label": "DLG_WU_FIRST_MEET_CHOICE2", "goto": "leave"}
		]
	},

	"repairer": {
		"speaker": "SPEAKER_WU",
		"text": "DLG_WU_REPAIRER_TEXT",
		"effect": [
			{"op": "set_flag", "key": "met_wu", "value": true},
			{"op": "add_int", "key": "affinity_wu", "value": 1}
		],
		"goto": "end_cold"
	},

	"maker": {
		"speaker": "SPEAKER_WU",
		"text": "DLG_WU_MAKER_TEXT",
		"effect": [
			{"op": "set_flag", "key": "met_wu", "value": true},
			{"op": "set_flag", "key": "knows_settlement_had_maker", "value": true},
			{"op": "add_int", "key": "affinity_wu", "value": 1}
		],
		"goto": "end_cold"
	},

	"end_cold": {
		"speaker": "SPEAKER_WU",
		"text": "DLG_WU_END_COLD_TEXT"
	},

	"retalk": {
		"speaker": "SPEAKER_WU",
		"text": "DLG_WU_RETALK_TEXT",
		"choices": [
			{
				"label": "DLG_WU_RETALK_CHOICE0",
				"effect": [
					{"op": "add_int", "key": "affinity_wu", "value": 1}
				],
				"goto": "end_cold"
			},
			{
				"label": "DLG_WU_RETALK_CHOICE1",
				"condition": {"flag": "knows_settlement_had_maker", "op": "==", "value": true},
				"goto": "ask_maker_more"
			},
			{"label": "DLG_WU_FIRST_MEET_CHOICE2", "goto": "leave"}
		]
	},

	"ask_maker_more": {
		"speaker": "SPEAKER_WU",
		"text": "DLG_WU_ASK_MAKER_MORE_TEXT"
	},

	"leave": {
		"speaker": "SPEAKER_WU",
		"text": "DLG_WU_LEAVE_TEXT"
	}
}

# Dialogue Tree for Seven
# File: res://data/dialogue/seven.gd

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "seven_peace_branch_d", "op": "==", "value": true}, "target": "retalk_d"},
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
			{
				"label": "DLG_SEVEN_RETALK_CHOICE_RECEIPT",
				"condition": [
					{"type": "has_item", "item_id": "childcare_supply_receipt", "op": "==", "value": true},
					{"flag": "peace_line_locked", "op": "!=", "value": true},
					{"flag": "seven_peace_branch_d", "op": "!=", "value": true}
				],
				"goto": [
					{"condition": {"flag": "seven_receipt_rebuffed", "op": "==", "value": true}, "target": "receipt_reprobe"},
					{"target": "receipt_probe"}
				]
			},
			{"label": "DLG_SEVEN_CONDITION_CHOICE0", "goto": "leave"}
		]
	},

	"retalk_d": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_RETALK_D_TEXT",
		"choices": [
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
	},

	"receipt_probe": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_RECEIPT_PROBE_TEXT",
		"choices": [
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_THREAT", "goto": "receipt_fail_cold"},
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_TAUNT", "goto": "receipt_fail_cold"},
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_QUESTION", "goto": "receipt_fail_cold"},
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_RETURN", "goto": "receipt_return"}
		]
	},

	"receipt_fail_cold": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_RECEIPT_FAIL_COLD_TEXT",
		"effect": [
			{"op": "set_flag", "key": "seven_receipt_rebuffed", "value": true}
		],
		"goto": "leave"
	},

	"receipt_reprobe": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_RECEIPT_REPROBE_TEXT",
		"choices": [
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_THREAT", "goto": "receipt_fail_cold"},
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_TAUNT", "goto": "receipt_fail_cold"},
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_QUESTION", "goto": "receipt_fail_cold"},
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_RETURN", "goto": "receipt_return"}
		]
	},

	"receipt_return": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_RECEIPT_RETURN_TEXT",
		"goto": "receipt_recognized"
	},

	"receipt_recognized": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_RECEIPT_RECOGNIZED_TEXT",
		"goto": "peace_branch_d_done"
	},

	"peace_branch_d_done": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_PEACE_BRANCH_D_DONE_TEXT",
		"effect": [
			{"op": "remove_item", "item_id": "childcare_supply_receipt", "value": 1},
			{"op": "set_flag", "key": "seven_peace_branch_d", "value": true},
			{"op": "add_int", "key": "affinity_seven", "value": 2},
			{"op": "add_trace", "value": -1}
		],
		"goto": "leave"
	}
}

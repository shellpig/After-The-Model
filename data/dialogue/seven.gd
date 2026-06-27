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

	# Receipt funnel = a 3-stage puzzle (mirrors the convenience-store robot
	# diagnosis): the player must pick the correct option in all three
	# consecutive stages for Seven to lower his guard and accept the receipt.
	# A wrong pick at ANY stage routes to a shared cold rebuff and ends at
	# leave (retriable). The protagonist never claims the receipt is Seven's;
	# the "this belongs to you" line only becomes available at stage 3, after
	# Seven's own reaction has revealed the connection.
	#
	# Stage 1 (first time).
	"receipt_probe": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_RECEIPT_PROBE_TEXT",
		"choices": [
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_THREAT", "goto": "rebuff_leverage"},
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_TAUNT", "goto": "rebuff_probe"},
			{"label": "DLG_SEVEN_RECEIPT_S1_CHOICE_CORRECT", "goto": "receipt_probe_s2"}
		]
	},

	# Stage 1 (retry, after a prior rebuff): terser opener, same branching.
	"receipt_reprobe": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_RECEIPT_REPROBE_TEXT",
		"choices": [
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_THREAT", "goto": "rebuff_leverage"},
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_TAUNT", "goto": "rebuff_probe"},
			{"label": "DLG_SEVEN_RECEIPT_S1_CHOICE_CORRECT", "goto": "receipt_probe_s2"}
		]
	},

	# Stage 2.
	"receipt_probe_s2": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_RECEIPT_S2_TEXT",
		"choices": [
			{"label": "DLG_SEVEN_RECEIPT_S2_CHOICE_PRY", "goto": "rebuff_probe"},
			{"label": "DLG_SEVEN_RECEIPT_S2_CHOICE_BARGAIN", "goto": "rebuff_leverage"},
			{"label": "DLG_SEVEN_RECEIPT_S2_CHOICE_CORRECT", "goto": "receipt_probe_s3"}
		]
	},

	# Stage 3 (the "give it back" line lives here, earned by Seven's reaction).
	"receipt_probe_s3": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_RECEIPT_S3_TEXT",
		"choices": [
			{"label": "DLG_SEVEN_RECEIPT_S3_CHOICE_PITY", "goto": "rebuff_leverage"},
			{"label": "DLG_SEVEN_RECEIPT_S3_CHOICE_WITHDRAW", "goto": "rebuff_probe"},
			{"label": "DLG_SEVEN_RECEIPT_CHOICE_RETURN", "goto": "receipt_return"}
		]
	},

	# Two shared cold-rejection replies. Every wrong choice across the three
	# stages routes to one of these by its nature; both set
	# seven_receipt_rebuffed, change no Trace/affinity, and are retriable.
	#  - rebuff_leverage: player treated the receipt as leverage / a bargaining
	#    chip / a pitying handout (threat, "what's it worth", "do you a favor").
	#  - rebuff_probe: player pried, mocked, or wavered (taunt, forcing him to
	#    admit it, taking the offer back).
	"rebuff_leverage": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_REBUFF_LEVERAGE_TEXT",
		"effect": [
			{"op": "set_flag", "key": "seven_receipt_rebuffed", "value": true}
		],
		"goto": "leave"
	},

	"rebuff_probe": {
		"speaker": "SPEAKER_SEVEN",
		"text": "DLG_SEVEN_REBUFF_PROBE_TEXT",
		"effect": [
			{"op": "set_flag", "key": "seven_receipt_rebuffed", "value": true}
		],
		"goto": "leave"
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

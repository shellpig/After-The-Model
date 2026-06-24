# Dialogue Tree for Wan
# File: res://data/dialogue/wan.gd

const TREE := {
	"start": {
		"goto": [
			{
				"condition": [
					{"flag": "mem_frag_linfei_1", "op": "==", "value": true},
					{"flag": "wan_noticed_daze", "op": "==", "value": false}
				],
				"target": "wan_daze_hook"
			},
			{"condition": {"flag": "gave_wan_old_module", "op": "==", "value": true}, "target": "retalk_close"},
			{"condition": {"flag": "met_wan", "op": "==", "value": true}, "target": "retalk"},
			{"target": "first_meet"}
		]
	},

	"wan_daze_hook": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_WAN_DAZE_HOOK_TEXT",
		"effect": [
			{"op": "set_flag", "key": "wan_noticed_daze", "value": true}
		],
		"goto": "wan_post_daze_routing"
	},

	"wan_post_daze_routing": {
		"goto": [
			{"condition": {"flag": "gave_wan_old_module", "op": "==", "value": true}, "target": "retalk_close"},
			{"condition": {"flag": "met_wan", "op": "==", "value": true}, "target": "retalk"},
			{"target": "first_meet"}
		]
	},
	"first_meet": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_FIRST_MEET_TEXT",
		"choices": [
			{"label": "DLG_WAN_FIRST_MEET_CHOICE0", "goto": "watch"},
			{"label": "DLG_WAN_FIRST_MEET_CHOICE1", "goto": "who"},
			{"label": "DLG_WAN_FIRST_MEET_CHOICE2", "goto": "flee"}
		]
	},
	"watch": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_WATCH_TEXT",
		"choices": [
			{"label": "DLG_WAN_WATCH_CHOICE0", "goto": "kin"},
			{"label": "DLG_WAN_WATCH_CHOICE1", "goto": "intel_gate"}
		]
	},
	"who": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_WHO_TEXT",
		"effect": [
			{"op": "set_flag", "key": "knows_wan_name", "value": true}
		],
		"goto": "watch"
	},
	"kin": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_KIN_TEXT",
		"effect": [
			{"op": "add_int", "key": "affinity_wan", "value": 1},
			{"op": "set_flag", "key": "met_wan", "value": true}
		],
		"goto": "end_warm"
	},
	"intel_gate": {
		"goto": [
			{"condition": {"type": "quest_status", "quest_id": "alley_backrooms_3f", "op": "==", "value": "completed"}, "target": "intel_already_done"},
			{"condition": {"type": "quest_status", "quest_id": "alley_backrooms_3f", "op": "==", "value": "active"}, "target": "intel_already_given"},
			{"condition": {"flag": "affinity_wan", "op": ">=", "value": 2}, "target": "intel"},
			{"target": "intel_locked"}
		]
	},
	"intel": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_INTEL_TEXT",
		"effect": [
			{"op": "start_quest", "value": "alley_backrooms_3f"}
		],
		"goto": "end_warm"
	},
	"intel_already_given": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_INTEL_ALREADY_GIVEN_TEXT",
		"goto": "end_warm"
	},
	"intel_already_done": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_INTEL_ALREADY_DONE_TEXT",
		"goto": "end_warm"
	},
	"intel_locked": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_INTEL_LOCKED_TEXT",
		"effect": [
			{"op": "add_int", "key": "affinity_wan", "value": 1},
			{"op": "set_flag", "key": "met_wan", "value": true}
		],
		"goto": "end_cold"
	},
	"end_warm": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_END_WARM_TEXT"
	},
	"end_cold": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_END_COLD_TEXT"
	},
	"flee": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_FLEE_TEXT"
	},
	"retalk": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_RETALK_TEXT",
		"choices": [
			{
				"label": "DLG_WAN_RETALK_CHOICE0",
				"effect": [
					{"op": "add_int", "key": "affinity_wan", "value": 1}
				],
				"goto": "end_warm"
			},
			{"label": "DLG_WAN_RETALK_CHOICE1", "goto": "intel_gate"},
			{"label": "DLG_WU_CONDITION_CHOICE0", "goto": "flee"},
			{
				"label": "DLG_WAN_RETALK_CHOICE3",
				"condition": [
					{"type": "quest_status", "quest_id": "alley_backrooms_3f", "op": "==", "value": "active"},
					{"type": "quest_step", "quest_id": "alley_backrooms_3f", "op": "==", "value": "found_activation_box"},
					{"type": "has_item", "item_id": "early_ai_assistant_activation_box", "op": "==", "value": true}
				],
				"goto": "alley_backrooms_turn_in"
			},
			{
				"label": "DLG_WAN_RETALK_CHOICE4",
				"condition": {
					"type": "has_item", "item_id": "childcare_supply_receipt", "op": "==", "value": true
				},
				"goto": "sell_receipt"
			}
		]
	},
	"alley_backrooms_turn_in": {
		"goto": [
			{"condition": {"type": "has_item", "item_id": "old_ai_authorization_module", "op": "==", "value": true}, "target": "turn_in_found_module"},
			{"target": "turn_in_plain"}
		]
	},
	"turn_in_found_module": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_TURN_IN_FOUND_MODULE_TEXT",
		"choices": [
			{"label": "DLG_WAN_TURN_IN_FOUND_MODULE_CHOICE0", "goto": "turn_in_plain"},
			{"label": "DLG_WAN_TURN_IN_FOUND_MODULE_CHOICE1", "goto": "turn_in_full"}
		]
	},
	"turn_in_plain": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_TURN_IN_PLAIN_TEXT",
		"effect": [
			{"op": "remove_item", "item_id": "early_ai_assistant_activation_box", "value": 1},
			{"op": "add_credits", "value": 500},
			{"op": "complete_quest", "value": "alley_backrooms_3f"}
		],
		"goto": "end_warm"
	},
	"turn_in_full": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_TURN_IN_FULL_TEXT",
		"effect": [
			{"op": "remove_item", "item_id": "early_ai_assistant_activation_box", "value": 1},
			{"op": "remove_item", "item_id": "old_ai_authorization_module", "value": 1},
			{"op": "add_credits", "value": 1000},
			{"op": "add_int", "key": "affinity_wan", "value": 2},
			{"op": "set_flag", "key": "gave_wan_old_module", "value": true},
			{"op": "complete_quest", "value": "alley_backrooms_3f"}
		],
		"goto": "end_warm"
	},
	"retalk_close": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_RETALK_CLOSE_TEXT",
		"choices": [
			{
				"label": "DLG_WAN_RETALK_CLOSE_CHOICE0",
				"effect": [
					{"op": "add_int", "key": "affinity_wan", "value": 1}
				],
				"goto": "end_close"
			},
			{"label": "DLG_WAN_RETALK_CHOICE1", "goto": "intel_gate"},
			{"label": "DLG_WU_CONDITION_CHOICE0", "goto": "flee_close"},
			{
				"label": "DLG_WAN_RETALK_CHOICE4",
				"condition": {
					"type": "has_item", "item_id": "childcare_supply_receipt", "op": "==", "value": true
				},
				"goto": "sell_receipt"
			}
		]
	},
	"end_close": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_END_CLOSE_TEXT"
	},
	"flee_close": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_FLEE_CLOSE_TEXT"
	},
	"sell_receipt": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_SELL_RECEIPT_TEXT",
		"choices": [
			{"label": "DLG_WAN_SELL_RECEIPT_CHOICE0", "goto": "do_sell_receipt"},
			{"label": "DLG_WAN_SELL_RECEIPT_CHOICE1", "goto": "end_warm"}
		]
	},
	"do_sell_receipt": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_DO_SELL_RECEIPT_TEXT",
		"effect": [
			{"op": "remove_item", "item_id": "childcare_supply_receipt", "value": 1},
			{"op": "add_credits", "value": 200},
			{"op": "add_trace", "value": -1},
			{"op": "add_int", "key": "affinity_wan", "value": -1},
			{"op": "set_flag", "key": "peace_line_locked", "value": true}
		],
		"goto": "end_warm"
	}
}

# Dialogue Tree for the convenience store control robot (店控機器人)
# File: res://data/dialogue/store_robot.gd
#
# start 路由依狀態分流（8-B 契約）：
#   vendor_bot_repaired -> repaired_router（8-E：reset / gleaned 分流招呼；8-F 於招呼結尾接 open_shop）
#   repair_vendor_bot active -> diagnose_intro（8-D 置換為深度診斷對話樹）
#   其餘 -> babble_intro（前導胡言亂語，設 talked_store_robot）

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "vendor_bot_repaired", "op": "==", "value": true}, "target": "repaired_router"},
			{"condition": {"type": "quest_status", "quest_id": "repair_vendor_bot", "op": "==", "value": "active"}, "target": "diagnose_intro"},
			{
				"condition": [
					{"flag": "mem_frag_linfei_1", "op": "==", "value": true},
					{"flag": "ada_misrecognized", "op": "==", "value": false}
				],
				"target": "ada_misrecognized_hook"
			},
			{"target": "babble_intro"}
		]
	},

	"ada_misrecognized_hook": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_ADA_MISRECOGNIZED_HOOK_TEXT",
		"effect": [
			{"op": "set_flag", "key": "ada_misrecognized", "value": true},
			{"op": "set_flag", "key": "talked_store_robot", "value": true}
		],
		"goto": "babble_intro"
	},

	# --- 8-B 前導 babble ---
	"babble_intro": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_BABBLE_INTRO_TEXT",
		"effect": [
			{"op": "set_flag", "key": "talked_store_robot", "value": true}
		],
		"choices": [
			{"label": "DLG_STORE_ROBOT_BABBLE_INTRO_CHOICE0", "goto": "babble_deny"},
			{"label": "DLG_STORE_ROBOT_BABBLE_INTRO_CHOICE1", "goto": "babble_mutter"}
		]
	},
	"babble_deny": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_BABBLE_DENY_TEXT",
		"goto": "babble_end"
	},
	"babble_mutter": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_BABBLE_MUTTER_TEXT",
		"goto": "babble_end"
	},
	"babble_end": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_BABBLE_END_TEXT"
	},

	# --- 8-D：深度診斷對話樹 ---
	"diagnose_intro": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_DIAGNOSE_INTRO_TEXT",
		"choices": [
			{"label": "DLG_STORE_ROBOT_DIAGNOSE_INTRO_CHOICE0", "goto": "diagnose_identity"},
			{"label": "DLG_STORE_ROBOT_DIAGNOSE_INTRO_CHOICE1", "goto": "diagnose_partial_intro"}
		]
	},
	"diagnose_identity": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_DIAGNOSE_IDENTITY_TEXT",
		"choices": [
			{"label": "DLG_STORE_ROBOT_DIAGNOSE_IDENTITY_CHOICE0", "goto": "diagnose_partial_intro"},
			{
				"label": "DLG_STORE_ROBOT_DIAGNOSE_IDENTITY_CHOICE1",
				"condition": [
					{"type": "has_note", "note_id": "clue_robot_plate"},
					{"type": "has_note", "note_id": "clue_counter_photo"}
				],
				"goto": "diagnose_identity_correct"
			},
			{"label": "DLG_STORE_ROBOT_DIAGNOSE_IDENTITY_CHOICE2", "goto": "diagnose_partial_intro"}
		]
	},
	"diagnose_identity_correct": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_DIAGNOSE_IDENTITY_CORRECT_TEXT",
		"choices": [
			{"label": "DLG_STORE_ROBOT_DIAGNOSE_IDENTITY_CORRECT_CHOICE0", "goto": "diagnose_partial_intro"},
			{"label": "DLG_STORE_ROBOT_DIAGNOSE_IDENTITY_CORRECT_CHOICE1", "goto": "diagnose_partial_intro"},
			{
				"label": "DLG_STORE_ROBOT_DIAGNOSE_IDENTITY_CORRECT_CHOICE2",
				"condition": [
					{"type": "has_note", "note_id": "clue_clerk_locker"},
					{"type": "has_note", "note_id": "clue_termination_notice"}
				],
				"goto": "diagnose_reason_correct"
			}
		]
	},
	"diagnose_reason_correct": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_DIAGNOSE_REASON_CORRECT_TEXT",
		"choices": [
			{"label": "DLG_STORE_ROBOT_DIAGNOSE_REASON_CORRECT_CHOICE0", "goto": "diagnose_partial_intro"},
			{
				"label": "DLG_STORE_ROBOT_DIAGNOSE_REASON_CORRECT_CHOICE1",
				"condition": {"type": "has_note", "note_id": "clue_clerk_diary"},
				"goto": "diagnose_truth_leaf"
			},
			{"label": "DLG_STORE_ROBOT_DIAGNOSE_REASON_CORRECT_CHOICE2", "goto": "diagnose_partial_intro"}
		]
	},
	"diagnose_partial_intro": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_DIAGNOSE_PARTIAL_INTRO_TEXT",
		"effect": [
			{"op": "set_quest_flag", "quest_id": "repair_vendor_bot", "key": "mainframe_revealed", "value": true},
			{"op": "set_quest_flag", "quest_id": "repair_vendor_bot", "key": "diagnosed", "value": true}
		]
	},
	"diagnose_truth_leaf": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_DIAGNOSE_TRUTH_LEAF_TEXT",
		"effect": [
			{"op": "set_quest_flag", "quest_id": "repair_vendor_bot", "key": "mainframe_revealed", "value": true},
			{"op": "set_quest_flag", "quest_id": "repair_vendor_bot", "key": "diagnosed", "value": true},
			{"op": "set_quest_flag", "quest_id": "repair_vendor_bot", "key": "understood_robot_truth", "value": true}
		]
	},

	# --- 8-E：修好後招呼，依 store_robot_resolution 分流；8-F：招呼結尾以 open_shop effect 開 ShopPanel ---
	"repaired_router": {
		"goto": [
			{"condition": {"flag": "store_robot_resolution", "op": "==", "value": "gleaned"}, "target": "repaired_gleaned"},
			{"target": "repaired_reset"}
		]
	},
	"repaired_reset": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_REPAIRED_RESET_TEXT",
		"effect": [
			{"op": "open_shop", "value": "convenience_store"}
		]
	},
	"repaired_gleaned": {
		"speaker": "SPEAKER_STORE_ROBOT",
		"text": "DLG_STORE_ROBOT_REPAIRED_GLEANED_TEXT",
		"effect": [
			{"op": "open_shop", "value": "convenience_store"}
		]
	}
}

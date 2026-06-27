# Dialogue Tree for the collector Lu Qichen (鹿其琛)
# File: res://data/dialogue/lu_qichen.gd

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "met_lu", "op": "==", "value": true}, "target": "entry_to_hub"},
			{"target": "first_meet"}
		]
	},

	"entry_to_hub": {
		"goto": [
			{
				"condition": [
					{"flag": "mem_frag_linfei_1", "op": "==", "value": true},
					{"flag": "lu_hinted_topside", "op": "==", "value": false}
				],
				"target": "lu_daze_hook"
			},
			{"target": "hub"}
		]
	},

	"lu_daze_hook": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_LU_DAZE_HOOK_TEXT",
		"effect": [
			{"op": "set_flag", "key": "lu_hinted_topside", "value": true}
		],
		"goto": "hub"
	},

	"first_meet": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_FIRST_MEET_TEXT",
		"effect": [
			{"op": "set_flag", "key": "met_lu", "value": true}
		],
		"choices": [
			{"label": "DLG_LU_QICHEN_FIRST_MEET_CHOICE0", "goto": "first_meet_reply"},
			{"label": "DLG_LU_QICHEN_FIRST_MEET_CHOICE1", "goto": "first_meet_brush_off"}
		]
	},
	"first_meet_reply": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_FIRST_MEET_REPLY_TEXT",
		"goto": "entry_to_hub"
	},
	"first_meet_brush_off": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_FIRST_MEET_BRUSH_OFF_TEXT",
		"goto": "entry_to_hub"
	},

	"hub": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_HUB_TEXT",
		"choices": [
			{
				"label": "DLG_LU_QICHEN_HUB_CHOICE0",
				"condition": [
					{"type": "has_item", "item_id": "old_probe_module"},
					{"type": "has_item", "item_id": "fingerless_gloves"},
					{"flag": "gleaner_gloves_installed", "op": "==", "value": false}
				],
				"goto": "appraise"
			},
			{
				"label": "DLG_LU_QICHEN_HUB_CHOICE1",
				"goto": "sell_gate"
			},
			{
				"label": "DLG_LU_QICHEN_HUB_CHOICE2",
				"goto": "chat_about_room"
			},
			{
				"label": "DLG_LU_QICHEN_HUB_CHOICE3",
				"goto": "exit"
			}
		]
	},

	"appraise": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_APPRAISE_TEXT",
		"choices": [
			{"label": "DLG_LU_QICHEN_APPRAISE_CHOICE0", "goto": "appraise_explain"},
			{"label": "DLG_LU_QICHEN_APPRAISE_CHOICE1", "goto": "appraise_gloves"}
		]
	},
	"appraise_explain": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_APPRAISE_EXPLAIN_TEXT",
		"goto": "appraise_gloves"
	},
	"appraise_gloves": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_APPRAISE_GLOVES_TEXT",
		"effect": [
			{"op": "install_module"}
		],
		"goto": "appraise_instructions"
	},
	"appraise_instructions": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_APPRAISE_INSTRUCTIONS_TEXT",
		"choices": [
			{"label": "DLG_LU_QICHEN_APPRAISE_INSTRUCTIONS_CHOICE0", "goto": "appraise_return_hint"},
			{"label": "DLG_LU_QICHEN_APPRAISE_INSTRUCTIONS_CHOICE1", "goto": "hub"}
		]
	},
	"appraise_return_hint": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_APPRAISE_RETURN_HINT_TEXT",
		"goto": "hub"
	},

	"chat_about_room": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_CHAT_ABOUT_ROOM_TEXT",
		"goto": "hub"
	},

	"sell_gate": {
		"goto": [
			{"condition": [{"type": "echo_complete", "value": "echo_clerk"}, {"type": "echo_unsold", "value": "echo_clerk"}], "target": "sell_menu"},
			{"condition": [{"type": "echo_complete", "value": "echo_room401_tenant"}, {"type": "echo_unsold", "value": "echo_room401_tenant"}], "target": "sell_menu"},
			{"condition": [{"type": "echo_complete", "value": "echo_song_rain_doesnt_stop"}, {"type": "echo_unsold", "value": "echo_song_rain_doesnt_stop"}], "target": "sell_menu"},
			{"condition": [{"type": "echo_complete", "value": "echo_settlement_erased"}, {"type": "echo_unsold", "value": "echo_settlement_erased"}], "target": "sell_menu"},
			{"condition": [{"type": "echo_complete", "value": "echo_ada_reset"}, {"type": "echo_unsold", "value": "echo_ada_reset"}], "target": "sell_menu"},
			{"condition": [{"type": "echo_complete", "value": "echo_linfei"}, {"type": "echo_unsold", "value": "echo_linfei"}], "target": "sell_menu"},
			{"target": "sell_empty"}
		]
	},
	"sell_empty": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_EMPTY_TEXT",
		"goto": "hub"
	},
	
	"sell_menu": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_MENU_TEXT",
		"choices": [
			{
				"label": "DLG_LU_QICHEN_SELL_MENU_CHOICE0",
				"condition": [
					{"type": "echo_complete", "value": "echo_clerk"},
					{"type": "echo_unsold", "value": "echo_clerk"}
				],
				"goto": "sell_clerk"
			},
			{
				"label": "DLG_LU_QICHEN_SELL_MENU_CHOICE1",
				"condition": [
					{"type": "echo_complete", "value": "echo_room401_tenant"},
					{"type": "echo_unsold", "value": "echo_room401_tenant"}
				],
				"goto": "sell_room401"
			},
			{
				"label": "DLG_LU_QICHEN_SELL_MENU_CHOICE2",
				"condition": [
					{"type": "echo_complete", "value": "echo_song_rain_doesnt_stop"},
					{"type": "echo_unsold", "value": "echo_song_rain_doesnt_stop"}
				],
				"goto": "sell_song"
			},
			{
				"label": "DLG_LU_QICHEN_SELL_MENU_CHOICE_SETTLEMENT",
				"condition": [
					{"type": "echo_complete", "value": "echo_settlement_erased"},
					{"type": "echo_unsold", "value": "echo_settlement_erased"}
				],
				"goto": "sell_settlement"
			},
			{
				"label": "DLG_LU_QICHEN_SELL_MENU_CHOICE_ADA",
				"condition": [
					{"type": "echo_complete", "value": "echo_ada_reset"},
					{"type": "echo_unsold", "value": "echo_ada_reset"}
				],
				"goto": "sell_ada"
			},
			{
				"label": "DLG_LU_QICHEN_SELL_MENU_CHOICE_LINFEI",
				"condition": [
					{"type": "echo_complete", "value": "echo_linfei"},
					{"type": "echo_unsold", "value": "echo_linfei"}
				],
				"goto": "sell_linfei"
			},
			{
				"label": "DLG_LU_QICHEN_SELL_MENU_CHOICE3",
				"goto": "hub"
			}
		]
	},

	"sell_clerk": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_CLERK_TEXT",
		"choices": [
			{
				"label": "DLG_LU_QICHEN_SELL_SONG_CHOICE0",
				"effect": [
					{"op": "sell_echo", "value": "echo_clerk"}
				],
				"goto": "sell_clerk_sold"
			},
			{
				"label": "DLG_LU_QICHEN_SELL_SONG_CHOICE1",
				"goto": "sell_menu"
			}
		]
	},
	"sell_clerk_sold": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_CLERK_SOLD_TEXT",
		"goto": "sell_done"
	},
	"sell_room401": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_ROOM401_TEXT",
		"choices": [
			{
				"label": "DLG_LU_QICHEN_SELL_SONG_CHOICE0",
				"effect": [
					{"op": "sell_echo", "value": "echo_room401_tenant"}
				],
				"goto": "sell_room401_sold"
			},
			{
				"label": "DLG_LU_QICHEN_SELL_SONG_CHOICE1",
				"goto": "sell_menu"
			}
		]
	},
	"sell_room401_sold": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_ROOM401_SOLD_TEXT",
		"goto": "sell_done"
	},
	"sell_song": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_SONG_TEXT",
		"choices": [
			{
				"label": "DLG_LU_QICHEN_SELL_SONG_CHOICE0",
				"effect": [
					{"op": "sell_echo", "value": "echo_song_rain_doesnt_stop"}
				],
				"goto": "sell_song_sold"
			},
			{
				"label": "DLG_LU_QICHEN_SELL_SONG_CHOICE1",
				"goto": "sell_menu"
			}
		]
	},
	"sell_song_sold": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_SONG_SOLD_TEXT",
		"goto": "sell_done"
	},
	"sell_settlement": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_SETTLEMENT_TEXT",
		"choices": [
			{
				"label": "DLG_LU_QICHEN_SELL_SONG_CHOICE0",
				"effect": [
					{"op": "sell_echo", "value": "echo_settlement_erased"}
				],
				"goto": "sell_settlement_sold"
			},
			{
				"label": "DLG_LU_QICHEN_SELL_SONG_CHOICE1",
				"goto": "sell_menu"
			}
		]
	},
	"sell_settlement_sold": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_SETTLEMENT_SOLD_TEXT",
		"goto": "sell_done"
	},
	"sell_ada": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_ADA_TEXT",
		"choices": [
			{
				"label": "DLG_LU_QICHEN_SELL_SONG_CHOICE0",
				"effect": [
					{"op": "sell_echo", "value": "echo_ada_reset"}
				],
				"goto": "sell_ada_sold"
			},
			{
				"label": "DLG_LU_QICHEN_SELL_SONG_CHOICE1",
				"goto": "sell_menu"
			}
		]
	},
	"sell_ada_sold": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_ADA_SOLD_TEXT",
		"goto": "sell_done"
	},
	"sell_linfei": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_LINFEI_TEXT",
		"choices": [
			{
				"label": "DLG_LU_QICHEN_SELL_SONG_CHOICE0",
				"effect": [
					{"op": "sell_echo", "value": "echo_linfei"}
				],
				"goto": "sell_linfei_sold"
			},
			{
				"label": "DLG_LU_QICHEN_SELL_SONG_CHOICE1",
				"goto": "sell_menu"
			}
		]
	},
	"sell_linfei_sold": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_LINFEI_SOLD_TEXT",
		"goto": "sell_done"
	},

	"sell_done": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_SELL_DONE_TEXT",
		"goto": "sell_gate"
	},

	"exit": {
		"speaker": "SPEAKER_LU_QICHEN",
		"text": "DLG_LU_QICHEN_EXIT_TEXT"
	}
}

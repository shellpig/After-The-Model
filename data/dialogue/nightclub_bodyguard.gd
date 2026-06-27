# Dialogue Tree for Nightclub Bodyguard
# File: res://data/dialogue/nightclub_bodyguard.gd

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "passed_nightclub_security", "op": "==", "value": true}, "target": "already_passed"},
			{"target": "lobby"}
		]
	},

	"already_passed": {
		"speaker": "SPEAKER_BODYGUARD",
		"text": "DLG_BODYGUARD_ALREADY_PASSED_TEXT"
	},

	"lobby": {
		"speaker": "SPEAKER_BODYGUARD",
		"text": "DLG_BODYGUARD_START_TEXT",
		"choices": [
			{
				"label": "DLG_BODYGUARD_BRIBE_CHOICE",
				"goto": [
					{"condition": {"type": "credits", "op": ">=", "value": 500}, "target": "bribe_success"},
					{"target": "bribe_fail"}
				]
			},
			{
				"label": "DLG_BODYGUARD_FAKE_IDENTITY_CHOICE",
				"goto": [
					{"condition": {"flag": "found_staff_pass", "op": "==", "value": true}, "target": "fake_identity_success"},
					{"target": "fake_identity_fail"}
				]
			},
			{
				"label": "DLG_BODYGUARD_LEAVE_CHOICE",
				"goto": "leave"
			}
		]
	},

	"bribe_success": {
		"speaker": "SPEAKER_BODYGUARD",
		"text": "DLG_BODYGUARD_BRIBE_SUCCESS_TEXT",
		"effect": [
			{"op": "add_credits", "value": -500},
			{"op": "set_flag", "key": "passed_nightclub_security", "value": true}
		]
	},

	"bribe_fail": {
		"speaker": "SPEAKER_BODYGUARD",
		"text": "DLG_BODYGUARD_BRIBE_FAIL_TEXT"
	},

	"fake_identity_success": {
		"speaker": "SPEAKER_BODYGUARD",
		"text": "DLG_BODYGUARD_FAKE_IDENTITY_SUCCESS_TEXT",
		"effect": [
			{"op": "set_flag", "key": "passed_nightclub_security", "value": true}
		]
	},

	"fake_identity_fail": {
		"speaker": "SPEAKER_BODYGUARD",
		"text": "DLG_BODYGUARD_FAKE_IDENTITY_FAIL_TEXT"
	},

	"leave": {
		"speaker": "SPEAKER_BODYGUARD",
		"text": "DLG_BODYGUARD_LEAVE_TEXT"
	}
}

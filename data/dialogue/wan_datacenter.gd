# Dialogue Tree for Wan (Act 4 datacenter entrance pull)
# File: res://data/dialogue/wan_datacenter.gd

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "wan_act4_pull_seen", "op": "==", "value": true}, "target": "retalk"},
			{"target": "pull"}
		]
	},

	"pull": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_DATACENTER_PULL_SAFE_TEXT",
		"goto": "pull_private"
	},

	"pull_private": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_DATACENTER_PULL_PRIVATE_TEXT",
		"effect": [
			{"op": "set_flag", "key": "wan_act4_pull_seen", "value": true}
		]
	},

	"retalk": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_DATACENTER_RETALK_TEXT"
	}
}

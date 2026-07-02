# Dialogue Tree for Ada (Act 4 final appearance, §3 four-beat closure)
# File: res://data/dialogue/ada.gd

const TREE := {
	"start": {
		"speaker": "SPEAKER_ADA",
		"text": "DLG_ADA_FINAL_WORDS_TEXT",
		"effect": [
			{"op": "set_flag", "key": "ada_final_words_seen", "value": true}
		]
	}
}

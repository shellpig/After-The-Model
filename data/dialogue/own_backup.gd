# Dialogue Tree for "自己的備份" — 三結局路由 (Phase 27-B)
# File: res://data/dialogue/own_backup.gd
#
# 只有在 datacenter_backup_core.gd 判定 stood_before_own_backup == true 且
# 三 route 旗標皆未設時才會被 start_dialogue("own_backup") 開啟（level 端 gate，
# 本樹不重複判斷）。三選（灌回去 / 刪掉它 / 拷貝走）無條件全開，不看 Trust / Trace；
# 選定即鎖（唯一寫入點在各 lock 節點）；退開／回去再想皆不寫旗標、可重開。

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "ending_save_hint_seen", "op": "==", "value": true}, "target": "anchor"},
			{"target": "save_hint"}
		]
	},

	# --- 存檔提示（一次性）：文案 2026-07-03 拍板 ---
	"save_hint": {
		"speaker": "",
		"text": "DLG_OWN_BACKUP_SAVE_HINT_TEXT",
		"effect": [
			{"op": "set_flag", "key": "ending_save_hint_seen", "value": true}
		],
		"goto": "anchor"
	},

	# --- 重錨定 + 三個動詞（節拍 2/3 合併一節點；名字不露出） ---
	"anchor": {
		"speaker": "",
		"text": "DLG_OWN_BACKUP_ANCHOR_TEXT",
		"choices": [
			{"label": "DLG_OWN_BACKUP_CHOICE_RECLAIM", "goto": "confirm_reclaim"},
			{"label": "DLG_OWN_BACKUP_CHOICE_PROTECT", "goto": "confirm_protect"},
			{"label": "DLG_OWN_BACKUP_CHOICE_EXPOSE", "goto": "confirm_expose"},
			{"label": "DLG_OWN_BACKUP_CHOICE_WITHDRAW", "goto": "withdraw"}
		]
	},

	"withdraw": {
		"speaker": "",
		"text": "DLG_OWN_BACKUP_WITHDRAW_TEXT"
	},

	# --- 確認前小節（只給重量，不劇透結局）---
	"confirm_reclaim": {
		"speaker": "",
		"text": "DLG_OWN_BACKUP_CONFIRM_RECLAIM_TEXT",
		"choices": [
			{"label": "DLG_OWN_BACKUP_LOCK_IN", "goto": "reclaim_lock"},
			{"label": "DLG_OWN_BACKUP_RECONSIDER", "goto": "anchor"}
		]
	},
	"confirm_protect": {
		"speaker": "",
		"text": "DLG_OWN_BACKUP_CONFIRM_PROTECT_TEXT",
		"choices": [
			{"label": "DLG_OWN_BACKUP_LOCK_IN", "goto": "protect_lock"},
			{"label": "DLG_OWN_BACKUP_RECONSIDER", "goto": "anchor"}
		]
	},
	"confirm_expose": {
		"speaker": "",
		"text": "DLG_OWN_BACKUP_CONFIRM_EXPOSE_TEXT",
		"choices": [
			{"label": "DLG_OWN_BACKUP_LOCK_IN", "goto": "expose_lock"},
			{"label": "DLG_OWN_BACKUP_RECONSIDER", "goto": "anchor"}
		]
	},

	# --- 鎖點：互斥旗標唯一寫入點 ---
	"reclaim_lock": {
		"speaker": "",
		"text": "DLG_OWN_BACKUP_RECLAIM_LOCK_TEXT",
		"effect": [
			{"op": "set_flag", "key": "ending_route_reclaim", "value": true}
		]
	},
	"protect_lock": {
		"speaker": "",
		"text": "DLG_OWN_BACKUP_PROTECT_LOCK_TEXT",
		"effect": [
			{"op": "set_flag", "key": "ending_route_protect", "value": true}
		]
	},
	"expose_lock": {
		"speaker": "",
		"text": "DLG_OWN_BACKUP_EXPOSE_LOCK_TEXT",
		"effect": [
			{"op": "set_flag", "key": "ending_route_expose", "value": true},
			{"op": "travel", "scene_id": "broadcast_station", "entry_point_id": "from_backup_core"}
		]
	}
}

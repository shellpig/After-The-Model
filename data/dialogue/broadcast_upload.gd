# Dialogue Tree for the broadcast station's upload terminal — 清洗閘五拍 (Phase 27-C)
# File: res://data/dialogue/broadcast_upload.gd
#
# level 端 gate（broadcast_station.gd）已保證：本樹只在 expose_upload_done == false
# 時被開啟；已上傳後改走中性 idle examine（MSG_BROADCAST_UPLOAD_DONE_IDLE），不重開樹。
# 五拍：① 掃描（echo_count 兩檔）→ ② 警告（seven_stopped_partial 變體）→
# ③ 反諷＋首選（動手清洗 / 原樣保留 / 退開）→ ④ 代價（兩版，不告知刪了哪些）→
# ⑤ 最終確認＝鎖點（唯一寫入 expose_upload_cleaned / expose_upload_done 的節點）。
# 退開（任一層）皆無 effect、不留半套狀態，下次重開整段重走。

# 已蒐殘響 segment 總數門檻：全遊戲最多 17 段（1+3+3+1+2+1+6），
# 半數以上（>=9）視為「蒐得多」；門檻為敘事用途，Phase 27-C 開工校定。
const ECHO_COUNT_HIGH_THRESHOLD := 9

const TREE := {
	"start": {
		"goto": [
			{"condition": {"type": "echo_count", "op": ">=", "value": ECHO_COUNT_HIGH_THRESHOLD}, "target": "scan_high"},
			{"target": "scan_low"}
		]
	},

	# --- ① 掃描：echo_count 兩檔文字變體 ---
	"scan_high": {
		"speaker": "",
		"text": "DLG_BROADCAST_UPLOAD_SCAN_HIGH_TEXT",
		"goto": "warning"
	},
	"scan_low": {
		"speaker": "",
		"text": "DLG_BROADCAST_UPLOAD_SCAN_LOW_TEXT",
		"goto": "warning"
	},

	# --- ② 中性警告：seven_stopped_partial 時加 Branch B 變體句 ---
	"warning": {
		"goto": [
			{"condition": {"flag": "seven_stopped_partial", "op": "==", "value": true}, "target": "warning_branch_b"},
			{"target": "warning_base"}
		]
	},
	"warning_base": {
		"speaker": "",
		"text": "DLG_BROADCAST_UPLOAD_WARNING_TEXT",
		"goto": "irony"
	},
	"warning_branch_b": {
		"speaker": "",
		"text": "DLG_BROADCAST_UPLOAD_WARNING_BRANCH_B_TEXT",
		"goto": "irony"
	},

	# --- ③ 手藝反諷 + 首選 ---
	"irony": {
		"speaker": "",
		"text": "DLG_BROADCAST_UPLOAD_IRONY_TEXT",
		"choices": [
			{"label": "DLG_BROADCAST_UPLOAD_CHOICE_CLEAN", "goto": "cost_clean"},
			{"label": "DLG_BROADCAST_UPLOAD_CHOICE_RAW", "goto": "cost_raw"},
			{"label": "DLG_BROADCAST_UPLOAD_CHOICE_WITHDRAW", "goto": "withdraw"}
		]
	},

	"withdraw": {
		"speaker": "",
		"text": "DLG_BROADCAST_UPLOAD_WITHDRAW_TEXT"
	},

	# --- ④ 代價當場兌現（兩版，不告知刪了哪些）---
	"cost_clean": {
		"speaker": "",
		"text": "DLG_BROADCAST_UPLOAD_COST_CLEAN_TEXT",
		"goto": "confirm_clean"
	},
	"cost_raw": {
		"speaker": "",
		"text": "DLG_BROADCAST_UPLOAD_COST_RAW_TEXT",
		"goto": "confirm_raw"
	},

	# --- ⑤ 最終確認＝鎖點（唯一寫入點）---
	"confirm_clean": {
		"speaker": "",
		"text": "DLG_BROADCAST_UPLOAD_CONFIRM_TEXT",
		"choices": [
			{"label": "DLG_BROADCAST_UPLOAD_CHOICE_UPLOAD", "goto": "upload_clean_lock"},
			{"label": "DLG_BROADCAST_UPLOAD_CHOICE_WITHDRAW", "goto": "withdraw"}
		]
	},
	"confirm_raw": {
		"speaker": "",
		"text": "DLG_BROADCAST_UPLOAD_CONFIRM_TEXT",
		"choices": [
			{"label": "DLG_BROADCAST_UPLOAD_CHOICE_UPLOAD", "goto": "upload_raw_lock"},
			{"label": "DLG_BROADCAST_UPLOAD_CHOICE_WITHDRAW", "goto": "withdraw"}
		]
	},

	"upload_clean_lock": {
		"speaker": "",
		"text": "DLG_BROADCAST_UPLOAD_DONE_TEXT",
		"effect": [
			{"op": "set_flag", "key": "expose_upload_cleaned", "value": true},
			{"op": "set_flag", "key": "expose_upload_done", "value": true}
		]
	},
	"upload_raw_lock": {
		"speaker": "",
		"text": "DLG_BROADCAST_UPLOAD_DONE_TEXT",
		"effect": [
			{"op": "set_flag", "key": "expose_upload_cleaned", "value": false},
			{"op": "set_flag", "key": "expose_upload_done", "value": true}
		]
	}
}

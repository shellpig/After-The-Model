# Dialogue Tree for Wan's ending farewell (Phase 28-A Reclaim; Phase 28-B Protect branch TBD)
# File: res://data/dialogue/wan_epilogue.gd
#
# 由 apartment_entrance.gd 在 epilogue_wan entry point 以 NpcAutoDialogueArea 自動觸發
# （26-A pattern 複用）。start 依 ending_route_reclaim 分流；Protect（ending_route_protect）
# 支的固定三句台詞屬 28-B 範圍，尚未實作，暫時 fallback 走 Reclaim 支。
# Reclaim 支再依 affinity_wan（既有 5-A/16 慣例，門檻 2）分二版：長訣別（warm）/ 短冷（cold）。
# 分支首拍即設 ending_reclaim_wan_farewell_seen（NpcAutoDialogueArea 的 seen_flag，防重播）；
# apartment_entrance.gd 輪詢「該旗標已設 + UIMode 回 NONE」（＝整棵對話樹已讀完關閉）後開
# photo_viewer 顯示 wan/cg_walk_into_rain，關閉後移除晚節點並 travel 至公寓 epilogue_home。

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "ending_route_reclaim", "op": "==", "value": true}, "target": "reclaim_affinity_gate"},
			{"target": "reclaim_affinity_gate"}
		]
	},

	"reclaim_affinity_gate": {
		"goto": [
			{"condition": {"flag": "affinity_wan", "op": ">=", "value": 2}, "target": "reclaim_warm_p1"},
			{"target": "reclaim_cold_p1"}
		]
	},

	# --- 長訣別版（affinity_wan >= 2）---
	"reclaim_warm_p1": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_EPILOGUE_RECLAIM_WARM_P1_TEXT",
		"effect": [
			{"op": "set_flag", "key": "ending_reclaim_wan_farewell_seen", "value": true}
		],
		"goto": "reclaim_warm_p2"
	},
	"reclaim_warm_p2": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_EPILOGUE_RECLAIM_WARM_P2_TEXT",
		"goto": "reclaim_warm_p3"
	},
	"reclaim_warm_p3": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_EPILOGUE_RECLAIM_WARM_P3_TEXT"
	},

	# --- 短冷版（affinity_wan < 2）---
	"reclaim_cold_p1": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_EPILOGUE_RECLAIM_COLD_P1_TEXT",
		"effect": [
			{"op": "set_flag", "key": "ending_reclaim_wan_farewell_seen", "value": true}
		],
		"goto": "reclaim_cold_p2"
	},
	"reclaim_cold_p2": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_EPILOGUE_RECLAIM_COLD_P2_TEXT"
	}
}

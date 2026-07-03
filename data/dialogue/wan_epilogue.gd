# Dialogue Tree for Wan's ending farewell (Phase 28-A Reclaim; Phase 28-B Protect branch)
# File: res://data/dialogue/wan_epilogue.gd
#
# 由 apartment_entrance.gd 在 epilogue_wan entry point 以 NpcAutoDialogueArea 自動觸發
# （26-A pattern 複用，Reclaim/Protect 各自一個 trigger area，require_flag 互斥）。
# start 依 ending_route_protect / ending_route_reclaim 分流。
# Reclaim 支再依 affinity_wan（既有 5-A/16 慣例，門檻 2）分二版：長訣別（warm）/ 短冷（cold）；
# 分支首拍即設 ending_reclaim_wan_farewell_seen（NpcAutoDialogueArea 的 seen_flag，防重播）；
# apartment_entrance.gd 輪詢「該旗標已設 + UIMode 回 NONE」（＝整棵對話樹已讀完關閉）後開
# photo_viewer 顯示 wan/cg_walk_into_rain，關閉後移除晚節點並 travel 至公寓 epilogue_home。
#
# Protect 支（28-B）：拍板台詞固定三句、不分二版、晚不消失、不開 CG；首拍設
# ending_protect_wan_seen（同款 seen_flag 防重播）。28-C 中間站分岔（小岑過閘 /
# 伍姐沉默搖頭）已在 datacenter_backup_core.gd 站 1 結束時判定並 travel 過，
# 站 3（本樹）在那之後才開始，故末拍 effect 只需單純 travel 到公寓
# apartment:epilogue_home，不重複判斷 cen_voiceprint_exposed。

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "ending_route_protect", "op": "==", "value": true}, "target": "protect_p1"},
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
	},

	# --- Protect 支（拍板台詞固定三句，不分版、晚不消失）---
	"protect_p1": {
		"speaker": "SPEAKER_WAN",
		"text": "DLG_WAN_EPILOGUE_PROTECT_P1_TEXT",
		"effect": [
			{"op": "set_flag", "key": "ending_protect_wan_seen", "value": true}
		],
		"goto": "protect_p2"
	},
	"protect_p2": {
		"speaker": "",
		"text": "DLG_WAN_EPILOGUE_PROTECT_P2_TEXT",
		"goto": "protect_p3"
	},
	"protect_p3": {
		"speaker": "",
		"text": "DLG_WAN_EPILOGUE_PROTECT_P3_TEXT",
		"effect": [
			{"op": "travel", "scene_id": "apartment", "entry_point_id": "epilogue_home"}
		]
	}
}

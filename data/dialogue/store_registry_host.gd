# Dialogue Tree for the store registry host (店籍主機)
# File: res://data/dialogue/store_registry_host.gd
#
# 8-E 三段 gating（level 已先以 mainframe_revealed gate 可互動性）：
#   vendor_bot_repaired            -> already_repaired（中性訊息，不再提供重置）
#   understood_robot_truth (quest) -> stage3（直接重置 / 先錄殘響再重置）
#   diagnosed (quest)              -> stage2（僅直接重置）
#   其餘                            -> stage1（資訊不足，只說明）
#
# 先錄殘響的背包滿防呆：choice effect 以 add_item 開頭，失敗即中止後續 effect
# （旗標不設、任務不 complete），goto 進 glean_result 條件路由，依
# vendor_bot_repaired 是否成立分流到成功 / 背包滿訊息；可整理背包後重試。

const ECHO_NOTE := {
	"id": "note_clerk_echo_recording",
	"category": "線索",
	"title": "ECHO_CLERK_TITLE",
	"body": "ECHO_CLERK_SEG_S1",
	"status": "active"
}

const TREE := {
	"start": {
		"goto": [
			{"condition": {"flag": "vendor_bot_repaired", "op": "==", "value": true}, "target": "already_repaired"},
			{"condition": {"type": "quest_flag", "quest_id": "repair_vendor_bot", "key": "understood_robot_truth", "op": "==", "value": true}, "target": "stage3"},
			{"condition": {"type": "quest_flag", "quest_id": "repair_vendor_bot", "key": "diagnosed", "op": "==", "value": true}, "target": "stage2"},
			{"target": "stage1"}
		]
	},

	# --- 段1：資訊不足，只說明 ---
	"stage1": {
		"speaker": "SPEAKER_STORE_REGISTRY_HOST",
		"text": "DLG_STORE_REGISTRY_HOST_STAGE1_TEXT"
	},

	# --- 段2：診斷完成（未全對），僅直接重置 ---
	"stage2": {
		"speaker": "SPEAKER_STORE_REGISTRY_HOST",
		"text": "DLG_STORE_REGISTRY_HOST_STAGE2_TEXT",
		"choices": [
			{
				"label": "DLG_STORE_REGISTRY_HOST_STAGE2_CHOICE0",
				"effect": [
					{"op": "set_flag", "key": "store_robot_resolution", "value": "reset"},
					{"op": "set_flag", "key": "vendor_bot_repaired", "value": true},
					{"op": "complete_quest", "value": "repair_vendor_bot"}
				],
				"goto": "reset_done"
			},
			{"label": "DLG_STORE_REGISTRY_HOST_STAGE2_CHOICE1", "goto": "stand_down"}
		]
	},

	# --- 段3：understood_robot_truth，二選一 ---
	"stage3": {
		"speaker": "SPEAKER_STORE_REGISTRY_HOST",
		"text": "DLG_STORE_REGISTRY_HOST_STAGE3_TEXT",
		"choices": [
			{
				"label": "DLG_STORE_REGISTRY_HOST_STAGE3_CHOICE0",
				"effect": [
					{"op": "set_flag", "key": "store_robot_resolution", "value": "reset"},
					{"op": "set_flag", "key": "vendor_bot_repaired", "value": true},
					{"op": "complete_quest", "value": "repair_vendor_bot"}
				],
				"goto": "reset_done"
			},
			{
				"label": "DLG_STORE_REGISTRY_HOST_STAGE3_CHOICE1",
				"effect": [
					{"op": "add_item", "item_id": "clerk_echo_recording", "value": 1},
					{"op": "add_note", "note": ECHO_NOTE},
					{"op": "set_flag", "key": "store_robot_resolution", "value": "gleaned"},
					{"op": "set_flag", "key": "vendor_bot_repaired", "value": true},
					{"op": "complete_quest", "value": "repair_vendor_bot"}
				],
				"goto": "glean_result"
			},
			{"label": "DLG_STORE_REGISTRY_HOST_STAGE2_CHOICE1", "goto": "stand_down"}
		]
	},
	"stand_down": {
		"speaker": "SPEAKER_STORE_REGISTRY_HOST",
		"text": "DLG_STORE_REGISTRY_HOST_STAND_DOWN_TEXT"
	},

	# --- 直接重置結局 ---
	"reset_done": {
		"speaker": "SPEAKER_STORE_REGISTRY_HOST",
		"text": "DLG_STORE_REGISTRY_HOST_RESET_DONE_TEXT"
	},

	# --- 先錄殘響結局（add_item 失敗時 vendor_bot_repaired 不會成立，分流到背包滿） ---
	"glean_result": {
		"goto": [
			{"condition": {"flag": "vendor_bot_repaired", "op": "==", "value": true}, "target": "gleaned_done"},
			{"target": "glean_bag_full"}
		]
	},
	"glean_bag_full": {
		"speaker": "SPEAKER_STORE_REGISTRY_HOST",
		"text": "DLG_STORE_REGISTRY_HOST_GLEAN_BAG_FULL_TEXT"
	},
	"gleaned_done": {
		"speaker": "SPEAKER_STORE_REGISTRY_HOST",
		"text": "DLG_STORE_REGISTRY_HOST_GLEANED_DONE_TEXT"
	},

	# --- 重置後：中性訊息，不再提供重置 ---
	"already_repaired": {
		"speaker": "SPEAKER_STORE_REGISTRY_HOST",
		"text": "DLG_STORE_REGISTRY_HOST_ALREADY_REPAIRED_TEXT"
	}
}

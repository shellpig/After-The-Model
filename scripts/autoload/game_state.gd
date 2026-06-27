extends Node

# Signals
signal inventory_changed
signal container_changed(container_id: String)
signal credits_changed(new_value: int)
signal knowledge_added(id: String)
signal notes_changed
signal equipment_changed
signal item_moved(move: Dictionary)
signal flag_changed(key: String, value)
signal quest_changed(quest_id: String, state: Dictionary)
signal shop_changed(shop_id: String)
signal note_added(note_data: Dictionary, is_update: bool)
signal echo_changed(echo_id: String)
# Phase 11：Trace 隱性軸變動（無 UI 綁定；供未來 debug overlay 使用）
signal trace_changed(new_value: int)


# Variables
var credits: int = 300
var inventory_slots: int = 15
var inventory: Array[Dictionary] = []
var equipment: Dictionary = {
	"clothing": [],     # Limit: 1
	"hand": [],         # Limit: 2
	"accessory": []     # Limit: 2
}
var knowledge: Dictionary = {}
var notes: Array[Dictionary] = []
var external_containers: Dictionary = {}
var external_container_configs: Dictionary = {}
var apartment_initialized: bool = false
var apartment_sonar_revealed: bool = false
var apartment_slot_unlocked: bool = false
var apartment_beyond_door_bgm_triggered: bool = false
var story_flags: Dictionary = {}
# Phase 11-A：Trace（系統追蹤風險）獨立隱性軸。賣↓ / 留↑ / 還 不增或微降。
# 隱性、不顯數值；清洗在 Phase 27 才硬兌現（此處只留資料 + hook）。
var trace: int = 0
var quest_states: Dictionary = {}
var shop_states: Dictionary = {}
var echo_progress: Dictionary = {}

# Phase M1: 進度追蹤集合
var visited_scenes: Dictionary = {}
var talked_npcs: Dictionary = {}
var collected_special_items: Dictionary = {}

const PROGRESS_SCENES := ["apartment","apartment_entrance","convenience_store","apartment_fire_escape","collector_shop","subway_station","subway_station_platform","underground_settlement","underground_settlement_right","tunnel_combat"]
const PROGRESS_NPCS := ["wan","store_robot","lu_qichen","cen","wu","seven"]
const PROGRESS_QUESTS := ["alley_backrooms_3f","repair_vendor_bot"]
const PROGRESS_ECHOES := ["echo_clerk","echo_room401_tenant","echo_song_rain_doesnt_stop","echo_lu_family","echo_settlement_erased"]
const PROGRESS_SPECIAL_ITEMS := ["early_ai_assistant_activation_box","old_ai_authorization_module","childcare_supply_receipt","old_probe_module","gleaner_gloves","clerk_echo_recording","decoder_cube"]


const ShopDB = preload("res://data/shops/shop_db.gd")
const SELL_RATIO := 0.5




const STORY_NOTES := {
	"work_ai_cleanup_role": {
		"id": "work_ai_cleanup_role",
		"category": "工作",
		"title": "NOTE_WORK_AI_CLEANUP_ROLE_TITLE",
		"body": "NOTE_WORK_AI_CLEANUP_ROLE_BODY",
		"status": "active"
	},
	"identity_gleaner": {
		"id": "identity_gleaner",
		"category": "身份",
		"title": "NOTE_IDENTITY_GLEANER_TITLE",
		"body": "NOTE_IDENTITY_GLEANER_BODY",
		"status": "active"
	},
	"clue_gloves_decoder": {
		"id": "clue_gloves_decoder",
		"category": "線索",
		"title": "NOTE_CLUE_GLOVES_DECODER_TITLE",
		"body": "NOTE_CLUE_GLOVES_DECODER_BODY",
		"status": "active"
	},
	"clue_decoder_cube": {
		"id": "clue_decoder_cube",
		"category": "線索",
		"title": "NOTE_CLUE_DECODER_CUBE_TITLE",
		"body": "NOTE_CLUE_DECODER_CUBE_BODY",
		"status": "active"
	},
	"clue_projection_clock": {
		"id": "clue_projection_clock",
		"category": "線索",
		"title": "NOTE_CLUE_PROJECTION_CLOCK_TITLE",
		"body": "NOTE_CLUE_PROJECTION_CLOCK_BODY",
		"status": "active"
	},
	"identity_door_unlock_method": {
		"id": "identity_door_unlock_method",
		"category": "身份",
		"title": "NOTE_IDENTITY_DOOR_UNLOCK_METHOD_TITLE",
		"body": "NOTE_IDENTITY_DOOR_UNLOCK_METHOD_BODY",
		"status": "active"
	},
	"clue_clerk_locker": {
		"id": "clue_clerk_locker",
		"category": "線索",
		"title": "NOTE_CLUE_CLERK_LOCKER_TITLE",
		"body": "NOTE_CLUE_CLERK_LOCKER_BODY",
		"status": "active"
	},
	"clue_clerk_diary": {
		"id": "clue_clerk_diary",
		"category": "線索",
		"title": "NOTE_CLUE_CLERK_DIARY_TITLE",
		"body": "NOTE_CLUE_CLERK_DIARY_BODY",
		"status": "active"
	},
	"clue_termination_notice": {
		"id": "clue_termination_notice",
		"category": "線索",
		"title": "NOTE_CLUE_TERMINATION_NOTICE_TITLE",
		"body": "NOTE_CLUE_TERMINATION_NOTICE_BODY",
		"status": "active"
	},
	"clue_robot_plate": {
		"id": "clue_robot_plate",
		"category": "線索",
		"title": "NOTE_CLUE_ROBOT_PLATE_TITLE",
		"body": "NOTE_CLUE_ROBOT_PLATE_BODY",
		"status": "active"
	},
	"clue_counter_photo": {
		"id": "clue_counter_photo",
		"category": "線索",
		"title": "NOTE_CLUE_COUNTER_PHOTO_TITLE",
		"body": "NOTE_CLUE_COUNTER_PHOTO_BODY",
		"status": "active"
	},
	"clue_vendor_error_lead": {
		"id": "clue_vendor_error_lead",
		"category": "線索",
		"title": "NOTE_CLUE_VENDOR_ERROR_LEAD_TITLE",
		"body": "NOTE_CLUE_VENDOR_ERROR_LEAD_BODY",
		"status": "active"
	},
	"clue_probe_module_lead": {
		"id": "clue_probe_module_lead",
		"category": "線索",
		"title": "NOTE_CLUE_PROBE_MODULE_LEAD_TITLE",
		"body": "NOTE_CLUE_PROBE_MODULE_LEAD_BODY",
		"status": "active"
	},
	"clue_old_work_order": {
		"id": "clue_old_work_order",
		"category": "身份",
		"title": "NOTE_CLUE_OLD_WORK_ORDER_TITLE",
		"body": "NOTE_CLUE_OLD_WORK_ORDER_BODY",
		"status": "active"
	}
}

const STORY_MESSAGES := {
	"bed_bad_sleep": "MSG_BED_BAD_SLEEP",
	"door_locked": "MSG_DOOR_LOCKED",
	"door_opened": "MSG_DOOR_OPENED",
	"desk_computer_msg": "MSG_DESK_COMPUTER_MSG",
	"desk_computer_dispatch_quest": "MSG_DESK_COMPUTER_DISPATCH_QUEST",
	"tape_recorder_msg": "MSG_TAPE_RECORDER_MSG",
	"decoder_cube_decoded": "MSG_DECODER_CUBE_DECODED",
	"nutrition_bar_consume": "MSG_NUTRITION_BAR_CONSUME",
	"slot_unlocked": "MSG_SLOT_UNLOCKED",
	"mem_frag_linfei_1": "MSG_MEM_FRAG_LINFEI_1",
	"mem_frag_commute_topside": "MSG_MEM_FRAG_COMMUTE_TOPSIDE",
	"mem_frag_erased_ada": "MSG_MEM_FRAG_ERASED_ADA",
	"mem_frag_hideout": "MSG_MEM_FRAG_HIDEOUT",
	"nightclub_security_blocked": "MSG_NIGHTCLUB_SECURITY_BLOCKED",
	"nightclub_staff_pass_found": "MSG_NIGHTCLUB_STAFF_PASS_FOUND",
	"nightclub_examine_pass_bag_full": "MSG_NIGHTCLUB_EXAMINE_PASS_BAG_FULL"
}

# MVP Temporary Stub DB
const ITEMS_DB := {
	"old_work_badge": {
		"id": "old_work_badge",
		"name": "ITEM_OLD_WORK_BADGE_NAME",
		"description": "ITEM_OLD_WORK_BADGE_DESC",
		"category": "key_item",
		"stackable": false,
		"max_stack": 1,
		"discardable": false,
		"usable": false,
		"equipment_slot": "",
		"icon_path": "res://assets/generated/sprites/items/old_work_badge/icon.png"
	},
	"fingerless_gloves": {
		"id": "fingerless_gloves",
		"name": "ITEM_FINGERLESS_GLOVES_NAME",
		"description": "ITEM_FINGERLESS_GLOVES_DESC",
		"category": "equipment",
		"stackable": false,
		"max_stack": 1,
		"discardable": false,
		"sellable": false,
		"usable": true,
		"equipment_slot": "hand",
		"icon_path": "res://assets/generated/sprites/items/fingerless_gloves/icon.png",
		"can_decode": true
	},
	"old_probe_module": {
		"id": "old_probe_module",
		"name": "ITEM_OLD_PROBE_MODULE_NAME",
		"description": "ITEM_OLD_PROBE_MODULE_DESC",
		"category": "misc",
		"stackable": false,
		"max_stack": 1,
		"discardable": false,
		"sellable": false,
		"usable": false,
		"icon_path": "res://assets/generated/sprites/items/old_probe_module/icon.png"
	},
	"gleaner_gloves": {
		"id": "gleaner_gloves",
		"name": "ITEM_GLEANER_GLOVES_NAME",
		"description": "ITEM_GLEANER_GLOVES_DESC",
		"category": "equipment",
		"stackable": false,
		"max_stack": 1,
		"discardable": false,
		"sellable": false,
		"usable": true,
		"equipment_slot": "hand",
		"icon_path": "res://assets/generated/sprites/items/fingerless_gloves/icon.png",
		"can_decode": true
	},

	"canned_food": {
		"id": "canned_food",
		"name": "ITEM_CANNED_FOOD_NAME",
		"description": "ITEM_CANNED_FOOD_DESC",
		"category": "consumable",
		"value": 20,
		"stackable": true,
		"max_stack": 5,
		"discardable": true,
		"usable": true,
		"equipment_slot": "",
		"icon_path": "res://assets/generated/sprites/items/canned_food/icon.png"
	},
	"faded_jacket": {
		"id": "faded_jacket",
		"name": "ITEM_FADED_JACKET_NAME",
		"description": "ITEM_FADED_JACKET_DESC",
		"category": "equipment",
		"value": 60,
		"stackable": false,
		"max_stack": 1,
		"discardable": true,
		"usable": true,
		"equipment_slot": "clothing",
		"icon_path": "res://assets/generated/sprites/items/faded_jacket/icon.png"
	},
	"worn_rubiks_cube": {
		"id": "worn_rubiks_cube",
		"name": "ITEM_WORN_RUBIKS_CUBE_NAME",
		"description": "ITEM_WORN_RUBIKS_CUBE_DESC",
		"category": "misc",
		"value": 1,
		"stackable": false,
		"max_stack": 1,
		"discardable": true,
		"usable": true,
		"equipment_slot": "",
		"icon_path": "res://assets/generated/sprites/items/worn_rubiks_cube/icon.png",
		"decodable_to": "decoder_cube"
	},
	"decoder_cube": {
		"id": "decoder_cube",
		"name": "ITEM_DECODER_CUBE_NAME",
		"description": "ITEM_DECODER_CUBE_DESC",
		"category": "misc",
		"stackable": false,
		"max_stack": 1,
		"discardable": true,
		"usable": true,
		"equipment_slot": "",
		"icon_path": "res://assets/generated/sprites/items/decoder_cube/icon.png"
	},
	"nutrition_bar_synth_blueberry": {
		"id": "nutrition_bar_synth_blueberry",
		"name": "ITEM_NUTRITION_BAR_SYNTH_BLUEBERRY_NAME",
		"description": "ITEM_NUTRITION_BAR_SYNTH_BLUEBERRY_DESC",
		"category": "consumable",
		"value": 12,
		"stackable": true,
		"max_stack": 5,
		"discardable": true,
		"usable": true,
		"equipment_slot": "",
		"icon_path": "res://assets/generated/sprites/items/synthetic_blueberry_nutrition_bar/icon.png",
		"consume_grants_note": "clue_projection_clock"
	},
	"nutrition_bar_synth_orange": {
		"id": "nutrition_bar_synth_orange",
		"name": "ITEM_NUTRITION_BAR_SYNTH_ORANGE_NAME",
		"description": "ITEM_NUTRITION_BAR_SYNTH_ORANGE_DESC",
		"category": "consumable",
		"value": 12,
		"stackable": true,
		"max_stack": 5,
		"discardable": true,
		"usable": true,
		"equipment_slot": "",
		"icon_path": "res://assets/generated/sprites/items/synthetic_orange_nutrition_bar/icon.png"
	},
	"early_ai_assistant_activation_box": {
		"id": "early_ai_assistant_activation_box",
		"name": "ITEM_EARLY_AI_ASSISTANT_ACTIVATION_BOX_NAME",
		"description": "ITEM_EARLY_AI_ASSISTANT_ACTIVATION_BOX_DESC",
		"category": "misc",
		"stackable": false,
		"max_stack": 1,
		"discardable": false,
		"usable": false,
		"icon_path": "res://assets/generated/sprites/items/early_ai_assistant_activation_box/icon.png",
		"inspect_grants_item": "old_ai_authorization_module",
		"inspect_grants_flag": "found_old_ai_authorization_module"
	},
	"old_ai_authorization_module": {
		"id": "old_ai_authorization_module",
		"name": "ITEM_OLD_AI_AUTHORIZATION_MODULE_NAME",
		"description": "ITEM_OLD_AI_AUTHORIZATION_MODULE_DESC",
		"category": "key_item",
		"stackable": false,
		"max_stack": 1,
		"discardable": false,
		"usable": false,
		"icon_path": "res://assets/generated/sprites/items/old_ai_authorization_module/icon.png"
	},
	"clerk_echo_recording": {
		"id": "clerk_echo_recording",
		"name": "ITEM_CLERK_ECHO_RECORDING_NAME",
		"description": "ITEM_CLERK_ECHO_RECORDING_DESC",
		"category": "misc",
		"stackable": false,
		"max_stack": 1,
		"discardable": false,
		"usable": false,
		"sellable": false,
		"icon_path": "res://assets/generated/sprites/items/clerk_echo_recording/icon.png"
	},
	"synth_cola": {
		"id": "synth_cola",
		"name": "ITEM_SYNTH_COLA_NAME",
		"description": "ITEM_SYNTH_COLA_DESC",
		"category": "consumable",
		"value": 15,
		"stackable": true,
		"max_stack": 5,
		"discardable": true,
		"usable": true,
		"equipment_slot": "",
		"icon_path": "res://assets/generated/sprites/items/synth_cola/icon.png"
	},
	"packaged_water": {
		"id": "packaged_water",
		"name": "ITEM_PACKAGED_WATER_NAME",
		"description": "ITEM_PACKAGED_WATER_DESC",
		"category": "consumable",
		"value": 10,
		"stackable": true,
		"max_stack": 5,
		"discardable": true,
		"usable": true,
		"equipment_slot": "",
		"icon_path": "res://assets/generated/sprites/items/packaged_water/icon.png"
	},
	"childcare_supply_receipt": {
		"id": "childcare_supply_receipt",
		"name": "ITEM_CHILDCARE_SUPPLY_RECEIPT_NAME",
		"description": "ITEM_CHILDCARE_SUPPLY_RECEIPT_DESC",
		"category": "key_item",
		"stackable": false,
		"max_stack": 1,
		"discardable": false,
		"sellable": true,
		"usable": false,
		"icon_path": "res://assets/generated/sprites/items/childcare_supply_receipt/icon.png"
	},
	"nightclub_staff_pass": {
		"id": "nightclub_staff_pass",
		"name": "ITEM_NIGHTCLUB_STAFF_PASS_NAME",
		"description": "ITEM_NIGHTCLUB_STAFF_PASS_DESC",
		"category": "key_item",
		"stackable": false,
		"max_stack": 1,
		"discardable": false,
		"sellable": false,
		"usable": false,
		"icon_path": "res://assets/generated/sprites/items/nightclub_staff_pass/icon.png"
	}
}

const EQUIPMENT_LIMITS := {
	"clothing": 1,
	"hand": 2,
	"accessory": 2
}

var _last_instance_id: int = 0

func _ready() -> void:
	# Initialize inventory slots with empty dictionaries
	inventory.clear()
	for i in range(inventory_slots):
		inventory.append({})

func generate_instance_id() -> String:
	_last_instance_id += 1
	return "item_%04d" % _last_instance_id

# ==========================================
# Credits API
# ==========================================
func get_credits() -> int:
	return credits

func add_credits(amount: int) -> void:
	set_credits(credits + amount)

func set_credits(value: int) -> void:
	var old_credits = credits
	credits = clampi(value, 0, 9999999)
	if credits != old_credits:
		credits_changed.emit(credits)

# ==========================================
# Story Flags API
# ==========================================
func set_flag(key: String, value) -> void:
	story_flags[key] = value
	flag_changed.emit(key, value)
	if key == "talked_outside_vendor" or key == "talked_store_robot":
		_maybe_set_discovered_vendor_error()
	if key == "store_robot_resolution":
		_maybe_backfill_clerk_echo()


# 8-B 發現錯誤聚合：兩台（街道販賣機 / 店內機器人）都互動過才視為「發現異常」；idempotent
func _maybe_set_discovered_vendor_error() -> void:
	if has_flag("discovered_vendor_error"):
		return
	if has_flag("talked_outside_vendor") and has_flag("talked_store_robot"):
		set_flag("discovered_vendor_error", true)
		add_knowledge(STORY_NOTES["clue_vendor_error_lead"])

func get_flag(key: String, default_value = 0):
	return story_flags.get(key, default_value)

func has_flag(key: String) -> bool:
	var val = story_flags.get(key, false)
	if val is bool:
		return val
	if val is int or val is float:
		return val != 0
	return val != null

func add_int(key: String, delta: int) -> void:
	var current_val = story_flags.get(key, 0)
	if not (current_val is int or current_val is float):
		current_val = 0
	var new_val = int(current_val) + delta
	story_flags[key] = new_val
	flag_changed.emit(key, new_val)

# ==========================================
# Trust / Trace API（Phase 11）
# ==========================================
# Trace 每次「賣」殘響時的降幅（原始資料離手）。數值為方向性占位，開工校。
const TRACE_DELTA_SELL := -1

# 11-A：Trace 隱性軸。隱性、不顯數值；正負皆可。
func add_trace(delta: int) -> void:
	if delta == 0:
		return
	trace += delta
	trace_changed.emit(trace)

func get_trace() -> int:
	return trace

# 11-B：Trust adapter。第一版不新建獨立軸——以既有 affinity_<target> 近似。
# 呼叫端一律走此介面；日後抽獨立 Trust 軸只改這裡，呼叫端不動。
func get_trust(target: String) -> int:
	return int(get_flag("affinity_" + target, 0))

# ==========================================
# Quest State API
# ==========================================
func get_quest_state(quest_id: String) -> Dictionary:
	return quest_states.get(quest_id, {}).duplicate(true)

func set_quest_state(quest_id: String, state: Dictionary) -> void:
	quest_states[quest_id] = state.duplicate(true)
	quest_changed.emit(quest_id, state)

func has_active_quest(quest_id: String) -> bool:
	var state = quest_states.get(quest_id, {})
	return state.get("status", "") == "active"

func get_quest_step(quest_id: String) -> String:
	var state = quest_states.get(quest_id, {})
	return state.get("step", "")

# ==========================================
# Knowledge / Notes API
# ==========================================
func has_knowledge(id: String) -> bool:
	return knowledge.get(id, false)

func has_note(id: String) -> bool:
	for note in notes:
		if note.get("id") == id:
			return true
	return false

func add_knowledge(note: Dictionary) -> void:
	var note_id: String = note.get("id", "")
	var category: String = note.get("category", "")
	var title: String = note.get("title", "")
	var body: String = note.get("body", "")

	if note_id.is_empty() or category.is_empty() or title.is_empty() or body.is_empty():
		return # Invalid schema

	var new_note = {
		"id": note_id,
		"category": category,
		"title": title,
		"body": body,
		"status": note.get("status", "active")
	}

	# Find and update existing note or append new one
	var found = false
	for i in range(notes.size()):
		if notes[i].get("id") == note_id:
			var old_body: String = notes[i].get("body", "")
			if not body in old_body:
				if not old_body.ends_with("\n\n"):
					if old_body.ends_with("\n"):
						old_body += "\n"
					else:
						old_body += "\n\n"
				new_note["body"] = old_body + body
			else:
				new_note["body"] = old_body
			notes[i] = new_note
			found = true
			break

	if not found:
		notes.append(new_note)

	note_added.emit(new_note, found)

	if category == "身份":
		if not knowledge.get(note_id, false):
			knowledge[note_id] = true
			knowledge_added.emit(note_id)

	notes_changed.emit()

func get_notes(category: String) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for note in notes:
		if note.get("category") == category:
			filtered.append(note)
	return filtered.duplicate(true)

func get_all_notes() -> Array[Dictionary]:
	return notes.duplicate(true)

# ==========================================
# Inventory API
# ==========================================
func get_inventory() -> Array[Dictionary]:
	return inventory.duplicate(true)

func has_item(item_id: String, count: int = 1) -> bool:
	if item_id.is_empty() or count <= 0:
		return false
	var total_qty = 0
	for slot in inventory:
		if not slot.is_empty() and slot.get("item_id") == item_id:
			total_qty += slot.get("quantity", 0)
	return total_qty >= count

func add_item(item_id: String, count: int = 1) -> bool:
	if count <= 0:
		return false

	if not ITEMS_DB.has(item_id):
		return false

	var item_meta: Dictionary = ITEMS_DB[item_id]
	var stackable: bool = item_meta.get("stackable", false)
	var max_stack: int = item_meta.get("max_stack", 1)

	# Atomic implementation
	var temp_inventory = inventory.duplicate(true)
	var remaining = count

	if stackable:
		# 1. Try to merge into existing non-full stacks
		for i in range(temp_inventory.size()):
			var slot = temp_inventory[i]
			if not slot.is_empty() and slot.get("item_id") == item_id:
				var current_qty: int = slot.get("quantity", 0)
				if current_qty < max_stack:
					var add_qty = min(remaining, max_stack - current_qty)
					slot["quantity"] = current_qty + add_qty
					remaining -= add_qty
					if remaining <= 0:
						break

	# 2. Fill empty slots
	if remaining > 0:
		for i in range(temp_inventory.size()):
			var slot = temp_inventory[i]
			if slot.is_empty():
				var add_qty = min(remaining, max_stack)
				temp_inventory[i] = {
					"instance_id": generate_instance_id(),
					"item_id": item_id,
					"quantity": add_qty
				}
				remaining -= add_qty
				if remaining <= 0:
					break

	if remaining > 0:
		return false # Not enough space to add all units

	inventory = temp_inventory
	_sort_container(inventory)
	_maybe_mark_special_item(item_id)
	inventory_changed.emit()
	return true

func remove_item(item_id: String, count: int = 1) -> bool:
	if count <= 0:
		return false

	# Atomic implementation
	var temp_inventory = inventory.duplicate(true)
	var remaining = count
	var cleared_instances := []

	# Remove items starting from non-equipped items, or just standard scan
	# Scanning slots
	for i in range(temp_inventory.size()):
		var slot = temp_inventory[i]
		if not slot.is_empty() and slot.get("item_id") == item_id:
			var current_qty: int = slot.get("quantity", 0)
			var sub_qty = min(remaining, current_qty)
			slot["quantity"] = current_qty - sub_qty
			remaining -= sub_qty
			if slot["quantity"] == 0:
				var instance_id: String = slot.get("instance_id", "")
				if not instance_id.is_empty():
					cleared_instances.append(instance_id)
				temp_inventory[i] = {}
			if remaining <= 0:
				break

	if remaining > 0:
		return false # Not enough items found to satisfy the count

	# Apply unequip side-effects only after the entire operation is guaranteed to succeed
	for instance_id in cleared_instances:
		_force_unequip_if_present(instance_id)

	inventory = temp_inventory
	_sort_container(inventory)
	inventory_changed.emit()
	return true

# ==========================================
# Equipment API
# ==========================================
func get_equipment() -> Dictionary:
	return equipment.duplicate(true)

func equip(instance_id: String) -> bool:
	if instance_id.is_empty():
		return false

	# 1. Find item in backpack
	var found_item: Dictionary = {}
	for slot in inventory:
		if not slot.is_empty() and slot.get("instance_id") == instance_id:
			found_item = slot
			break

	if found_item.is_empty():
		return false

	var item_id: String = found_item.get("item_id", "")
	var item_meta: Dictionary = ITEMS_DB.get(item_id, {})
	var slot_type: String = item_meta.get("equipment_slot", "")

	if slot_type.is_empty() or not EQUIPMENT_LIMITS.has(slot_type):
		return false

	# Check if already equipped
	if equipment[slot_type].has(instance_id):
		return true

	# Check limits
	var limit: int = EQUIPMENT_LIMITS[slot_type]
	if equipment[slot_type].size() >= limit:
		return false # Slot is full

	equipment[slot_type].append(instance_id)
	_sort_container(inventory)
	equipment_changed.emit()
	inventory_changed.emit()
	return true

func unequip_by_instance(instance_id: String) -> bool:
	for slot_type in equipment:
		var slot_list: Array = equipment[slot_type]
		if slot_list.has(instance_id):
			slot_list.erase(instance_id)
			_sort_container(inventory)
			equipment_changed.emit()
			inventory_changed.emit()
			return true
	return false

func unequip(equipment_type: String, slot_index: int) -> bool:
	if not equipment.has(equipment_type):
		return false

	var slot_list: Array = equipment[equipment_type]
	if slot_index < 0 or slot_index >= slot_list.size():
		return false

	slot_list.remove_at(slot_index)
	_sort_container(inventory)
	equipment_changed.emit()
	inventory_changed.emit()
	return true

func _force_unequip_if_present(instance_id: String) -> void:
	if instance_id.is_empty():
		return
	var changed = false
	for slot_type in equipment:
		var slot_list: Array = equipment[slot_type]
		if slot_list.has(instance_id):
			slot_list.erase(instance_id)
			changed = true
	if changed:
		equipment_changed.emit()

func _is_equipped(instance_id: String) -> bool:
	if instance_id.is_empty():
		return false
	for slot_type in equipment:
		if equipment[slot_type].has(instance_id):
			return true
	return false

func is_equipped(instance_id: String) -> bool:
	return _is_equipped(instance_id)

func is_item_equipped(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	for slot_type in equipment:
		for instance_id in equipment[slot_type]:
			for slot in inventory:
				if not slot.is_empty() and slot.get("instance_id") == instance_id:
					if slot.get("item_id") == item_id:
						return true
	return false


# ==========================================
# External Container Minimal API
# ==========================================
func configure_container(container_id: String, slot_count: int, accepted_item: Array = [], deposit_locked: bool = false) -> void:
	if container_id.is_empty() or slot_count <= 0:
		return
	if not external_containers.has(container_id):
		var slots: Array[Dictionary] = []
		for i in range(slot_count):
			slots.append({})
		external_containers[container_id] = slots

		external_container_configs[container_id] = {
			"slot_count": slot_count,
			"accepted_item": accepted_item.duplicate(),
			"deposit_locked": deposit_locked
		}

func get_container_config(container_id: String) -> Dictionary:
	if external_container_configs.has(container_id):
		return external_container_configs[container_id].duplicate(true)
	return {
		"slot_count": 0,
		"accepted_item": [],
		"deposit_locked": false
	}

func get_container(container_id: String) -> Array[Dictionary]:
	if external_containers.has(container_id):
		return external_containers[container_id].duplicate(true)
	return []

func move_one_item_to(target_container_id: String, instance_id: String) -> bool:
	if target_container_id.is_empty() or instance_id.is_empty():
		return false

	# Find source
	var source_container_id = ""
	var source_slots: Array = []
	var item_to_move: Dictionary = {}
	var source_slot_index = -1

	# Check backpack first
	for i in range(inventory.size()):
		var slot = inventory[i]
		if not slot.is_empty() and slot.get("instance_id") == instance_id:
			source_container_id = "player_inventory"
			source_slots = inventory
			item_to_move = slot
			source_slot_index = i
			break

	# Check external containers if not in backpack
	if source_container_id.is_empty():
		for container_key in external_containers:
			var container_list: Array = external_containers[container_key]
			for i in range(container_list.size()):
				var slot = container_list[i]
				if not slot.is_empty() and slot.get("instance_id") == instance_id:
					source_container_id = container_key
					source_slots = container_list
					item_to_move = slot
					source_slot_index = i
					break
			if not source_container_id.is_empty():
				break

	if source_container_id.is_empty() or item_to_move.is_empty():
		return false # Item not found

	# Direction constraints check
	var is_to_backpack = (target_container_id == "player_inventory")
	if is_to_backpack:
		# source must be external and target is backpack
		if source_container_id == "player_inventory":
			return false # Moving backpack to backpack (noop/invalid)
	else:
		# source must be backpack and target must be a configured external container
		if source_container_id != "player_inventory":
			return false # Container-to-container is blocked in MVP
		if not external_containers.has(target_container_id):
			return false # Target container not configured

	var target_slots: Array = inventory if is_to_backpack else external_containers[target_container_id]

	# Atomic Space Check
	var item_id: String = item_to_move.get("item_id", "")

	# Whitelist constraint check for target container
	if not is_to_backpack:
		var target_config = get_container_config(target_container_id)
		var accepted: Array = target_config.get("accepted_item", [])
		if not accepted.is_empty() and not accepted.has(item_id):
			return false # Target container does not accept this item type

	# Deposit lock constraint check for source container
	if source_container_id != "player_inventory":
		var source_config = get_container_config(source_container_id)
		if source_config.get("deposit_locked", false):
			return false # Cannot remove items from a locked deposit container
	var item_meta: Dictionary = ITEMS_DB.get(item_id, {})
	var stackable: bool = item_meta.get("stackable", false)
	var max_stack: int = item_meta.get("max_stack", 1)

	var temp_source = source_slots.duplicate(true)
	var temp_target = target_slots.duplicate(true)

	var target_accomodated_index = -1
	var is_merge = false

	if stackable:
		# Look for non-full stack in target
		for i in range(temp_target.size()):
			var slot = temp_target[i]
			if not slot.is_empty() and slot.get("item_id") == item_id:
				var qty: int = slot.get("quantity", 0)
				if qty < max_stack:
					target_accomodated_index = i
					is_merge = true
					break

	if target_accomodated_index == -1:
		# Look for first empty slot in target
		for i in range(temp_target.size()):
			var slot = temp_target[i]
			if slot.is_empty():
				target_accomodated_index = i
				is_merge = false
				break

	if target_accomodated_index == -1:
		return false # Target has no space (Full)

	# Deduct 1 unit from source
	var source_slot = temp_source[source_slot_index]
	var source_qty: int = source_slot.get("quantity", 1)
	source_qty -= 1
	if source_qty <= 0:
		# If we clear a slot, check if it's currently equipped and unequip it first
		if source_container_id == "player_inventory":
			_force_unequip_if_present(instance_id)
		temp_source[source_slot_index] = {}
	else:
		source_slot["quantity"] = source_qty

	# Add 1 unit to target
	var target_instance_id := ""
	if is_merge:
		var target_slot = temp_target[target_accomodated_index]
		var target_qty: int = target_slot.get("quantity", 0)
		target_slot["quantity"] = target_qty + 1
		target_instance_id = target_slot.get("instance_id", "")
	else:
		# Create new slot in target
		# Since it's a new slot, generate a fresh instance ID
		var new_instance_id = generate_instance_id()
		temp_target[target_accomodated_index] = {
			"instance_id": new_instance_id,
			"item_id": item_id,
			"quantity": 1
		}
		target_instance_id = new_instance_id

	# Auto-sort both sides
	_sort_container(temp_source)
	_sort_container(temp_target)

	# Apply mutations
	if is_to_backpack:
		external_containers[source_container_id] = temp_source
		inventory = temp_target
	else:
		inventory = temp_source
		external_containers[target_container_id] = temp_target

	# Emit signals
	var move_payload = {
		"source_container_id": source_container_id,
		"target_container_id": target_container_id,
		"source_instance_id": instance_id,
		"target_instance_id": target_instance_id,
		"item_id": item_id
	}
	item_moved.emit(move_payload)

	inventory_changed.emit()
	if is_to_backpack:
		container_changed.emit(source_container_id)
	else:
		container_changed.emit(target_container_id)

	return true

func discard_item(instance_id: String) -> bool:
	if instance_id.is_empty():
		return false

	var source_id := ""
	var source_slots: Array = []
	var slot_index := -1
	var item_id_found := ""

	for i in range(inventory.size()):
		if inventory[i].get("instance_id", "") == instance_id:
			source_id = "player_inventory"
			source_slots = inventory
			slot_index = i
			item_id_found = inventory[i].get("item_id", "")
			break

	if source_id.is_empty():
		for c_key in external_containers:
			var c: Array = external_containers[c_key]
			for i in range(c.size()):
				if c[i].get("instance_id", "") == instance_id:
					source_id = c_key
					source_slots = c
					slot_index = i
					item_id_found = c[i].get("item_id", "")
					break
			if not source_id.is_empty():
				break

	if source_id.is_empty() or slot_index == -1:
		return false

	var item_meta: Dictionary = ITEMS_DB.get(item_id_found, {})
	if not item_meta.get("discardable", true):
		return false
	if _is_equipped(instance_id):
		return false

	var stackable: bool = item_meta.get("stackable", false)
	if stackable:
		var qty: int = source_slots[slot_index].get("quantity", 1)
		if qty <= 1:
			source_slots[slot_index] = {}
		else:
			source_slots[slot_index]["quantity"] = qty - 1
	else:
		source_slots[slot_index] = {}

	_sort_container(source_slots)

	if source_id == "player_inventory":
		inventory_changed.emit()
	else:
		container_changed.emit(source_id)

	return true

# ==========================================
# Commerce API (Phase 8-F)
# ==========================================
func get_item_value(item_id: String) -> int:
	return ITEMS_DB.get(item_id, {}).get("value", 0)

func get_sell_value(item_id: String) -> int:
	return floori(get_item_value(item_id) * SELL_RATIO)

func is_sellable(item_id: String) -> bool:
	var item_meta: Dictionary = ITEMS_DB.get(item_id, {})
	if item_meta.is_empty():
		return false
	if item_meta.get("sellable", true) == false:
		return false
	if item_meta.get("category", "") == "key_item":
		return false
	if get_item_value(item_id) <= 0:
		return false
	# 防 floor 後 0 元賣出（value 過低的物品視為不可賣）
	if get_sell_value(item_id) <= 0:
		return false
	return true

# 以焦點背包格 instance_id 定位賣出（仿 discard_item）；不回補店庫存。
# 不可用 remove_item(item_id)：多 stack / 多 instance 時會賣到非焦點格、誤觸 force-unequip 副作用。
func sell_item(instance_id: String, count: int = 1) -> bool:
	if instance_id.is_empty() or count <= 0:
		return false

	var slot_index := -1
	for i in range(inventory.size()):
		if inventory[i].get("instance_id", "") == instance_id:
			slot_index = i
			break
	if slot_index == -1:
		return false

	var item_id: String = inventory[slot_index].get("item_id", "")
	if not is_sellable(item_id):
		return false
	if _is_equipped(instance_id):
		return false

	var qty: int = inventory[slot_index].get("quantity", 1)
	if qty < count:
		return false

	if qty - count <= 0:
		inventory[slot_index] = {}
	else:
		inventory[slot_index]["quantity"] = qty - count

	_sort_container(inventory)
	add_credits(get_sell_value(item_id) * count)
	inventory_changed.emit()
	return true

func get_shop_stock(shop_id: String) -> Dictionary:
	if not shop_states.has(shop_id):
		var catalog: Dictionary = ShopDB.get_catalog(shop_id)
		if catalog.is_empty():
			return {}
		var stock := {}
		var catalog_stock: Dictionary = catalog.get("stock", {})
		for item_id in catalog_stock:
			var entry: Dictionary = catalog_stock[item_id]
			stock[item_id] = {
				"price": entry.get("price", 0),
				"stock": entry.get("stock", 0)
			}
		shop_states[shop_id] = stock
	return shop_states[shop_id].duplicate(true)

# 庫存重設僅限：通關上新等顯式事件呼叫；不綁時間、不因離店再進補貨
func refresh_shop_stock(shop_id: String) -> void:
	shop_states.erase(shop_id)
	get_shop_stock(shop_id)
	shop_changed.emit(shop_id)

func get_buy_price(shop_id: String, item_id: String) -> int:
	return get_shop_stock(shop_id).get(item_id, {}).get("price", 0)

# 只檢 stock / credits 供 UI 提示；背包滿由 buy_item 實際執行 add_item 時回報
func can_buy(shop_id: String, item_id: String) -> Dictionary:
	var stock := get_shop_stock(shop_id)
	if not stock.has(item_id):
		return {"ok": false, "reason": "not_in_catalog"}
	if stock[item_id].get("stock", 0) <= 0:
		return {"ok": false, "reason": "out_of_stock"}
	if credits < stock[item_id].get("price", 0):
		return {"ok": false, "reason": "not_enough_credits"}
	return {"ok": true, "reason": ""}

# 原子買入：純讀檢查 → add_item（唯一可能失敗的變動步驟）→ 成功才扣庫存、扣 credits
func buy_item(shop_id: String, item_id: String) -> bool:
	var check := can_buy(shop_id, item_id)
	if not check.get("ok", false):
		return false
	var price: int = shop_states[shop_id][item_id].get("price", 0)
	if not add_item(item_id, 1):
		return false # 背包滿；庫存與 credits 未動
	shop_states[shop_id][item_id]["stock"] -= 1
	add_credits(-price)
	shop_changed.emit(shop_id)
	return true

func seed_container(container_id: String, item_id: String, count: int) -> bool:
	if not external_containers.has(container_id) or not ITEMS_DB.has(item_id) or count <= 0:
		return false

	var slots: Array = external_containers[container_id]
	var item_meta: Dictionary = ITEMS_DB[item_id]
	var stackable: bool = item_meta.get("stackable", false)
	var max_stack: int = item_meta.get("max_stack", 1)

	var remaining: int = count

	# 1. Merge into existing non-full stacks
	if stackable:
		for i in range(slots.size()):
			var slot: Dictionary = slots[i]
			if not slot.is_empty() and slot.get("item_id") == item_id:
				var qty: int = slot.get("quantity", 0)
				if qty < max_stack:
					var to_add: int = min(remaining, max_stack - qty)
					slots[i]["quantity"] = qty + to_add
					remaining -= to_add
					if remaining <= 0:
						break

	# 2. Place remainder in empty slots
	if remaining > 0:
		for i in range(slots.size()):
			if slots[i].is_empty():
				var to_add: int = min(remaining, max_stack if stackable else 1)
				slots[i] = {
					"instance_id": generate_instance_id(),
					"item_id": item_id,
					"quantity": to_add
				}
				remaining -= to_add
				if remaining <= 0:
					break

	_sort_container(slots)
	container_changed.emit(container_id)
	return remaining == 0

func change_item_id(instance_id: String, new_item_id: String) -> bool:
	if instance_id.is_empty() or not ITEMS_DB.has(new_item_id):
		return false

	# Find in backpack
	for i in range(inventory.size()):
		var slot = inventory[i]
		if not slot.is_empty() and slot.get("instance_id") == instance_id:
			slot["item_id"] = new_item_id
			_sort_container(inventory)
			_maybe_mark_special_item(new_item_id)
			inventory_changed.emit()
			return true

	# Find in external containers
	for container_key in external_containers:
		var container_list: Array = external_containers[container_key]
		for i in range(container_list.size()):
			var slot = container_list[i]
			if not slot.is_empty() and slot.get("instance_id") == instance_id:
				slot["item_id"] = new_item_id
				_sort_container(container_list)
				_maybe_mark_special_item(new_item_id)
				container_changed.emit(container_key)
				return true

	return false

# ==========================================
# Echo Progress API (Phase 9-A)
# ==========================================
func collect_echo_segment(echo_id: String, segment_id: String) -> bool:
	if echo_id.is_empty() or segment_id.is_empty():
		return false
	if not EchoDB.has_echo(echo_id):
		return false
	
	if not echo_progress.has(echo_id):
		echo_progress[echo_id] = {
			"collected": [],
			"sold": false
		}
	
	var collected_arr: Array = echo_progress[echo_id]["collected"]
	if collected_arr.has(segment_id):
		return false
		
	var was_complete = is_echo_complete(echo_id)
	collected_arr.append(segment_id)
	
	if not was_complete and is_echo_complete(echo_id):
		var echo_data = EchoDB.get_echo(echo_id)
		if echo_data.has("trace_on_collect"):
			add_trace(echo_data["trace_on_collect"])
			
	echo_changed.emit(echo_id)
	return true

func record_full_echo(echo_id: String) -> void:
	if not EchoDB.has_echo(echo_id):
		return
	
	var echo_data = EchoDB.get_echo(echo_id)
	var all_segments = []
	for seg in echo_data.get("segments", []):
		all_segments.append(seg.get("id", ""))
		
	echo_progress[echo_id] = {
		"collected": all_segments,
		"sold": false
	}
	echo_changed.emit(echo_id)

func has_echo_segment(echo_id: String, segment_id: String) -> bool:
	if not echo_progress.has(echo_id):
		return false
	return echo_progress[echo_id].get("collected", []).has(segment_id)

func get_collected_segment_count(echo_id: String) -> int:
	if not echo_progress.has(echo_id):
		return 0
	return echo_progress[echo_id].get("collected", []).size()

func is_echo_known(echo_id: String) -> bool:
	if not echo_progress.has(echo_id):
		return false
	return echo_progress[echo_id].get("collected", []).size() > 0

func is_echo_complete(echo_id: String) -> bool:
	if not echo_progress.has(echo_id):
		return false
	var echo_data = EchoDB.get_echo(echo_id)
	if echo_data.get("unknown_total", false):
		return false
	var collected_count = echo_progress[echo_id].get("collected", []).size()
	return collected_count == EchoDB.get_segment_count(echo_id)

func is_echo_audio_unlocked(echo_id: String) -> bool:
	if not echo_progress.has(echo_id) or is_echo_sold(echo_id):
		return false
	var echo_data = EchoDB.get_echo(echo_id)
	if echo_data.is_empty():
		return false
	if echo_data.has("media_slots"):
		var slots = echo_data.get("media_slots", {})
		if slots.has("audio"):
			var threshold = slots["audio"].get("threshold", 0)
			return get_collected_segment_count(echo_id) >= threshold
		return false
	else:
		return is_echo_complete(echo_id) and not echo_data.get("audio_path", "").is_empty()

func is_echo_image_unlocked(echo_id: String) -> bool:
	if not echo_progress.has(echo_id) or is_echo_sold(echo_id):
		return false
	var echo_data = EchoDB.get_echo(echo_id)
	if echo_data.is_empty():
		return false
	if echo_data.has("media_slots"):
		var slots = echo_data.get("media_slots", {})
		if slots.has("image"):
			var threshold = slots["image"].get("threshold", 0)
			return get_collected_segment_count(echo_id) >= threshold
		return false
	else:
		return is_echo_complete(echo_id) and not echo_data.get("image_path", "").is_empty()

func get_echo_audio_path(echo_id: String) -> String:
	if not is_echo_audio_unlocked(echo_id):
		return ""
	var echo_data = EchoDB.get_echo(echo_id)
	if echo_data.has("media_slots"):
		return echo_data.get("media_slots", {}).get("audio", {}).get("path", "")
	return echo_data.get("audio_path", "")

func get_echo_image_path(echo_id: String) -> String:
	if not is_echo_image_unlocked(echo_id):
		return ""
	var echo_data = EchoDB.get_echo(echo_id)
	if echo_data.has("media_slots"):
		return echo_data.get("media_slots", {}).get("image", {}).get("path", "")
	return echo_data.get("image_path", "")

# Phase M1 進度頁專用：與 is_echo_complete 刻意分流。
# is_echo_complete 對 unknown_total 殘響（鹿家記事）永遠回 false（給媒體/筆記 gate 用，嚴格）；
# 進度頁依凍結決定「採到現有段數即算完成」，確保 100% 可達。勿合併成 is_echo_complete。
func _is_echo_complete_for_progress(echo_id: String) -> bool:
	if not echo_progress.has(echo_id):
		return false
	var collected_count = echo_progress[echo_id].get("collected", []).size()
	return collected_count >= EchoDB.get_segment_count(echo_id)

func is_echo_sold(echo_id: String) -> bool:
	if not echo_progress.has(echo_id):
		return false
	return echo_progress[echo_id].get("sold", false)

func sell_echo(echo_id: String) -> bool:
	if not is_echo_complete(echo_id) or is_echo_sold(echo_id):
		return false
		
	var echo_data = EchoDB.get_echo(echo_id)
	var price = echo_data.get("sell_price", 0)
	add_credits(price)
	echo_progress[echo_id]["sold"] = true
	if echo_id == "echo_linfei":
		set_flag("sold_linfei_echo", true)
	# 11-C：賣＝把別人的存在再次商品化，原始資料離手 → Trace↓（集中在此，與對話無關）
	add_trace(TRACE_DELTA_SELL)
	echo_changed.emit(echo_id)
	return true

func _maybe_backfill_clerk_echo() -> void:
	if get_flag("store_robot_resolution", "") == "gleaned" and not is_echo_known("echo_clerk"):
		record_full_echo("echo_clerk")

func install_probe_module() -> bool:
	var has_module = has_item("old_probe_module")
	
	# Find fingerless gloves in equipment or inventory
	var gloves_instance_id := ""
	var is_gloves_equipped := false
	
	# Check equipment first
	for slot_type in equipment:
		for instance_id in equipment[slot_type]:
			for slot in inventory:
				if not slot.is_empty() and slot.get("instance_id") == instance_id:
					if slot.get("item_id") == "fingerless_gloves":
						gloves_instance_id = instance_id
						is_gloves_equipped = true
						break
			if not gloves_instance_id.is_empty():
				break
		if not gloves_instance_id.is_empty():
			break
			
	if gloves_instance_id.is_empty():
		# Check inventory (not equipped)
		for slot in inventory:
			if not slot.is_empty() and slot.get("item_id") == "fingerless_gloves":
				gloves_instance_id = slot.get("instance_id", "")
				break
				
	if not has_module or gloves_instance_id.is_empty():
		return false
		
	# Remove module
	var removed = remove_item("old_probe_module", 1)
	if not removed:
		return false
		
	# Replace fingerless_gloves with gleaner_gloves in inventory slots
	for i in range(inventory.size()):
		var slot = inventory[i]
		if not slot.is_empty() and slot.get("instance_id") == gloves_instance_id:
			slot["item_id"] = "gleaner_gloves"
			break
			
	if is_gloves_equipped:
		equipment_changed.emit()
		
	set_flag("gleaner_gloves_installed", true)
	inventory_changed.emit()
	return true



# ==========================================
# Internal Helpers
# ==========================================
func _sort_container(slots: Array) -> void:
	var equipped_items := []
	var regular_items := []
	var empty_slots_count := 0

	for slot in slots:
		if slot.is_empty():
			empty_slots_count += 1
		else:
			var instance_id: String = slot.get("instance_id", "")
			if _is_equipped(instance_id):
				equipped_items.append(slot)
			else:
				regular_items.append(slot)

	# Sort regular items alphabetically by item_id
	regular_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("item_id", "").naturalnocasecmp_to(b.get("item_id", "")) < 0
	)

	slots.clear()
	slots.append_array(equipped_items)
	slots.append_array(regular_items)
	for i in range(empty_slots_count):
		slots.append({})

# ==========================================
# Serialization & State Management API
# ==========================================
func to_save_dict() -> Dictionary:
	return {
		"credits": credits,
		"inventory": inventory.duplicate(true),
		"equipment": equipment.duplicate(true),
		"knowledge": knowledge.duplicate(true),
		"notes": notes.duplicate(true),
		"external_containers": external_containers.duplicate(true),
		"external_container_configs": external_container_configs.duplicate(true),
		"apartment_initialized": apartment_initialized,
		"apartment_sonar_revealed": apartment_sonar_revealed,
		"apartment_slot_unlocked": apartment_slot_unlocked,
		"apartment_beyond_door_bgm_triggered": apartment_beyond_door_bgm_triggered,
		"story_flags": story_flags.duplicate(true),
		"trace": trace,
		"quest_states": quest_states.duplicate(true),
		"shop_states": shop_states.duplicate(true),
		"echo_progress": echo_progress.duplicate(true),
		"visited_scenes": visited_scenes.duplicate(true),
		"talked_npcs": talked_npcs.duplicate(true),
		"collected_special_items": collected_special_items.duplicate(true),
		"_last_instance_id": _last_instance_id
	}

func load_save_dict(data: Dictionary) -> void:
	if data.has("credits"):
		credits = data["credits"]
	if data.has("inventory"):
		inventory.clear()
		for item in data["inventory"]:
			inventory.append(item.duplicate() if item is Dictionary else item)
	if data.has("equipment"):
		equipment.clear()
		for key in data["equipment"]:
			var arr = data["equipment"][key]
			var restored_arr = []
			for val in arr:
				restored_arr.append(val)
			equipment[key] = restored_arr
	if data.has("knowledge"):
		knowledge = data["knowledge"].duplicate(true)
	if data.has("notes"):
		notes.clear()
		for note in data["notes"]:
			notes.append(note.duplicate() if note is Dictionary else note)
	if data.has("external_containers"):
		external_containers = data["external_containers"].duplicate(true)
	if data.has("external_container_configs"):
		external_container_configs = data["external_container_configs"].duplicate(true)
	if data.has("apartment_initialized"):
		apartment_initialized = data["apartment_initialized"]
	if data.has("apartment_sonar_revealed"):
		apartment_sonar_revealed = data["apartment_sonar_revealed"]
	if data.has("apartment_slot_unlocked"):
		apartment_slot_unlocked = data["apartment_slot_unlocked"]
	if data.has("apartment_beyond_door_bgm_triggered"):
		apartment_beyond_door_bgm_triggered = data["apartment_beyond_door_bgm_triggered"]
	if data.has("story_flags"):
		story_flags = data["story_flags"].duplicate(true)
	# Phase 11-A：trace 向後相容——舊存檔無此鍵時保持預設 0
	if data.has("trace"):
		trace = int(data["trace"])
	else:
		trace = 0
	if data.has("quest_states"):
		quest_states = data["quest_states"].duplicate(true)
	if data.has("shop_states"):
		shop_states = data["shop_states"].duplicate(true)
	if data.has("echo_progress"):
		echo_progress = data["echo_progress"].duplicate(true)
	else:
		echo_progress.clear()
	
	if data.has("visited_scenes"):
		visited_scenes = data["visited_scenes"].duplicate(true)
	else:
		visited_scenes.clear()
	if data.has("talked_npcs"):
		talked_npcs = data["talked_npcs"].duplicate(true)
	else:
		talked_npcs.clear()
	if data.has("collected_special_items"):
		collected_special_items = data["collected_special_items"].duplicate(true)
	else:
		collected_special_items.clear()

	if data.has("_last_instance_id"):
		_last_instance_id = data["_last_instance_id"]

	# Emit signals
	inventory_changed.emit()
	credits_changed.emit(credits)
	notes_changed.emit()
	equipment_changed.emit()
	for container_id in external_containers:
		container_changed.emit(container_id)
	for quest_id in quest_states:
		quest_changed.emit(quest_id, quest_states[quest_id])
	for shop_id in shop_states:
		shop_changed.emit(shop_id)
	for echo_id in echo_progress:
		echo_changed.emit(echo_id)

	_maybe_backfill_clerk_echo()

func reset_for_new_game() -> void:
	credits = 300
	_last_instance_id = 0
	inventory.clear()
	for i in range(inventory_slots):
		inventory.append({})
	equipment = {
		"clothing": [],
		"hand": [],
		"accessory": []
	}
	knowledge.clear()
	notes.clear()
	external_containers.clear()
	external_container_configs.clear()
	apartment_initialized = false
	apartment_sonar_revealed = false
	apartment_slot_unlocked = false
	apartment_beyond_door_bgm_triggered = false
	story_flags.clear()
	trace = 0
	quest_states.clear()
	shop_states.clear()
	echo_progress.clear()
	visited_scenes.clear()
	talked_npcs.clear()
	collected_special_items.clear()

	# Emit signals
	inventory_changed.emit()
	credits_changed.emit(credits)
	notes_changed.emit()
	equipment_changed.emit()


# ==========================================
# Phase M1 Progress APIs
# ==========================================
func mark_scene_visited(scene_id: String) -> void:
	if scene_id.is_empty():
		return
	if not visited_scenes.has(scene_id):
		visited_scenes[scene_id] = true

func mark_npc_talked(dialogue_id: String) -> void:
	if dialogue_id.is_empty() or not PROGRESS_NPCS.has(dialogue_id):
		return
	if not talked_npcs.has(dialogue_id):
		talked_npcs[dialogue_id] = true

func _maybe_mark_special_item(item_id: String) -> void:
	if item_id.is_empty() or not PROGRESS_SPECIAL_ITEMS.has(item_id):
		return
	if not collected_special_items.has(item_id):
		collected_special_items[item_id] = true

func get_progress_summary() -> Dictionary:
	var summary := {
		"scenes": {
			"done": 0,
			"total": PROGRESS_SCENES.size(),
			"items": []
		},
		"npcs": {
			"done": 0,
			"total": PROGRESS_NPCS.size(),
			"items": []
		},
		"quests": {
			"done": 0,
			"total": PROGRESS_QUESTS.size() + 1,
			"items": []
		},
		"echoes": {
			"done": 0,
			"total": PROGRESS_ECHOES.size(),
			"items": []
		},
		"special": {
			"done": 0,
			"total": PROGRESS_SPECIAL_ITEMS.size(),
			"items": []
		},
		"overall_done": 0,
		"overall_total": 0,
		"overall_pct": 0
	}

	# 1. Scenes
	for scene_id in PROGRESS_SCENES:
		var done = visited_scenes.get(scene_id, false)
		var name = ""
		match scene_id:
			"tunnel_combat": name = "廢棄隧道"
			_:
				# Resolve SaveSystem via node path instead of the autoload global
				# identifier, so this script still compiles when loaded standalone
				# (e.g. headless `-s` tests where autoload globals are unregistered).
				var save_system = get_node_or_null("/root/SaveSystem")
				name = save_system.get_scene_display_name(scene_id) if save_system else scene_id
		if done:
			summary["scenes"]["done"] += 1
		summary["scenes"]["items"].append({
			"id": scene_id,
			"name": name,
			"done": done
		})

	# 2. NPCs
	for npc_id in PROGRESS_NPCS:
		var done = talked_npcs.get(npc_id, false)
		var name = ""
		match npc_id:
			"wan": name = "晚"
			"store_robot": name = "店控機器人"
			"lu_qichen": name = "鹿其琛"
			"cen": name = "小岑"
			"wu": name = "伍姐"
			"seven": name = "七號"
			_: name = npc_id
		if done:
			summary["npcs"]["done"] += 1
		summary["npcs"]["items"].append({
			"id": npc_id,
			"name": name,
			"done": done
		})

	# 3. Quests
	var left_apt = get_flag("left_apartment_once", false)
	if left_apt:
		summary["quests"]["done"] += 1
	summary["quests"]["items"].append({
		"id": "left_apartment_once",
		"name": "離開公寓家",
		"done": left_apt
	})
	for quest_id in PROGRESS_QUESTS:
		var done = quest_states.get(quest_id, {}).get("status", "") == "completed"
		var name = ""
		match quest_id:
			"alley_backrooms_3f": name = "晚的委託：後巷偵查"
			"repair_vendor_bot": name = "便利商店的故障機器人"
			_: name = quest_id
		if done:
			summary["quests"]["done"] += 1
		summary["quests"]["items"].append({
			"id": quest_id,
			"name": name,
			"done": done
		})

	# 4. Echoes
	for echo_id in PROGRESS_ECHOES:
		var done = _is_echo_complete_for_progress(echo_id)
		var title = "未命名殘響"
		if EchoDB.has_echo(echo_id):
			title = EchoDB.get_echo(echo_id).get("title", title)
		if done:
			summary["echoes"]["done"] += 1
		summary["echoes"]["items"].append({
			"id": echo_id,
			"name": title,
			"done": done
		})

	# 5. Special Items
	for item_id in PROGRESS_SPECIAL_ITEMS:
		var done = collected_special_items.get(item_id, false)
		var name = ""
		if ITEMS_DB.has(item_id):
			name = ITEMS_DB[item_id].get("name", item_id)
		else:
			name = item_id
		if done:
			summary["special"]["done"] += 1
		summary["special"]["items"].append({
			"id": item_id,
			"name": name,
			"done": done
		})

	var overall_total = summary["scenes"]["total"] + summary["npcs"]["total"] + summary["quests"]["total"] + summary["echoes"]["total"] + summary["special"]["total"]
	var overall_done = summary["scenes"]["done"] + summary["npcs"]["done"] + summary["quests"]["done"] + summary["echoes"]["done"] + summary["special"]["done"]
	summary["overall_total"] = overall_total
	summary["overall_done"] = overall_done
	summary["overall_pct"] = int(round(float(overall_done) * 100.0 / float(overall_total))) if overall_total > 0 else 0

	return summary




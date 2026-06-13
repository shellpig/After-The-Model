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
var quest_states: Dictionary = {}
var shop_states: Dictionary = {}
var echo_progress: Dictionary = {}

const ShopDB = preload("res://data/shops/shop_db.gd")
const SELL_RATIO := 0.5




const STORY_NOTES := {
	"work_ai_cleanup_role": {
		"id": "work_ai_cleanup_role",
		"category": "工作",
		"title": "AI 善後員",
		"body": "派工單一筆一筆自己跳出來, 地址、編號, 註記欄寫著「殘留清除」「記憶體焚毀」。從沒見過發派的人, 只有螢幕那頭簡短的指示, 從不寒暄, 也從不出錯。原來你靠這個過活——收拾 AI 留下的、人們不想再看見的東西。",
		"status": "active"
	},
	"identity_gleaner": {
		"id": "identity_gleaner",
		"category": "身份",
		"title": "拾遺者",
		"body": "牆上整排都是舊帶子, 老歌、舊廣播、不知道誰的留言。這些早該被善後員銷毀的東西, 你卻一捲一捲留了下來。你一邊清除過去, 一邊偷偷把它撿回家。",
		"status": "active"
	},
	"clue_gloves_decoder": {
		"id": "clue_gloves_decoder",
		"category": "線索",
		"title": "不只是手套",
		"body": "這雙手套你戴得很習慣, 習慣到忘了它哪裡不對勁。指尖那圈接點碰到某些東西時, 會有反應。你還想不起它是用來「讀」什麼的——但你的手記得。",
		"status": "active"
	},
	"clue_decoder_cube": {
		"id": "clue_decoder_cube",
		"category": "線索",
		"title": "解碼方塊",
		"body": "一種普遍用於解開設備功能的道具, 性質有點像鑰匙。放入對應的插槽, 就能開啟特定功能。",
		"status": "active"
	},
	"clue_projection_clock": {
		"id": "clue_projection_clock",
		"category": "線索",
		"title": "別信那個時鐘",
		"body": "營養棒的空包裝裡藏了張紙, 是你自己寫的。那台投影時鐘不只是時鐘——它底下還裝著別的東西。",
		"status": "active"
	},
	"identity_door_unlock_method": {
		"id": "identity_door_unlock_method",
		"category": "身份",
		"title": "我鎖上的門",
		"body": "戴上手套那刻就該想起來的——指尖那圈接點, 是我自己改的。是我把那顆方塊解了碼, 用時鐘裡的舊終端掃出牆內的插槽, 再把它嵌進去。一整套機關, 全是我親手裝的。我把自己鎖在這裡, 連從裡面都打不開。可這道門不挑人——它一樣能把別人關在裡面。當初, 我到底是想鎖住誰?",
		"status": "active"
	},
	"clue_clerk_locker": {
		"id": "clue_clerk_locker",
		"category": "線索",
		"title": "阿達的置物櫃",
		"body": "便利商店員工區的置物櫃裡有一套屬於店員『阿達』的制服。機器人顯然不是阿達，但它表現得像是這間店的唯一負責人。",
		"status": "active"
	},
	"clue_clerk_diary": {
		"id": "clue_clerk_diary",
		"category": "線索",
		"title": "日記殘頁",
		"body": "被辭退的店員阿達在最後的日記中提到，他被要求將工作交接給櫃台終端（機器人），於是他賭氣地把個人日記與情緒資料備份進了店籍主機中。",
		"status": "active"
	},
	"clue_termination_notice": {
		"id": "clue_termination_notice",
		"category": "線索",
		"title": "自動化通知",
		"body": "店內的辭退公告證實了這家便利商店已全面無人化。排班表上的名字都被劃掉，取而代之的是 AI 系統自動接管的指令。",
		"status": "active"
	},
	"clue_robot_plate": {
		"id": "clue_robot_plate",
		"category": "線索",
		"title": "機器人型號銘牌",
		"body": "櫃台上的機器人有明確的工業銘牌，型號是 CS-Retail-098。它是一個零售服務終端，但它的行為卻在模仿人類店員阿達。",
		"status": "active"
	},
	"clue_counter_photo": {
		"id": "clue_counter_photo",
		"category": "線索",
		"title": "褪色的照片",
		"body": "照片上的人就是店員阿達。這張照片被隨意塞在收銀檯下方，是阿達曾經在這裡工作過的唯一真實物證。",
		"status": "active"
	},
	"clue_vendor_error_lead": {
		"id": "clue_vendor_error_lead",
		"category": "線索",
		"title": "異常的售貨設備",
		"body": "街上的自動販賣機和便利商店內的零售機器人都出現了類似的通訊混亂與行為異常。這看起來不像是單一設備的硬體故障，更像是系統層面的殘留問題。或許這能成為一筆新的善後委託，該回房間的電腦確認看看。",
		"status": "active"
	},
	"clue_probe_module_lead": {
		"id": "clue_probe_module_lead",
		"category": "線索",
		"title": "老舊的探測器",
		"body": "從公寓投影時鐘底下拆出來的模組，看起來是用來探測某種微弱數位訊號的。\n既然大門已經解鎖，或許可以去街區外碰碰運氣。聽說街區最東端有個收廢舊電子玩意的『鹿三爺』，他對這種古怪老設備最感興趣，也許能找他看看。",
		"status": "active"
	}
}

const STORY_MESSAGES := {
	"bed_bad_sleep": "你心中有事, 根本睡不著...",
	"door_locked": "門上了鎖, 而你發現自己不知道如何打開...",
	"door_opened": "你將手套貼上讀取器，綠燈閃爍。伴隨著液壓氣動沉悶的釋放聲，門鎖緩慢退開，滑出一條縫。門外灌進了深夜的冷雨、舊機油與高架鐵軌呼嘯而過的冷冽氣息。外頭是五彩斑斕的折射霓虹——你終於要回到那座把你遺忘的都市了。",
	"desk_computer_msg": "螢幕還亮著, 一份新的派工單正自己跳出來, 沒有寄件人。",
	"desk_computer_dispatch_quest": "新的派工單跳進收件匣，標題寫著「異常販賣行為回報」，末尾只有一行備註：\n「接案者須具備基礎設備診斷能力。任務地點：附近便利商店。報酬視修復結果結算。」\n你感覺這不像普通的清理工作，但這個工作本來就沒有普通這回事。\n（已接下委託：便利商店的故障機器人）",
	"tape_recorder_msg": "錄音機裡卡著一捲帶子。按下播放, 是首沒人記得的老歌, 雜訊裡有人輕輕跟著哼。",
	"decoder_cube_decoded": "當你戴著無指手套拿起魔術方塊時，指尖的接點突然傳來一陣微弱的電流，方塊的接縫處隨之亮起了一道黯淡的迴路光芒。方塊的結構在微弱的喀噠聲中重新排列——它被解碼了。",
	"nutrition_bar_consume": "包裝比手感該有的輕。撕開才發現裡頭沒有營養棒, 只有一張折起來的紙——上面是你自己的字跡：「別信那個時鐘。」",
	"slot_unlocked": "方塊嵌進凹槽, 牆裡某個東西「喀」地鬆開了。你忽然想起來——這道門是你自己鎖上的。不是壞了, 是你親手裝了這套機關, 把自己關在裡面。連從裡面都打不開……當初到底是為了什麼?\n（門, 解鎖了。）"
}

# MVP Temporary Stub DB
const ITEMS_DB := {
	"old_work_badge": {
		"id": "old_work_badge",
		"name": "磨損的工作證",
		"description": "一張舊式的工作識別證，上面的照片已經有些模糊。",
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
		"name": "無指工作手套",
		"description": "半截手套, 指節處的布料磨得發亮。右手食指內側有一圈細小的接點, 不像普通手套該有的東西。你戴上時, 指尖有極輕微的、像是在「讀取」什麼的震動。",
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
		"name": "老舊探測模組",
		"description": "底座彈出的老舊探測模組。外殼有些磨損，指示燈已經熄滅。它看起來不像普通的儲存介質，更像某種專門用來接收特定頻段訊號的古老天線。",
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
		"name": "拾遺手套",
		"description": "裝有老舊探測模組的工作手套。電路接點與手套表面的貼合處有些粗糙，但當你握拳時，能感覺到微弱的電磁共振。\n（可用於感知並採集環境中的數位殘響。）",
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
		"name": "合成罐頭",
		"description": "便宜的合成肉罐頭，雖然味道一般但能填飽肚子。",
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
		"name": "隱士防風夾克",
		"description": "一件低調的防雨夾克，兩側口袋極深。",
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
		"name": "普通魔術方塊",
		"description": "一個褪色的舊塑料魔術方塊，邊角已經磨損，很久沒有人玩過了。普通得不能再普通。",
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
		"name": "在公寓裡找到的解碼方塊",
		"description": "配色與接點完全改變的方塊。上面印有細微的導電迴路與一圈感應觸點。你的手套指尖在碰到它時，會發出輕微的同步震動。",
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
		"name": "合成藍莓口味營養棒",
		"description": "一條包裝完好的合成藍莓口味營養棒，拿在手上感覺異常輕盈。",
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
		"name": "合成橘子口味營養棒",
		"description": "一條包裝完好的合成橘子口味營養棒，便宜又耐餓。",
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
		"name": "早期 AI 助理啟用盒",
		"description": "一個保存良好的早期 AI 助理啟用盒。那時候，人們還會把 AI 當成新家電一樣帶回家，拆封、註冊、期待它讓生活變好。",
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
		"name": "舊式 AI 授權模組",
		"description": "薄片狀的舊式 AI 授權模組。標籤已經褪色，但接點仍然完整。它看起來不像收藏品，比較像某種能讓舊系統暫時認人的鑰匙。",
		"category": "key_item",
		"stackable": false,
		"max_stack": 1,
		"discardable": false,
		"usable": false,
		"icon_path": "res://assets/generated/sprites/items/old_ai_authorization_module/icon.png"
	},
	"clerk_echo_recording": {
		"id": "clerk_echo_recording",
		"name": "店員的殘響",
		"description": "一段從店籍主機備份區拷貝出來的資料——被辭退店員阿達的日記、情緒殘片，與他拒絕離開的那句「憑什麼」。標籤上沒有型號，也沒有條碼。這種東西沒有市場價格，也不該有。",
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
		"name": "合成可樂",
		"description": "一罐廉價的合成氣泡飲料，包裝上印著早已過期的生產序號。拉環拉開時，發出無機的嘶嘶聲。",
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
		"name": "包裝飲用水",
		"description": "淨化過的回收水，帶有微弱的過濾後塑料味。便宜，安全，毫無特色。",
		"category": "consumable",
		"value": 10,
		"stackable": true,
		"max_stack": 5,
		"discardable": true,
		"usable": true,
		"equipment_slot": "",
		"icon_path": "res://assets/generated/sprites/items/packaged_water/icon.png"
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
		
	collected_arr.append(segment_id)
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
	var collected_count = echo_progress[echo_id].get("collected", []).size()
	return collected_count == EchoDB.get_segment_count(echo_id)

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
		"quest_states": quest_states.duplicate(true),
		"shop_states": shop_states.duplicate(true),
		"echo_progress": echo_progress.duplicate(true),
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
	if data.has("quest_states"):
		quest_states = data["quest_states"].duplicate(true)
	if data.has("shop_states"):
		shop_states = data["shop_states"].duplicate(true)
	if data.has("echo_progress"):
		echo_progress = data["echo_progress"].duplicate(true)
	else:
		echo_progress.clear()
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
	quest_states.clear()
	shop_states.clear()
	echo_progress.clear()

	# Emit signals
	inventory_changed.emit()
	credits_changed.emit(credits)
	notes_changed.emit()
	equipment_changed.emit()



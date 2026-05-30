extends Node

# Signals
signal inventory_changed
signal container_changed(container_id: String)
signal credits_changed(new_value: int)
signal knowledge_added(id: String)
signal notes_changed
signal equipment_changed
signal item_moved(move: Dictionary)

# Variables
var credits: int = 0
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
		"discardable": true,
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
		"stackable": true,
		"max_stack": 5,
		"discardable": true,
		"usable": true,
		"equipment_slot": "",
		"icon_path": "res://assets/generated/sprites/items/synthetic_blueberry_nutrition_bar/icon.png",
		"consume_grants_note": "clue_projection_clock"
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
	credits = max(0, value)
	if credits != old_credits:
		credits_changed.emit(credits)

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
			notes[i] = new_note
			found = true
			break

	if not found:
		notes.append(new_note)

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

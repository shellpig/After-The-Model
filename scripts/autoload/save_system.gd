extends Node

const SLOT_COUNT := 7
const SAVE_VERSION := 1

var can_save_here := true
var pending_load_slot := -1

# Display names map for scene_id -> scene_name
const SCENE_NAMES := {
	"apartment": "主角公寓",
	"apartment_entrance": "公寓入口",
	"convenience_store": "便利商店",
	"apartment_fire_escape": "火逃梯外牆",
	"collector_shop": "收藏家的店",
	"subway_station": "地鐵站入口",
	"subway_station_platform": "地鐵站月台",
	"underground_settlement": "地下道聚落",
	"underground_settlement_right": "地下道聚落右區",
	"nightclub_entrance": "夜總會大門口",
	"nightclub": "夜總會前廳",
	"nightclub_back": "夜總會後場包廂",
	"datacenter_entrance": "資料中心入口",
	"datacenter_backup_core": "資料中心核心備份區",
	"broadcast_station": "地下廣播站"
}

func capture(scene_id: String, player_x: float, facing := 1) -> Dictionary:
	var state_dict = GameState.to_save_dict()
	state_dict["current_scene_id"] = scene_id
	state_dict["player_x"] = player_x
	state_dict["player_facing"] = facing
	
	return {
		"meta": {
			"version": SAVE_VERSION,
			"timestamp": int(Time.get_unix_time_from_system()),
			"scene_name": get_scene_display_name(scene_id),
			"credits": GameState.get_credits()
		},
		"data": state_dict
	}

func write_slot(slot: int, payload: Dictionary) -> bool:
	if slot < 1 or slot > SLOT_COUNT:
		return false
	var file_path = _slot_path(slot)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(var_to_str(payload))
	file.close()
	return true

func read_slot(slot: int) -> Dictionary:
	if slot < 1 or slot > SLOT_COUNT:
		return {}
	var file_path = _slot_path(slot)
	if not FileAccess.file_exists(file_path):
		return {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}
	var content = file.get_as_text()
	file.close()
	var payload = str_to_var(content)
	if not payload is Dictionary:
		return {}
	return payload

func validate(payload: Dictionary) -> bool:
	if payload.is_empty():
		return false
	if not payload.has("meta") or not payload.has("data"):
		return false
	var meta = payload["meta"]
	var data = payload["data"]
	if not meta is Dictionary or not data is Dictionary:
		return false
	if not meta.has("version") or meta["version"] != SAVE_VERSION:
		return false
	if not data.has("current_scene_id") or not (data["current_scene_id"] is String) or data["current_scene_id"].is_empty():
		return false
	if not data.has("player_x") or not (data["player_x"] is int or data["player_x"] is float):
		return false
	return true

func apply(payload: Dictionary) -> void:
	if not validate(payload):
		return
	GameState.load_save_dict(payload["data"])

func list_slots() -> Array:
	var slots = []
	for slot in range(1, SLOT_COUNT + 1):
		var file_path = _slot_path(slot)
		if not FileAccess.file_exists(file_path):
			slots.append({ "slot": slot, "empty": true })
		else:
			var payload = read_slot(slot)
			if payload.is_empty() or not validate(payload):
				slots.append({ "slot": slot, "empty": false, "corrupt": true })
			else:
				slots.append({
					"slot": slot,
					"empty": false,
					"meta": payload["meta"]
				})
	return slots

func _slot_path(slot: int) -> String:
	return "user://save_%02d.sav" % slot

func get_scene_display_name(scene_id: String) -> String:
	return SCENE_NAMES.get(scene_id, "未知區域")


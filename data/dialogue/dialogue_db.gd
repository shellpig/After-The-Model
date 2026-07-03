# Dialogue Database
# File: res://data/dialogue/dialogue_db.gd
class_name DialogueDB


const WanDialogue = preload("res://data/dialogue/wan.gd")
const WanDatacenterDialogue = preload("res://data/dialogue/wan_datacenter.gd")
const AdaDialogue = preload("res://data/dialogue/ada.gd")
const StoreRobotDialogue = preload("res://data/dialogue/store_robot.gd")
const StoreRegistryHostDialogue = preload("res://data/dialogue/store_registry_host.gd")
const TravelStreetEastDialogue = preload("res://data/dialogue/travel_street_east.gd")
const TravelStreetWestDialogue = preload("res://data/dialogue/travel_street_west.gd")
const TravelDeepTunnelDialogue = preload("res://data/dialogue/travel_deep_tunnel.gd")
const TravelDatacenterDialogue = preload("res://data/dialogue/travel_datacenter.gd")
const LuQichenDialogue = preload("res://data/dialogue/lu_qichen.gd")
const CenDialogue = preload("res://data/dialogue/cen.gd")
const WuDialogue = preload("res://data/dialogue/wu.gd")
const SevenDialogue = preload("res://data/dialogue/seven.gd")
const NightclubBodyguardDialogue = preload("res://data/dialogue/nightclub_bodyguard.gd")
const OwnBackupDialogue = preload("res://data/dialogue/own_backup.gd")
const BroadcastUploadDialogue = preload("res://data/dialogue/broadcast_upload.gd")
const WanEpilogueDialogue = preload("res://data/dialogue/wan_epilogue.gd")

const TREES := {
	"wan": WanDialogue.TREE,
	"wan_datacenter": WanDatacenterDialogue.TREE,
	"ada": AdaDialogue.TREE,
	"store_robot": StoreRobotDialogue.TREE,
	"store_registry_host": StoreRegistryHostDialogue.TREE,
	"travel_street_east": TravelStreetEastDialogue.TREE,
	"travel_street_west": TravelStreetWestDialogue.TREE,
	"travel_deep_tunnel": TravelDeepTunnelDialogue.TREE,
	"travel_datacenter": TravelDatacenterDialogue.TREE,
	"lu_qichen": LuQichenDialogue.TREE,
	"cen": CenDialogue.TREE,
	"wu": WuDialogue.TREE,
	"seven": SevenDialogue.TREE,
	"nightclub_bodyguard": NightclubBodyguardDialogue.TREE,
	"own_backup": OwnBackupDialogue.TREE,
	"broadcast_upload": BroadcastUploadDialogue.TREE,
	"wan_epilogue": WanEpilogueDialogue.TREE
}

static func get_tree_for(dialogue_id: String) -> Dictionary:
	return TREES.get(dialogue_id, {})

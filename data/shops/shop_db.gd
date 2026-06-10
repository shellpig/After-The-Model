# Shop Database
# File: res://data/shops/shop_db.gd
# { shop_id: { "name": String, "stock": {item_id: {price, stock}} } }
# 8-G 將新增 street_vending（迷你飲料商店）驗證 data-driven 多商店。

const ConvenienceStoreShop = preload("res://data/shops/convenience_store.gd")

const SHOPS := {
	"convenience_store": ConvenienceStoreShop.CATALOG
}

static func get_catalog(shop_id: String) -> Dictionary:
	return SHOPS.get(shop_id, {})

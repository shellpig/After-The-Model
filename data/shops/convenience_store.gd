# data/shops/convenience_store.gd
# Phase 8-F：便利商店店內貨架 catalog
# price 為買入價（與 ITEMS_DB.value 脫鉤，允許店家加價）；stock 為初始庫存。
# 當前庫存進 GameState.shop_states["convenience_store"]（首次開店 lazy-init），
# 此檔僅為重設來源（refresh_shop_stock）。
const CATALOG := {
	"name": "便利商店",
	"stock": {
		"canned_food": {"price": 40, "stock": 10},
		"nutrition_bar_synth_blueberry": {"price": 25, "stock": 8}
	}
}

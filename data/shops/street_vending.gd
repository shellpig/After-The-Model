# data/shops/street_vending.gd
# Phase 8-G：街道外面販賣機 (迷你飲料商店) catalog
# price 為買入價；stock 為初始庫存。
# 當前庫存進 GameState.shop_states["street_vending"]（首次開店 lazy-init），
# 此檔僅為重設來源（refresh_shop_stock）。
const CATALOG := {
	"name": "外面販賣機",
	"stock": {
		"synth_cola": {"price": 30, "stock": 5},
		"packaged_water": {"price": 20, "stock": 10}
	}
}

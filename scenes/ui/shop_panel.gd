# Shop Panel (Phase 8-F)
# File: res://scenes/ui/shop_panel.gd
# 雙欄買賣 UI：左 BuyList（店內貨架：名稱 / 買價 / 庫存）、右 SellList（背包：名稱 / 售出價或不可賣）。
# focus 不用引擎焦點（避免 Button 吞方向鍵 / E），以 active_pane + index 手動高亮，
# 鍵盤走 _unhandled_input，觸控由 GameUI shop_move_focus / shop_switch_pane / shop_confirm 代理。
extends PanelContainer

@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var credits_label: Label = $MarginContainer/VBoxContainer/Header/CreditsLabel
@onready var buy_title: Label = $MarginContainer/VBoxContainer/Body/BuyPane/BuyTitle
@onready var sell_title: Label = $MarginContainer/VBoxContainer/Body/SellPane/SellTitle
@onready var buy_scroll: ScrollContainer = $MarginContainer/VBoxContainer/Body/BuyPane/BuyScroll
@onready var sell_scroll: ScrollContainer = $MarginContainer/VBoxContainer/Body/SellPane/SellScroll
@onready var buy_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/BuyPane/BuyScroll/BuyList
@onready var sell_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/SellPane/SellScroll/SellList
@onready var footer_hint: Label = $MarginContainer/VBoxContainer/FooterHint

const COLOR_NORMAL := Color(0.7, 0.7, 0.7, 1.0)
const COLOR_FOCUSED := Color(0.94, 0.92, 0.84, 1.0)
const COLOR_DISABLED := Color(0.42, 0.44, 0.48, 1.0)
const COLOR_TITLE_ACTIVE := Color(0.78, 0.42, 0.2, 1.0)
const COLOR_TITLE_IDLE := Color(0.55, 0.58, 0.6, 1.0)

var shop_id: String = ""
var active_pane: String = "buy" # "buy" / "sell"
var buy_index: int = 0
var sell_index: int = 0
var _input_active: bool = false
# _buy_rows: [{item_id, price, stock}]；_sell_rows: [{instance_id, item_id, quantity, sellable, equipped}]
var _buy_rows: Array = []
var _sell_rows: Array = []

func _ready() -> void:
	visible = false
	_apply_panel_style()
	GameState.shop_changed.connect(_on_shop_changed)
	GameState.inventory_changed.connect(_on_state_changed)
	GameState.credits_changed.connect(_on_credits_changed)
	GameState.equipment_changed.connect(_on_state_changed)
	footer_hint.text = tr("UI_SHOP_FOOTER_HINT")

func open(p_shop_id: String) -> void:
	shop_id = p_shop_id
	active_pane = "buy"
	buy_index = 0
	sell_index = 0
	var catalog: Dictionary = GameState.ShopDB.get_catalog(shop_id)
	title_label.text = catalog.get("name", shop_id)
	_refresh_all()
	visible = true

func close() -> void:
	visible = false
	shop_id = ""

func is_open() -> bool:
	return visible and not shop_id.is_empty()

func set_input_active(active: bool) -> void:
	_input_active = active

func move_focus(dir: int) -> void:
	if not is_open():
		return
	if active_pane == "buy":
		if _buy_rows.is_empty():
			return
		buy_index = clampi(buy_index + dir, 0, _buy_rows.size() - 1)
	else:
		if _sell_rows.is_empty():
			return
		sell_index = clampi(sell_index + dir, 0, _sell_rows.size() - 1)
	_update_highlight()

func switch_pane(dir: int) -> void:
	if not is_open():
		return
	active_pane = "buy" if dir < 0 else "sell"
	_update_highlight()

func confirm_current() -> void:
	if not is_open():
		return
	if active_pane == "buy":
		_do_buy()
	else:
		_do_sell()

func _do_buy() -> void:
	if buy_index < 0 or buy_index >= _buy_rows.size():
		return
	var row: Dictionary = _buy_rows[buy_index]
	var item_id: String = row.get("item_id", "")
	var item_name: String = tr(GameState.ITEMS_DB.get(item_id, {}).get("name", item_id))
	if GameState.buy_item(shop_id, item_id):
		FloatingToast.show_toast(tr("UI_SHOP_TOAST_BOUGHT_FMT") % [tr(item_name), row.get("price", 0)], self)
		return
	var check: Dictionary = GameState.can_buy(shop_id, item_id)
	match check.get("reason", ""):
		"out_of_stock":
			FloatingToast.show_toast(tr("UI_SHOP_TOAST_SOLD_OUT"), self)
		"not_enough_credits":
			FloatingToast.show_toast(tr("UI_SHOP_TOAST_NO_CREDITS"), self)
		_:
			# can_buy 過了但 buy_item 失敗 = add_item 失敗 = 背包滿
			FloatingToast.show_toast(tr("UI_SHOP_TOAST_BAG_FULL"), self)

func _do_sell() -> void:
	if sell_index < 0 or sell_index >= _sell_rows.size():
		return
	var row: Dictionary = _sell_rows[sell_index]
	var item_id: String = row.get("item_id", "")
	var item_name: String = tr(GameState.ITEMS_DB.get(item_id, {}).get("name", item_id))
	if row.get("equipped", false):
		FloatingToast.show_toast(tr("UI_SHOP_TOAST_EQUIPPED"), self)
		return
	if not row.get("sellable", false):
		FloatingToast.show_toast(tr("UI_SHOP_TOAST_UNSELLABLE"), self)
		return
	var sell_value := GameState.get_sell_value(item_id)
	if GameState.sell_item(row.get("instance_id", "")):
		FloatingToast.show_toast(tr("UI_SHOP_TOAST_SOLD_FMT") % [tr(item_name), sell_value], self)

func _unhandled_input(event: InputEvent) -> void:
	if not _input_active or not is_open():
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		move_focus(-1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		move_focus(1)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		get_viewport().set_input_as_handled()
		switch_pane(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		get_viewport().set_input_as_handled()
		switch_pane(1)
	elif event.is_action_pressed("interact_primary"):
		get_viewport().set_input_as_handled()
		confirm_current()

# ==========================================
# List building / refresh
# ==========================================
func _on_shop_changed(changed_shop_id: String) -> void:
	if is_open() and changed_shop_id == shop_id:
		_refresh_all()

func _on_state_changed() -> void:
	if is_open():
		_refresh_all()

func _on_credits_changed(_new_value: int) -> void:
	if is_open():
		credits_label.text = "credits : %d" % GameState.get_credits()

func _refresh_all() -> void:
	credits_label.text = "credits : %d" % GameState.get_credits()
	_rebuild_buy_rows()
	_rebuild_sell_rows()
	buy_index = clampi(buy_index, 0, max(0, _buy_rows.size() - 1))
	sell_index = clampi(sell_index, 0, max(0, _sell_rows.size() - 1))
	_rebuild_list(buy_list, _buy_rows.size(), _format_buy_row, "buy")
	_rebuild_list(sell_list, _sell_rows.size(), _format_sell_row, "sell")
	_update_highlight()

func _rebuild_buy_rows() -> void:
	_buy_rows.clear()
	var stock: Dictionary = GameState.get_shop_stock(shop_id)
	for item_id in stock:
		_buy_rows.append({
			"item_id": item_id,
			"price": stock[item_id].get("price", 0),
			"stock": stock[item_id].get("stock", 0)
		})

func _rebuild_sell_rows() -> void:
	_sell_rows.clear()
	for slot in GameState.get_inventory():
		if slot.is_empty():
			continue
		var item_id: String = slot.get("item_id", "")
		var instance_id: String = slot.get("instance_id", "")
		_sell_rows.append({
			"instance_id": instance_id,
			"item_id": item_id,
			"quantity": slot.get("quantity", 1),
			"sellable": GameState.is_sellable(item_id),
			"equipped": GameState.is_equipped(instance_id)
		})

func _format_buy_row(i: int) -> Dictionary:
	var row: Dictionary = _buy_rows[i]
	var item_name: String = tr(GameState.ITEMS_DB.get(row["item_id"], {}).get("name", row["item_id"]))
	var out_of_stock: bool = row.get("stock", 0) <= 0
	var stock_part := tr("UI_SHOP_SOLD_OUT") if out_of_stock else tr("UI_SHOP_STOCK_FMT") % row.get("stock", 0)
	var text := tr("UI_SHOP_BUY_ROW_FMT") % [
		item_name, row.get("price", 0),
		stock_part
	]
	return {"text": text, "disabled": out_of_stock}

func _format_sell_row(i: int) -> Dictionary:
	var row: Dictionary = _sell_rows[i]
	var item_name: String = tr(GameState.ITEMS_DB.get(row["item_id"], {}).get("name", row["item_id"]))
	var qty_part := " ×%d" % row.get("quantity", 1) if row.get("quantity", 1) > 1 else ""
	if row.get("equipped", false):
		return {"text": tr("UI_SHOP_ITEM_EQUIPPED_FMT") % [item_name, qty_part], "disabled": true}
	if not row.get("sellable", false):
		return {"text": tr("UI_SHOP_ITEM_UNSELLABLE_FMT") % [item_name, qty_part], "disabled": true}
	return {
		"text": tr("UI_SHOP_ITEM_SELL_VAL_FMT") % [item_name, qty_part, GameState.get_sell_value(row["item_id"])],
		"disabled": false
	}

func _rebuild_list(list: VBoxContainer, count: int, formatter: Callable, pane: String) -> void:
	# 立即出樹再 queue_free：同 frame 內 _highlight_list 會重掃 get_children()，
	# 殘留待刪節點會破壞 index 對應
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	if count == 0:
		var empty_label := Label.new()
		empty_label.text = tr("UI_SHOP_EMPTY")
		empty_label.add_theme_color_override("font_color", COLOR_DISABLED)
		empty_label.add_theme_font_size_override("font_size", 16)
		list.add_child(empty_label)
		return
	for i in range(count):
		var info: Dictionary = formatter.call(i)
		var btn := Button.new()
		btn.name = "Row%d" % i
		btn.text = "  " + info["text"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		var empty_style := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", empty_style)
		btn.add_theme_stylebox_override("hover", empty_style)
		btn.add_theme_stylebox_override("pressed", empty_style)
		btn.add_theme_stylebox_override("focus", empty_style)
		btn.add_theme_font_size_override("font_size", 16)
		btn.set_meta("disabled_row", info["disabled"])
		btn.pressed.connect(_on_row_pressed.bind(pane, i))
		list.add_child(btn)

func _on_row_pressed(pane: String, index: int) -> void:
	if not _input_active:
		return
	active_pane = pane
	if pane == "buy":
		buy_index = index
	else:
		sell_index = index
	_update_highlight()
	confirm_current()

func _update_highlight() -> void:
	buy_title.add_theme_color_override("font_color", COLOR_TITLE_ACTIVE if active_pane == "buy" else COLOR_TITLE_IDLE)
	sell_title.add_theme_color_override("font_color", COLOR_TITLE_ACTIVE if active_pane == "sell" else COLOR_TITLE_IDLE)
	_highlight_list(buy_list, buy_index if active_pane == "buy" else -1, buy_scroll)
	_highlight_list(sell_list, sell_index if active_pane == "sell" else -1, sell_scroll)

func _highlight_list(list: VBoxContainer, focused_idx: int, scroll: ScrollContainer) -> void:
	var i := 0
	for child in list.get_children():
		if not (child is Button):
			continue
		var btn := child as Button
		var disabled: bool = btn.get_meta("disabled_row", false)
		var base_text: String = btn.text.substr(2)
		if i == focused_idx:
			btn.text = "> " + base_text
			btn.add_theme_color_override("font_color", COLOR_DISABLED if disabled else COLOR_FOCUSED)
			if scroll != null:
				scroll.ensure_control_visible(btn)
		else:
			btn.text = "  " + base_text
			btn.add_theme_color_override("font_color", COLOR_DISABLED if disabled else COLOR_NORMAL)
		i += 1

func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.92)
	style.border_color = Color(0.78, 0.42, 0.2, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 16.0
	style.content_margin_top = 16.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 16.0
	add_theme_stylebox_override("panel", style)

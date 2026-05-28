# Phase 1-E 實作計畫 v4 — 物品操作（查看 / 丟棄 / 裝備）

> v4 以 v3 為基礎，保留 v3 的 4 個 Critical Bug 修正與 3 個規格符合性修正。
> 另合併 code review findings：BagGrid 雙欄輸入衝突、CONFIRM callback toast 錨點錯誤、ItemDetailModal 位置/API deviation、測試覆蓋不足。

---

## v4 修正摘要

| # | 類型 | 問題 | 修法 |
|---|---|---|---|
| Bug 1 | Critical | `Input.is_action_just_pressed()` 不受 `set_input_as_handled()` 影響，Modal 開啟時 Esc/I 會把整個 INVENTORY 關掉 | `_process()` UI mode 分支最前面加 `if item_detail_modal.visible: return` |
| Bug 2 | Critical | BagGrid 沒有 `inventory_changed` listener，E 裝備後 EquippedMarker 不刷新 | `bag_grid.gd._ready()` 連 `GameState.inventory_changed`；`_input_active` 時自動 `initialize_grid()` |
| Bug 3 | Critical | `dual_pane_container.set_input_active(false)` 在 view 路徑中永久關掉雙欄輸入 | view 路徑不 deactivate dual pane，只靠 modal `_input` swallow |
| Bug 4 | Critical | `CONTAINER -> CONFIRM -> CONTAINER` 把 `active_pane` 重置成 `"right"` | `_on_ui_mode_changed()` CONTAINER 分支加 `if not dual_pane_container.is_input_active` 守衛 |
| Finding 1 | Critical | BagGrid 同時用於單獨背包與雙欄左欄；若直接加 E/R/T，會在雙欄左欄搶走 E 移動 | BagGrid 新增 `_item_actions_enabled` flag；只有 INVENTORY 單獨背包啟用，雙欄內 BagGrid navigation-only |
| Finding 2 | High | ConfirmDialog callback 執行時 UIMode 仍是 CONFIRM，`_get_active_panel()` 會讓 INVENTORY 丟棄成功 toast 錨到 dual pane | `_start_discard_flow()` 先保存 `toast_panel`，bind 到 `_on_discard_confirmed()` |
| Finding 3 | Medium | v3 把 ItemDetailModal 改成 viewport 置中，與規格「蓋在 panel 上方中央」不一致 | `show_modal()` 保留 `anchor_node` 參數，依 anchor panel/active grid 置中定位 |
| Finding 4 | Medium | `test_runner` 只驗 node/API/z-order，抓不到 Bug 1-4 行為 | 保留 smoke test，另新增 headless/manual 驗收項目；若時間允許補 input harness |
| 規格 5 | Medium | Toast 逗號應為全形「，」 | 修正 toast 字串 |
| 規格 6 | Medium | `show_modal()` / `show_dialog()` 是刻意 API rename，未文件化 | 明確記錄 deviation 理由 |
| 規格 7 | Medium | 「請先卸下再丟棄」wording 已在規格書確認 | 標記合規 |

---

## 背景

Phase 1-A 到 1-D 均已完成並人工驗收。目前底層已具備：

- `GameState`：`equip` / `unequip` / `is_equipped` 已實作；`unequip_by_instance` / `discard_item` 待補。
- `UIMode`：`CONFIRM` enum 已定義；`enter_confirm` / `exit_confirm` 待補。
- `BagGrid`：`EquippedMarker` 預留位已有；目前只處理方向鍵；無 `inventory_changed` listener。
- `DualPaneContainer`：E 只做移動，R / T 未接。
- `FloatingToast.show_toast()` 可呼叫。
- `_sort_container()` 已實作 equipped-first 排序，不需修改排序策略。

本文件是實作文件，目標是讓 implementer 直接照做。除非另有使用者指示，實作角色只改 code / scene / test，不同步改規格書。

---

## 核心架構決定

### 1. 輸入路由

`ItemDetailModal` / `ConfirmDialog` 使用 `_input`，不是 `_unhandled_input`。

visible 時 `_input()` 第一行：

```gdscript
get_viewport().set_input_as_handled()
```

目的：遮蓋底層節點的 `_unhandled_input`。

但 `_process()` 使用的 `Input.is_action_just_pressed()` 是全域輪詢，不在 event routing phase 內，不受 `set_input_as_handled()` 影響。因此 `apartment_room.gd._process()` 仍必須有 visible/mode guard。

### 2. BagGrid action mode

`BagGrid` 是共用 component：

- 單獨背包：需要 E/R/T item action。
- 雙欄左欄：只負責 navigation；E/R/T 必須交給 `DualPaneContainer` 統一路由，否則 E 會不再是「移動」。

因此 `BagGrid` 新增 item action flag，預設 `false`：

```gdscript
signal item_action_requested(action: String, instance_id: String)

var _item_actions_enabled: bool = false

func set_item_actions_enabled(enabled: bool) -> void:
    _item_actions_enabled = enabled
```

`_unhandled_input()` 中只有 `_item_actions_enabled == true` 時才處理 E/R/T。

### 3. CONFIRM caller 還原

`ConfirmDialog` 切 `UIMode.CONFIRM`，但 caller UI 不關閉。關閉 dialog 後由 `UIMode.exit_confirm()` 還原 caller mode。

`CONFIRM` 期間 I/J/Esc 等大型 UI 關閉/切換邏輯不反應，只有 dialog 自己處理 E/Esc。

---

## 新增檔案

### `scenes/ui/item_detail_modal.gd` + `item_detail_modal.tscn`

R 鍵查看物品的浮動 modal。**不切 UIMode**。

Panel：

```text
寬 = 320
高 = 400
skin = inventory skin
位置 = 依 anchor_node 置中；若無 anchor_node 才 fallback viewport 置中
```

節點結構：

```text
PanelContainer (item_detail_modal.tscn)
└── VBoxContainer
    ├── IconRect       (TextureRect, 128x128, centered)
    ├── NameLabel      (Label, 22px, 米白, centered)
    ├── DescLabel      (RichTextLabel, 16px, wrap)
    ├── Spacer         (Control, size_flags expand)
    ├── CategoryLabel  (Label, 14px, 暗灰, centered)
    └── FooterHint     (Label, 14px, 暗灰) "R / Esc: 關閉"
```

API：

> Spec deviation：規格書舊版寫 `show()` / `close()`，但 `Control.show()` 已是 Godot 基類方法。避免覆蓋 Godot 內部 API，實作使用 `show_modal()` / `close_modal()`。

```gdscript
var _restore_grid: Control = null
var _restore_index: int = 0

func show_modal(instance_id: String, restore_grid: Control, restore_index: int, anchor_node: Control = null) -> void:
    _restore_grid = restore_grid
    _restore_index = restore_index
    _fill_content(instance_id)
    visible = true
    _position_for_anchor(anchor_node)

func close_modal() -> void:
    visible = false
    if _restore_grid != null:
        _restore_grid.set_input_active(true)
        _restore_grid.set_focused_index(_restore_index)

func _input(event: InputEvent) -> void:
    if not visible:
        return
    get_viewport().set_input_as_handled()
    if event.is_action_pressed("interact_secondary") or event.is_action_pressed("ui_cancel"):
        close_modal()
```

Positioning：

```gdscript
func _position_for_anchor(anchor_node: Control = null) -> void:
    reset_size()
    var viewport_size := get_viewport_rect().size
    if anchor_node == null:
        position = (viewport_size - size) * 0.5
        return

    var anchor_pos := anchor_node.global_position
    var anchor_size := anchor_node.size
    global_position = anchor_pos + Vector2((anchor_size.x - size.x) * 0.5, (anchor_size.y - size.y) * 0.5)
```

`category_tag` 規則：

| category | tag 文字 |
|---|---|
| `key_item` | `劇情物品（不可丟棄）` |
| `equipment` | `裝備（{slot 中文}）` |
| `consumable` | `消耗品` |
| `misc` | `物品` |

slot 中文：

- `clothing` -> `衣服`
- `hand` -> `手持`
- `accessory` -> `其他`

### `scenes/ui/confirm_dialog.gd` + `confirm_dialog.tscn`

T 鍵丟棄確認。切 `UIMode.CONFIRM`。

Panel：

```text
寬 = 360
高 = 160
skin = inventory skin
位置 = viewport 置中
```

節點結構：

```text
PanelContainer (confirm_dialog.tscn)
└── VBoxContainer
    ├── MessageLabel   (Label, 18px, 米白, centered)
    ├── Spacer         (Control, size_flags expand)
    └── FooterHint     (Label, 14px, 暗灰) "E: 確定    Esc: 取消"
```

API：

```gdscript
var _on_confirm: Callable
var _on_cancel: Callable
var _restore_grid: Control = null
var _restore_index: int = 0

func show_dialog(message: String, on_confirm: Callable,
                 restore_grid: Control = null, restore_index: int = 0,
                 on_cancel: Callable = Callable()) -> void:
    _on_confirm = on_confirm
    _on_cancel = on_cancel
    _restore_grid = restore_grid
    _restore_index = restore_index
    message_label.text = message
    visible = true

func close_dialog() -> void:
    visible = false
    UIMode.exit_confirm()
    if _restore_grid != null:
        _restore_grid.set_input_active(true)
        _restore_grid.set_focused_index(_restore_index)

func _input(event: InputEvent) -> void:
    if not visible:
        return
    get_viewport().set_input_as_handled()
    if event.is_action_pressed("interact_primary"):
        if _on_confirm.is_valid():
            _on_confirm.call()
        close_dialog()
    elif event.is_action_pressed("ui_cancel"):
        if _on_cancel.is_valid():
            _on_cancel.call()
        close_dialog()
```

注意：callback 會在 `close_dialog()` 前執行，此時 UIMode 仍是 `CONFIRM`。任何 callback 不得依賴 `_get_active_panel()` 重新判斷錨點；需要的 panel 必須事先 bind。

---

## 修改現有檔案

### `scripts/autoload/ui_mode.gd`

補 `CONFIRM` caller 還原機制：

```gdscript
var _caller_mode: int = Mode.NONE

func enter_confirm() -> void:
    _caller_mode = current_mode
    current_mode = Mode.CONFIRM
    mode_changed.emit(Mode.CONFIRM)

func exit_confirm() -> void:
    current_mode = _caller_mode
    _caller_mode = Mode.NONE
    mode_changed.emit(current_mode)
```

### `scripts/autoload/game_state.gd`

新增：

```gdscript
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
```

新增：

```gdscript
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

    var item_meta := ITEMS_DB.get(item_id_found, {})
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
```

### `scenes/ui/bag_grid.gd`

新增 signal、inventory refresh、item action mode。

```gdscript
signal item_action_requested(action: String, instance_id: String)

var _item_actions_enabled: bool = false

func set_item_actions_enabled(enabled: bool) -> void:
    _item_actions_enabled = enabled
```

`_ready()`：

```gdscript
func _ready() -> void:
    self.columns = 5
    add_theme_constant_override("h_separation", 4)
    add_theme_constant_override("v_separation", 4)
    _ensure_slots_exist()
    if not GameState.inventory_changed.is_connected(_on_inventory_changed):
        GameState.inventory_changed.connect(_on_inventory_changed)

func _on_inventory_changed() -> void:
    if _input_active:
        initialize_grid(GameState.get_inventory())
```

`_unhandled_input()` 方向鍵邏輯維持原樣，最後補 E/R/T，但必須包在 `_item_actions_enabled`：

```gdscript
elif _item_actions_enabled and event.is_action_pressed("interact_primary"):
    _emit_item_action("equip_toggle")
    get_viewport().set_input_as_handled()
elif _item_actions_enabled and event.is_action_pressed("interact_secondary"):
    _emit_item_action("view")
    get_viewport().set_input_as_handled()
elif _item_actions_enabled and event.is_action_pressed("interact_tertiary"):
    _emit_item_action("discard")
    get_viewport().set_input_as_handled()
```

```gdscript
func _emit_item_action(action: String) -> void:
    var items := GameState.get_inventory()
    var slot := items[focused_index] if focused_index < items.size() else {}
    item_action_requested.emit(action, slot.get("instance_id", ""))
```

Important：

- `apartment_room.gd` 的單獨背包 `bag_grid` 要 `set_item_actions_enabled(true)`。
- `dual_pane_container.tscn` 內左欄 `BagGrid` 要保持 `set_item_actions_enabled(false)`，由 `DualPaneContainer` 統一處理 E/R/T。

### `scenes/ui/dual_pane_container.gd`

新增 signal：

```gdscript
signal item_action_requested(action: String, instance_id: String, source_pane: String)
```

`_ready()` 確保左欄 BagGrid 不處理 item action：

```gdscript
if left_grid.has_method("set_item_actions_enabled"):
    left_grid.set_item_actions_enabled(false)
```

`_unhandled_input()`：

```gdscript
if event.is_action_pressed("interact_primary"):
    _handle_item_move()
    get_viewport().set_input_as_handled()
elif event.is_action_pressed("interact_secondary"):
    _emit_dual_action("view")
    get_viewport().set_input_as_handled()
elif event.is_action_pressed("interact_tertiary"):
    _emit_dual_action("discard")
    get_viewport().set_input_as_handled()
```

```gdscript
func _emit_dual_action(action: String) -> void:
    var items_array: Array
    var index: int
    var pane: String
    if active_pane == "left":
        items_array = GameState.get_inventory()
        index = left_grid.focused_index
        pane = "left"
    else:
        items_array = GameState.get_container(container_id)
        index = right_grid.focused_index
        pane = "right"
    var slot := items_array[index] if index < items_array.size() else {}
    item_action_requested.emit(action, slot.get("instance_id", ""), pane)
```

Footer：

```gdscript
left_footer.text = "E: 移動    R: 查看    T: 丟棄    Esc: 關閉"
right_footer.text = "E: 移動    R: 查看    T: 丟棄    Esc: 關閉"
```

### `apartment_room.gd`

新增 onready：

```gdscript
@onready var item_detail_modal: Control = $UI/ItemDetailModal
@onready var confirm_dialog: Control = $UI/ConfirmDialog
```

`_ready()`：

```gdscript
if bag_grid.has_method("set_item_actions_enabled"):
    bag_grid.set_item_actions_enabled(true)
bag_grid.item_action_requested.connect(_on_bag_item_action)
dual_pane_container.item_action_requested.connect(_on_dual_pane_item_action)
```

刪除 `_process()` INVENTORY branch 中舊的 E/R/T swallow：

```gdscript
if Input.is_action_just_pressed("interact_primary") or \
   Input.is_action_just_pressed("interact_secondary") or \
   Input.is_action_just_pressed("interact_tertiary"):
    return
```

`_process()` 在 `current_mode != NONE` 區塊最前面加：

```gdscript
if current_mode != UIMode.Mode.NONE:
    if item_detail_modal.visible:
        return
    if current_mode == UIMode.Mode.CONFIRM:
        return
    # 原有 INVENTORY / NOTEBOOK / MESSAGE / CONTAINER 分支接在後面
```

`_on_ui_mode_changed()`：

```gdscript
func _on_ui_mode_changed(new_mode: int) -> void:
    if new_mode == UIMode.Mode.CONFIRM:
        confirm_dialog.visible = true
        return

    ui_overlay.visible = (new_mode != UIMode.Mode.NONE)
    inventory_panel.visible = (new_mode == UIMode.Mode.INVENTORY)
    dual_pane_container.visible = (new_mode == UIMode.Mode.CONTAINER)
    message_box.visible = (new_mode == UIMode.Mode.MESSAGE)
    notebook_panel.visible = (new_mode == UIMode.Mode.NOTEBOOK)

    if new_mode != UIMode.Mode.MESSAGE:
        _clear_message_typewriter()

    bag_grid.set_input_active(new_mode == UIMode.Mode.INVENTORY)
    notebook_panel.set_input_active(new_mode == UIMode.Mode.NOTEBOOK)

    if new_mode == UIMode.Mode.CONTAINER and current_interactable != null:
        if not dual_pane_container.is_input_active:
            var c_id: String = current_interactable.interaction_id
            var c_data: Dictionary = CONTAINERS.get(c_id, {})
            var c_slot_count: int = c_data.get("cols", 1) * c_data.get("rows", 1)
            var c_title: String = c_data.get("title", "儲物空間")
            dual_pane_container.set_input_active(true, c_id, c_slot_count, c_title)
        prompt_panel.visible = false
    else:
        if new_mode != UIMode.Mode.CONTAINER:
            dual_pane_container.set_input_active(false)

    if new_mode == UIMode.Mode.INVENTORY:
        bag_grid.initialize_grid(GameState.get_inventory())
        bag_grid.set_focused_index(0)
        credits_label.text = "Credits: %d" % GameState.get_credits()
        prompt_panel.visible = false
    elif new_mode == UIMode.Mode.MESSAGE:
        prompt_panel.visible = false
    elif new_mode == UIMode.Mode.NOTEBOOK:
        notebook_panel.load_notebook_data()
        prompt_panel.visible = false
    elif new_mode == UIMode.Mode.NONE:
        item_detail_modal.visible = false
        confirm_dialog.visible = false
        _update_prompt()
```

新增：

```gdscript
func _on_bag_item_action(action: String, instance_id: String) -> void:
    if UIMode.get_mode() != UIMode.Mode.INVENTORY:
        return
    if instance_id.is_empty():
        return

    var item_id := ""
    for slot in GameState.get_inventory():
        if slot.get("instance_id", "") == instance_id:
            item_id = slot.get("item_id", "")
            break
    var item_meta := GameState.ITEMS_DB.get(item_id, {})

    match action:
        "view":
            bag_grid.set_input_active(false)
            item_detail_modal.show_modal(instance_id, bag_grid, bag_grid.focused_index, inventory_panel)
        "discard":
            _start_discard_flow(instance_id, item_meta, bag_grid, bag_grid.focused_index)
        "equip_toggle":
            _handle_equip_toggle(instance_id, item_meta)
```

新增：

```gdscript
func _on_dual_pane_item_action(action: String, instance_id: String, source_pane: String) -> void:
    if UIMode.get_mode() != UIMode.Mode.CONTAINER:
        return
    if instance_id.is_empty():
        return

    var item_id := _find_item_id_anywhere(instance_id)
    var item_meta := GameState.ITEMS_DB.get(item_id, {})
    var active_grid := dual_pane_container.left_grid if source_pane == "left" else dual_pane_container.right_grid
    var active_idx := active_grid.focused_index
    var anchor_panel := dual_pane_container.left_panel if source_pane == "left" else dual_pane_container.right_panel

    match action:
        "view":
            item_detail_modal.show_modal(instance_id, active_grid, active_idx, anchor_panel)
        "discard":
            _start_discard_flow(instance_id, item_meta, active_grid, active_idx)
```

新增：

```gdscript
func _handle_equip_toggle(instance_id: String, item_meta: Dictionary) -> void:
    if item_meta.get("category", "") != "equipment":
        return

    if GameState.is_equipped(instance_id):
        GameState.unequip_by_instance(instance_id)
    else:
        if not GameState.equip(instance_id):
            FloatingToast.show_toast(
                "這類裝備已經滿了，先卸下身上的再裝備新的。",
                inventory_panel
            )
```

新增 discard flow。注意 `toast_panel` 必須先算好並 bind，不能在 confirm callback 時再用 `_get_active_panel()`：

```gdscript
func _start_discard_flow(instance_id: String, item_meta: Dictionary,
                         restore_grid: Control, restore_index: int) -> void:
    var item_name: String = item_meta.get("name", "物品")
    var toast_panel := _get_active_panel()

    if not item_meta.get("discardable", true):
        FloatingToast.show_toast("無法丟棄 " + item_name, toast_panel)
        return
    if GameState.is_equipped(instance_id):
        FloatingToast.show_toast("請先卸下再丟棄", toast_panel)
        return

    UIMode.enter_confirm()
    confirm_dialog.show_dialog(
        "確定要丟棄 " + item_name + "？",
        _on_discard_confirmed.bind(instance_id, item_name, toast_panel),
        restore_grid,
        restore_index
    )

func _on_discard_confirmed(instance_id: String, item_name: String, toast_panel: Control) -> void:
    if GameState.discard_item(instance_id):
        FloatingToast.show_toast("已丟棄 " + item_name, toast_panel)
```

Helpers：

```gdscript
func _get_active_panel() -> Control:
    if UIMode.get_mode() == UIMode.Mode.INVENTORY:
        return inventory_panel
    return dual_pane_container

func _find_item_id_anywhere(instance_id: String) -> String:
    for slot in GameState.get_inventory():
        if slot.get("instance_id", "") == instance_id:
            return slot.get("item_id", "")
    for c_id in GameState.external_containers.keys():
        for slot in GameState.get_container(c_id):
            if slot.get("instance_id", "") == instance_id:
                return slot.get("item_id", "")
    return ""
```

### `apartment_room.tscn`

新增 ext_resource：

```text
res://scenes/ui/item_detail_modal.tscn
res://scenes/ui/confirm_dialog.tscn
```

`$UI` 子節點順序：

```text
PromptPanel
MessageBox
UIOverlay
NotebookPanel
DualPaneContainer
InventoryPanel
ItemDetailModal
ConfirmDialog
```

`ItemDetailModal.visible = false`。

`ConfirmDialog.visible = false`。

### `tests/manual/test_runner.gd`

新增 node path：

```gdscript
"ItemDetailModal": "UI/ItemDetailModal",
"ConfirmDialog": "UI/ConfirmDialog",
```

Z-order 斷言擴展：

```gdscript
var modal_idx = children.find(room_instance.get_node_or_null("UI/ItemDetailModal"))
var confirm_idx = children.find(room_instance.get_node_or_null("UI/ConfirmDialog"))

if not (overlay_idx < notebook_idx and notebook_idx < dual_pane_idx
        and dual_pane_idx < inventory_idx
        and inventory_idx < modal_idx
        and modal_idx < confirm_idx):
    printerr("FAIL: UI sibling Z-order wrong!")
    get_tree().quit(1)
    return
print("PASS: UI sibling Z-order correct (Overlay -> Notebook -> DualPane -> Inventory -> Modal -> Confirm).")
```

UIMode API：

```gdscript
if not UIMode.has_method("enter_confirm") or not UIMode.has_method("exit_confirm"):
    printerr("FAIL: UIMode lacks enter_confirm / exit_confirm!")
    get_tree().quit(1)
    return
print("PASS: UIMode CONFIRM APIs verified.")
```

---

## 實作順序

| # | 步驟 | 驗證 |
|---|---|---|
| 1 | `ui_mode.gd` 補 `enter_confirm` / `exit_confirm` | `test_runner` API check |
| 2 | `game_state.gd` 補 `unequip_by_instance` / `discard_item` | `verify_game_state.gd` 或 headless smoke |
| 3 | 建 `item_detail_modal.gd` + `.tscn` | R/Esc 關閉、anchor positioning、focus restore |
| 4 | 建 `confirm_dialog.gd` + `.tscn` | E confirm、Esc cancel、UIMode restore |
| 5 | `bag_grid.gd` 加 signal、inventory listener、`_item_actions_enabled` | INVENTORY 有 E/R/T；雙欄左欄不搶 E |
| 6 | `dual_pane_container.gd` 加 signal、R/T、footer | 雙欄左/右欄 R/T 都路由到 controller |
| 7 | `apartment_room.gd` 接全部 routing | Bug 1/3/4/Finding 2 驗收 |
| 8 | `apartment_room.tscn` 加兩個子節點 | node path + z-order |
| 9 | `test_runner.gd` 擴充 smoke checks | headless 通過 |
| 10 | 手動驗收清單逐條跑 | 1-E 完整驗收 |

---

## 驗收清單

### R 鍵查看

- [ ] R 在 INVENTORY focused 物品 -> ItemDetailModal 開啟；icon / name / description / category tag 正確。
- [ ] R 在 CONTAINER 雙欄任一格 -> ItemDetailModal 開啟。
- [ ] R 在空格 -> 完全沉默。
- [ ] Modal 開啟時按 Esc -> 只關 modal，inventory/container 維持開啟。
- [ ] Modal 開啟時按 I/J/E/T/方向鍵 -> 底層 UI 不反應。
- [ ] Modal 關閉後 focus 回原格，方向鍵可立即使用。
- [ ] Modal 位置依 anchor panel 置中，不是錯位到 viewport 其他位置。

### T 鍵丟棄

- [ ] T 在可丟棄物品 -> ConfirmDialog 開啟；E 確定 -> 丟棄 + toast；Esc 取消 -> 無變動。
- [ ] T 在 `discardable=false` -> toast「無法丟棄 {name}」，無 dialog。
- [ ] T 在已裝備品 -> toast「請先卸下再丟棄」，無 dialog。
- [ ] T 在 CONTAINER 雙欄左/右欄 -> 同上行為。
- [ ] T 在空格 -> 完全沉默。
- [ ] ConfirmDialog 開啟時 I/J/R/T/方向鍵 -> 全部沉默。
- [ ] INVENTORY 中丟棄成功 toast 錨在 inventory panel，不會跑到 dual pane。
- [ ] 左欄 slot 8 按 T -> dialog 確定 -> 回到雙欄後 active_pane 仍為 left。

### E 鍵裝備

- [ ] E 在 INVENTORY 未裝備 equipment -> 裝備；E marker 出現；置頂排序立即出現。
- [ ] E 在 INVENTORY 已裝備 equipment -> 卸下；marker 消失；立即重排。
- [ ] E 在裝備槽已滿 -> toast「這類裝備已經滿了，先卸下身上的再裝備新的。」
- [ ] E 在 consumable / key_item / misc -> 完全沉默。
- [ ] E 在 CONTAINER 雙欄 -> 永遠是「移動」。
- [ ] 雙欄左欄 BagGrid 不搶 E；左欄 E 仍會把背包物品移到容器。

### Footer Hint

- [ ] 背包單獨 panel：`E: 裝備/卸下    R: 查看    T: 丟棄    Esc/I: 關閉`
- [ ] 雙欄兩欄：`E: 移動    R: 查看    T: 丟棄    Esc: 關閉`
- [ ] ItemDetailModal：`R / Esc: 關閉`
- [ ] ConfirmDialog：`E: 確定    Esc: 取消`

### Test Runner

- [ ] headless 執行通過。
- [ ] z-order 斷言包含 `inventory < modal < confirm`。
- [ ] `UI/ItemDetailModal` 和 `UI/ConfirmDialog` node path 驗收通過。
- [ ] `UIMode.enter_confirm` / `UIMode.exit_confirm` API 存在。

---

## 注意事項

- `_input` 的 `set_input_as_handled()` 只能擋 event routing phase，不能擋 `_process()` 全域輪詢。
- BagGrid 的 E/R/T 必須只在單獨背包啟用；雙欄內 BagGrid 不可直接處理 item action。
- `ConfirmDialog` callback 執行時 UIMode 仍是 CONFIRM；toast anchor 必須事先 bind。
- `DualPaneContainer` 從 CONFIRM 回 CONTAINER 時不可重置 active pane。
- ItemDetailModal view 路徑不可 deactivate dual pane。
- `show_modal()` / `show_dialog()` 是刻意 API rename，避免覆蓋 Godot `Control.show()`。
- `phase 1-E實作.md` 是 implementer 文件；若實作後規格書需同步，應由 verifier/documentation 角色另行確認。

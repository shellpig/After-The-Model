# After-The-Model 專案簡報

本文件供新 session 快速了解專案全貌，減少每次重讀全部規格文件的成本。需要深入細節時，按下方文件索引讀對應規格。

最後更新：2026-07-03

---

## 專案概述

《After-The-Model》是一款 2D 橫向探索 / 都市漫遊 / 碎片化敘事 cyberpunk 遊戲，主題是「AI 改變世界之後，普通人怎麼活下去」。

- **引擎**：Godot 4.6.3 / GDScript
- **視角**：純 2D 側捲，角色只左右移動；未來可加入 light platforming
- **美術方向**：Riso-inspired HD 2D Cyberpunk，非 hard pixel art
- **目標平台**：先做本機 PC MVP；Steam / iOS / Android 後置
- **MVP 範圍**：一條街 + 一個地鐵站 + 一個小公寓 + 2 NPC + 1 零工任務
- **目前可玩場景**：`apartment_room.tscn`、`apartment_entrance.tscn`、`apartment_fire_escape.tscn`、`convenience_store.tscn`
- **目前主線進度**：參照下方 ## Phase 進度 區塊

## 核心調性

不是英雄拯救世界，也不是打倒邪惡企業。玩家是近未來低階層普通人，在 AI 後時代的城市裡生活、接零工、拾回被系統抹掉的記憶。

第一關公寓主軸：

```text
醒來失憶
-> 試門發現打不開
-> examine 房間取得身份 / 工作線索
-> 戴手套、解碼方塊、找插槽
-> 取得 identity_door_unlock_method
-> 大門 gate 通過
```

## 技術棧

- **Engine**：Godot 4.6.3 stable
- **Language**：GDScript
- **Runtime tools**：Godot console / editor、Python venv、agent-sprite-forge
- **Python**：固定使用 `.\.venv\Scripts\python.exe`
- **Asset generation**：`$generate2dmap` / `$generate2dsprite`
- **Validation**：Godot headless manual runner

外部工具路徑：

| 工具 | 路徑 |
|---|---|
| Godot editor | `C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64.exe` |
| Godot console | `C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe` |
| agent-sprite-forge | `C:\_work\AI_Work\Tools\agent-sprite-forge` |
| Codex DeepSeek home | `C:\_work\AI_Work\Tools\codex-deepseek-home` |

## 目錄結構

```text
.
├── project.godot
├── scenes/levels/apartment/
│   ├── apartment_room.tscn / apartment_room.gd   # 目前主場景 controller（4-A0 搬入）
├── scenes/actors/player/
│   └── player.gd                             # 主角移動；UI mode 時凍結（4-A0 搬入）
├── scripts/autoload/
│   ├── game_state.gd                         # credits / inventory / notes / containers / equipment
│   └── ui_mode.gd                            # NONE / INVENTORY / CONTAINER / NOTEBOOK / MESSAGE / CONFIRM
├── scripts/components/
│   └── interactable_area.gd                  # Area2D 互動物 export 欄位（4-A0 搬入）
├── scenes/ui/
│   ├── game_ui.tscn / game_ui.gd            # 常駐 UI CanvasLayer（4-B 新增）
│   ├── bag_grid.*                            # 背包格
│   ├── external_grid.*                       # 外部容器格
│   ├── dual_pane_container.*                 # 背包 + 容器雙欄
│   ├── notebook_panel.*                      # 筆記 UI
│   ├── item_detail_modal.*                   # R 查看
│   ├── confirm_dialog.*                      # T 丟棄確認
│   ├── floating_toast.*                      # 短提示
│   └── panel_footer_hint.gd                  # 操作鍵提示
├── tests/manual/
│   ├── test_runner.tscn / test_runner.gd
│   └── verify_game_state.gd
├── assets/
│   ├── art_bible/                            # 視覺錨點與 prompt
│   └── generated/                            # AI 生成 map / sprite / item icons
├── subdocs/
│   ├── 人/主角設定.md
│   └── 地點/主角公寓.md
└── 舊文件/                                  # 歷史 archive，開工時忽略
```

Godot autoload：

```text
GameState = res://scripts/autoload/game_state.gd
UIMode    = res://scripts/autoload/ui_mode.gd
```

## 核心系統

### GameState

管理 MVP 全域狀態：

- credits
- player inventory
- equipment
- notes / knowledge
- external containers
- external container configs（`accepted_item` / `deposit_locked`）
- item metadata stub `ITEMS_DB`
- signals：`inventory_changed`、`container_changed`、`credits_changed`、`knowledge_added`、`notes_changed`、`equipment_changed`、`item_moved`

重要語意：

- `has_knowledge(id)`：只用於劇情 gate，目前由 `category == "身份"` note 寫入。
- `has_note(id)`：任意分類筆記存在判斷，供 examine / 一次性提示去重。
- `move_one_item_to(...)`：物品搬運權威 API；UI 不直接改 GameState internals。
- `get_container_config(container_id)`：回傳容器設定 deep copy，供 UI 判斷白名單 / 鎖定失敗訊息。
- `accepted_item`：空陣列代表不限；非空時只允許清單內 item id 放入。
- `deposit_locked`：可放入，但該容器內物品不可再取出。

### UIMode

模式：

```text
NONE
INVENTORY
CONTAINER
NOTEBOOK
MESSAGE
CONFIRM
```

規則：

- mode != NONE 時，主角不能移動。
- 大型 UI 互切：`I` / `J` 可一鍵切換背包 / 筆記 / 容器。
- MESSAGE / CONFIRM 為 overlay modal：記住 caller mode，結束時還原，不關閉 caller UI（2-E overlay 重構後 MESSAGE 比照 CONFIRM，可疊在雙欄 / detail modal 上）。

### 互動系統

每個世界互動物是 `Area2D + interactable_area.gd`。

目前 export 欄位：

```gdscript
interaction_id
prompt_text
message_id
required_knowledge
note_id
```

場景 controller 選最近互動物；按 `interact_primary` (`E`) 分派：

- container id -> 開雙欄容器
- `note_id` 非空 -> examine：顯示 MessageBox + `add_knowledge`
- `door_exit` -> `has_knowledge("identity_door_unlock_method")` gate
- 其他 -> 一般訊息

## Phase 進度

| Phase | 狀態 | 概要 |
|---|---|---|
| 1-A | ✅ 完成 | `GameState` autoload；credits / 背包 / 裝備 / 知識 / 筆記 / 容器 / signals；公寓大門 knowledge gate |
| 1-B | ✅ 完成 | `UIMode` autoload；背包 UI（`I`）、5x3 grid、Credits、item icon、focus、overlay |
| 1-C | ✅ 完成 | 筆記 UI（`J`）、身份 / 工作 / 線索 tab、列表 + 全文、Page Up / Down |
| 1-D | ✅ 完成 | 容器資料化；櫥櫃 5x6 / 冰箱 5x2；雙欄 UI；跨欄 focus；E 移動 1 個；FloatingToast |
| 1-E | ✅ 完成 | 物品操作：R 查看、T 丟棄、E 裝備 / 卸下；ConfirmDialog；ItemDetailModal；focus routing 修補 |
| 2-A | ✅ 完成 | 公寓線索 examine：桌上電腦 `work_ai_cleanup_role`、左牆錄音機 `identity_gleaner`；`note_id` export；`has_note()` 去重 |
| 2-B | ✅ 完成 | 解碼手套 + `worn_rubiks_cube` -> `decoder_cube`；手套線索筆記；R 查看 fallback |
| 2-C | ✅ 完成 | `accepted_item` 白名單 + `deposit_locked` 容器擴充；`get_container_config()`；`item_moved` payload 驗證 |
| 2-D | ✅ 完成 | 投影時鐘（偵測終端）+ 營養棒線索麵包屑 + 聲納 reveal 隱藏插槽 |
| 2-E | ✅ 完成 | 插槽放入 -> 電磁聲響 / MessageBox / `identity_door_unlock_method` -> 開門整合 |
| 2-F | ✅ 完成 | 筆記內容/操作修正（測試長筆記改氛圍版「雨還沒停」、A/D 切分頁 + W/S 選筆記、與 Page Up/Down 停用）+ 公寓 BGM（`AudioStreamPlayer` loop / -12dB） |
| 2-G | ✅ 完成 | 開場獨白序列：prone 甦醒 → 3 頁不可跳過 MessageBox（標題首行 + 6 字/秒）→ P3 起身動畫 `get_up` → 解鎖；每次進場都播；隱藏 T×3（1 秒內）跳頁捷徑 |
| 3-A | ✅ 完成 | 顯示 / 橫向 / 觸控模擬設定：`project.godot` landscape、`emulate_*_from_touch`、`canvas_items`+`expand`；headless 回歸 PASS（commit `8b385c8`） |
| 3-B | ✅ 完成 | 世界模式觸控：`TouchControls` autoload（layer 100）左下方向鍵走路 / 右下 E / 右上 背包·筆記；顯示規則 `visible` 恆真 + `OS.get_name()` 判 PC + PC 端觸控 toggle（棄用 `is_touchscreen_available`，Windows 觸控筆電誤判）；headless 自動測試 PASS、待 GUI 純觸控走查 |
| 3-C | ✅ 完成 | 面板模式觸控：方向鍵移焦點、右下 E / R / T（情境感知顯隱）、面板開時右上「X 返回」=`ui_cancel`；headless PASS、**里程碑 PC 純觸控通關 B0–B9（GUI 實機驗收完成）** |
| 3-D | ✅ 完成 | Safe area + 比例排版：按鈕內縮 `get_display_safe_area()`（test_runner 9.1 驗證）、D-pad 54 / 功能鍵 60（≥44px）；待 GUI 比例目視、真機座標換算待 3-E |
| 3-E | ✅ 完成 | 真機導出 + iPhone 校正（需 Mac）：Mac+Xcode 免費簽名進 iPhone、真機純觸控通關、瀏海 / 效能校正 |
| 4-A0 | ✅ 完成 | 檔案結構整理：`apartment_room.*`→`scenes/levels/apartment/`、`player.gd`→`scenes/actors/player/`、`interactable_area.gd`→`scripts/components/`（含 `.gd.uid` sidecar）；改 `.tscn` 3 path + `test_runner.gd` 1 字面量；headless PASS（搬檔後需 `--import` 重建 uid 快取）（commit `78be6de`）|
| 4-A | ✅ 完成 | `main.tscn` + `main.gd`（SceneRouter + SceneRegistry inline）；`WorldRoot` 載入公寓；`transition_to(scene_id, entry_point_id)` API；`prepare_entry_point` → `add_child` → `set_entry_point` 順序；headless PASS |
| 4-B | ✅ 完成 | `game_ui.tscn/gd` 常駐 CanvasLayer；共用 UI 節點從 `apartment_room.tscn` 搬入 GameUI；`show_message`/`begin_message` API + `_is_simple_message` 旗標防止獨白被 GameUI 提前關閉；FloatingToast 改掛 GameUI；headless PASS |
| 4-C | ✅ 完成 | Level interaction contract：`current_interactable_changed` / `interaction_requested` / `scene_transition_requested` signal；Main mediator 接 signal 轉 GameUI / SceneRouter；Level 不直接碰 UI node path；UI hotkey / item action routing / toast / prompt 跟蹤全部搬入 GameUI；NOTES/MESSAGES 統一至 `GameState.STORY_NOTES` / `STORY_MESSAGES`；headless PASS |
| 4-D | ✅ 完成 | TouchControls 改接 GameUI contract：`set_game_ui()` + `_get_game_ui()` 注入；世界 E 用 `has_current_interactable()`；Inv/Container E/R/T 用 `can_primary/secondary/tertiary_action()`；PC toggle 用 `is_touch_toggle_blocked()`；不再讀 `scene.get("current_interactable")` / `UI/...` 固定路徑；headless PASS |
| 4-E | ✅ 完成 | `prepare_entry_point` / `set_entry_point` API；`wake_bed` 入口播開場 prone→monologue→idle，`from_street` 跳過開場直接 idle 於門邊；大門 `on_closed` callback emit `scene_transition_requested("apartment_entrance", ...)`；公寓專屬 sonar/slot/BGM 留在 level 不誤搬 GameUI；無 `$UI/` 直接依賴、無 `change_scene_to_file`；headless PASS |
| 4-F | ✅ 完成 | `apartment_entrance` 第二場景 + 真轉場；大門開鎖後真轉場至街道，街道可回公寓且不重播獨白 |
| 4-G | ❌ 取消 | 原為未來系統 contract pass（placeholder 插槽）。架構契約（`scene_id+entry_point_id` 通用轉場、各場景自管 BGM、SceneRouter 持穩定 scene id）已被 4-A~4-F 滿足；`dialogue_id` / `quest_event_id` 的 placeholder 屬丟棄工，故取消。真 NPC / 對話移至 Phase 5；Quest / Save 僅預留資料路徑 |
| 5-A | ✅ 完成 | `GameState` 故事旗標 store（bool/int，含 `affinity_wan`）+ 對話樹 schema（`data/dialogue/wan.gd` + `dialogue_db.gd` 對照）+ `DialogueRunner`（純邏輯，`start`/`current`/`choose`/`advance`/`finished`，goto 條件路由 + effect `set_flag`/`add_int`/`add_gleaner_lead`，`add_gleaner_lead` 為 log/noop 不寫 knowledge）；test_runner 模擬首見 / 重講 / 情報門鎖開三路徑；headless PASS（commit `d535882`）|
| 5-B | ✅ 完成 | `DialoguePanel.tscn/gd`（立繪槽 / 名字 / 內文 / 選項列，`Portrait.texture==null` 安全）+ `UIMode.DIALOGUE` + interactable `dialogue_id`；接線 Level→Main(`start_dialogue`)→GameUI；鍵盤 上 / 下移焦點、`E` 確認選取 / 推進（`_unhandled_input` 對有 / 無選項分流，真實 `parse_input_event` 路由驗證焦點 Button 不吞 E）；分支 / effect 在 UI 流程正確反映、結束回 `NONE` 無殘留；GameUI 公開 `has_active_dialogue`/`dialogue_move_focus`/`dialogue_confirm` 供 5-C；headless PASS |
| 5-C | ✅ 完成 | TouchControls 對話路由（D-pad 選項 + 確認），經 GameUI 公開查詢；對話時世界移動與其它 UI 隱藏，不誤觸底層 |
| 5-D | ✅ 完成 | NPC「晚」落地 `apartment_entrance`（Area2D + Sprite2D，立繪 ext_resource 帶 uid），對話 dispatch 泛化（dialogue_id 優先），條件路由（首見 `first_meet` / `met_wan` 後 `retalk`）與跨場景旗標保留，`affinity_wan>=2` 解 `intel` 情報；headless PASS + 人工驗證通過 |
| 6-A | ✅ 完成 | `SaveSystem` Autoload：`capture()` / `apply()` / `validate()`（只驗 shape/version）+ `var_to_str` / `str_to_var` 讀寫；`GameState.to_save_dict()` / `load_save_dict()` / `reset_for_new_game()`；payload = 全可變狀態（含 `_last_instance_id`）+ scene_id + 玩家座標，排除 code-owned 常數；headless round-trip PASS（commit `003d22f`）|
| 6-B | ✅ 完成 | 讀檔回場：載入進場景、直接 set 玩家精確座標、跳過 entry point 副作用；Load 兩段驗證（SaveSystem 驗 shape/version → Main 驗 `scene_id ∈ SCENES`）→ 才 apply；New Game 先 `reset_for_new_game()` 再播開場、讀檔不播；headless PASS（commit `003d22f`）|
| 6-C | ✅ 完成 | 多槽模型：檔名 `user://save_01..10.sav` + `{meta,data}` header + 列舉 10 槽 API（只讀 meta 不套用）；損毀槽優雅失敗；headless PASS（commit `003d22f`）|
| 6-D | ✅ 完成 | 最小標題畫面（New Game / Load Game）+ 開機流程（`main_scene=title_screen.tscn`，Load 經 `pending_load_slot` 交棒 main）；標題頁隔離 TouchControls overlay（`set_force_hidden`）；headless PASS（commit `15e7f5f`）|
| 6-E | ✅ 完成 | 暫停選單（Resume/Save/Load/回標題）+ Save/Load 共用槽列表 UI + 覆蓋確認（`ConfirmDialog`）+ `UIMode==NONE` gating + Save 入口查預留 `can_save_here` 旗標 + TouchControls 接線；ConfirmDialog 重用崩錯（Button restore_grid）+ double exit_confirm 已修並補回歸測試（commit `15e7f5f` + `c4b8abe`）|
| 6-F | ✅ 完成 | 邊界處理（版本 / 損毀 / 場景缺失於 apply 前擋下 / 座標出界 clamp）+ 回標題未存確認 + GUI 走查驗收；headless 100 PASS / 0 FAIL（commit `c4b8abe`）|
| 7-A | ✅ 完成 | `QuestManager` 最小真系統 + `GameState.quest_states` + 存讀檔整合；支援 `start` / `advance` / `complete` / `fail`，任務 flags 不寫 `story_flags` / `knowledge`；工作筆記 step/status 查表同步；headless PASS |
| 7-B | ✅ 完成 | 晚的對話接任務：沿用既有 `affinity_wan >= 2` / `intel` 門檻；新增 `start_quest` effect；DialogueRunner condition 支援 quest status / step / inventory（單 Dict 或 Array=AND，舊 flag 相容）；headless PASS |
| 7-C | ✅ 完成 | `apartment_entrance` 後巷偵查事件：未接任務維持原文字；接任務後顯示危險暗巷描述、推進 `checked_alley`、更新工作筆記；再次互動不重複推進；headless PASS |
| 7-D | ✅ 完成 | 公寓窗戶條件式入口：未達 `checked_alley` 不可互動，達成後 `fire_escape_window` 轉場 `apartment_fire_escape:from_window`；回程 `apartment:from_fire_escape` 落窗邊不播獨白；headless PASS |
| 7-E | ✅ 完成 | `apartment_fire_escape` 場景骨架：右棟 4F / 梯子 / 右棟 3F / 中央 gap / 3F 天橋 / 左棟 3F 箱子，唯一 entry point `from_window`；headless 載入 PASS |
| 7-F | ✅ 完成 | 梯子攀爬 + 天橋步行 + 相機 + 外牆禁存：climb mode 僅本場景使用；E 先離梯再互動；離開場景恢復 `SaveSystem.can_save_here`；headless PASS |
| 7-G | ✅ 完成 | 三樓箱子搜索 + A 物品取得：搜索文字安靜避開亮燈住戶；取得 A 跳異常重量/夾扣提示，推進 `found_activation_box` 並設 flag；背包滿時不 `set_flag` / `advance`、不吞 A、可重試；取得後箱子不再可互動；headless PASS |
| 7-H | ✅ 完成 | R 查看 A 得 B：首次 R 查看掀夾層取得 B「舊式 AI 授權模組」，A 保留不消耗；背包滿時不設 flag、不吞 B、可重試；再次 R 查看不重複給 B 直接開 detail；headless PASS |
| 7-I | ✅ 完成 | 回報晚 + 任務完成：只有 active + `found_activation_box` + 持有 A 才顯示交任務分支；effect 依序 `remove_item` → `complete_quest`，移除失敗即中止不 complete（status / 工作筆記保持 active）；B 保留；headless PASS |
| 7-J | ✅ 完成 | Phase 7 回歸驗證：接任務 / 後巷偵查 / 取得 A 未查看 / 取得 B 未交 / 完成後五個存讀檔情境，任務鏈、工作筆記、A/B 物品、窗戶 gate、外牆禁存與回程不退化；headless PASS |
| 7-K | ✅ 完成 | 任務結局分支：回報時依是否持有 B 分流，持有 B 時二選一「只交 / 連模組一起交」；A/B +500、C +1000 + `affinity_wan +2` + `gave_wan_old_module`；三種結局訊息（既有 2 向→3 向）與三種完成工作筆記；交出 B 後晚的招呼改親近版（`retalk_close`）；新增 `add_credits` 對話 effect op + `resolve_completed_note()` 筆記分流；headless PASS（commit `6a20664`） |
| 8-A | ✅ 完成 | `convenience_store` 場景骨架（placeholder 視覺：貨架 / 自動門 / 熟食機 / 櫃台機器人 / 冷藏櫃 / 員工區 / 鎖住後門）+ SceneRegistry 註冊（entry `from_street`）；街道 `store_front` 改門轉場進店、店內自動門回 `apartment_entrance:from_store`；店內 `can_save_here == true`；機器人 / 後門 / flavor 物件先給 examine 佔位訊息（8-B 起對話化）；BGM 暫沿用 street_rain；headless 載入 + 雙向轉場 + 存讀檔 round-trip PASS |
| 8-B | ✅ 完成 | 前導對話 + 發現錯誤旗標：`data/dialogue/store_robot.gd` 註冊進 DialogueDB，`start` 依狀態路由（repaired / quest active / babble，前二者為 8-D/8-E 置換用 stub）；babble 樹（intro 設 `talked_store_robot` + 否認自己是販賣機 / 自語兩分支）；店內機器人 interactable 改 `dialogue_id` dispatch；街道販賣機 examine 改前導 babble 訊息 + 設 `talked_outside_vendor`；`GameState.set_flag` hook `_maybe_set_discovered_vendor_error()` 聚合（兩旗標皆真才設、idempotent、單談一台不設）；headless PASS |
| 8-C | ✅ 完成 | 公寓電腦兩段 gate + 接案：第一次互動仍顯示舊 `work_ai_cleanup_role` 內容並設 `used_room_computer_once`；第二次起且 `discovered_vendor_error` 已成立、任務未接時派工 `QuestManager.start("repair_vendor_bot")`；新增 `data/quests/repair_vendor_bot.gd` 工作筆記模板與 reset / gleaned 完成筆記 resolver；未發現錯誤或任務 active 時不重開任務；headless PASS |
| 8-D | ✅ 完成 | 蒐證系統 + 診斷對話樹 + 揭示主機：5 線索接案後可 examine 並寫 `clue_*` 筆記；診斷對話樹的正確選項以 `has_note` 為門檻限制；5 筆記齊全且對話全程正確設 `understood_robot_truth` + `diagnosed` + `mainframe_revealed`；否則設 `diagnosed` + `mainframe_revealed`；對話可重試與修正；`mainframe_revealed` 後主機可互動；headless PASS |
| 8-E | ✅ 完成 | 店籍主機三段 + 兩種重置結局：`store_registry_host` 對話樹（start 依 `vendor_bot_repaired` / `understood_robot_truth` / `diagnosed` 路由三段 + 已修復中性訊息）；直接重置 / 先錄殘響皆設 `store_robot_resolution` + `vendor_bot_repaired` + complete quest；先錄殘響以 `add_item` effect 失敗中止 + goto 條件分流做背包滿防呆（不設旗標、可重試），成功取得 `clerk_echo_recording`（不可賣 / 不可丟）+ 殘響線索筆記；完成訊息暗示外面販賣機回線；機器人 `repaired_router` 依結局分 reset（純 AI）/ gleaned（殘留人味）招呼；DialogueRunner 新增 `quest_flag` condition + `add_item` / `add_note` effect；headless PASS |
| 8-F | ✅ 完成 | 買賣系統核心 + ShopPanel + `UIMode.SHOP`：`ITEMS_DB` 補 `value`（罐頭 20 / 營養棒 12 / 夾克 60 / 魔術方塊 1=折算 0 不可賣）；`SELL_RATIO 0.5` + `get_item_value` / `get_sell_value` / `is_sellable`（key_item / `sellable=false` / 折算 0 元皆擋）；`sell_item(instance_id)` 以焦點格定位（已裝備擋、不自動卸下、不回補店庫存）；`shop_states` lazy-init 自 `data/shops/shop_db.gd` catalog + `refresh_shop_stock` + `buy_item` 原子三檢（純讀檢查 → `add_item` 唯一可失敗變動 → 扣庫存扣 credits）+ 納入存讀檔 / reset；`ShopPanel` 雙欄（左貨架 名稱/買價/庫存、右背包 售價或灰掉，手動高亮不搶引擎焦點）+ FloatingToast 失敗提示；機器人 repaired 招呼結尾 `open_shop` effect（DialogueRunner pending → DialoguePanel 收尾交棒 GameUI，DIALOGUE 直切 SHOP）；TouchControls SHOP 路由（D-pad 經 GameUI 代理）；headless PASS |
| 8-G | ✅ 完成 | 迷你飲料商店 + 多商店資料化：修好後街道外面販賣機直接開 `street_vending` ShopPanel；`data/shops/street_vending.gd` 飲料 catalog（`synth_cola` / `packaged_water`）接入 `shop_db.gd`；兩店庫存各自獨立並納入存讀檔 / reset；`tests/manual/test_runner.gd` 已加入 8-G 多商店資料化驗證；飲料 item icon 已整合 |
| 8-H | ✅ 完成 | Phase 8 全鏈回歸 + 存讀檔驗證 + 人工對話 / 買賣系統 GUI / 純觸控走查 |
| 9-A | ✅ 完成 | 殘響資料模型 + `echo_progress` 存讀檔 + 筆記「殘響」分頁投影（`????` 佔位）+ 8-E 店員殘響回寫 / 舊存檔 backfill |
| 9-B | ✅ 完成 | 公寓時鐘取「老舊探測模組」+ 一次性線索筆記 `clue_probe_module_lead`（公寓解謎完成後開放；背包滿防呆） |
| 9-C | ✅ 完成 | 街道右端暫時通道目的地選單 + `collector_shop` 場景 + 鹿其琛首見 / 鑑定 → 手套原地升級 `gleaner_gloves` + 口頭提及「還」；DialogueRunner 新增 `travel` / `install_module` / `sell_echo` effect + `echo_complete` / `echo_unsold` condition type；headless PASS |
| 9-D | ✅ 完成 | 感知採集：`EchoPoint` Area2D 組件（微光 + 距離雜訊 + 靜止 ≥1 秒 gate + E 採集一次性）；裝備 `gleaner_gloves` 才 active；跨存讀檔保持；headless PASS |
| 9-E | ✅ 完成 | 媒體層：集滿才出 `E: 看照片` / `R: 播放錄音`（單媒體用 E）；照片 overlay + 錄音播放 + 觸控路由 |
| 9-F | ✅ 完成 | 內容鋪設：4 條殘響 / 7 採集點跨 5 場景 + 照片（生圖）/ 歌曲 / 雜訊 SFX / 店 BGM 素材 |
| 9-G | ✅ 完成 | 收購（賣 vs 留）：對話式成交、每條專屬評語、只收已集滿、賣後標記已售出 + 媒體永久失效；`echo_lu_family` 不收 |
| 9-H | ✅ 完成 | Phase 9 全鏈回歸 + 存讀檔驗證 + GUI / 觸控走查 |
| 10-A | ✅ 完成 | 街道音景：雨 bed（`AmbientRain` autoplay loop, -22dB）+ 地鐵遠轟（`AmbientSubway` one-shot，`SubwayTimer` 40~90 秒隨機間隔，`_a`/`_b` 隨機挑）；新增 Audio Bus `Ambient`；echo 播放時 `main.duck_ambient()` 與既有 `pause_bgm`/`resume_bgm` 同步壓低（-14dB，淡降非全靜，0.3s tween）／淡回；確認街道 BGM 由 `main.gd` 中央系統播放，移除場景內死節點 `BGMPlayer`；headless PASS，GUI / 真機聽感驗收完成 |
| 10-B | ✅ 完成 | 不分層視覺基底：雨粒子兩層（`RainFar`/`RainNear`，掛 `Camera2D` 子節點隨鏡頭走，垂直下落、霓虹染色非純白，落速 3x）+ 落地水花（`RainSplash`）+ `Vignette`（`CanvasLayer` layer=1 + shader，`GameUI` 改 layer=2 確保不被遮）+ 相機 idle 微擺（`Camera2D.offset` sin drift，走路時淡出）；無 CRT；headless PASS，GUI / 真機驗收完成 |
| 10-C | ✅ 完成 | `BillboardScreen` Polygon2D + shader（掃描線 / flicker / 邊緣輝光 / RGB 錯位）+ 廣告圖 3 張輪播 + 路燈柔光池（`StreetLights`）；`GlowLayers`（AlleyNeonGlow / StoreSignGlow / StoreWindowGlow）+ `ReflectionStrip` 霓虹倒影 + 兩盞 PointLight2D；headless PASS，GUI 目視驗收完成 |
| 10-D | ✅ 完成 | NPC 微演出：晚 idle break「撇一眼暗巷」——`NpcWan` 改 `AnimatedSprite2D`（`idle` + `idle_glance` 6 幀）+ `IdleBreak` 組件；headless PASS，GUI 真機目視驗收完成 |
| 11-A | ✅ 完成 | 主線地基 Trust/Trace。`GameState.trace:int` + `add_trace`/`get_trace`（正負皆可、`add_trace(0)` no-op）+ `trace_changed` signal（隱性、無 UI）；納入 `to_save_dict`/`load_save_dict`（缺鍵→0 向後相容）/`reset_for_new_game` 歸零；本機 headless PASS |
| 11-B | ✅ 完成 | `get_trust(target)` adapter＝`get_flag("affinity_"+target,0)`；第一版不新建獨立軸，呼叫端統一走此介面；本機 headless PASS |
| 11-C | ✅ 完成 | 賣→Trace↓ 集中在 `GameState.sell_echo()`（`TRACE_DELTA_SELL=-1`，無條件、不靠對話）；DialogueRunner 新增通用 `add_trace` effect op（供未來「留」↑/「還」對話，觸發場景待 Phase 18/20/鹿線）；本機 headless PASS |
| 11-D | ❌ 取消 | 清洗刻意不在 Phase 11 落地（避免提前蓋 placeholder，呼應 4-G 教訓）；移至 **Phase 27**（Expose 上傳前清洗閘）硬兌現 |
| 11-E | ✅ 完成 | `tests/manual/test_runner.gd` 新增 Phase 11 區（trace 累加/存讀檔/缺鍵相容/reset、trust adapter、賣→trace↓、`add_trace` effect op）；trace 完全隱性無 UI；2026-06-19 本機 headless PASS（`test_runner.tscn` / `verify_game_state.gd`，exit code 0） |
| 12-A | ✅ 完成 | 跳躍狀態：`jump` action（Space）+ `player.gd` walk-line 之上腳本化拋物弧（地面起跳 / 空中水平微調 / 無二段跳 / 蹬牆）+ 抓邊緣吸附（group `ledges`，12-B 前安全 no-op）+ 單一連貫 `jump` clip（loop=false，落地由狀態接回，6 幀接進 5 個 level 的 SpriteFrames）。**架構決策：不引入全域重力**；headless + GUI 走查 PASS |
| 12-B | ✅ 完成 | 平台組件 `ledge_area.gd` / `jump_gap.gd` + 採集點沿用 `EchoPoint`；最小原型床 `scenes/levels/jump_proto`（gap 跨越 + 跳上 ledge + 採集點），拋棄式、不接正式動線；headless + GUI 走查 PASS |
| 12-C | ✅ 完成 | TouchControls `BtnJump`（綁 `jump`）+ 僅世界模式顯隱；headless + 純觸控走查 PASS |
| 13-A | ✅ 完成 | `attack` action + `melee_stick`（命中→stun，棍不壞 / 無升級 / **無 HP·血條**）+ `enemy_base` 最小 AI（右側巡邏 / 受擊倒地自修復 stun；**察覺 / 追擊後置**）|
| 13-B | ✅ 完成 | 繞後格式化（限機器）：`machine_enemy.gd`（`can_format` stun 中背後 true / 正面或非 stun false）+ `format_reset.gd`（按住 E 2.0s → `defeated()`；鬆手 / 離區 / 起身 / UI 開 → 歸零可重試）；`walker_01` 改繼承 `MachineEnemy`；headless PASS |
| 13-C | ✅ 完成 | 人類分支 `human_enemy`（繼承 `EnemyBase`）：`can_format` 恆 false、`apply_stun`/`is_stunned` no-op；解法走對話（嚇退 / 交易）/ 環境阻隔 / 出口；人類不會死在玩家手上；本階段僅骨架 + headless 護欄；headless PASS |
| 13-D | ✅ 完成 | 輸 = 岔故事線 `combat_loss`：失敗 set 場景定義旗標 + 轉替代流程（原型＝`combat_proto_failed` + 送回安全點 `x≈250` + 替代訊息），**無 Game Over / 無死亡重來**；headless PASS |
| 13-E | ✅ 完成 | 原型床 `scenes/levels/combat_proto`（隧道清潔機），拋棄式；正式 Act 2B 遭遇在 Phase 18 用此組件作者化；headless PASS |
| 13-F | ✅ 完成 | TouchControls `BtnAttack`（綁 `attack`）+ 格式化長按沿用 `BtnE` + 純觸控走查；headless PASS |
| 14-A | ✅ 完成 | 林霏殘響碎片①「莫名一震」：`memory_fragment_area` 被動碰撞觸發一次，設 `mem_frag_linfei_1`，擺街道 x≈1500 保證出公寓往便利商店必撞；不採集、不加 EchoPoint / 媒體 |
| 14-B | ✅ 完成 | 鹿「從線上面下來的」鉤（`lu_hinted_topside`）+ 晚瞥見失神鉤（`wan_noticed_daze`），gate 皆為 `mem_frag_linfei_1`；一次性、不破壞既有鹿 / 晚對話路由 |
| 14-C | ✅ 完成 | 阿達①店控首談前置誤認：未修好店控首談時，gate＝`mem_frag_linfei_1 AND not ada_misrecognized`，effect 設 `ada_misrecognized` + `talked_store_robot`，再回既有 babble；不依賴首談前不存在的 `talked_store_robot` |
| 14-D | ✅ 完成 | 回歸 + 存讀檔 + GUI 走查：四旗標 round-trip（缺鍵→false / reset 歸零）、Phase 1~13 不退化；GUI 確認一震只播一次、三鉤條件成立後出；headless PASS |
| 15-A | ✅ 完成 | 地鐵站切兩室（user 拍板 split）：`subway_station`（大廳/閘口，真美術 concourse + 真 BGM `The Last Platform`）+ `subway_station_platform`（月台，platform 圖）；main.gd SCENES 註冊兩 scene_id（`from_street`/`from_platform`、`from_concourse`/`from_settlement`）+ `apartment_entrance` 補 `from_subway`；街道 travel 選單「地鐵站」（gate＝`lu_hinted_topside`）；街道→大廳→月台、月台→街道轉場；`can_save_here`。程式 + test_runner 護欄已就緒，**自動測試與 GUI 實機走查已完成** |
| 15-B | ✅ 完成 | 地下道聚落切兩室：`underground_settlement`（左 panel 帳篷群，真美術 left + 真 BGM `The Deleted Still Breathe`）+ `underground_settlement_right`（右 panel 淨水站/隧道口，right 圖）；SCENES 註冊兩 scene_id（`from_subway`/`from_right`、`from_left`）+ 月台↔聚落、左↔右轉場；首抵 `reached_settlement`（左 panel `_ready` set_flag，走既有 story_flags 持久化）；`can_save_here`；**自動測試與 GUI 實機走查已完成** |
| 15-C | ✅ 完成 | 四室 final flavor 互動物：地鐵（站名牌 / 售票機 / 票閘 / 通勤螢幕「往上的線停了」=P17 錨 / 排水 / 月台空地）、聚落（空帳篷 / 淨水發電 / 收音機底噪 / 深隧道口=P18 入口 / 維修門）；NPC（16）/ 殘響（17）/ 戰鬥（18）以真掛點登記、場景中無假物件 stand-in；**自動測試與 GUI 實機走查已完成** |
| 15-D | ✅ 完成 | 回歸 + 存讀檔 + 全鏈雙向轉場（街道→大廳→月台→聚落左→右→回程）：test_runner Phase 15 區（四 scene_id entry points、SaveSystem 顯示名、travel gate、split 路由、`reached_settlement`）已寫；**自動測試與 GUI 實機走查已完成**；Phase 1~14 不退化 |
| 16-A | ✅ 完成 | 小岑 `cen`（嘴臭 / 防備 / 會偷東西，非純潔受害者）：對話樹 + 被抓包冷收尾（純對話、不引入偷竊系統）+ 自我介紹不具名「弄聲紋的人」+ 落地左室帳篷群；旗標 `met_cen` / `affinity_cen`；**程式完成 + headless PASS（2026-06-21）** |
| 16-B | ✅ 完成 | 伍姐 `wu`（C 版：問現象不問名字）：維修人 + 建立者節點「她只是比我們晚一點壞掉」防聖女且**不具名** + `knows_settlement_had_maker` + 追問 gate；落地右室淨水站前；**對話不出現「林霏」**；**程式完成 + headless PASS** |
| 16-C | ✅ 完成 | 七號 `seven`（2A 鋪墊「我有一個名字還掛在上面」，**全程不提妹妹**）：鋪墊鉤 + `seven_hinted_name_topside` + 追問 gate；落地右室深隧道口牆邊（不重疊 P18 戰鬥掛點）；**程式完成 + headless PASS** |
| 16-D | ✅ 完成 | DialogueDB 註冊三樹 + 條件路由（首見 / 重講）+ 跨場景旗標保留 + 回歸護欄；六旗標 round-trip；三樹掃描不含「林霏」；Phase 1~15 不退化；**headless PASS** |
| 16-E | ✅ 完成 | GUI / 觸控走查：三人對話可玩、首見→重講正確、純觸控可推進；立繪 / 角色圖（6 張，`三張臉.md` §5）到位後風格合規（三人不可大面積飽和橙）；**真機 GUI 走查完成（2026-06-22）** |
| 17-A | ✅ 完成 | 記憶碎片「你以前往上通勤」：複用 `MemoryFragmentArea`（無新系統），落 `subway_station_platform` 通勤螢幕 / 月台錨 + `mem_frag_commute_topside` 旗標 + STORY_MESSAGES 文字；**失神基調、不揭主角身份、headless PASS** |
| 17-B | ✅ 完成 | 聚落殘響採集點：複用 `EchoPoint` + `EchoDB` 加 `echo_settlement_erased`（一個被刪住戶，**不得是林霏 / 阿達、不含「林霏」**）；右室落點避開七號 / 伍姐互動 / P18 入口；**headless PASS** |
| 17-C | ✅ 完成 | 回歸 + 存讀檔：碎片旗標 + `echo_progress` round-trip、跨場景採集點不復生、Phase 1~16 不退化；**headless PASS** |
| 18-A | ✅ 完成 | 隧道清潔機正式遭遇：右室 `deep_tunnel` 由封閉 examine 改轉場進新戰鬥場景 `tunnel_combat`（廢棄通道，背景 4768×896 對齊 subway_platform 慣例），作者化 13-E 原型 + walker_01；格式化＝停機並設 `tunnel_machine_defeated`；Player `combat_mode=true` 兌現前瞻契約（attack gate + `_e_reserved()` E 優先鏈）；2026-06-23 本機 headless PASS |
| 18-B | ✅ 完成 | 戰後失物物流箱（gate `tunnel_machine_defeated`）→ `add_item("childcare_supply_receipt")`（key item，表面雜物 / 模糊代碼 / 無姓名、不揭七號 / 妹妹 / 林霏）；**背包滿防呆**（add_item 回 false 不掉件）；回執描述禁字測試 PASS；headless PASS |
| 18-C | ✅ 完成 | 晚對話「賣回執」分支 gate `has_item` → `remove_item` + `add_credits(200)` + `add_trace(-1)` + `add_int(affinity_wan,-1)` + `set_flag(peace_line_locked)`（effect ops 皆既有，無需補）；**賣＝永久鎖死和平線**；headless PASS |
| 18-D | ✅ 完成 | 回歸 + 存讀檔：`tunnel_machine_defeated` / 回執持有 / `peace_line_locked` round-trip、Phase 1~17 不退化、非戰鬥場景按 attack 無副作用；headless PASS（exit 0）。已知：test_runner 退出時 AudioStream teardown 殘留為框架既有（非本 Phase 引入） |
| M1 | ✅ 完成 | **進度頁（Meta / 非敘事 QoL，時序卡 Phase 19 之前，不佔故事編號、不順延 19~31）**：筆記分類列最右加「進度」分頁，第一項固定「總進度」（五分類 done/total + 整體 %＝跨分類加總 done÷31）；五收集分類＝場景10 / NPC6 / 任務3（含里程碑「離開公寓家」）/ 殘響5 / 特殊道具7。新增 GameState 三集合 `visited_scenes` / `talked_npcs` / `collected_special_items` + 旗標 `left_apartment_once`（皆納入存讀檔，缺鍵→空/false，舊檔不 backfill）；判定＝曾達成（特殊道具賣/消耗/升級不退勾）；未解鎖顯示 `???`。**純加法不改 Phase 1~18**。規格三份文件已寫（2026-06-23 凍結）；程式已實作（commit `bd4717f`）並驗證完成（2026-06-24，已隨 Windows build v0.18.4 出貨）。契約見 `開發設計方針.md > Phase M1`、驗收見 `遊戲規格書.md > Phase M1`、清單見 `測試指南.md > Phase M1` |
| M2-A | ✅ 完成 | 多國語系 i18n 基礎建設：`LocaleManager` autoload、`TranslationServer` 接線、fallback=`zh_TW`、`settings.cfg` 持久化、OS locale 首啟偵測、`NotoSansSC` 字型納入 + runtime 字型切換、最小設定頁（標題 + 暫停入口）與 `ui.csv` 最小閉環已完成；headless 驗證與 `tr()` 三語查表護欄已補（commits `36af800` / `87d07ca`）。 |
| M2-B | ✅ 完成 | UI Chrome i18n：UI 腳本與 `.tscn` prompt / footer / toast / panel label key 化，`ui.csv` 三語填齊，Control auto-translate 與手動 `tr()` 接線完成；補 coverage lint、CSV/translation 同步、zh_CN 繁體洩漏檢查與 note_title toast 覆蓋（commits `7f39402` / `4f684cd` / `61dc7f2`）。 |
| M2-C | ✅ 完成 | 敘事資料 i18n：`STORY_NOTES` title/body、`STORY_MESSAGES`、`ITEMS_DB` name/description、分類名改為翻譯 key；`story.csv` / `items.csv` 三語完成；資料驅動覆蓋檢查與抽樣 `tr()` 驗證已加入，對話 / 旗標 / 存檔邏輯不變（commit `29d14e3`）。 |
| M2-D | ✅ 完成 | 對話樹 i18n：9 棵 dialogue tree 的 speaker / text / choices key 化（`dialogue.csv` 176 keys 三語）、`DialoguePanel` 顯示端全 `tr()`、英文人名音譯對照鎖定（Wan / Lu Qichen / Cen / Wu / Seven）、三語禁字檢查（無「林霏」/「Lin Fei」）；顯示 / 邏輯分離保持（`goto` / `effect` / `condition` 用原 id）。code review 修正 `DialoguePanel` 離開選項排序在英文 locale 失效（`"Exit"` token → 翻譯實際用字 `"leave"`）與 `shop_panel` surgical 雜訊。`data/echoes` / `shops` / `quests` → `data.csv`（46 keys，原列 M2-E）一併前移完成。headless 全鏈 PASS。 |
| M2-E | ✅ 完成 | 收尾 + 全域 i18n 驗證網：~~`data/echoes` / `shops` / `quests` → `data.csv`~~（已於 M2-D 前移完成）；全鏈 Phase 1~19 / M1 / M2-A~E headless 回歸 PASS；新增跨 5 份 CSV（ui/story/items/dialogue/data）key 唯一性、佔位型別簽章一致、`林霏`/`Lin Fei` 禁字全域掃描護欄。三語 GUI / 純觸控走查與 iOS / Android 真機（OS locale 偵測 + 字型無豆腐）屬手動裝置驗收清單（見 `測試指南.md`），留待真機階段執行。 |
| 19-A | ✅ 完成 | 阿達殘響②「穿雨衣、拿維修棍、說只是照流程」：`EchoDB` 加 `echo_ada_reset`（含 `trace_on_collect`＝採集「留」一次性 Trace↑，兌現 11-C 預留）落聚落左室 `EchoPoint`（避開小岑 16-A 站位）；可賣（`sell_echo` → Trace↓）；媒體層可選後置；headless PASS（commit `a823cea`）|
| 19-B | ✅ 完成 | 舊善後工單③（**鎖 2C**，gate＝先採殘響）examine → set `read_old_work_order` + 寫 `clue_old_work_order` + badge 描述換揭露版（`get_item_description`）；**`old_work_badge` 公寓開場即持有（Phase 1 預載 key item），19-B 不 `add_item`、不是首取得點**；工單編號＝舊工作證號碼＝確認兇手＝失憶前主角；未採殘響前只給中性提示；headless PASS（commit `f3c3ada`）|
| 19-C | ✅ 完成 | 收束碎片「你親手抹過阿達」：`MemoryFragmentArea` 加 `require_flag` gate（預設 "" 向後相容）+ `mem_frag_erased_ada` + `STORY_MESSAGES`；gate＝`read_old_work_order`，揭露工單後離開必經帶觸發；headless PASS（commit `d41028f`）|
| 19-D | ✅ 完成 | 回歸 + 存讀檔護欄（折入 19-A/B/C commit，非獨立 commit）：`echo_progress`（含 sold）/ `trace` / `read_old_work_order` / `old_work_badge` 持有 / `mem_frag_erased_ada` round-trip；Phase 1~18 不退化；三拍文字不含「林霏」；2026-06-25 本機 headless 350 PASS / 0 FAIL（exit 0）|
| 20-A | ✅ 完成 | 七號對話加和平入口：`data/dialogue/seven.gd` 補窄漏斗對話 + 12 i18n key；入口 gate＝持回執 + `peace_line_locked != true` + `seven_peace_branch_d != true`；不新增場景 / 系統，沿用 Phase 16 七號對話樹 + Phase 18 回執 + Phase 11 Trust/Trace（commit `ddbd174`）|
| 20-B | ✅ 完成 | 交還回執 + Branch D：成功漏斗＝交還且不威脅 / 不嘲諷 / 不逼問 → `remove_item` 成功後才 `set_flag(seven_peace_branch_d)` + `affinity_seven +2` + `add_trace(-1)`（微降）；錯誤語氣冷收尾無副作用，被冷拒設 `seven_receipt_rebuffed` 走簡短 `receipt_reprobe` 重試入口（仍可成功、不重播初見反應）；賣回執 `peace_line_locked` 永久鎖死 D。canonical：`seven_peace_branch_d` / `childcare_supply_receipt` / `peace_line_locked` |
| 20-C | ✅ 完成 | 未處理延燒到 Phase 24：`seven_betrayal_pending` 不在本 Phase 設，留 Phase 24 爆點 |
| 20-D | ✅ 完成 | GUI / 純觸控走查：headless PASS（含全鏈回歸）+ code review 通過（commit `ddbd174` + 重試入口潤飾）|
| 21-A | ✅ 完成 | 夜總會場景骨架 + 轉場：新增 3 場景（`nightclub_entrance` 大門口＝Art Bible anchor-04 / `nightclub` 門面廳 / `nightclub_back` 後場殘響房）+ 雙向轉場 + BGM 兩軌（前區 `nightclub-1` / 後場 `nightclub-2`）；進入動線＝月台 `commuter_screen` → `learned_topside_shortcut` → 街道最左端 travel「前往上層區」→ `nightclub_entrance`（commit `f1a6549` + `f47223f`，headless PASS）|
| 21-B | ✅ 完成 | 林霏核心殘響 + 分段媒體：跨幕殘響 `echo_linfei` 6 段 + 分段媒體門檻（半收集 3 段→女聲歌、全收集 6 段→照片）+ 向後相容舊式 echo；s1~s6 真佈點（s1 大門口 / s2 月台 / s3 聚落左室 / s4 門面廳 / s5·s6 後場碎片右側折返必經）+ test_runner 跨場景佈點守門測試 |
| 21-C | ✅ 完成 | 收束碎片「黑戶藏身方式」：`MemoryFragmentArea` `mem_frag_hideout`（gate＝採滿 `echo_linfei`）|
| 21-D | ✅ 完成 | 女聲主題歌掛載：林霏女聲歌掛半收集 slot；夜總會美術 3 圖 + BGM 兩軌 + 女聲歌 / 殘響照片 2026-06-27 全到貨 |
| 21-E | ✅ 完成 | 《雨還沒停》環境母題：複用既有 `echo_song_rain_doesnt_stop.mp3`，掛地鐵月台 / 地下道聚落 `ThemeMotifPlayer`（Ambient bus / -24dB）；修補 `duplicate()` 後再設 `.loop` 防污染共享快取殘響回放（commit `7058974`）|
| 21-F | ✅ 完成 | 可賣 + 回歸 + 存讀檔：`echo_linfei` 可賣（`sell_echo`→credits 400 + Trace↓ + set `sold_linfei_echo` forward-契約）+ 補收藏家賣出選單缺的 `echo_settlement_erased`(P17) / `echo_ada_reset`(P19) + round-trip；本機 headless 全測 PASS（exit 0）。canonical：`echo_linfei` / `mem_frag_hideout` / `sold_linfei_echo` / `learned_topside_shortcut`。GUI / 真機走查（母題聽感、殘響回放不循環）已完成|
| 22 | — 併入 21 | **已併入 Phase 21（編號保留，不再使用）**；原 22-A~D（夜總會場景 / 林霏核心殘響 / 黑戶碎片 / 回歸）整併進 Phase 21；23~31 編號不變 |
| 23-A | ✅ 完成 | 場景接線骨架：Phase 21 門面廳 `back_door` 無條件門改四解 gate retrofit；新增保全 NPC（`Bodyguard` Area2D）+ `bar_bot` 互動 + 工牌 examine + ITEMS_DB key item `nightclub_staff_pass`（與 19-B `old_work_badge` 為不同物件，命名 / 顯示名 / 描述刻意拉開）；不新增場景（commit `3056bda`，headless PASS）|
| 23-B | ✅ 完成 | 保全對話樹（賄賂 + 假裝身份）+ `credits` condition：`data/dialogue/nightclub_bodyguard.gd`（賄賂 credits≥500 複用 Phase 8 經濟 / 假裝身份 gate `found_staff_pass`）+ DialogueRunner 補 `credits` condition type（最小 op）+ 三語 locale + staff_pass icon。code review 修補：`nightclub.gd._trigger_interaction()` 補回標準 `dialogue_id` dispatch（原缺→保全對話實機不可觸發）|
| 23-C | ✅ 完成 | 引開→潛行（一次性限時組合，2026-06-28 redesign）：① 前置 gate＝先與保全對話（`talked_nightclub_bodyguard`）才解鎖 `bar_bot` 引開；② 引發＝先跳前置 messagebox（玩家動手腳→吧台混亂 `MSG_NIGHTCLUB_BAR_BOT_TAMPER`，緊張 BGM 此時切入）→ 關閉後保全 + bar_bot 淡出停用 → 中央情境圖鎖操作 5 秒（複用 `set_monologue_active` 擋熱鍵 + `player.set_physics_process(false)`）→ 淡出後解鎖並開 20 秒倒數空窗；③ 空窗內 E `back_door` 溜過 set `passed_nightclub_security`；④ 倒數歸零未潛入＝全暗 messagebox「保全已處理完畢」(`MSG_NIGHTCLUB_GUARD_RETURNED`) → 保全 + bar_bot 歸位；⑤ **引開永久一次性**：`nightclub_bar_bot_used`（持久、納存讀檔），用過後 bar_bot prompt 改中性「查看」+ 給中性訊息。`_bodyguard_off_post` 仍 transient 不存檔。**演出細節（2026-06-28 二修）**：情境圖 fade-in/hold/fade-out 轉場（非直接 pop）；倒數＝紅色大數字 + 上方「混亂時間」(`UI_NIGHTCLUB_CHAOS_TIME`) 標題；**保全永遠在崗**（移除 passed→隱藏保全邏輯，四解仍永久通行、passed 只負責後場門放行）。情境圖 `assets/generated/sprites/nightclub_bar_bot_distraction/situation/`；新訊息 key `MSG_NIGHTCLUB_BAR_BOT_PRE_TALK`/`_USED`/`_TAMPER`/`MSG_NIGHTCLUB_GUARD_RETURNED` + prompt `PROMPT_NIGHTCLUB_BAR_BOT_EXAMINE`（移除舊 `MSG_NIGHTCLUB_BAR_BOT_DISTRACTED`）；緊張氛圍 BGM `nightclub-chaos.mp3`（引發瞬間切入，保全歸位切回 `nightclub-1`，潛入成功由後場 `nightclub-2` 接手）；headless PASS（含一次性 + 視窗到期歸位測試）|
| 23-D | ✅ 完成 | 回歸 + 存讀檔 + GUI / 觸控走查：本機 headless 全測 PASS（exit 0）；GUI / 純觸控走查（四解各自可玩、保全淡出 / 歸位、刷閘導向側門）已完成。canonical：`passed_nightclub_security` / `found_staff_pass` / `nightclub_staff_pass`。前提硬規則：保全人類不可打死 / 格式化；大門口閘門無 Trace；四解皆不動 Trace |
| 24-A | ✅ 完成 | quest 化 + 爆發 gate：v2.3 §7.2 三分支（D 和平 / A 攔下 / B 部分攔下，無 C / 不做大災難線）quest 化；新增 `data/quests/seven_betrayal.gd` + 註冊 `quest_db.gd`；沿用 QuestManager + 七號 NPC + Trust/Trace；伍姐 / 小岑提前警告對話分支（`wu.gd` / `cen.gd`）+ 聚落右室觸發接線 + i18n（`data.csv` / `dialogue.csv`）+ test_runner 護欄；headless PASS（commit `ef9f94b`）|
| 24-B | ✅ 完成 | 分支判定 + 伍姐 / 小岑提前警告：確定性可 headless＝`seven_stopped_partial =（get_trace() >= TRACE_BETRAYAL_THRESHOLD[第一版 3]）and not（get_trust("wu") >= 2 or get_trust("cen") >= 2）`，否則 `seven_stopped_full`；D＝`seven_peace_branch_d`（Phase 20）爆發前已成則不爆；`resolve_betrayal_results()` 結算 + 邊界測試；double-settlement 漏洞已修（`resolve_betrayal_results()` 改為冪等，commit `c9d9706`）；headless PASS（commit `ef9f94b` + `786c1dc`）|
| 24-C | ✅ 完成 | 深隧道追逐（**2026-06-28 重設計＝限時選門迷宮，兩室**）+ 兩去處選單接線：新增兩室 `tunnel_chase`（房間1，固定正解高門）/ `tunnel_chase_right`（房間2，`tunnel_chase_true_exit` 隨機真出口、reset 骰一次存讀檔固定）+ 目的地選單 `travel_deep_tunnel`；聚落右室深隧道口改看 `deep_tunnel_opened` 路由（爆點前直通 `tunnel_combat`、爆點後出兩去處選單，不取代 Phase 18）；全域 180 秒倒數＝七號交易通話接通 %（錯誤口各扣 20 秒一次、已試短訊息、純張力不改分支）；真出口 or 倒數歸零 → 七號攤牌情境圖（複用 23-C overlay）套 24-B 分支；梯子沿用 Phase 7-F 防火梯 climb 機制、窄 gap 用 Phase 12 跳躍；兩室 `can_save_here=false`、房間1左緣鎖住。規格／契約／測試清單已改寫三份文件；美術已到貨（`tunnel-chase-left/right.png` + 七號攤牌情境圖）。|
| 24-D | ✅ 完成 | Branch B 代價（小岑暴露演出）：set `cen_voiceprint_exposed`（餵 28-C 小岑缺席）；小岑代價純敘事（無 minigame）|
| 24-E | ✅ 完成 | 回歸 + 存讀檔：canonical＝`seven_betrayal_triggered` / `seven_stopped_full`(A) / `seven_stopped_partial`(B，餵 26-D 檔案重標記) / `cen_voiceprint_exposed`(餵 28-C) / `deep_tunnel_opened`。前提硬規則：無 C 分支 / 七號人類不可殺 / 三分支皆不動 Trace |
| 25-A | ✅ 完成 | Act 4 備份區三場景骨架（`datacenter_entrance`＝anchor-05 / `datacenter_backup` 戰鬥③廊道 / `datacenter_backup_core` 核心＝結局觸發掛點佔位）+ SceneRegistry + 雙向轉場 + `nightclub_entrance` travel「AI 資料中心」+ 善後員合法門禁 gate（反諷）。travel gate＝`passed_nightclub_security AND (seven_peace_branch_d OR seven_stopped_full OR seven_stopped_partial)`、門禁 gate＝`has_item("old_work_badge") AND get_flag("read_old_work_order")`，**皆讀既有旗標 / 物品，零新存讀檔欄位、不改 Phase 24**。晚 flavor 提醒「再看一眼舊卡」純演出不參與 gate。headless PASS（commit `9ec5bad`）|
| 25-B | ✅ 完成 | 戰鬥③（低階保全，跑到門）：`datacenter_backup` 混合敵人＝機器哨兵（`machine_enemy` 格式化清路，沿用 13）+ 人類保全（`human_enemy` 朝玩家 x 追擊、**不可殺**，唯一新做＝最小追擊 AI）；勝利＝抵達右端門按 E（`exit_to_core` 互動，與 tunnel_combat / 24-C 出口同型）→ 轉 `datacenter_backup_core`；**無失敗態**（碰撞＝knockback / stagger，無 Game Over / 無 combat_loss 岔線）。headless PASS（commit `97fb782`；驗證後修正＝UI 開啟時敵人凍結（walker_01 / rack_sentinel / security_guard 比照 player 查 UIMode）+ knockback 直接取消跳躍 / 攻擊狀態，均含回歸測試）|
| 25-C | ✅ 完成 | 回歸 + 存讀檔護欄：三場景載入 + 全鏈 round-trip、travel / 門禁 gate、戰鬥③ 抵達門、Phase 1~24 不退化（尤其 Phase 24 追逐 / 攤牌、`tunnel_combat` 入口、聚落往返）。前提硬規則：人類不可打死 / 格式化；無 Game Over；不碰 Phase 26 演出 / 結局；不動 Trace。外部素材已全數到貨（2026-07-02）：兩室 map 圖 + 機器哨兵 / 人類保全 sprite + Act 4 BGM 兩軌（`Heartbeat of the Machine`＝戰鬥③ `datacenter_backup`、`The Cold Mirror (Loop)`＝entrance / core）；entrance 用 anchor-05。headless PASS（commit `4dcb28b`；該 commit 並補回 24-C `tunnel_chase` 兩室 Player 缺失的 AnimatedSprite2D / CollisionShape2D 節點，見 `驗證後已知問題.md > 25-C`）|
| 26-A | ✅ 完成 | 晚拉扯演出：晚實體到場 `datacenter_entrance` 門禁大門前，走近自動觸發一次性對話（v2.3 §4.3 活人安全版＋私心版**一次給足、不設 affinity 門檻**）→ set `wan_act4_pull_seen`；之後留原地可 E retalk 短版（5-D 慣例）；**不參與門禁 gate**。headless PASS（commit `2bc4da7`）|
| 26-B | ✅ 完成 | 阿達④本人短暫登場一次（「你忘了啊？也好。至少有人可以忘」，§3 四段式收尾）：`datacenter_entrance` 靠 travel 落點，首次到場且 `read_old_work_order`（**順序護欄④不早於③**）自動觸發一拍短對話 → set `ada_final_words_seen` → 淡出**永久消失**。阿達 Act 4 世界 sprite（idle）＋對話立繪已到貨。headless PASS（commit `2bc4da7`，素材 commit `086a98e`）|
| 26-C | ✅ 完成 | 真相碎片「你自己選擇被刪、為保護那個網」：`datacenter_backup_core` 備份主機前必經 `MemoryFragmentArea`（14 同款）自動收取 → set `mem_frag_chose_deletion`；文案回連 `mem_frag_commute_topside` / `mem_frag_hideout`。headless PASS（commit `003db3b`）|
| 26-D | ✅ 完成 | 結局觸發點武裝 + Branch B 檔案重標記（**v2.3 §12 開放問題 5 拍板，2026-07-02**）：「自己的備份」碎片後 examine 換重量級文字（名字露出一次）＋ set `stood_before_own_backup`（**forward 契約：27-B 三結局路由掛點，已於 27-B 兌現**；不開選單，4-G 教訓）；新「檔案索引終端」examine `seven_stopped_partial` 變體＝小岑聲紋檔具體標紅「待清理」＋未具名黑戶檔案重標記（不點名伍姐／七號／林霏）。headless PASS（commit `003db3b`）|
| 26-E | ✅ 完成 | 回歸 + 存讀檔 + GUI：四旗標 round-trip、26-A/B 一次性跨存讀不重播、順序護欄、Phase 1~25 不退化。headless PASS（commit `d31f4a0`）|
| 27-A | ✅ 完成 | `broadcast_station` 正式場景（**v2.3 §12 問題 1 拍板升正式，2026-07-02**）：單室、唯一 entry `from_backup_core`、進場一次性 MessageBox、flavor examine（**不放 NPC**）、**無回程出口**（單向）、`can_save_here = true`、新 BGM（user 委製，**已到貨 2026-07-02**＝`assets/bgm/The Yellow Light Tape.mp3`）、map（**已到貨 2026-07-02**＝`assets/generated/maps/broadcast_station/`）。headless PASS（commit `7941519`）|
| 27-B | ✅ 完成 | 三結局路由（26-D forward 契約兌現；**v2.3 §12 問題 3 拍板不硬鎖**）：`stood_before_own_backup` 後重看「自己的備份」開三選對話（存檔提示[一次性，set `ending_save_hint_seen`，文案拍板 2026-07-03]→重錨定＋三個動詞合併一節點→「灌回去 / 刪掉它 / 拷貝走」/「退開」→確認前小節「就這麼做」/「回去再想」→鎖點）；三選無條件全開不看 Trust / Trace；互斥旗標 `ending_route_reclaim/protect/expose`（level `datacenter_backup_core.gd` 四層分派：佔位→TRUTH+武裝→開 `own_backup` 對話→任一 route 已設則 DECIDED 不可重選）；退開／回去再想皆不寫旗標、可重開；R / P 停原地待 28、Expose 效果內含 `travel` 單向轉場 `broadcast_station:from_backup_core`。新增 `data/dialogue/own_backup.gd` + `dialogue_db.gd` 註冊 + `dialogue.csv`/`story.csv` 三語；headless PASS（`tests/manual/test_runner.gd` Phase 27-B 區塊，本機待跑——此 session 無 Godot 執行環境，待使用者於 Windows 端跑 headless 驗證）|
| 27-C | 📐 規格可實作 | 上傳前清洗閘五拍（**清洗第一次硬兌現**，11-D 移入）：掃描染色（`echo_count` 兩檔）→ 中性警告（Branch B 變體）→ 手藝反諷三選 → 代價當場兌現 → 最終確認鎖點寫 `expose_upload_cleaned` + `expose_upload_done`；單一 bool 無逐項清洗 UI；退開不留半套狀態。系統擴充唯一＝DialogueRunner `echo_count` condition。程式未開工 |
| 27-D | 📐 規格可實作 | 回歸 + 存讀檔：6 旗標 round-trip（含 `ending_save_hint_seen`）、廣播站內存讀、三選前留檔三路皆可達、Phase 1~26 不退化；**本 Phase 不碰 Trace / 不做 A/B/C 判定（29）/ 不做結局演出（28）**。程式未開工 |
| 28-A | 📐 規格可實作 | Reclaim 三站腳本化序列（**2026-07-03 規格定案**）：backup_core 灌回演出（2-G 開場鏡像多頁＋`trace` 兩檔壓垮拍）→ `apartment_entrance` 晚訣別（`affinity_wan` 兩檔）＋fade out **永久消失** → 公寓痕跡拍＋set `ending_reclaim_played` 靜止停（30-A 掛點）；站間自動 travel、全程禁存。程式未開工 |
| 28-B | 📐 規格可實作 | Protect 主體：刪除演出（短、與 Reclaim 刻意不對稱）→ 28-C 中間站 → 晚拍板台詞「你又變回來了」固定**不消失** → 公寓 set `ending_protect_played` 靜止停；Protect 全程無染色變體。程式未開工 |
| 28-C | 📐 規格可實作 | 小岑條件式回收＝中間站分岔：not-B → `subway_station` 大廳**上行線復駛背景事件**（廣播拍＋`AmbientSubway` 遠轟；與主角／分支無關、不改聚落安全）＋小岑過閘「大叔，站那邊幹嘛？車要來了欸。」（v2.3 §8 舞台化改句）；B → 聚落 `empty_tent`＋伍姐沉默搖頭拍。程式未開工 |
| 28-D | 📐 規格可實作 | 回歸 + 存讀檔：2 旗標（`ending_reclaim/protect_played`）round-trip、序列站禁存、選擇前留檔 R / P 含 28-C 兩變體共 3 條路可達、**孤兒檔救援**（route 已設未 played 讀檔強制回 backup_core 開序列）、Phase 1~27 不退化。程式未開工 |

> 狀態圖例：✅ 完成（含可驗收）；🟦 待驗收 = 程式實作完成且 headless 自動測試 PASS，但互動 / 視覺 / 真機驗收尚未執行；🟧 待 headless = 程式實作完成，但 headless 自動測試尚未執行（本機待跑）；📐 規格可實作 = 規格 / 契約 / 測試清單已寫到可動工，但程式未開工；⬜ 待開工 / 待規劃。3-B~3-D 的「純觸控 GUI 走查」與 B0–B9 里程碑實測已完成。

> **主線《雨還沒停》v2.3 後續規劃（Phase 11–31，順敘版）**：完整 Phase / 子階段排程已寫入 `遊戲規格書.md > Phase 11+`、`開發設計方針.md > Phase 11+`、`測試指南.md > Phase 11+`（敘事事實來源 `subdocs/主線/雨還沒停v2.3.md`）。**地基 Phase 11 / 12 / 13 / 14 / 15 均已完成（headless PASS + GUI 走查）：Phase 15（Act 2 場景骨架，15-A~D ✅）真美術 4 圖 + 專屬 BGM 2 軌已落地（2026-06-21），4 個 scene_id（地鐵大廳 / 月台、聚落左 / 右）+ travel gate + test_runner 護欄已就緒，GUI 實機走查已完成（實作契約見 `開發設計方針.md > Act 2 場景骨架（Phase 15，實作契約）`，場景設計見 `subdocs/地點/地鐵站.md` / `subdocs/地點/地下道聚落.md`）**；**Phase 16（三張臉 NPC 落地：小岑 / 伍姐 / 七號）已完成（headless PASS + 真機 GUI 走查驗收完成，2026-06-22，16-A~E ✅）：沿用 Phase 5 對話系統（無新系統），3 對話樹 + 條件路由 + 新旗標納入既有存讀檔；NPC 站位用 Phase 15 已建聚落兩室真掛點；三前提硬規則（主角不知「林霏」名字 / 對話不出現「林霏」/ 七號不明說妹妹）。實作契約見 `開發設計方針.md > 三張臉 NPC 落地（Phase 16，實作契約）`，人設 / 對話定稿草案 / 旗標見 `subdocs/人/三張臉.md`**；**Phase 17（Act 2A 記憶碎片 + 殘響鋪設）實作規格已寫入三份文件（2026-06-21，📐 規格可實作）：全程複用既有組件（無新系統）——記憶碎片複用 `MemoryFragmentArea`（Phase 14 同款）、聚落殘響複用 `EchoPoint` + `EchoDB`（Phase 9）；新旗標 `mem_frag_commute_topside` + 新殘響 `echo_settlement_erased` 走既有 story_flags / echo_progress 存讀檔（`game_state.gd` 邏輯不需改，僅加一條 STORY_MESSAGES 文字常數 + 一條 echo 資料）；掛點用 Phase 15 已建真錨（地鐵月台通勤螢幕 / 聚落右室殘響點）；前提硬規則（碎片不揭主角身份 / 聚落殘響不得是林霏 / 阿達、segment 不含「林霏」）。文案方向已寫進規格，定稿待實作者補。實作契約見 `開發設計方針.md > Act 2A 碎片 + 殘響鋪設（Phase 17，實作契約）`**；**Phase 18（Act 2B 戰鬥遭遇 + 回執取得）已完成（headless PASS，2026-06-23，18-A~D ✅；原規格 2026-06-21 寫入三份文件）：複用 Phase 13 戰鬥組件作者化進真動線——`deep_tunnel` 轉場進新戰鬥場景 `tunnel_combat`、敵人沿用 walker_01（13-E 原型同款）、戰後失物物流箱發回執、回執經晚對話分支賣出鎖死和平線；新增 1 條 ITEMS_DB key item `childcare_supply_receipt` + 旗標 `tunnel_machine_defeated` / `peace_line_locked`（走既有 story_flags / inventory 存讀檔）；兌現「戰鬥場景互動契約（前瞻契約）」的 `combat_mode` gate；唯一系統小擴充＝賣出對話的 add_credits / affinity↓ effect op（缺則補最小版，複用既有 match op 結構）。前提硬規則（回執表面＝雜物、不揭七號 / 妹妹 / 林霏；無 Game Over；格式化＝停機不死）。實作契約見 `開發設計方針.md > Act 2B 戰鬥遭遇 + 回執取得（Phase 18，實作契約）`，敘事事實來源 `subdocs/主線/雨還沒停v2.3.md` §4.2.1 / §4.2.2**；**Phase 19（Act 2C 阿達罪責）已完成（headless PASS，2026-06-25，19-A~D ✅）：複用既有組件（`EchoPoint`/`EchoDB`、`MemoryFragmentArea`、examine）落聚落左室——②阿達殘響 `echo_ada_reset` + ③舊善後工單 examine + 收束碎片 `mem_frag_erased_ada`；新增 `trace_on_collect` / `require_flag` / 左室 examine 分派，並完成回歸與存讀檔護欄。前提硬規則：阿達本人不登場（④留 Phase 26）/ 罪責中檔 / 三拍不含「林霏」/ 順序鎖死（殘響→工單→碎片）**；**Phase 20（Act 2D 七號可選 + 和平線 Branch D）規格已寫入三份文件（📐 規格可實作，2026-06-25）：不新增場景 / 系統，沿用 Phase 16 七號對話樹 + Phase 18 回執 + Phase 11 Trust/Trace；canonical 旗標 `seven_peace_branch_d` / `seven_betrayal_pending`，成功漏斗＝持回執 + 事件前主動 + 不威脅 / 不嘲諷 / 不逼問 + 交還，賣回執 `peace_line_locked` 永久鎖死 D。Phase 20（Act 2D 七號可選 + 和平線 Branch D）已完成（✅ 20-A~D，headless PASS + code review 通過，2026-06-26，commit `ddbd174` + 重試入口潤飾）：不新增場景 / 系統，沿用 Phase 16 七號對話樹 + Phase 18 回執 + Phase 11 Trust/Trace；成功移除回執、`seven_peace_branch_d` true、`affinity_seven +2`、Trace 微降；錯誤語氣冷收尾無副作用、可重試（`receipt_reprobe`），賣回執 `peace_line_locked` 永久鎖死 D，`seven_betrayal_pending` 留 Phase 24。Phase 21（Act 3 夜總會 + 林霏核心殘響 + 主題歌整合，原 Phase 22 已併入）規格已寫入三份文件（📐 規格可實作，2026-06-25）：合併原 Phase 21 主題歌 + 原 Phase 22 夜總會 / 林霏殘響，**新增 3 場景**（大門口 `nightclub_entrance`＝anchor-04 / 門面廳 `nightclub` / 後場對話包廂 `nightclub_back`）+ 1 跨幕殘響 `echo_linfei`，系統擴充＝EchoDB/EchoPoint 媒體分段門檻（半→女聲歌、全→照片）+ 保全四解小解謎（門面廳→後場；先不做完整戰鬥），進入動線改月台 `commuter_screen`→`learned_topside_shortcut`→街道上層區 travel；canonical `echo_linfei` / `mem_frag_hideout` / `sold_linfei_echo`（可賣，結局僅台詞微調）/ `learned_topside_shortcut` / `passed_nightclub_security` / `found_staff_pass`；場景設計檔 `subdocs/地點/夜總會.md`（2026-06-26 拍板）；外部 blocker＝已全數到貨（夜總會美術 3 圖 + BGM 兩軌 + 林霏女聲歌 / 照片，2026-06-27，待 21-D/E 接線；剩餘僅 g2d 可生的保全 NPC / bar_bot 圖、非 user blocker；《雨還沒停》複用既有 `echo_song_rain_doesnt_stop` 歌檔，非 blocker）；**Phase 22 編號保留不再使用，23~31 不變**；Phase 23 起為 ⬜ 待規劃**；嚴格順敘、不跳號。Phase 12 跳躍架構已拍板（2026-06-19）＝**方案 A 腳本化拋物弧**（不引入全域重力）。Phase 15 範圍已拍板（2026-06-19）＝**地鐵站 + 地下道聚落 2 真場景**，硬規則**不暫代**（不借 BGM、不放 placeholder 美術、不寫待覆寫佔位文字；NPC/殘響/戰鬥後置但以真掛點預留）；**場景切分（2026-06-21 user 拍板）＝每地點切兩室、共 4 個 scene_id**（原 2 圖拼接單室改為兩室 `InteractableArea` 互轉，利相機 clamp 與後續往兩側補內容）。**另：Phase M1（進度頁）為 meta / 非敘事 QoL 功能，時序卡在 Phase 19 之前，刻意以 out-of-band 編號落地——不插 Phase 19、不順延 19~31，避免動到既有 80+ 處敘事交叉引用（呼應 4-G 教訓）；規格已寫入三份文件（2026-06-23 凍結）、程式已實作並驗證完成（2026-06-24，commit `bd4717f`，隨 build v0.18.4 出貨）。**

### Phase 3 子階段（公寓觸控化）

> 子階段細項（狀態 + 概要）已併入上方「Phase 進度」主表（單一事實來源），此處不重列以免漂移。

平台策略：最終 iOS、MVP 不做 Android；開發 / 驗收在 **Windows 桌面版 + 滑鼠模擬觸控**，真機在 **Mac + Xcode 免費簽名**進自己 iPhone（**不需付費 Apple Developer Program**，付費僅 TestFlight / 上架）。依賴線性：3-A → 3-B → 3-C → 3-D（皆 Windows）→ 3-E（需 Mac）。

驗收意圖見 `遊戲規格書.md > Phase 規劃 > Phase 3`；實作契約見 `開發設計方針.md > Phase 3`；操作清單見 `測試指南.md > Phase 3`。

### Phase 4 子階段（跨場景架構化）

目的：採用 `main.tscn` 常駐宿主 + `WorldRoot` 動態關卡 + `GameUI` 常駐 CanvasLayer。Phase 4 只做跨場景 runtime 架構與未來系統 contract，不做完整 NPC 對話、完整任務、真存檔、完整 MusicManager、地鐵完整網路或街區正式美術量產。

核心決策：

- `GameUI` 不做 Autoload；放在 `main.tscn`，持有 Prompt / Inventory / Notebook / DualPane / MessageBox / ConfirmDialog / ItemDetailModal / FloatingToast。
- `GameState` / `UIMode` / `TouchControls` 維持 Autoload。
- SceneRouter 第一版可在 `main.gd`；所有轉場使用 `scene_id + entry_point_id`。
- Entry points固定：`apartment:wake_bed`（新遊戲，播開場）、`apartment:from_street`（回公寓，不播開場）、`apartment_entrance:from_apartment`（從公寓出去）。
- `player.tscn` 目前不存在；Phase 4 不新建 / 不抽出，只在 4-A0 搬 `player.gd + player.gd.uid`。各 level 可暫時內嵌 `Player` node 並共用 `player.gd`。
- 每個子階段完成後遊戲都應仍可手動驗證；4-F 起應跨場景可玩。

子階段依賴：4-A0 → 4-A → 4-B → 4-C → 4-D → 4-E → 4-F。（4-G 已取消，見上方 Phase 進度表。）

驗收意圖見 `遊戲規格書.md > Phase 4`；實作契約見 `開發設計方針.md > Phase 4`；操作清單見 `測試指南.md > Phase 4`。

## Phase 2 公寓解謎鏈

```text
B0 醒來（床）
B1 試門（door_locked）
B2 examine 房間：桌上電腦 / 左牆錄音機
B3 戴上解碼手套
B4 解碼櫥櫃魔術方塊 -> decoder_cube
B5 線索揭示偵測終端
B6 啟動終端 -> 聲納模式
B7 最強區停留 5 秒 -> reveal 隱藏插槽
B8 放入 decoder_cube -> add_knowledge(identity_door_unlock_method)
B9 開門 gate 通過
```

目前玩家已具備完整通關路徑（B0 ~ B9）；公寓解謎核心鏈已全數開發完成並通過自動與手動驗收。

## 各階段查閱地圖（文件 + 行範圍）

> 開某子階段前只讀對應行範圍，避免每次重掃整份規格。行號以 2026-05-31 版為準；大幅改寫後需校正。
> 四份文件角色：**規格書**=驗收意圖（what must be true）／**設計方針**=實作契約（API・欄位・接線）／**測試指南**=操作清單（click-by-click）／**主角公寓**=敘事・互動物・線索文字。

### Phase 2 子階段（四份對照）

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） | subdocs/地點/主角公寓.md（流程・文字） |
|---|---|---|---|---|
| 2-A examine 線索 | 1522–1532 | 27–48 | 45–67 | 384–392・432–463 |
| 2-B 解碼手套／方塊 | 1533–1547 | 49–75 | 68–96 | 394–431 |
| 2-C 容器白名單／鎖定 | 1548–1559 | 76–99 | 97–121 | 497–505 |
| 2-D 投影時鐘＋聲納 reveal | 1560–1574 | 100–145 | 122–160 | 464–505 |
| 2-E 放入→語音→開門＋overlay 重構 | 1575–1586 | 146–174 | 161–186 | 506–534 |
| 2-G 開場獨白序列 | 1631–1646 | 199–234 | 209–244 | 383–416 |

### Phase 4 子階段（三份對照）

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 4 總覽 | 1705–1807 | 333–339 | 285–288 |
| 4-A0 檔案結構整理 | 1809–1818 | 340–399 | 289–298 |
| 4-A Main / SceneRouter / SceneRegistry | 1820–1827 | 402–466 | 301–309 |
| 4-B GameUI 抽離 | 1829–1835 | 468–552 | 312–319 |
| 4-C Level interaction contract | 1837–1842 | 554–589 | 322–329 |
| 4-D TouchControls 解耦 | 1844–1849 | 591–611 | 332–339 |
| 4-E 公寓遷移 / B0-B9 回歸 | 1851–1859 | 613–650 | 342–355 |
| 4-F 第二場景 stub / 真轉場 | 1861–1867 | 653–671 | 358–365 |
| 4-G（已取消，原 future contracts pass） | 1870–1876 | 674–683 | 368–374 |

### Phase 5 子階段（三份對照）

> 行號以 2026-06-06 版為準；大幅改寫後需校正。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 5 總覽 + 對話/旗標語意 | 1882–1941 | 685–709 | 379–382 |
| 5-A 旗標 store / 對話資料 / DialogueRunner | 1942–1950 | 710–830 | 383–397 |
| 5-B 對話 UI / DIALOGUE / 接線 | 1951–1960 | 831–896 | 398–409 |
| 5-C TouchControls 對話路由 | 1961–1966 | 897–909 | 410–416 |
| 5-D 晚落地 / dispatch 泛化 | 1967–1973 | 910–942 | 417–426 |

NPC「晚」內容定稿：`subdocs/人/晚.md`。

### Phase 6 子階段（三份對照）

> 行號以 2026-06-07 版為準；大幅改寫後需校正。規格書 Phase 6 無「每子階段獨立驗收意圖段」，故規格書欄位指共用段（範圍 / 語意 / 邊界 / 子階段表）與子階段表對應列；契約 / 清單細節在設計方針與測試指南。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 6 總覽 + 範圍 / 語意 / 邊界 | 1977–2028 | 944–967 | 428–431 |
| 子階段表 + 依賴順序 + 契約索引 | 2029–2049 | — | — |
| 6-A SaveSystem / 序列化 / reset | 2033（表列） | 968–1039 | 432–445 |
| 6-B 讀檔回場 / 兩段驗證 | 2034（表列） | 1040–1070 | 446–451 |
| 6-C 多槽模型 / meta 列舉 | 2035（表列） | 1071–1085 | 452–457 |
| 6-D 最小標題畫面 / TouchControls 隔離 | 2036（表列） | 1086–1093 | 458–465 |
| 6-E 暫停選單 / 槽列表 / gating | 2037（表列） | 1094–1105 | 466–474 |
| 6-F 邊界與失敗處理 / GUI 走查 | 2038（表列）・2019–2028 | 1106–1111 | 475–480 |

存檔架構決策（ResourceSaver → `var_to_str`、多槽、回場座標、gating）：`技術概念.md > 存檔策略`。

### Phase 7 子階段（三份對照）

> 行號以 2026-06-07 版為準；大幅改寫後需校正。Phase 7 規格 / 契約 / 測試清單已定；7-A~7-K 全部已實作並驗證（headless PASS）。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 7 總覽 + 範圍 / quest state / 任務流程 / A-B 物品 / 外牆語意 | 2053–2194 | 1113–1137 | 482–484 |
| 7-A QuestManager + quest state save | 2184（表列） | 1142–1223 | 486–497 |
| 7-B 晚的對話接任務 + Dialogue condition extension | 2185（表列） | 1225–1262 | 499–505 |
| 7-C 後巷偵查事件 | 2186（表列） | 1264–1289 | 507–514 |
| 7-D 公寓窗戶條件式入口 | 2187（表列） | 1291–1320 | 516–521 |
| 7-E `apartment_fire_escape` 場景骨架 | 2170–2178・2188（表列） | 1322–1374 | 523–532 |
| 7-F 梯子攀爬 / 天橋步行 / 相機 / 外牆禁存 | 2175–2178・2189（表列） | 1376–1417 | 534–543 |
| 7-G 箱子搜索 + A 物品取得 | 2134–2138・2190（表列） | 1419–1451 | 545–552 |
| 7-H R 查看 A 得 B | 2140–2152・2191（表列） | 1453–1497 | 554–562 |
| 7-I 回報晚 + 任務完成 | 2154–2167・2192（表列） | 1499–1528 | 564–572 |
| 7-J 回歸與存讀檔驗證 | 2193（表列） | — | 574–580 |
| 7-K 任務結局分支（隱藏物交還 + 好感 + 親近對話） | 表列＋「7-K 任務結局分支」段（行號待校正） | 「7-K 任務結局分支」段（行號待校正） | 「7-K 任務結局分支」段（行號待校正） |

> 註：7-K 為 7-A~7-J vertical slice 完成後追加；以上三份對照行號因 7-K 改寫而位移，待下次校正。

### Phase 8 子階段（三份對照）

> 行號以 2026-06-13 版為準；大幅改寫後需校正。Phase 8 規格 / 契約 / 測試清單已寫入；8-A~8-H 已完成；`8-H：發現販賣機錯誤後缺少「回電腦接案」前置線索筆記` 已驗收完成；人工對話與買賣系統 GUI / 純觸控走查已完成。
> 規格書 Phase 8 無「每子階段獨立驗收意圖段」，故規格書欄位指對應系統語意段 + 子階段表（2353–2369）的對應列；契約 / 清單細節在設計方針與測試指南。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 8 總覽 + 範圍 / 買賣語意 | 2230–2279 | 1682–1712 | 620–623 |
| 8-A 場景骨架 + 轉場 | 2280–2286・2353 表 | 1713–1733 | 625–631 |
| 8-B 前導對話 + 發現錯誤旗標 | 2245・2287–2293・2313–2323・2353 表 | 1734–1767 | 633–638 |
| 8-C 電腦兩段 gate + 接案 | 2287–2312・2353 表 | 1769–1821 | 640–646 |
| 8-D 蒐證 + 診斷對話樹 | 2324–2331・2353 表 | 1822–1838 | 648–655 |
| 8-E 店籍主機三段 + 兩種結局 | 2332–2352・2353 表 | 1839–1895 | 657–668 |
| 8-F 買賣系統核心 + ShopPanel | 2259–2279・2353 表 | 1896–1950 | 670–685 |
| 8-G 迷你飲料商店 + 多商店 | 2353 表 | 1951–1956 | 687–691 |
| 8-H 回歸 + 存讀檔 + GUI 走查 | 2353 表 | 1957–1959 | 693–700 |
| 旗標 / 狀態一覽 | 2370–2384 | — | — |

便利商店場景敘事 / layout / 互動物：`subdocs/地點/便利商店.md`。

### Phase 9 子階段（三份對照）

> 行號以 2026-06-13 版為準；大幅改寫後需校正。Phase 9 = 拾遺系統（殘響蒐集 + 收藏家），已全數完成（9-A~9-H，headless 100 PASS / 0 FAIL）。鑑定鏈不走 QuestManager；不做「還」流程 / TravelPanel / 時間系統。
> 規格書 Phase 9 無「每子階段獨立驗收意圖段」，規格書欄位指對應系統語意段 + 子階段表（2475–2491）的對應列。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 9 總覽 + 範圍 | 2386–2415 | 1962–1992 | 702–705 |
| 9-A 殘響資料模型 + 筆記投影 | 2416–2424・2475 表 | 1993–2038 | 706–716 |
| 9-B 時鐘取模組 | 2425–2432・2475 表 | 2039–2060 | 717–723 |
| 9-C 暫時通道 + 收藏家 + 鑑定 | 2449–2461・2475 表 | 2061–2113 | 724–733 |
| 9-D 感知採集 | 2433–2440・2475 表 | 2114–2130 | 734–742 |
| 9-E 媒體層 | 2441–2448・2475 表 | 2131–2147 | 743–750 |
| 9-F 內容鋪設 | 2462–2474・2475 表 | 2148–2154 | 751–755 |
| 9-G 收購（賣 vs 留） | 2449–2455・2475 表 | 2155–2168 | 756–763 |
| 9-H 回歸 + 走查 | 2475 表 | 2169–2172 | 764–769 |
| 旗標 / 狀態一覽 | 2492–2502 | — | — |

收藏家人物設定：`subdocs/人/鹿其琛.md`；收藏家的店場景：`subdocs/地點/收藏家的店.md`。

### Phase 10 子階段（三份對照）

> 行號以 2026-06-16 版為準；大幅改寫後需校正。Phase 10 = 氛圍與演出 pass（只在街道 `apartment_entrance` 做垂直切片），規格已寫、待開工。
> 規格書 Phase 10 無「每子階段獨立驗收意圖段」，以對應語意段（音景 / 視覺基底 / 分層進階 / NPC 微演出）+ 子階段表對應；驗收以 GUI / 真機目視為主，headless 僅作回歸護欄。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 10 總覽 + 範圍 + 氛圍原則 | 2504–2536 | 2181–2210 | 771–775 |
| 10-A 街道音景 | 2537–2543 | 2211–2241 | 776–784 |
| 10-B 不分層視覺基底 | 2544–2552 | 2242–2261 | 785–796 |
| 10-C-1 看板廣告螢幕 + 路燈柔光池（免分層 / 可先行） | 2553–2571（1/2 同語意段） | 2262–2285 | 797–805 |
| 10-C-2 分層進階（條件式 / 卡分層前置） | 2553–2571（1/2 同語意段） | 2286–2295 | 806–813 |
| 10-D 晚 idle break（撇一眼暗巷） | 2572–2579 | 2296–2313 | 814–821 |
| 子階段表 / 驗收性質 / 回歸 | 2580–2599 | 2314–2320 | 822–824 |

Phase 10 素材交付：音訊 `assets/audio/ambient/street_rain_loop.mp3`、`subway_rumble*.mp3`（提示詞已備）；雨絲 / 水花貼圖 `assets/vfx/rain_streak.png`、`rain_splash.png`（已生成，生成腳本 `assets/vfx/gen_rain_vfx.py`）；vignette 走 shader。**待生 / 待寫**：10-C-1 看板廣告靜圖 `assets/generated/sprites/street_billboard_ad/`（opaque、對齊看板矩形）+ `assets/shaders/billboard_screen.gdshader`（掃描線 / flicker / 邊緣輝光）；10-D 晚 `assets/generated/sprites/wan/idle_glance/`（2~3 關鍵姿勢，須接上現有 idle）+ `scripts/components/idle_break.gd`。10-C-2 街道分層素材仍為條件式。

- `遊戲規格書.md` Phase 規劃總覽 1272–1521（含 Phase 2 拆分 1510–1521）
- `subdocs/地點/主角公寓.md` 機制鏈總覽 B0–B9 357–381
- `開發設計方針.md` 本檔範圍與邊界 6–21

### Phase 12–13 子階段（三份對照）

> 行號以 2026-06-20 校正版為準（Phase 13 規格改寫後重算；Phase 12 行號未動）；大幅改寫後需校正。Phase 12（跳躍 / 平台）、Phase 13（戰鬥）為主線地基，規格 / 契約 / 測試清單已展開到可實作（📐）；Phase 13 目前僅 `jump_proto` 內有拋棄式雛形（player attack + walker 巡邏 / 倒地自修復），正式組件待收斂到 `combat_proto`。
> 規格書 12/13 採「架構決策 + 範圍 / 語意 + 子階段表」整段式（無每子階段獨立段），故子階段列的規格書欄指子階段表 + 對應語意整段。
> 跨 Phase 地基語意（Trust/Trace/清洗、戰鬥 / 跳躍、三結局硬鎖）見 `遊戲規格書.md` Phase 11+ 開頭「跨 Phase 系統語意」段。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 12 總覽 + 架構決策 + 範圍 / 語意 | 2648–2685 | 2372–2398（現況基準 + 新增/異動檔） | 841–844 |
| 12-A 跳躍狀態（拋物弧 + 抓邊緣） | 2686–2693（子階段表） | 2399–2418 | 845–853 |
| 12-B 平台 / ledge / gap + 原型床 | 2686–2693（子階段表） | 2419–2426 | 854–858 |
| 12-C 觸控 Jump 鈕 | 2686–2693（子階段表） | 2427–2433 | 859–863 |
| 12 驗收性質 / 回歸 | 2694–2696 | 2434–2439 | 864–867 |
| Phase 13 總覽 + 架構決策 + 範圍 / 語意 | 2697–2740 | 2459–2491（現況基準 + 新增/異動檔） | 868–871 |
| 13-A 棍 stun + 敵人 AI 骨架 | 2741–2748（子階段表） | 2492–2500 | 872–877 |
| 13-B 繞後格式化（限機器） | 2741–2748（子階段表） | 2501–2509 | 878–883 |
| 13-C 人類分支（不格式化） | 2741–2748（子階段表） | 2510–2516 | 884–888 |
| 13-D 輸 = 岔線（無 Game Over） | 2741–2748（子階段表） | 2517–2523 | 889–892 |
| 13-E 原型床 `combat_proto` | 2741–2748（子階段表） | 2524–2528 | 893–897 |
| 13-F 觸控 Attack 鈕 | 2741–2748（子階段表） | 2529–2534 | 898–901 |
| 13 驗收性質 / 回歸 | 2752–2753 | 2535–2540 | 902–905 |

Phase 12 待生 / 待寫：`project.godot` `jump` action；`player.gd` 跳躍狀態；`player` SpriteFrames `jump` 動畫；`scripts/components/ledge_area.gd` / `jump_gap.gd`；`scenes/levels/jump_proto`；TouchControls `BtnJump`。
Phase 13 待生 / 待寫：`project.godot` `attack` action；`melee_stick.gd` / `enemy_base.gd` / `machine_enemy.gd` / `human_enemy.gd` / `format_reset.gd` / `combat_loss.gd`；`player` SpriteFrames `attack` 動畫；`scenes/levels/combat_proto`（隧道清潔機）；TouchControls `BtnAttack`。

### Phase 14 子階段（三份對照）

> 行號以 2026-06-20 Phase 14 gate 修正版為準；大幅改寫後需校正。Phase 14 = Act 1 主線鉤子，複用既有平民區，不新建場景、不新增美術 / 立繪 / 音圖。14-C 定案：店控未修好首談時先播阿達誤認鉤，gate = `mem_frag_linfei_1 AND not ada_misrecognized`，effect 同時設 `ada_misrecognized` + `talked_store_robot`，再回既有 babble。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 14 總覽 + 拍板決策 + 旗標 | 2755–2765 | 2585–2627（現況基準 + 新增/異動檔 + canonical 旗標） | 906–907 |
| 14-A 林霏碎片① `memory_fragment_area` | 2768（子階段表） | 2629–2640 | 910 |
| 14-B 鹿 / 晚一次性鉤 | 2769（子階段表） | 2642–2654 | 911–912 |
| 14-C 阿達①店控首談前置誤認 | 2770（子階段表） | 2656–2673 | 913 |
| 14-D 回歸 + 存讀檔 + GUI | 2771–2773 | 2669–2673 | 914–921 |

Phase 14 已完成 / 已驗證：`scripts/components/memory_fragment_area.gd`；`apartment_entrance.tscn` 擺 `memory_fragment_area`；`game_state.gd` 新旗標與 `STORY_MESSAGES["mem_frag_linfei_1"]`；`data/dialogue/lu_qichen.gd` / `wan.gd` / `store_robot.gd` 三條鉤；`tests/manual/test_runner.gd` 14-A~D headless 護欄。

### Phase 15 子階段（三份對照）

> 行號以 2026-06-21 場景切分（split）改寫版為準；大幅改寫後需校正。Phase 15 = Act 2 場景骨架，15-A~15-D 已完成。**場景切分**：每地點切兩室＝**4 個 scene_id**（地鐵 `subway_station` 大廳 / `subway_station_platform` 月台；聚落 `underground_settlement` 左 / `underground_settlement_right` 右），由場景內 `InteractableArea` 互轉。
> 規格書 Phase 15 採「目的 + 不暫代硬規則 + 子階段表」整段式（無每子階段獨立段），故子階段列的規格書欄指子階段表（2781–2784）對應列；測試指南 Phase 15 為扁平 checklist（923–933），子階段列指對應勾項。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 15 總覽 + 場景切分 + 不暫代 + 現況基準 + 新增/異動 + 旗標 | 2775–2780・2786 | 2675–2744 | 923–924 |
| 15-A 地鐵站兩室（大廳 / 月台）+ 街道接入 + 轉場 | 2781（表列） | 2745–2756 | 925–927 |
| 15-B 地下道聚落兩室（左 / 右）+ `reached_settlement` | 2782（表列） | 2757–2767 | 928–929 |
| 15-C 四室 final flavor + 真掛點預留 | 2783（表列） | 2768–2772 | 930–931 |
| 15-D 回歸 + 存讀檔 + 全鏈雙向轉場 + GUI | 2784（表列） | 2773–2778 | 932–933 |
| 新場景 / SceneRegistry 4 室總表 | — | 2880–2891 | — |

Phase 15 已完成：`scenes/levels/subway_station/`（`subway_station` + `subway_station_platform` 各 .tscn+.gd）、`scenes/levels/underground_settlement/`（`underground_settlement` + `underground_settlement_right` 各 .tscn+.gd）；`scenes/main/main.gd` SCENES 註冊 4 scene_id + `apartment_entrance` 補 `from_subway`；`scripts/autoload/save_system.gd` 4 新 scene_id 顯示名；`data/dialogue/travel_street_west.gd`（街道最左端）加「地鐵站」目的地（gate＝`lu_hinted_topside`；east 端 `travel_street_east.gd` → `collector_shop`）；`tests/manual/test_runner.gd` Phase 15 split 路由護欄。**已交付素材**：美術 4 圖 `assets/generated/maps/subway_station/`（concourse+platform）/ `.../underground_settlement/`（left+right）；BGM `assets/bgm/The Last Platform.mp3`（地鐵）/ `The Deleted Still Breathe.mp3`（聚落）。場景設計檔 `subdocs/地點/地鐵站.md` / `地下道聚落.md`（已隨 split 對齊）。自動測試與 GUI 實機走查已完成。

### Phase 16 子階段（三份對照）

> 行號以 2026-06-21 Phase 16 實作規格寫入版為準；大幅改寫後需校正。Phase 16 = 三張臉 NPC 落地（小岑 / 伍姐 / 七號），沿用 Phase 5 對話系統（無新系統）。**已完成：headless 自動測試 PASS（2026-06-21，16-A~D）+ 真機 GUI 走查（16-E）驗收完成（2026-06-22，✅）。**
> 規格書 Phase 16 為「目的 + 三前提 + 旗標 + 子階段表」整段式（無每子階段獨立段），故子階段列的規格書欄指子階段表（2803–2807）對應列；測試指南為 headless + GUI 扁平 checklist。
> **人設 / 外觀 / 對話定稿草案 / 旗標事實來源**：`subdocs/人/三張臉.md`；NPC 站位（真掛點）：`subdocs/地點/地下道聚落.md`；敘事因果：`subdocs/主線/雨還沒停v2.3.md` §4.2 / §4.1.1。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 16 總覽 + 三前提 + 旗標 + 站位 | 2788–2801 | 2779–2827（總覽 / 三前提 / 現況基準 / 新增異動 / 旗標）| 935–937 |
| 16-A 小岑 `cen`（左室帳篷群）| 2803（表列）| 2828–2839 | 938–948（headless）/ 949–955（GUI）|
| 16-B 伍姐 `wu`（C 版不具名）| 2804（表列）| 2840–2850 | 938–948 / 949–955 |
| 16-C 七號 `seven`（鋪墊鉤不提妹妹）| 2805（表列）| 2851–2860 | 938–948 / 949–955 |
| 16-D DialogueDB 註冊 + 路由 + 立繪掛接 + 回歸 | 2806（表列）| 2861–2872 | 938–948 |
| 16-E GUI / 觸控走查 | 2807（表列）| 2873–2879 | 949–955 |

Phase 16 已落地（2026-06-21）：`data/dialogue/cen.gd` / `wu.gd` / `seven.gd`（3 對話樹）；`data/dialogue/dialogue_db.gd` preload + TREES 加三 id；`underground_settlement.tscn` 加 `NpcCen`（帳篷群）；`underground_settlement_right.tscn` 加 `NpcWu`（淨水站前）+ `NpcSeven`（深隧道口）；`tests/manual/test_runner.gd` Phase 16 護欄（16-A~D headless PASS）。新旗標 `met_cen` / `met_wu` / `met_seven` / `knows_settlement_had_maker` / `seven_hinted_name_topside` 走既有 story_flags 存讀檔（`game_state.gd` 不需改）；`affinity_cen` / `affinity_wu` / `affinity_seven` target 已登錄（trust adapter 不需改）。**美術交付**：6 張立繪 / 角色圖（`三張臉.md` §5），未到位前 placeholder 不卡對話邏輯驗收。

### Phase 17 子階段（三份對照）

> 行號以 2026-06-21 Phase 17 實作規格寫入版為準；大幅改寫後需校正。Phase 17 = Act 2A 記憶碎片 + 殘響鋪設，**全程複用既有組件（無新系統）**：記憶碎片複用 `MemoryFragmentArea`（Phase 14）、聚落殘響複用 `EchoPoint` + `EchoDB`（Phase 9）；規格 / 契約 / 測試清單已展開到可實作（📐）；程式未開工。
> 規格書 Phase 17 為「目的 + 前提 + 旗標 + 內容方向 + 子階段表」整段式（無每子階段獨立段），故子階段列的規格書欄指子階段表（2832–2834）對應列；測試指南為 headless + GUI 扁平 checklist。
> **敘事事實來源**：`subdocs/主線/雨還沒停v2.3.md` §7.1（Act 2 拆段）/ §10（每幕一條殘響）/ §4.2（黑戶網）；**真掛點**：`subdocs/地點/地鐵站.md`（通勤螢幕碎片錨）/ `subdocs/地點/地下道聚落.md`（右室殘響點）。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 17 總覽 + 前提 + 旗標 + 內容方向 | 2811–2830 | 2880–2918（總覽 / 前提 / 現況基準 / 新增異動 / 旗標）| 956–958 |
| 17-A 記憶碎片「你以前往上通勤」 | 2832（表列）| 2919–2924 | 959–967（headless）/ 968–973（GUI）|
| 17-B 聚落殘響採集點（複用 EchoPoint）| 2833（表列）| 2925–2930 | 959–967 / 968–973 |
| 17-C 回歸 + 存讀檔 | 2834（表列）| 2931–2939 | 959–967 |

Phase 17 待寫 / 待掛：`data/echoes/echo_db.gd` 加 `echo_settlement_erased`（1–2 segment）；`game_state.gd` `STORY_MESSAGES` 加 `mem_frag_commute_topside` 文字（**僅資料常數，無邏輯改動**）；`subway_station_platform.tscn` 加 `MemoryFragmentArea`（通勤螢幕 / 月台錨）；`underground_settlement_right.tscn` 加 `EchoPoint`（右室底噪 / 發電一帶，避開七號 / 伍姐 / P18 入口）；`tests/manual/test_runner.gd` Phase 17 護欄。新旗標 `mem_frag_commute_topside` 走既有 story_flags、採集進度 `echo_settlement_erased` 走既有 `echo_progress`（`game_state.gd` 邏輯不需改）。**可選後置**：殘響 `image_path` / `audio_path` 媒體層（不卡 headless，可委製）。**前提硬規則**：碎片不揭主角身份；聚落殘響不得是林霏 / 阿達、segment 不含「林霏」。

### Phase 18 子階段（三份對照）

> 行號以 2026-06-21 Phase 18 實作規格寫入版為準；大幅改寫後需校正。Phase 18 = Act 2B 戰鬥遭遇 + 回執取得，**複用 Phase 13 戰鬥組件作者化進真動線（無重造戰鬥機制）**；新增 1 戰鬥場景 `tunnel_combat` + 1 ITEMS_DB key item + 兌現 `combat_mode` gate + 晚賣回執對話分支；規格 / 契約 / 測試清單已展開到可實作（📐）；程式未開工。
> 規格書 Phase 18 為「目的 + 前提 + 旗標 + 子階段表」整段式，子階段列的規格書欄指子階段表（2854–2857）對應列；測試指南為 headless + GUI 扁平 checklist。
> **敘事事實來源**：`subdocs/主線/雨還沒停v2.3.md` §4.2.1（回執本質 / 表面 / 把關）/ §4.2.2（賣給晚）/ §7.1（2B 拆段）；**真掛點**：`subdocs/地點/地下道聚落.md`（右室 `deep_tunnel`＝戰鬥入口）；**前瞻契約**：`開發設計方針.md > 戰鬥場景互動契約（Phase 18，前瞻契約）`（`combat_mode` gate + E 優先鏈）。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 18 總覽 + 前提 + 旗標 | 2838–2852 | 2940–2984（總覽 / 前提 / 現況基準 / 新增異動 / 旗標）| 974–976 |
| 18-A 隧道清潔機遭遇（作者化 13-E）| 2854（表列）| 2985–2991 | 977–985（headless）/ 986–992（GUI）|
| 18-B 戰後探索 + 回執取得 | 2855（表列）| 2992–2998 | 977–985 / 986–992 |
| 18-C 回執賣給晚（鎖死和平線）| 2856（表列）| 2999–3005 | 977–985 / 986–992 |
| 18-D 回歸 + 存讀檔 | 2857（表列）| 3006–3015 | 977–985 |

Phase 18 待寫 / 待掛：`scenes/levels/tunnel_combat/tunnel_combat.tscn` / `.gd`（自 combat_proto 收斂；Player `combat_mode=true`；walker_01 一台；失物物流箱 InteractableArea；出口回右室）；`underground_settlement_right.gd` / `.tscn` `deep_tunnel` 改 `transition_to("tunnel_combat","from_settlement")` + 加回程 entry point `from_deep_tunnel`；`game_state.gd` ITEMS_DB 加 `childcare_supply_receipt`；`dialogue_runner.gd`（如缺）補 add_credits / adjust_affinity effect op；晚對話檔加「賣回執」分支；`player.gd` `combat_mode` gate + E 優先鏈（兌現前瞻契約）；`tests/manual/test_runner.gd` Phase 18 護欄。SceneRegistry 加 `tunnel_combat`（`can_save_here=false`）。**可選後置**：回執 icon / 隧道清潔機專屬圖 / 戰鬥區背景（placeholder 不卡邏輯）。**前提硬規則**：回執表面＝雜物、不揭七號 / 妹妹 / 林霏；無 Game Over；格式化＝停機不死。

### Phase 19 子階段（三份對照）

> 行號以 2026-06-24 Phase 19 實作規格寫入版為準；大幅改寫後需校正。Phase 19 = Act 2C 阿達罪責（②阿達殘響 + ③舊善後工單 + 收束碎片），**全程複用既有組件（`EchoPoint`/`EchoDB`、`MemoryFragmentArea`、examine），落 Phase 15 已建的聚落左室 `underground_settlement`**；唯三處小擴充（`EchoDB` 加 `trace_on_collect` + `collect_echo_segment` 兌現留→Trace↑、`MemoryFragmentArea` 加 `require_flag` gate、左室 controller 加一條 examine 分派）；規格 / 契約 / 測試清單已展開到可實作（📐）；程式未開工。
> 規格書 Phase 19 為「目的 + 前提 + 旗標 + 內容方向 + 子階段表」整段式，子階段列的規格書欄指子階段表對應列；測試指南為 headless + GUI 扁平 checklist。
> **敘事事實來源**：`subdocs/主線/雨還沒停v2.3.md` §3（罪責四段式 ②③，③鎖 2C）/ §7.1（2C 拆段）；**真掛點**：`subdocs/地點/地下道聚落.md`（左室殘響 / 工單 / 碎片掛點，待補）。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 19 總覽 + 前提 + 旗標 + 內容方向 | 2861–2893 | 3017–3037（總覽 / 前提 / 現況基準）| 993–1015 |
| 19-A 阿達殘響②（`trace_on_collect`）| 2884（表列）| 3038–3043 | 997–999（headless）/ 1009–1015（GUI）|
| 19-B 舊工單③ examine + 取得 `old_work_badge` | 2885（表列）| 3044–3055 | 1000–1002 / 1009–1015 |
| 19-C 收束碎片 + `require_flag` gate | 2886（表列）| 3056–3061 | 1003–1004 / 1009–1015 |
| 19-D 回歸 + 存讀檔 | 2887（表列）| 3062–3072 | 1005–1006 |

依賴：18（Act 2B）、17（碎片 pattern + 媒體層慣例）、14（碎片旗標）、9（`EchoPoint`/`EchoDB`/`echo_progress`/拾遺手套/收購）、11-C（`add_trace` + 賣→Trace↓；本 Phase 兌現「留→Trace↑」）、16-A（左室小岑站位避讓）。`old_work_badge` 既有 ITEMS_DB 定義由本 Phase 接上首個取得點（M1 進度頁不追蹤此道具，無影響）。

### Phase 20 子階段（三份對照）

> 行號以 2026-06-25 Phase 20 實作規格寫入版為準；大幅改寫後需校正。Phase 20 = Act 2D 七號可選 + 和平線 Branch D，**不新增場景、不新增系統**，沿用 Phase 16 七號對話樹 + Phase 18 回執 + Phase 11 Trust/Trace；規格 / 契約 / 測試清單已展開到可實作（📐）；程式未開工。
> 規格書 Phase 20 為「目的 + 硬規則 + 旗標 / 資料 + 內容方向 + 子階段表」整段式，子階段列的規格書欄指子階段表對應列；測試指南為 headless + GUI 扁平 checklist。
> **敘事事實來源**：`subdocs/主線/雨還沒停v2.3.md` §4.2.1（回執真正用途）/ §4.2.3（和平成功線）/ §7.1（2D 拆段）；**真掛點**：`subdocs/地點/地下道聚落.md`（右室七號站位）。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 20 總覽 + 前提 + 旗標 + 內容方向 | 2894–2914 | 3073–3102（總覽 / 前提 / 現況基準 / canonical 旗標）| 1016–1037 |
| 20-A 七號對話加和平入口 | 2917（表列）| 3104–3121 | 1019–1029（headless）/ 1031–1037（GUI）|
| 20-B 交還回執 + Branch D | 2918（表列）| 3123–3137 | 1019–1029 / 1031–1037 |
| 20-C 未處理延燒到 Phase 24 | 2919（表列）| 3139–3143 | 1019–1029 |
| 20-D GUI / 純觸控走查 | 2920（表列）| 3145–3152 | 1031–1037 |

依賴：18（`childcare_supply_receipt` / `peace_line_locked`）、16（七號 / `affinity_seven` / `seven_hinted_name_topside`）、11（Trust/Trace）。待寫 / 待掛：`data/dialogue/seven.gd` Phase 20 交還入口與成功 / 錯誤路線；`tests/manual/test_runner.gd` Phase 20 護欄。新 canonical 旗標 `seven_peace_branch_d`（D 成功）與 `seven_betrayal_pending`（Phase 24 初始化用）；Phase 20 錯誤對話不設 pending，避免過早鎖死。**前提硬規則**：稀有恩典不加路標；妹妹永不登場；七號不洗白；賣回執永久鎖死 D。

### Phase 21 子階段（三份對照）

> 行號以 2026-06-25 Phase 21 合併規格寫入版為準；大幅改寫後需校正。Phase 21 = Act 3 夜總會 + 林霏核心殘響 + 主題歌整合（**原 Phase 21 主題歌 + 原 Phase 22 夜總會 / 林霏殘響合併；Phase 22 編號保留不再使用，23~31 不變**）；📐 規格可實作，程式未開工。
> **唯一系統擴充**：EchoDB/EchoPoint 媒體分段門檻解鎖（半收集→女聲歌、全收集→照片），其餘純複用 Phase 9 / 10 / 14。**結構先行**（21-A~C 無素材依賴）、**素材後掛**（21-D/E）；素材一律 user 提供、不暫代。
> **敘事事實來源**：`subdocs/主線/雨還沒停v2.3.md` §4.1（林霏核心殘響台詞）。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 21 總覽 + 依賴 + blocker | 2924–2939 | 3154–3183（總覽 / 前提 / 現況基準 / canonical 旗標）| 1039–1047 |
| 21-A 夜總會場景骨架 + 轉場 | 2930（表列）| 3184–3190 | 1040 |
| 21-B 林霏核心殘響 + 分段媒體 | 2931（表列）| 3191–3197 | 1041–1042 |
| 21-C 收束碎片「黑戶藏身方式」 | 2932（表列）| 3198–3203 | 1043 |
| 21-D 女聲主題歌掛載 | 2933（表列）| 3204–3208 | 1044 |
| 21-E 《雨還沒停》環境母題 | 2934（表列）| 3209–3213 | 1045 |
| 21-F 可賣 + 回歸 + 存讀檔 | 2935（表列）| 3214–3220 | 1046–1047 |

依賴：17（殘響系統）、14（碎片旗標）、9（`EchoPoint`/`EchoDB`/`echo_progress`/採集/收購）、11-C（賣→Trace↓）、10（ducking / Ambient bus）。新 canonical：`echo_linfei`（分段媒體 + 可賣）、`mem_frag_hideout`、`sold_linfei_echo`（**forward-契約**：Phase 26~28 結局讀此改少數台詞）。**外部 blocker（user 提供新素材，不暫代）**：**已全數到貨**（2026-06-27）——夜總會背景美術 3 圖（`assets/generated/maps/nightclub/`）、BGM 兩軌（前區 `nightclub-1.mp3` / 後場 `nightclub-2.mp3`）、林霏女聲主題歌（`echo_linfei_song.mp3`）、林霏殘響照片（`echo_linfei.jpeg`），待 21-D/E 接線。剩餘僅 g2d 可生的保全 NPC / bar_bot 圖（非 user blocker）。**《雨還沒停》非 blocker**——複用既有 `echo_song_rain_doesnt_stop.mp3`（21-E）。

### Phase 23 子階段（三份對照）

> 行號以 2026-06-27 Phase 23 規格寫入版為準；大幅改寫後需校正。Phase 23 = Act 3 夜總會保全四解小解謎（戰鬥② 智取版）；📐 規格可實作，程式未開工。**不新增場景**（沿用 Phase 21 三場景），把門面廳 `back_door` 無條件門改造成四解（賄賂 / 假裝身份 / 引開 / 潛行）殊途同歸 set `passed_nightclub_security`。
> **唯一系統擴充**：DialogueRunner 補 `credits` condition type（最小 op）；引開 / 潛行 transient（`_bodyguard_off_post`）不存檔。其餘純複用 Phase 8 經濟 / Phase 13-C 人類分支精神 / 既有 examine + add_item 防呆。
> **場景設計事實來源**：`subdocs/地點/夜總會.md > 保全解謎`（四解機制 / 旗標 / 真掛點）。**範圍更正（2026-06-27）**：原規格書 23 表「人類保全潛行 / 撐過（13-C）」為舊薄殼，已改寫；不做 13-C 式戰鬥。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 23 總覽 + 前提 + 旗標 | 2941–2959 | 3277–3309（總覽 / 前提 / 現況基準 / canonical 旗標）| 1051–1053 |
| 23-A 場景接線骨架（保全 NPC / `back_door` gate / 工牌 item）| 2961（表列）| 3310–3336 | 1054–1069（headless）/ 1070–1077（GUI）|
| 23-B 保全對話樹（賄賂 + 假裝身份）+ `credits` condition | 2962（表列）| 3337–3369 | 1054–1069 / 1070–1077 |
| 23-C 引開→潛行 transient（兩步組合）| 2963（表列）| 3370–3376 | 1054–1069 / 1070–1077 |
| 23-D 回歸 + 存讀檔 + GUI / 觸控走查 | 2964（表列）| 3377–3388 | 1054–1069 / 1070–1077 |

依賴：21（夜總會三場景 / `back_door` / `echo_linfei` 後場房 / 已備料旗標 `passed_nightclub_security`·`found_staff_pass` 與保全 / bar_bot 立繪）、13-C（人類不可格式化分支精神）、8（賄賂複用 credits 經濟）、11-C（四解皆不動 Trace）。新 canonical：`passed_nightclub_security`（四解殊途同歸）/ `found_staff_pass`（假裝身份 gate）/ `nightclub_staff_pass`（ITEMS_DB key item，與 `old_work_badge` 為不同物件）。**無外部素材 blocker**（立繪 / 美術 / BGM 已到貨；唯工牌 icon 由實作者自製）。**前提硬規則**：保全人類不可打死 / 格式化；大門口閘門無 Trace 無代價；工牌不點名七號 / 林霏 / 妹妹；引開 / 潛行 transient 不存檔。

### Phase 24 子階段（三份對照）

> 行號以 2026-06-27 Phase 24 規格寫入版為準；大幅改寫後需校正。Phase 24 = Act 3→4 七號小爆點（三分支 quest）；📐 規格可實作，程式未開工。三分支（D 和平 / A 攔下 / B 部分攔下，**無 C / 不做大災難線**）由旗標確定性計算，可 headless 重現。
> **新場景**：`tunnel_chase`（房間1）+ `tunnel_chase_right`（房間2）＝深隧道追逐限時選門迷宮（2026-06-28 重設計，取代原單室跳躍翻越版；梯子沿用 Phase 7-F 防火梯 climb、窄 gap 用 Phase 12 跳躍）；**新對話**：`travel_deep_tunnel`（深隧道口兩去處選單，沿用 `travel` op）。深隧道口爆點前直通 `tunnel_combat`、爆點後出選單，**不取代既有 Phase 18 戰鬥區入口**。
> **敘事事實來源**：`subdocs/主線/雨還沒停v2.3` §7.2（七號事件三分支）。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 24 總覽 + 前提 + 旗標 + 公式 | 2968–3020 | 3392–3428（總覽 / 前提 / 現況基準 / canonical 旗標）| 1078–1079 |
| 24-A quest 化 + 爆發 gate | 3021（表列）| 3429–3447 | 1081–1082 |
| 24-B 分支判定 + 伍姐 / 小岑提前警告 | 3022（表列）| 3448–3459 | 1083–1084 |
| 24-C 深隧道追逐 + 兩去處選單接線 | 3023（表列）| 3460–3490 | 1085–1087 |
| 24-D Branch B 代價（小岑暴露演出）| 3024（表列）| 3491–3496 | 1088 |
| 24-E 回歸 + 存讀檔 | 3025（表列）| 3497–3509 | 1089–1093 |

依賴：20（和平線前置 / `seven_peace_branch_d` / `seven_betrayal_pending` / `affinity_seven`）、23（`passed_nightclub_security` ＝ Act 3→4 爆發 gate）、12（跳躍動詞）、7（攀爬 + `from_deep_tunnel` 往返）、16（七號 / 伍姐 / 小岑 NPC 與 affinity）、9-C（`travel` 目的地選單 pattern）、11-B（`get_trust`）、11-C（`get_trace`）。新 canonical：`seven_betrayal_triggered` / `seven_stopped_full`(A) / `seven_stopped_partial`(B，餵 26-D)/ `cen_voiceprint_exposed`(餵 28-C)/ `deep_tunnel_opened` / `tunnel_chase_true_exit`(int，reset 骰一次存讀檔固定)。**外部素材：已全數到貨（2026-06-28）**——`tunnel-chase-left/right.png` + 七號攤牌情境圖。**系統小擴充**：`TRACE_BETRAYAL_THRESHOLD` 常數（建議放 `seven_betrayal.gd`）+ 追逐關全域倒數/通話接通 % UI（複用 23-C）+ 攤牌情境圖 overlay（複用 23-C）+ `tunnel_chase_true_exit` 隨機骰於 reset，其餘純複用既有 quest / dialogue / travel / 移動系統。**前提硬規則**：無 C 分支 / 不做大災難線；七號人類不可殺 / 格式化；小岑代價純敘事（無 minigame）；D 窗口只在 Phase 20。

### Phase 25 子階段（三份對照）

> 行號以 2026-06-28 Phase 25 規格寫入版為準；大幅改寫後需校正。Phase 25 = Act 4 備份區三場景骨架 + 戰鬥③（跑到門）；✅ 25-A~C 已完成（headless PASS，commits `9ec5bad` / `97fb782` / `4dcb28b` + 驗證修補 `c620ba5`；GUI / 純觸控走查完成，2026-07-02）。純複用既有系統（travel / interactable / scene router / Phase 13 戰鬥），唯一新做＝人類保全最小追擊 AI；**無新存讀檔欄位**（gate 全讀既有旗標 / 物品）。
> **新場景**：`datacenter_entrance`（anchor-05）/ `datacenter_backup`（戰鬥③）/ `datacenter_backup_core`（核心＝結局觸發掛點佔位，26-D 才接）。**入口**：`nightclub_entrance` travel「AI 資料中心」。**敘事事實來源**：`subdocs/主線/雨還沒停v2.3` §7（Act 4）+ §6 + §8。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 25 總覽 + 三場景 + travel gate + 門禁 + 子階段表 | 3039–3074 | 3521–3586（核心 / 場景 / 動線 / 門禁 / 戰鬥 / 存讀檔 / 素材）| 1100–1114 |
| 25-A 三場景骨架 + travel + 門禁 + 核心掛點 | 3039（子階段表）| 3526–3559（場景 + 入口動線 + 門禁 gate）| 1102–1106 |
| 25-B 戰鬥③（混合敵人 / 跑到門）| 3039（子階段表）| 3560–3568（戰鬥③）| 1107–1109 |
| 25-C 回歸 + 存讀檔護欄 | 3039（子階段表）| 3569–3586（存讀檔 / test_runner / 素材）| 1110–1114 |

依賴：13（戰鬥組件 / 機器格式化 / 人類不可殺）、24（Act 3→4 終端旗標＝travel gate）、23（`passed_nightclub_security`）、19-B（`read_old_work_order` 門禁前置→自動成 Act 4 硬前置）、9-C（`travel` 目的地選單）、21（anchor-05 / `nightclub_entrance` 入口）。canonical（**皆既有、無新增**）：`old_work_badge`（公寓開場 key item，不可丟 / 不可賣）/ `read_old_work_order` / `passed_nightclub_security` / `seven_peace_branch_d` / `seven_stopped_full` / `seven_stopped_partial`。**外部素材（blocker，你方提供）**：`datacenter_backup` / `datacenter_backup_core` 兩張 map 圖、機器哨兵 + 人類保全 sprite、Act 4 專屬 BGM；`datacenter_entrance` 用既有 anchor-05。**前提硬規則**：人類保全不可打死 / 格式化；無 Game Over / 無失敗岔線；不碰 Phase 26 演出 / 結局；不動 Trace。

### Phase 26 子階段（三份對照）

> 行號以 2026-07-02 Phase 26 規格寫入版為準；大幅改寫後需校正。Phase 26 = Act 4 演出（阿達④ / 晚拉扯）+ 真相碎片 + 結局觸發點武裝；✅ 已完成（headless PASS，commits `2bc4da7` / `003db3b` / `d31f4a0`）。**零新系統**（對話 5/16、`MemoryFragmentArea` 14、examine 條件變體 19、自動觸發 Area2D 全複用）、**零新存讀檔 schema**（4 旗標全走 story_flags）；三結局路由本體＝27-B，本 Phase 不寫結局分支 / 不開選單 / 不碰 Trace。
> **無新場景**（全掛 Phase 25 三場景；`datacenter_backup` 戰鬥③不動）。**敘事事實來源**：`subdocs/主線/雨還沒停v2.3` §4.3（晚拉扯拍板台詞）+ §3（四段式④拍板台詞）+ §7（Act 4 碎片）+ §8（共用觸發點）+ §7.2（Branch B）。規格 2026-07-02 討論定案，同日拍板 v2.3 §12 開放問題 5（Branch B 檔案重標記＝core 檔案索引終端、小岑具體＋其餘不具名）。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 26 總覽 + 節拍動線 + 子階段表 | 3075–3103 | 3587–3662（核心 / 佈點 / 26-A~D / 旗標 / i18n / test_runner）| 1115–1126 |
| 26-A 晚拉扯 | 3089（子階段表）| 3603–3610 | 1118 |
| 26-B 阿達④ | 3090（子階段表）| 3611–3617 | 1119 |
| 26-C 真相碎片 | 3091（子階段表）| 3618–3623 | 1120 |
| 26-D 觸發點武裝 + Branch B 檔案重標記 | 3092（子階段表）| 3624–3637 | 1121–1122 |
| 26-E 回歸 + 存讀檔（test_runner）| 3093（子階段表）| 3655–3662 | 1123–1126 |

依賴：25（三場景 + 核心佔位 + BGM 已接）、24（`seven_stopped_partial`）、19-B（`read_old_work_order`）、5/16（對話系統 + NPC 掛法）、14（`MemoryFragmentArea`）、19（examine 條件變體 pattern）。新 canonical（皆 bool / story_flags）：`wan_act4_pull_seen` / `ada_final_words_seen` / `mem_frag_chose_deletion` / `stood_before_own_backup`（**forward 契約：27-B 三結局路由掛點**）。**外部素材（唯一缺口，g2d 可生、非 user blocker）**：阿達世界 sprite（idle，離場 fade 不需 walk）＋對話立繪，26-B 動工前補。**前提硬規則**：不碰 Trace；不寫結局分支 / 不開結局選單；④不得早於③；私心版不設 affinity 門檻；Branch B 小岑具體、其餘不具名、不點名伍姐／七號／林霏。

### Phase 27 子階段（三份對照）

> 行號以 2026-07-03 Phase 28 規格寫入後重校版為準；大幅改寫後需校正。Phase 27 = 地下廣播站 + 三結局路由 + 清洗閘兌現；**27-A / 27-B ✅ 已完成，27-C / 27-D 📐 規格可實作、程式未開工**。**1 新場景**（`broadcast_station`，Expose 唯一出口、單向、可存檔、無 NPC）、**1 系統小擴充**（DialogueRunner `echo_count` condition，23 補 `credits` 同例）、**零新存讀檔 schema**（5 旗標全走 story_flags）。A/B/C 判定與 Trace 臨界值＝Phase 29；結局演出＝Phase 28/29；**本 Phase 不碰 Trace**。
> **敘事事實來源**：`subdocs/主線/雨還沒停v2.3` §8（三結局共用觸發點 + Expose 清洗）+ §6（清洗定義）+ §4.1（名字不對稱）。規格 2026-07-02 討論定案，同日拍板 v2.3 §12 開放問題 1（地下廣播站升正式場景）與 3（Reclaim / Protect 不硬鎖，三選無條件全開）。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 27 總覽 + 路由規則 + 節拍 + 子階段表 | 3105–3141 | 3663–3737（核心 / 27-A~C / 旗標 / i18n / test_runner）| 1128–1138 |
| 27-A `broadcast_station` 場景 | 3128（子階段表）| 3668–3675 | 1131 |
| 27-B 三結局路由（三選對話＋存檔提示拍） | 3110–3116（節拍）+ 3129 | 3676–3702 | 1132–1134 |
| 27-C 清洗閘五拍 | 3118–3124（五拍）+ 3130 | 3703–3713 | 1135 |
| 27-D 回歸 + 存讀檔（test_runner）| 3131（子階段表）| 3732–3737 | 1136 |

依賴：26（`stood_before_own_backup` 觸發點武裝）、5/16（對話系統）、24（`travel` effect op / `seven_stopped_partial`）、4-E（entry point 演出）、9（`echo_progress` 計數）、11（清洗概念自 11-D 移入）。新 canonical（皆 bool / story_flags）：`ending_route_reclaim` / `ending_route_protect` / `ending_route_expose`（**互斥**，27-B 確認拍寫入；下游 28-A / 28-B / 29）＋ `expose_upload_cleaned` / `expose_upload_done`（27-C 鎖點寫入；29-A/B 分界 / 判定觸發）＋ `ending_save_hint_seen`（27-B 存檔提示一次性去重，2026-07-03 拍板回補）。**外部素材：已全數到貨（2026-07-02）**——map（`assets/generated/maps/broadcast_station/broadcast_station-20260702-234241.png`）＋ 廣播站 BGM 新軌（`assets/bgm/The Yellow Light Tape.mp3`，user 委製）；無剩餘 blocker。**前提硬規則**：三選無條件全開；選定即鎖、確認拍前皆可退開；名字不再露出（26-D 已露一次）；清洗＝單一 bool 不可逐項檢視；不碰 Trace / 不做 A/B/C 判定 / 不做結局演出；台詞補白實作時定稿。

### Phase 28 子階段（三份對照）

> 行號以 2026-07-03 Phase 28 規格寫入版為準；大幅改寫後需校正。Phase 28 = Reclaim + Protect 結局演出；📐 規格可實作，程式未開工（依賴 27 先行）。**零新場景、零系統擴充、零新存讀檔 schema**（2 旗標走 story_flags）；腳本化單向序列（站間自動 travel、玩家不自由走動、全程禁存）；染色只落 Reclaim（`trace` / `affinity_wan` 各兩檔共四版文字）、Protect 拍板台詞固定。共用收尾（雨＋歌＋橙）＝30-A；Expose＝29；**Trace 只讀不寫**。
> **敘事事實來源**：v2.3 §8（＋2026-07-03 加註：小岑台詞舞台化改句「車要來了欸」、「上行線復駛」背景事件；後日談點子記 §12-6）。規格 2026-07-03 討論定案（序列形態 / 存檔提示 / R 序列 / P+C 序列 / 染色範圍 / 存檔語意 六題拍板）；同日拍板回補 27-B 存檔提示拍（`ending_save_hint_seen`）。

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） |
|---|---|---|---|
| Phase 28 總覽 + 序列規則 + 兩序列節拍 + 子階段表 | 3143–3177 | 3739–3797（序列控制 / 28-A~C / 旗標 / i18n / test_runner）| 1140–1148 |
| 28-A Reclaim 三站（灌回＋訣別＋痕跡） | 3148–3152（節拍）+ 3164 | 3756–3761 | 1143–1144 |
| 28-B Protect 主體（刪除＋晚固定拍） | 3154–3162（節拍）+ 3165 | 3762–3767 | 1145 |
| 28-C 小岑條件式回收（中間站分岔＋復駛） | 3157–3159（節拍）+ 3166 | 3768–3774 | 1146 |
| 28-D 回歸 + 存讀檔（test_runner） | 3167（子階段表）| 3790–3797 | 1147 |

依賴：27（`ending_route_reclaim/protect`＋停原地掛點）、26（五枚碎片旗標 / 26-A 自動對話 / 26-B fade）、24（`travel` op / `cen_voiceprint_exposed` / `empty_tent`）、11（`trace` 只讀）、10（`AmbientSubway`）、5/16（對話系統）、4-E（entry point 演出）、2-G（begin_message 序列）。新 canonical（皆 bool / story_flags）：`ending_reclaim_played` / `ending_protect_played`（公寓終站寫入；30-A 共用收尾掛點）。新 epilogue entry points：`apartment_entrance:epilogue_wan` / `subway_station:epilogue_cen` / `underground_settlement:epilogue_settlement` / `apartment:epilogue_home`。**外部素材**：小岑 walk sprite（若既有僅 idle；g2d 可生）＋可選地鐵大廳亮屏 overlay；**非 user blocker**。**前提硬規則**：序列全自動＋全程禁存；Protect 固定台詞不染色；復駛＝世界背景事件（與主角／分支無關、不改聚落安全、僅 Protect not-B 途經可見）；七號不實體登場（30-A 文字帶）；孤兒檔救援（route 已設未 played 強制回 backup_core）；名字不露出；台詞補白實作時定稿。

### Phase M1 子階段（三份對照）

> 行號以 2026-06-28 校正版為準（Phase 25 spec 寫入後重校）；大幅改寫後需校正。Phase M1 = 進度頁（Meta / 非敘事 QoL，純加法，不佔故事編號）；非子階段化，三份文件各為單一整段。規格凍結（2026-06-23），程式已實作並驗證完成（2026-06-24，commit `bd4717f`）。
> **凍結決定**：六分類總數 31（場景10 / NPC6 / 任務3 / 殘響5 / 特殊7）；判定＝曾達成；未解鎖 `???`；整體 %＝跨分類加總 done÷31；新增三集合 + `left_apartment_once` 納入存讀檔，舊檔不 backfill。

| 文件 | 段落 | 行範圍 |
|---|---|---|
| 遊戲規格書.md（驗收意圖） | Phase M1 — 進度頁（目的 / 分類判定表 / 驗收意圖 / 邊界）| 3146–3182 |
| 開發設計方針.md（契約） | Phase M1 — 進度頁（GameState API / 接線點 / UI / 新增異動檔 / 存讀檔）| 3595–3678 |
| 測試指南.md（清單） | Phase M1 進度頁（headless + GUI checklist）| 1153–1175 |

Phase M1 已寫 / 已掛（2026-06-24 完成）：`game_state.gd`（三集合 + 5 白名單常數 + `mark_scene_visited` / `mark_npc_talked` / `_maybe_mark_special_item` / `is_echo_complete` / `get_progress_summary` + `add_item` / `change_item_id` hook + 存讀檔納入）；`main.gd`（`transition_to` 進場 `mark_scene_visited` + 偵測離開公寓 set `left_apartment_once`）；`notebook_panel.gd` / `.tscn`（「進度」分頁 + 總進度 / 分類詳情 + `???` 遮罩）；`game_ui.gd` / 對話接線（對話 start `mark_npc_talked` 白名單）；`tests/manual/test_runner.gd` Phase M1 護欄。**SaveSystem 不需改**（payload 由 `GameState.to_save_dict` 自帶）。**前提硬規則**：純加法不改 Phase 1~18；`old_work_badge` 不列特殊道具（遊戲無取得點）。

### Phase M2 子階段（三份對照）

> 行號以 2026-06-28 校正版為準（Phase 25 spec 寫入後重校）；大幅改寫後需校正。Phase M2 = 多國語系 i18n（Meta / 非敘事 QoL，out-of-band 編號，不佔故事編號）。M2-A~M2-D 已完成並有 headless 護欄（M2-D 含 `data.csv` echoes/shops/quests 前移）；M2-E 僅剩全鏈回歸 + 三語 GUI / 觸控走查 + 真機驗收。
> **凍結決定（2026-06-24 user 拍板）**：三語 `zh_TW`(預設+fallback)/`zh_CN`/`en`；機制＝Godot 原生 `tr()`+CSV；簡中與英文 LLM 獨立翻譯（簡中非 OpenCC）；相容 iOS/Android（字型 runtime 動態切換 + 新增 `NotoSansSC`）；繁中為 fallback；語言偏好存 `user://settings.cfg` 不入存檔槽；對玩家行為純加法。

| 文件 | 段落 | 行範圍 |
|---|---|---|
| 遊戲規格書.md（驗收意圖） | Phase M2 — 多國語系 i18n（目的 / 驗收意圖 / fallback / 前提 / 邊界）| 3183–3226 |
| 開發設計方針.md（契約） | Phase M2 — 多國語系 i18n（LocaleManager / project.godot / 字型切換 / CSV+key 規則 / 顯示端 tr() / 設定頁 / 子階段 / 驗證網 / 異動檔）| 3679–3885 |
| 測試指南.md（清單） | Phase M2 多國語系 i18n（headless + GUI + 真機 checklist）| 1176–1210 |

Phase M2 子階段依賴鏈：**M2-A 基礎建設**（✅ `LocaleManager` autoload / `TranslationServer` 接線 / fallback=zh_TW / `NotoSansSC` runtime 字型切換 / `settings.cfg` / OS locale 偵測 / 最小設定頁）→ **M2-B UI chrome**（✅ 178 處 UI + 12 `.tscn` prompt 抽 key）→ **M2-C 敘事資料**（✅ notes / messages / items）→ **M2-D 對話樹**（✅ 9 樹 + 英文人名音譯對照 + `data.csv` echoes/shops/quests 前移，headless PASS）→ **M2-E 收尾**（📐 全鏈回歸 + 真機 iOS/Android 驗收）。**前提硬規則**：顯示與邏輯分離（goto/effect/condition 用既有 id/flag）；三語禁字（無「林霏」）；缺翻譯退繁中、三語全缺顯示 key；SaveSystem 不改。

### 規格書 — 常引用系統段（跨階段）

| 系統段 | 行範圍 | 主要相關階段 |
|---|---|---|
| 輸入設計 | 27–46 | 全 |
| UI Mode（含 overlay caller 還原 104–130・驗收 131–140） | 47–140 | 2-E |
| 共用 UI 元件（PanelFooterHint 182・ItemDetailModal 216・ConfirmDialog 262） | 141–294 | 2-B／2-D |
| 互動系統 | 295–321 | 2-A／2-D |
| MessageBox | 338–357 | 2-A／2-B／2-E |
| 容器系統 | 358–415 | 2-C／2-D |
| 背包系統 | 416–524 | 2-D（footer E 段） |
| 容器雙欄操作 | 525–652 | 2-C／2-D／2-E |
| GameState（Item Metadata 716・Notes API 759・Container API 875・Signals 988） | 653–1024 | 全 |
| 裝備系統 | 1081–1120 | 2-B |
| 筆記／知識系統・知識解鎖 | 1121–1271 | 2-A／2-B／2-E |

### Phase 1（已收尾，需回查時）

實作細節集中在 `遊戲規格書.md > Phase 規劃`：1-B 1286–1338／1-C 1339–1384／1-D 1385–1437／1-E 1438–1490。系統行為見上方「常引用系統段」。設計方針 / 測試指南自 Phase 2 起新寫，不 backfill Phase 1。

## 測試速查

Godot headless 在目前 Windows / sandbox 環境中，直接 sandbox 執行可能因 `user://logs/godot*.log` 權限 crash。驗證時直接用 elevated 權限跑：

```powershell
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/manual/test_runner.tscn
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . -s res://tests/manual/verify_game_state.gd
```

最近已記錄的 Phase 8 headless 驗證結果（記錄時 HEAD `9ecc0da`）：

```text
test_runner.tscn: PASS
verify_game_state.gd: PASS
```

Phase 8-A~8-H 已完成並有測試覆蓋寫入 `tests/manual/test_runner.gd`。人工對話與買賣系統 GUI / 純觸控走查已完成；最新 為 Windows v0.8.9 build 匯出。本次 brief 同步未重新執行 Godot headless。

`git diff --check` 若只出現 LF -> CRLF warning，屬 Windows autocrlf 提示，不是 whitespace error。

## 規格文件索引

| 文件 | 何時讀 |
|---|---|
| `AGENTS.md` | 新 session 開場；專案規則、工具路徑、驗證 / 修改 / commit 規則 |
| `PROJECT_BRIEF.md` | 快速建立全貌；先讀本檔，再按需求深入 |
| `遊戲概念.md` | 世界觀、玩家定位、都市調性 |
| `技術概念.md` | Godot 選型、MVP 技術方向、平台路線、輸入 / UI / 存檔 / debug 架構決策 |
| `Art Bible.md` | 生圖、角色、場景、item icon、視覺一致性；任何素材工作必讀 |
| `遊戲規格書.md` | 全遊戲通用系統、GameState / UIMode / UI / 背包 / 容器 / Phase 規劃 |
| `開發設計方針.md` | Phase 2 起的實作契約、API、資料欄位、接線規則 |
| `測試指南.md` | Headless 命令、手動驗收清單、Phase 2+ acceptance checklist |
| `subdocs/地點/主角公寓.md` | 公寓場景敘事、互動物、Phase 2 B0-B9 流程、線索文字 |
| `subdocs/人/主角設定.md` | 主角身份、敘事定位、AI 善後員 + 拾遺者設定 |
| `subdocs/人/鹿其琛.md` | 收藏家 NPC：鹿家三少爺、鑑定 / 收購 / 「還」伏筆（Phase 9） |
| `subdocs/地點/收藏家的店.md` | 收藏家的店場景：layout、互動物、暫時通道（Phase 9） |

注意：`舊文件/` 是歷史 archive，除非使用者明確要求，開工時忽略。

## 實作注意事項

- 修改授權：使用者明確說「修 / 修改 / 實作 / 處理 phase / commit / push」才可改檔。
- Verify-only：使用者說「驗證」時只檢查、讀檔、跑測試、回報；不可 patch / stage / commit。
- 文件分工：`開發設計方針.md` 偏 implementer-owned；`測試指南.md` 偏 verifier-owned。若角色不符，只列建議。
- `.claude/` 是 local tooling config，不 commit。
- `舊文件/` 永遠忽略。
- 不要把 `agent-sprite-forge` repo 放進本專案。
- 生圖輸出必須落回 `assets/generated/...`，保留 prompt / raw / processed / metadata。

## 目前已知邊界

- `驗證後已知問題.md` 已建立；`4-F：從街道回公寓時，公寓狀態被重置` 已修復，`8-H：發現販賣機錯誤後缺少「回電腦接案」前置線索筆記` 已修復並驗收完成，目前暫無待修項目。
- `subdocs/地點/主角公寓.md` 底部「已知落差 / 待修」有部分 Phase 1 歷史描述可能已過期；以 `AGENTS.md`、`遊戲規格書.md`、目前 code 與 git log 判斷最新狀態。
- Phase 2-B 已實作並驗證；`worn_rubiks_cube`、`decoder_cube` 與解碼手套流程已存在於 code。
- Phase 2-C 已實作並驗證；`accepted_item`、`deposit_locked`、`get_container_config()` 與 `item_moved` payload 可供 2-D / 2-E 使用。
- 大門目前已實作真轉場，MessageBox 關閉後真轉場到 `apartment_entrance:from_apartment`。
- Phase 4-A0 已完成（純搬檔，未動遊戲邏輯）。Phase 4-A 已完成：`project.godot` 主場景改為 `res://scenes/main/main.tscn`；SceneRouter + SceneRegistry inline 在 `main.gd`；`apartment_room.gd` 尚無 `prepare_entry_point` / `set_entry_point`（`main.gd` 以 `has_method()` 守衛，安全跳過；完整入口邏輯待 4-E）。
- Phase 4-B 已完成：共用 UI 從 `apartment_room.tscn` 搬入 `game_ui.tscn`（CanvasLayer）；`apartment_room.gd` 透過 `_find_game_ui()` 取得 GameUI 節點參照（過渡方案，4-C 改為 contract）。`_is_simple_message` 旗標區分 `show_message`（GameUI 自動關閉）與 `begin_message`（caller 控制關閉），防止開場獨白被 GameUI 提前終結。`sonar_label` font_size override 已移除（用預設大小）。雙重 `_on_ui_mode_changed` handler 與冗餘 `_ready()` 初始化待 4-C 清理。
- 日後再搬動 `.tscn`/`.gd` 後，headless 跑前需先 `--import` 重建 uid 快取。
- headless `test_runner.tscn` 退出時的 `ObjectDB instances leaked` / `resources still in use`（BGM `AudioStreamMP3`）為**既有、良性的退出期音訊清理 artifact**：所有斷言先 PASS 才出現，成因是 `quit()` 與 ResourceLoader 快取 / audio server 拆除競態（BGM 由 `apartment_room.tscn` ext_resource + `main.gd` `load()` 持有）。committed baseline 也會漏，非 Phase 7 引入；不影響功能驗收，暫接受為已知邊界。

## 下一步建議

架構主線：**Phase 5 — NPC + 對話（真系統）已完成（5-A~5-D 驗證通過）**。**Phase 6 — SaveSystem 已全數完成（6-A~6-F，headless 100 PASS / 0 FAIL）**：`SaveSystem` capture/apply/validate 純邏輯 + 回場路徑 + 多槽 + 標題 / 暫停選單 UI + 邊界處理皆上線並驗證；ConfirmDialog 重用缺陷已修並補回歸測試。剩 6-E/6-F 真機 GUI 走查為人工驗收項。**Phase 7 — QuestManager + `alley_backrooms_3f` vertical slice 已全數完成**：7-A~7-K（任務狀態系統、晚的對話接任務、後巷偵查事件、公寓窗戶條件入口、外牆場景骨架、梯子攀爬 / 外牆禁存、箱子搜索取得 A、R 查看得 B、回報晚完成任務含移除失敗防呆、回歸與存讀檔驗證、**結局分支 + `add_credits` + 親近對話**）已完成並驗證（headless PASS）。（4-G 已取消；其架構契約已由 4-A~4-F 滿足。）

**Phase 8 — 便利商店 vertical slice + 買賣系統：8-A~8-H 已完成並通過 headless + 人工 GUI / 純觸控走查。** 已完成可進入的便利商店室內場景、街道↔店內雙向轉場、前導對話 / `discovered_vendor_error` 聚合、公寓電腦兩段 gate 與 `repair_vendor_bot` 接案、5 線索蒐證、店控機器人診斷對話樹、店籍主機三段與兩種重置結局、買賣系統核心與 `ShopPanel`、街道迷你飲料商店 + 多商店資料化，以及人工對話與買賣系統 GUI / 純觸控走查。

**Phase 9 — 拾遺系統（殘響蒐集 + 收藏家）：9-A~9-H 已全數完成。** 主軸：把主角副業「拾遺者」落地為真系統——時鐘取「老舊探測模組」→ 收藏家鹿其琛鑑定 → 解碼手套升級「拾遺手套」→ 感知採集 4 條殘響（7 點跨 5 場景）→ 筆記殘響分頁（`????` 佔位 + 集滿解鎖照片 / 錄音）→ 賣 vs 留（對話式收購、賣後標記已售出且媒體永久失效、鹿家殘響排除且不收）。

**Phase 10 — 氛圍與演出（Atmosphere & Presentation pass）：10-A~10-D 已全數完成並通過 GUI / 真機目視驗收。** 街道 `apartment_entrance` 垂直切片：音景（雨 bed + 偶爾地鐵 + ducking）、視覺基底（雨粒子 + 水花 + vignette + 相機微擺）、看板廣告輪播 + glitch + 路燈柔光池 + glow layers / 霓虹倒影、晚 idle break「撇一眼暗巷」。視差（ParallaxBackground）門控在美術切層後才開，目前跳過。

另一條短線：**3-B~3-D 的 GUI 純觸控走查** + **4-A/4-B GUI 目視驗收**（headless 全 PASS，互動 / 視覺驗收已完成）。

```text
GUI 走查（Windows 桌面 + 滑鼠模擬觸控）
-> 4-B 目視：啟動遊戲確認開場獨白三頁完整播放、背包/筆記/容器/MessageBox/Toast 行為不退化
-> 3-B：純螢幕按鈕走到大門 / 電腦 / 錄音機按 E、開背包 / 筆記
-> 3-C 里程碑：純觸控從 2-G 開場（連點 T 三下）玩到 B9 開門
-> 3-D：視窗拉成 ~19.5:9，目視按鈕不重疊 / 不遮 prompt·MessageBox·背包格
-> 全部過後再進 3-E（需 Mac + Xcode）
```

Phase 4-C 前必讀：

- `遊戲規格書.md` 4-C 驗收意圖（行 1837–1842）
- `開發設計方針.md` 4-C Level interaction contract（行 554–589）
- `測試指南.md` 4-C（行 322–331）

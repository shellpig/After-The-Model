# After-The-Model 專案簡報

本文件供新 session 快速了解專案全貌，減少每次重讀全部規格文件的成本。需要深入細節時，按下方文件索引讀對應規格。

最後更新：2026-06-16

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
| 3-C | ✅ 完成 | 面板模式觸控：方向鍵移焦點、右下 E / R / T（情境感知顯隱）、面板開時右上「X 返回」=`ui_cancel`；headless PASS、**里程碑 PC 純觸控通關 B0–B9（GUI 實測未跑）** |
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
| 10-A | 🟦 待驗收 | 街道音景：雨 bed（`AmbientRain` autoplay loop, -22dB）+ 地鐵遠轟（`AmbientSubway` one-shot，`SubwayTimer` 40~90 秒隨機間隔，`_a`/`_b` 隨機挑）；新增 Audio Bus `Ambient`；echo 播放時 `main.duck_ambient()` 與既有 `pause_bgm`/`resume_bgm` 同步壓低（-14dB，淡降非全靜，0.3s tween）／淡回；確認街道 BGM 由 `main.gd` 中央系統播放，移除場景內死節點 `BGMPlayer`；headless PASS，GUI / 真機聽感驗收待進行 |
| 10-B | 🟦 待驗收 | 不分層視覺基底：雨粒子兩層（`RainFar`/`RainNear`，掛 `Camera2D` 子節點隨鏡頭走，垂直下落、霓虹染色非純白，落速 3x）+ 落地水花（`RainSplash`）+ `Vignette`（`CanvasLayer` layer=1 + shader，`GameUI` 改 layer=2 確保不被遮；目前 `visible=false` 待調整）+ 相機 idle 微擺（`Camera2D.offset` sin drift，走路時淡出）；無 CRT；`CanvasModulate` 夜色已試做後拿掉（不好看）；headless PASS，GUI / 手機效能聽感驗收待進行 |
| 10-C | ⬜ 規劃中 | 分層進階。**A 免分層（可先行，無 gate）**：看板廣告螢幕（中央遠景看板疊會播放的廣告，先 1 張 + `billboard_screen.gdshader` 掃描線 / flicker，OK 再多張輪播）、路燈柔光池；**B 需分層前置（門控在 10-B 後、kill-switch）**：招牌閃爍 / 窗光呼吸 / 視差 / 濕地面反射。素材：`assets/generated/sprites/street_billboard_ad/`（待生）|
| 10-D | ⬜ 規劃中 | NPC 微演出：晚 idle break「撇一眼暗巷」——`NpcWan` 改 `AnimatedSprite2D`（`idle` + `idle_glance` 2~3 關鍵姿勢真幀）+ `IdleBreak` 組件每隔幾秒插播再回正；可獨立移除。素材：`assets/generated/sprites/wan/idle_glance/`（待生，須接得上現有 idle）|

> 狀態圖例：✅ 完成（含可驗收）；🟦 待驗收 = 程式實作完成且 headless 自動測試 PASS，但互動 / 視覺 / 真機驗收尚未執行；⬜ 待開工 / 待規劃。3-B~3-D 的「純觸控 GUI 走查」與 B0–B9 里程碑實測仍待進行。

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
| 10-C-A 看板廣告螢幕 + 路燈柔光池（免分層 / 可先行） | 2553–2571（A/B 同語意段） | 2262–2285 | 797–805 |
| 10-C-B 分層進階（條件式 / 卡分層前置） | 2553–2571（A/B 同語意段） | 2286–2295 | 806–813 |
| 10-D 晚 idle break（撇一眼暗巷） | 2572–2579 | 2296–2313 | 814–821 |
| 子階段表 / 驗收性質 / 回歸 | 2580–2599 | 2314–2320 | 822–824 |

Phase 10 素材交付：音訊 `assets/audio/ambient/street_rain_loop.mp3`、`subway_rumble*.mp3`（提示詞已備）；雨絲 / 水花貼圖 `assets/vfx/rain_streak.png`、`rain_splash.png`（已生成，生成腳本 `assets/vfx/gen_rain_vfx.py`）；vignette 走 shader。**待生 / 待寫**：10-C-A 看板廣告靜圖 `assets/generated/sprites/street_billboard_ad/`（opaque、對齊看板矩形）+ `assets/shaders/billboard_screen.gdshader`（掃描線 / flicker / 邊緣輝光）；10-D 晚 `assets/generated/sprites/wan/idle_glance/`（2~3 關鍵姿勢，須接上現有 idle）+ `scripts/components/idle_break.gd`。10-C-B 街道分層素材仍為條件式。

- `遊戲規格書.md` Phase 規劃總覽 1272–1521（含 Phase 2 拆分 1510–1521）
- `subdocs/地點/主角公寓.md` 機制鏈總覽 B0–B9 357–381
- `開發設計方針.md` 本檔範圍與邊界 6–21

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

**Phase 10 — 氛圍與演出（Atmosphere & Presentation pass）：規格已寫（三件套），待開工。** 方向決議：殘響 / 記憶線為敘事主軸，氛圍服務主軸。只在街道 `apartment_entrance` 做垂直切片：10-A 街道音景（雨 + 偶爾地鐵 + 接既有 ducking）、10-B 不分層視覺基底（CanvasModulate 夜色 + 稀疏雨粒子 + 水花 + vignette + 相機微擺，無 CRT）、10-C 分層進階（招牌閃爍 / 窗光 / 視差 / 濕地面反射，**條件式、門控在 10-B 目視通過後**，kill-switch）。手機效能為硬約束；本階段以 GUI / 真機目視驗收為主，headless 僅作回歸護欄。敘事脊椎（主線 A）與寫作密度（C）排在 Phase 10 之後。

另一條短線：**3-B~3-D 的 GUI 純觸控走查** + **4-A/4-B GUI 目視驗收**（headless 全 PASS，唯互動 / 視覺驗收未跑）。

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

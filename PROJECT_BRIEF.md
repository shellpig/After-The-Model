# After-The-Model 專案簡報

本文件供新 session 快速了解專案全貌，減少每次重讀全部規格文件的成本。需要深入細節時，按下方文件索引讀對應規格。

最後更新：2026-06-07

---

## 專案概述

《After-The-Model》是一款 2D 橫向探索 / 都市漫遊 / 碎片化敘事 cyberpunk 遊戲，主題是「AI 改變世界之後，普通人怎麼活下去」。

- **引擎**：Godot 4.6.3 / GDScript
- **視角**：純 2D 側捲，角色只左右移動；未來可加入 light platforming
- **美術方向**：Riso-inspired HD 2D Cyberpunk，非 hard pixel art
- **目標平台**：先做本機 PC MVP；Steam / iOS / Android 後置
- **MVP 範圍**：一條街 + 一個地鐵站 + 一個小公寓 + 2 NPC + 1 零工任務
- **目前可玩場景**：`apartment_room.tscn`、`apartment_entrance.tscn`、`apartment_fire_escape.tscn`
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

> 行號以 2026-06-07 版為準；大幅改寫後需校正。Phase 7 規格 / 契約 / 測試清單已定；7-A~7-J 全部已實作並驗證（headless PASS）。

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

共同前置（任一子階段都建議先掃一次）：

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

最近已記錄的 Phase 7 headless 驗證結果（commit `878ebd6`）：

```text
test_runner.tscn: PASS
verify_game_state.gd: PASS
```

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

- `驗證後已知問題.md` 已建立；目前 KI-001 已修復，暫無待修項目。
- `subdocs/地點/主角公寓.md` 底部「已知落差 / 待修」有部分 Phase 1 歷史描述可能已過期；以 `AGENTS.md`、`遊戲規格書.md`、目前 code 與 git log 判斷最新狀態。
- Phase 2-B 已實作並驗證；`worn_rubiks_cube`、`decoder_cube` 與解碼手套流程已存在於 code。
- Phase 2-C 已實作並驗證；`accepted_item`、`deposit_locked`、`get_container_config()` 與 `item_moved` payload 可供 2-D / 2-E 使用。
- 大門目前已實作真轉場，MessageBox 關閉後真轉場到 `apartment_entrance:from_apartment`。
- Phase 4-A0 已完成（純搬檔，未動遊戲邏輯）。Phase 4-A 已完成：`project.godot` 主場景改為 `res://scenes/main/main.tscn`；SceneRouter + SceneRegistry inline 在 `main.gd`；`apartment_room.gd` 尚無 `prepare_entry_point` / `set_entry_point`（`main.gd` 以 `has_method()` 守衛，安全跳過；完整入口邏輯待 4-E）。
- Phase 4-B 已完成：共用 UI 從 `apartment_room.tscn` 搬入 `game_ui.tscn`（CanvasLayer）；`apartment_room.gd` 透過 `_find_game_ui()` 取得 GameUI 節點參照（過渡方案，4-C 改為 contract）。`_is_simple_message` 旗標區分 `show_message`（GameUI 自動關閉）與 `begin_message`（caller 控制關閉），防止開場獨白被 GameUI 提前終結。`sonar_label` font_size override 已移除（用預設大小）。雙重 `_on_ui_mode_changed` handler 與冗餘 `_ready()` 初始化待 4-C 清理。
- 日後再搬動 `.tscn`/`.gd` 後，headless 跑前需先 `--import` 重建 uid 快取。
- headless `test_runner.tscn` 退出時的 `ObjectDB instances leaked` / `resources still in use`（BGM `AudioStreamMP3`）為**既有、良性的退出期音訊清理 artifact**：所有斷言先 PASS 才出現，成因是 `quit()` 與 ResourceLoader 快取 / audio server 拆除競態（BGM 由 `apartment_room.tscn` ext_resource + `main.gd` `load()` 持有）。committed baseline 也會漏，非 Phase 7 引入；不影響功能驗收，暫接受為已知邊界。

## 下一步建議

架構主線：**Phase 5 — NPC + 對話（真系統）已完成（5-A~5-D 驗證通過）**。**Phase 6 — SaveSystem 已全數完成（6-A~6-F，headless 100 PASS / 0 FAIL）**：`SaveSystem` capture/apply/validate 純邏輯 + 回場路徑 + 多槽 + 標題 / 暫停選單 UI + 邊界處理皆上線並驗證；ConfirmDialog 重用缺陷已修並補回歸測試。剩 6-E/6-F 真機 GUI 走查為人工驗收項。**Phase 7 — QuestManager + `alley_backrooms_3f` vertical slice 已全數完成**：7-A~7-J（任務狀態系統、晚的對話接任務、後巷偵查事件、公寓窗戶條件入口、外牆場景骨架、梯子攀爬 / 外牆禁存、箱子搜索取得 A、R 查看得 B、回報晚完成任務含移除失敗防呆、回歸與存讀檔驗證）已完成並驗證（headless PASS）。（4-G 已取消；其架構契約已由 4-A~4-F 滿足。）

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

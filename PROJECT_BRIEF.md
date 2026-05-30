# After-The-Model 專案簡報

本文件供新 session 快速了解專案全貌，減少每次重讀全部規格文件的成本。需要深入細節時，按下方文件索引讀對應規格。

最後更新：2026-05-30

---

## 專案概述

《After-The-Model》是一款 2D 橫向探索 / 都市漫遊 / 碎片化敘事 cyberpunk 遊戲，主題是「AI 改變世界之後，普通人怎麼活下去」。

- **引擎**：Godot 4.6.3 / GDScript
- **視角**：純 2D 側捲，角色只左右移動；未來可加入 light platforming
- **美術方向**：Riso-inspired HD 2D Cyberpunk，非 hard pixel art
- **目標平台**：先做本機 PC MVP；Steam / iOS / Android 後置
- **MVP 範圍**：一條街 + 一個地鐵站 + 一個小公寓 + 2 NPC + 1 零工任務
- **目前可玩場景**：`apartment_room.tscn`
- **目前主線進度**：Phase 1 與 Phase 2（公寓解謎全鏈及 2-F 筆記與 BGM 修正）已全數完成並驗證；下一步 Phase 3（新場景與轉場）

最新 commit：

```text
77abac5 feat: implement and refine Phase 2-D sonar reveal & nutrition bar clue flows
```

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
├── apartment_room.tscn / apartment_room.gd   # 目前主場景 controller
├── player.gd                                 # 主角移動；UI mode 時凍結
├── interactable_area.gd                      # Area2D 互動物 export 欄位
├── scripts/autoload/
│   ├── game_state.gd                         # credits / inventory / notes / containers / equipment
│   └── ui_mode.gd                            # NONE / INVENTORY / CONTAINER / NOTEBOOK / MESSAGE / CONFIRM
├── scenes/ui/
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
| 3+ | ⬜ 待規劃 | SceneRouter、第二場景、NPC 對話、第一個零工任務 |

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

> 開某子階段前只讀對應行範圍，避免每次重掃整份規格。行號以 2026-05-30 版為準；大幅改寫後需校正。
> 四份文件角色：**規格書**=驗收意圖（what must be true）／**設計方針**=實作契約（API・欄位・接線）／**測試指南**=操作清單（click-by-click）／**主角公寓**=敘事・互動物・線索文字。

### Phase 2 子階段（四份對照）

| 子階段 | 遊戲規格書.md（驗收意圖） | 開發設計方針.md（契約） | 測試指南.md（清單） | subdocs/地點/主角公寓.md（流程・文字） |
|---|---|---|---|---|
| 2-A examine 線索 | 1522–1532 | 27–48 | 45–67 | 384–392・432–463 |
| 2-B 解碼手套／方塊 | 1533–1547 | 49–75 | 68–96 | 394–431 |
| 2-C 容器白名單／鎖定 | 1548–1559 | 76–99 | 97–121 | 497–505 |
| 2-D 投影時鐘＋聲納 reveal | 1560–1574 | 100–145 | 122–160 | 464–505 |
| 2-E 放入→語音→開門＋overlay 重構 | 1575–1586 | 146–174 | 161–186 | 506–534 |

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

最近 2-C 驗證結果：

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
| `測試指南.md` | Headless 命令、手動驗收清單、Phase 2 acceptance checklist |
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

- `驗證後已知問題.md` 尚未建立；規劃於 Phase 2-E 收尾建立。
- `subdocs/地點/主角公寓.md` 底部「已知落差 / 待修」有部分 Phase 1 歷史描述可能已過期；以 `AGENTS.md`、`遊戲規格書.md`、目前 code 與 git log 判斷最新狀態。
- Phase 2-B 已實作並驗證；`worn_rubiks_cube`、`decoder_cube` 與解碼手套流程已存在於 code。
- Phase 2-C 已實作並驗證；`accepted_item`、`deposit_locked`、`get_container_config()` 與 `item_moved` payload 可供 2-D / 2-E 使用。
- 大門目前只顯示 `door_opened` 訊息，不轉場；SceneRouter 留 Phase 3+。

## 下一步建議

短線最合理下一步：

```text
Phase 2-E
-> 插槽放入 decoder_cube
-> 觸發電磁聲響 + 語音 MessageBox
-> 關閉 MessageBox 後，GameState 寫入 identity_door_unlock_method 知識
-> 大門互動取得解鎖方法後可通過 gate
```

2-E 前必讀：

- `遊戲規格書.md > Phase 2 > 2-E 驗收意圖`
- `開發設計方針.md > 2-E 插槽放入整合 + MESSAGE/CONFIRM overlay 重構`
- `測試指南.md > 2-E 放入→語音→開門＋overlay 重構`
- `subdocs/地點/主角公寓.md > 隱藏插槽 / 解碼方塊放入路徑`

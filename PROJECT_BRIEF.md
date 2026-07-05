# After-The-Model 專案簡報

本文件供新 session 快速了解專案全貌，減少每次重讀全部規格文件的成本。需要深入細節時，按下方文件索引讀對應規格。

最後更新：2026-07-05

> **當前進度**：Phase 29（Edited Expose 三判定）與 Phase 30（三結局共用收尾、主線脊椎回歸與存讀檔矩陣）已完成；主線結局段已收束至五結局路由、共用收尾、結局 meta 記錄與全主線回歸。M1（進度頁）/ M2（i18n）已完成。

---

## 專案概述

《After-The-Model》是一款 2D 橫向探索 / 都市漫遊 / 碎片化敘事 cyberpunk 遊戲，主題是「AI 改變世界之後，普通人怎麼活下去」。

- **引擎**：Godot 4.6.3 / GDScript
- **視角**：純 2D 側捲，角色只左右移動；未來可加入 light platforming
- **美術方向**：Riso-inspired HD 2D Cyberpunk，非 hard pixel art
- **目標平台**：先做本機 PC MVP；Steam / iOS / Android 後置
- **MVP 範圍**：一條街 + 一個地鐵站 + 一個小公寓 + 2 NPC + 1 零工任務
- **目前可玩場景**：20+（公寓、街道、防火梯、便利商店、收藏家的店、地鐵站兩室、聚落兩室、隧道戰鬥、追逐兩室、夜總會三場景、資料中心三場景、廣播站…）；正式清單以 `scenes/main/main.gd` 的 `SCENES` 為準
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

> 一行一列的狀態索引。歷史子階段的詳細 changelog（決策記錄、旗標清單、commit 對照）已於 2026-07-04 歸檔至 `subdocs/歸檔/PROJECT_BRIEF_phase進度詳表.md`，不再維護；細節請看三份規格文件對應 Phase 段落（標題 grep，見 `AGENTS.md > 按 Phase 查閱規則`）與 `git log`。

| Phase | 狀態 | 概要 |
|---|---|---|
| 1-A | ✅ | `GameState` autoload：credits / 背包 / 裝備 / 知識 / 筆記 / 容器 + 公寓大門 knowledge gate |
| 1-B | ✅ | `UIMode` autoload + 背包 UI（`I`、5x3、Credits、icon、focus） |
| 1-C | ✅ | 筆記 UI（`J`、身份 / 工作 / 線索 tab、列表 + 全文） |
| 1-D | ✅ | 容器資料化 + 雙欄 UI（櫥櫃 / 冰箱、跨欄 focus、E 移動）+ FloatingToast |
| 1-E | ✅ | 物品操作 R 查看 / T 丟棄 / E 裝備 + ConfirmDialog / ItemDetailModal |
| 2-A | ✅ | 公寓線索 examine（桌上電腦 / 左牆錄音機）+ `note_id` 去重 |
| 2-B | ✅ | 解碼手套 + 魔術方塊 → `decoder_cube` |
| 2-C | ✅ | 容器 `accepted_item` 白名單 + `deposit_locked` 擴充 |
| 2-D | ✅ | 投影時鐘偵測終端 + 聲納 reveal 隱藏插槽 |
| 2-E | ✅ | 插槽放入 → `identity_door_unlock_method` → 開門整合 |
| 2-F | ✅ | 筆記操作修正（A/D 分頁、W/S 選筆記）+ 公寓 BGM |
| 2-G | ✅ | 開場獨白序列（prone 甦醒 → 3 頁 MessageBox → 起身；隱藏 T×3 跳頁） |
| 3-A | ✅ | 顯示 / 橫向 / 觸控模擬設定（landscape、`canvas_items`+`expand`） |
| 3-B | ✅ | 世界模式觸控：`TouchControls` autoload（D-pad / E / 背包·筆記） |
| 3-C | ✅ | 面板模式觸控；里程碑 PC 純觸控通關 B0–B9 |
| 3-D | ✅ | Safe area + 比例排版（按鈕 ≥44px） |
| 3-E | ✅ | 真機導出 + iPhone 校正（Mac + Xcode 免費簽名） |
| 4-A0 | ✅ | 檔案結構整理（levels / actors / components 搬檔） |
| 4-A | ✅ | `main.tscn` SceneRouter + SceneRegistry；`transition_to(scene_id, entry_point_id)` |
| 4-B | ✅ | `game_ui` 常駐 CanvasLayer，共用 UI 搬入 GameUI |
| 4-C | ✅ | Level interaction contract（signal 中介，Level 不碰 UI node path） |
| 4-D | ✅ | TouchControls 改接 GameUI contract |
| 4-E | ✅ | Entry point API（`wake_bed` / `from_street`）+ 公寓遷移 |
| 4-F | ✅ | `apartment_entrance` 第二場景 + 真轉場 |
| 4-G | ❌ 取消 | future contract placeholder pass 取消（契約已由 4-A~F 滿足） |
| 5-A | ✅ | 故事旗標 store + 對話樹 schema + `DialogueRunner` 純邏輯 |
| 5-B | ✅ | `DialoguePanel` + `UIMode.DIALOGUE` + 鍵盤選項路由 |
| 5-C | ✅ | TouchControls 對話路由 |
| 5-D | ✅ | NPC「晚」落地街道 + dialogue dispatch 泛化 |
| 6-A | ✅ | `SaveSystem` capture / apply / validate + GameState 序列化 |
| 6-B | ✅ | 讀檔回場（精確座標、跳過 entry point 副作用、兩段驗證） |
| 6-C | ✅ | 多槽模型（10 槽 + `{meta,data}` header） |
| 6-D | ✅ | 標題畫面 New Game / Load + 開機流程 |
| 6-E | ✅ | 暫停選單 + Save/Load 槽列表 + 覆蓋確認 |
| 6-F | ✅ | 存讀檔邊界處理（版本 / 損毀 / 出界 clamp）+ GUI 走查 |
| 7-A | ✅ | `QuestManager` + `quest_states` 存讀檔整合 |
| 7-B | ✅ | 晚的對話接任務 + DialogueRunner condition 擴充 |
| 7-C | ✅ | 後巷偵查事件 |
| 7-D | ✅ | 公寓窗戶條件式入口 → 防火梯 |
| 7-E | ✅ | `apartment_fire_escape` 場景骨架 |
| 7-F | ✅ | 梯子攀爬 + 天橋步行 + 外牆禁存 |
| 7-G | ✅ | 三樓箱子搜索取得 A 物品（背包滿防呆） |
| 7-H | ✅ | R 查看 A 得 B「舊式 AI 授權模組」 |
| 7-I | ✅ | 回報晚 + 任務完成（remove → complete 原子順序） |
| 7-J | ✅ | Phase 7 回歸 + 存讀檔驗證 |
| 7-K | ✅ | 任務結局分支（B 交還 / `add_credits` / 親近對話） |
| 8-A | ✅ | `convenience_store` 場景骨架 + 街道雙向轉場 |
| 8-B | ✅ | 店控機器人前導對話 + `discovered_vendor_error` 聚合 |
| 8-C | ✅ | 公寓電腦兩段 gate + `repair_vendor_bot` 接案 |
| 8-D | ✅ | 5 線索蒐證 + 診斷對話樹 + 揭示主機 |
| 8-E | ✅ | 店籍主機兩種重置結局（直接重置 / 先錄殘響） |
| 8-F | ✅ | 買賣系統核心 + `ShopPanel` + `UIMode.SHOP` |
| 8-G | ✅ | 街道飲料販賣機 + 多商店資料化 |
| 8-H | ✅ | Phase 8 全鏈回歸 + GUI / 純觸控走查 |
| 9-A | ✅ | 殘響資料模型 + 筆記「殘響」分頁（`????` 佔位） |
| 9-B | ✅ | 公寓時鐘取「老舊探測模組」 |
| 9-C | ✅ | `collector_shop` + 鹿其琛鑑定 → 拾遺手套升級 |
| 9-D | ✅ | `EchoPoint` 感知採集組件（裝備手套才 active） |
| 9-E | ✅ | 殘響媒體層（集滿解鎖照片 / 錄音） |
| 9-F | ✅ | 內容鋪設：4 條殘響 / 7 採集點跨 5 場景 |
| 9-G | ✅ | 收購賣 vs 留（賣後媒體永久失效；鹿家殘響不收） |
| 9-H | ✅ | Phase 9 全鏈回歸 + GUI / 觸控走查 |
| 10-A | ✅ | 街道音景（雨 bed + 地鐵遠轟 + echo ducking） |
| 10-B | ✅ | 雨粒子 / 水花 / vignette / 相機微擺 |
| 10-C | ✅ | 看板輪播 glitch + 路燈 / 霓虹 glow + 倒影 |
| 10-D | ✅ | 晚 idle break「撇一眼暗巷」（`IdleBreak` 組件） |
| 11-A | ✅ | `GameState.trace` + `add_trace`（隱性、無 UI） |
| 11-B | ✅ | `get_trust(target)` adapter（= `affinity_*` 旗標） |
| 11-C | ✅ | 賣殘響 → Trace↓ 集中 `sell_echo()` + `add_trace` effect op |
| 11-D | ❌ 取消 | 清洗不提前落地，移至 Phase 27 硬兌現 |
| 11-E | ✅ | Phase 11 測試護欄 |
| 12-A | ✅ | 跳躍：腳本化拋物弧（架構決策：不引入全域重力） |
| 12-B | ✅ | 平台組件（ledge / gap）+ `jump_proto` 原型床 |
| 12-C | ✅ | TouchControls 跳躍鍵 |
| 13-A | ✅ | `attack` + `melee_stick` + `enemy_base`（stun、無 HP / 血條） |
| 13-B | ✅ | 繞後格式化（限機器；長按 E 2 秒） |
| 13-C | ✅ | `human_enemy` 骨架（不可格式化；人類不死在玩家手上） |
| 13-D | ✅ | 輸 = 岔故事線 `combat_loss`（無 Game Over） |
| 13-E | ✅ | `combat_proto` 原型床 |
| 13-F | ✅ | TouchControls 攻擊鍵 |
| 14-A | ✅ | 林霏碎片①「莫名一震」（`memory_fragment_area` 被動觸發） |
| 14-B | ✅ | 鹿 / 晚鋪墊鉤（`lu_hinted_topside` / `wan_noticed_daze`） |
| 14-C | ✅ | 阿達①店控首談前置誤認 |
| 14-D | ✅ | Phase 14 回歸 + GUI 走查 |
| 15-A | ✅ | 地鐵站兩室（大廳 / 月台）+ 街道 travel gate |
| 15-B | ✅ | 地下道聚落兩室 + `reached_settlement` |
| 15-C | ✅ | 四室 flavor 互動物（P16~18 真掛點預留） |
| 15-D | ✅ | Phase 15 回歸 + 全鏈雙向轉場 |
| 16-A | ✅ | 小岑 `cen` NPC 落地聚落左室 |
| 16-B | ✅ | 伍姐 `wu` NPC（建立者節點、不具名） |
| 16-C | ✅ | 七號 `seven` NPC（「名字還掛在上面」鋪墊） |
| 16-D | ✅ | 三對話樹註冊 + 條件路由 + 回歸護欄 |
| 16-E | ✅ | GUI / 觸控走查 + 三人立繪到位 |
| 17-A | ✅ | 碎片「你以前往上通勤」（月台） |
| 17-B | ✅ | 聚落殘響 `echo_settlement_erased` |
| 17-C | ✅ | Phase 17 回歸 + 存讀檔 |
| 18-A | ✅ | `tunnel_combat` 正式戰鬥遭遇 + Player `combat_mode` |
| 18-B | ✅ | 戰後物流箱 → 回執 `childcare_supply_receipt`（key item） |
| 18-C | ✅ | 晚「賣回執」分支 = `peace_line_locked` 永久鎖死和平線 |
| 18-D | ✅ | Phase 18 回歸 + 存讀檔 |
| M1 | ✅ | 進度頁（筆記「進度」分頁、五收集分類；out-of-band meta 編號；隨 v0.18.4 出貨） |
| M2-A | ✅ | i18n 基礎建設（`LocaleManager`、fallback `zh_TW`、字型切換） |
| M2-B | ✅ | UI chrome i18n（`ui.csv` 三語 + coverage lint） |
| M2-C | ✅ | 敘事資料 i18n（`story.csv` / `items.csv`） |
| M2-D | ✅ | 對話樹 i18n（`dialogue.csv` 176 keys + 三語禁字檢查） |
| M2-E | ✅ | i18n 收尾 + 全域驗證網（5 份 CSV 護欄） |
| 19-A | ✅ | 阿達殘響②（`trace_on_collect` 兌現 11-C 預留） |
| 19-B | ✅ | 舊善後工單③（工單編號 = 舊工作證 = 失憶前主角） |
| 19-C | ✅ | 收束碎片「你親手抹過阿達」（`require_flag` gate） |
| 19-D | ✅ | Phase 19 回歸 + 存讀檔 |
| 20-A | ✅ | 七號和平入口（窄漏斗對話） |
| 20-B | ✅ | 交還回執 + Branch D（`seven_peace_branch_d`；可重試、賣回執鎖死） |
| 20-C | ✅ | 爆點延燒刻意留 Phase 24 |
| 20-D | ✅ | Phase 20 GUI / 純觸控走查 |
| 21-A | ✅ | 夜總會 3 場景 + 進入動線（anchor-04；原 Phase 22 併入本 Phase） |
| 21-B | ✅ | 林霏核心殘響 `echo_linfei` 6 段 + 分段媒體門檻 |
| 21-C | ✅ | 收束碎片「黑戶藏身方式」 |
| 21-D | ✅ | 女聲主題歌掛載 + 夜總會素材落地 |
| 21-E | ✅ | 《雨還沒停》環境母題（`ThemeMotifPlayer`） |
| 21-F | ✅ | `echo_linfei` 可賣 + Phase 21 回歸 |
| 22 | — | 已併入 Phase 21（編號保留、不再使用；23~31 編號不變） |
| 23-A | ✅ | 後場門四解 gate retrofit + 保全 / bar_bot / 工牌 |
| 23-B | ✅ | 保全對話樹（賄賂 / 假裝身份）+ `credits` condition |
| 23-C | ✅ | 引開 → 潛行限時組合（一次性、20 秒空窗、情境圖演出） |
| 23-D | ✅ | Phase 23 回歸 + 四解 GUI / 觸控走查 |
| 24-A | ✅ | `seven_betrayal` quest 化 + 伍姐 / 小岑提前警告分支 |
| 24-B | ✅ | 爆發分支判定（trace 門檻 + trust 攔截；冪等結算） |
| 24-C | ✅ | 深隧道限時選門迷宮兩室 + 180 秒倒數 + 攤牌情境圖 |
| 24-D | ✅ | Branch B 代價（`cen_voiceprint_exposed`，餵 28-C） |
| 24-E | ✅ | Phase 24 回歸 + 存讀檔 |
| 25-A | ✅ | Act 4 資料中心三場景 + travel / 善後員門禁 gate（anchor-05） |
| 25-B | ✅ | 戰鬥③混合敵人跑到門（人類不可殺、無失敗態） |
| 25-C | ✅ | Phase 25 回歸 + 素材 / BGM 落地 |
| 26-A | ✅ | 晚拉扯演出（`wan_act4_pull_seen`） |
| 26-B | ✅ | 阿達④本人登場一次後永久消失 |
| 26-C | ✅ | 真相碎片「你自己選擇被刪」 |
| 26-D | ✅ | 結局觸發點武裝（`stood_before_own_backup`）+ Branch B 檔案重標記 |
| 26-E | ✅ | Phase 26 回歸 + 存讀檔 + GUI |
| 27-A | ✅ | `broadcast_station` 正式場景（單向、可存檔、新 BGM / map） |
| 27-B | ✅ | 三結局路由（Reclaim / Protect / Expose 互斥鎖點；三選無條件全開） |
| 27-C | ✅ | 上傳前清洗閘五拍（11-D 兌現；`echo_count` condition） |
| 27-D | ✅ | Phase 27 回歸 + 同檔三路可達驗證 |
| 28-A | ✅ | Reclaim 三站序列（backup_core 灌回 → 晚訣別 CG 永久消失 → 公寓痕跡拍） |
| 28-B | ✅ | Protect 序列（短刪除演出、與 Reclaim 刻意不對稱；晚不消失） |
| 28-C | ✅ | 小岑條件式回收中間站（not-B 地鐵復駛 + 過閘 CG / B 空帳篷 + 伍姐搖頭） |
| 28-D | ✅ | Phase 28 回歸 + 孤兒檔救援（headless 435 PASS / 0 FAIL） |
| 29-A | ✅ | Trace 經濟補正 + 判定框架 + Expose A 分支（警報 + 聚落火光 CG） |
| 29-B | ✅ | Expose B 分支（已清洗 → 雜訊收尾拍） |
| 29-C | ✅ | Expose C 分支（trace ≥ 臨界 → 攔截抹除，優先於 A/B） |
| 29-D | ✅ | 四組合判定矩陣回歸 + 孤兒檔救援 |
| 30-A | ✅ | 共用收尾三拍（11 CG）＋《雨還沒停》＋credits→回標題＋M1 結局記錄（meta 檔） |
| 30-B | ✅ | 全主線脊椎回歸（wake_bed 起真實路徑、六條終點全跑：Reclaim / Protect not-B / Protect Branch B / Expose A/B/C） |
| 30-C | ✅ | 三結局 × 存讀檔矩陣 + GUI / 純觸控 / i18n 走查 |

> 狀態圖例：✅ 完成（含可驗收）；🟦 待驗收 = 程式實作完成且 headless PASS，互動 / 視覺 / 真機驗收未執行；🟧 待 headless = 程式完成、headless 未跑；📐 規格可實作 = 三份文件規格已寫到可動工、程式未開工；⬜ 待開工 / 待規劃。
>
> 主線《雨還沒停》v2.3（Phase 11–31，嚴格順敘不跳號）：完整排程見三份規格文件的 `Phase 11+` 段；敘事事實來源 `subdocs/主線/雨還沒停v2.3.md`。Phase 22 已併入 21；M1（進度頁）/ M2（i18n）為 out-of-band meta 編號、皆已完成。


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


## 測試速查

```powershell
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/manual/test_runner.tscn
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . -s res://tests/manual/verify_game_state.gd
```

- Windows sandbox 下 headless 會因 `user://logs` 權限 crash：直接用 elevated 權限跑（詳見 `AGENTS.md > 本機 Windows 環境專用`）。
- 搬動 `.tscn` / `.gd` 或改 CSV 翻譯後，headless 前先 `--import` 重建快取。
- `git diff --check` 若只出現 LF -> CRLF warning，屬 Windows autocrlf 提示，不是 whitespace error。
- 最新測試結果不在本檔維護：看 `git log` 最近 commit message（慣例會寫 headless PASS / FAIL 數）。

## 規格文件索引

| 文件 | 何時讀 |
|---|---|
| `AGENTS.md` | 新 session 開場；專案規則、修改 / 驗證授權、本機工具路徑 |
| `PROJECT_BRIEF.md` | 快速建立全貌；先讀本檔，再按需求深入 |
| `遊戲概念.md` | 世界觀、玩家定位、都市調性 |
| `技術概念.md` | Godot 選型、MVP 技術方向、平台路線、輸入 / UI / 存檔 / debug 架構決策 |
| `Art Bible.md` | 生圖、角色、場景、item icon、視覺一致性；任何素材工作必讀 |
| `遊戲規格書.md` | 全遊戲通用系統規格 + 各 Phase 驗收意圖（按 Phase 標題 grep 讀對應段，勿整份讀） |
| `開發設計方針.md` | Phase 2 起實作契約、API、資料欄位、接線規則（按 Phase 標題 grep） |
| `測試指南.md` | Headless 命令、手動驗收清單（按 Phase 標題 grep） |
| `驗證後已知問題.md` | 待修清單與已接受邊界；修 bug 前先看 |
| `subdocs/主線/` | 主線劇情文本；最新定稿 `雨還沒停v2.3.md`（敘事事實來源） |
| `subdocs/人/` | 角色設定（主角、晚、鹿其琛、三張臉…） |
| `subdocs/地點/` | 場景專屬規格（公寓、便利商店、收藏家的店、地鐵站、聚落、夜總會…） |
| `subdocs/歸檔/` | 歷史歸檔：Phase 進度詳表 + 三份規格文件的已完成 phase 段落（同標題可 grep）；查舊 phase 細節時才讀 |

## 實作注意事項

- 修改授權 / verify-only 規則：見 `AGENTS.md > 修改授權與驗證規則`（單一事實來源，本檔不重複）。
- 文件分工：`開發設計方針.md` 偏 implementer-owned；`測試指南.md` 偏 verifier-owned。若角色不符，只列建議。
- `.claude/` 是 local tooling config，不 commit。
- 不要把 `agent-sprite-forge` repo 放進本專案。
- 生圖輸出必須落回 `assets/generated/...`，保留 prompt / raw / processed / metadata。

## 目前已知邊界

- 待修清單以 `驗證後已知問題.md` 為單一事實來源，本檔不重複列。
- 搬動 `.tscn` / `.gd` 後，headless 跑前需先 `--import` 重建 uid 快取。
- headless `test_runner.tscn` 退出時的 `ObjectDB instances leaked` / AudioStream teardown 殘留為既有、良性的退出期 artifact（所有斷言先 PASS 才出現），已接受為已知邊界。

## 下一步建議

- **Phase 29 / Phase 30 已完成**：Edited Expose 三判定、三結局共用收尾、六條結局脊椎回歸、存讀檔矩陣、結局 meta 記錄與 i18n 驗證均已落地；最新狀態以 Phase 進度表與近期 commit / headless gate 為準。
- **下一步**：進入結局後發行前總整理（手動遊玩紀錄、平台匯出、credits / 授權盤點、已知問題收斂）；若要新增 Phase 31，先在三份規格文件補 Phase 31 契約與驗收清單。

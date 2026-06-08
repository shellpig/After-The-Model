# After-The-Model

[English](./README.md) | **繁體中文** | [简体中文](./README_zh-CN.md)

![Godot](https://img.shields.io/badge/GODOT-4.6.3-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDSCRIPT-blue)
![Platform](https://img.shields.io/badge/PLATFORM-WINDOWS%20%7C%20iOS-0078D6?logo=windows&logoColor=white)
![Genre](https://img.shields.io/badge/GENRE-2D%20SIDE--SCROLL-purple)
![Status](https://img.shields.io/badge/STATUS-MVP%20IN%20DEVELOPMENT-orange)

> 一款 2D 橫向探索 cyberpunk 遊戲，主題是「AI 改變世界之後，普通人怎麼活下去」。

不是英雄拯救世界，也不是打倒邪惡企業。你是 AI 後時代城市裡的低階層普通人，在霓虹與雨夜之間生活、接零工、拾回被系統抹掉的記憶。

---

## ⚠️ 開發狀態

本專案為**開發中的個人作品**，目前處於 MVP 階段。可玩內容、系統與美術素材都還在迭代，存檔格式、場景與數值皆可能變動。尚未發行，亦未附正式授權條款。

---

## 遊戲概念

**背景時間：2030 年左右。** AI 已徹底改變社會，但世界沒有進入科幻電影式的未來——科技進步了，卻不平均：有些地方高度自動化、極端先進；有些地方反而比現在更破敗落後。

> 「高科技與社會失能同時存在」的世界。

| 光鮮的一面 | 陰暗的一面 |
|---|---|
| 無人便利店極度先進 | 地下道塞滿失業人口 |
| AI 行政系統效率驚人 | 人類客服幾乎消失 |
| 每個人都有 AI 助理 | 沒人能真正申訴 AI 的錯誤 |
| 空中廣告與自動化城市隨處可見 | 人與人之間變得更加孤獨 |

整體調性：**都市漫遊 / 生存感 / 小事件 / 社會觀察 / 碎片化敘事**。玩家不是世界中心，只是努力活下去的一個普通人。主角是 **AI 善後員 + 拾遺者**——白天替系統修正錯誤，私下拾回被抹掉的人類痕跡。

---

## 世界的三個區

色彩即階級語言，玩家走過三個區的瞬間，眼睛立刻讀出社會結構：

| 區 | 視覺策略 | 居民態度 |
|---|---|---|
| **平民區** | 一切褪色，但**橙色還在** | 「我們什麼都沒有，但招牌不能熄」 |
| **富人區** | 硬黑、亮金、銳 cyber 紫 | 「我們維持得起顏色」 |
| **AI 區** | 近乎白、無機、扁平 | 「我們不需要顏色」 |

地鐵是貫穿全城的「階級流動系統」：一般車廂、AI VIP 車廂、躲票者聚集區、地下非法列車——車廂本身就是城市縮影。

---

## 玩法

- **純 2D 側捲**：角色只做 X 軸左右移動，搭配 light platforming（跨水溝、爬火逃梯、走天橋），服務「探索 + 漫遊」而非動作挑戰。
- **原地互動 vs 場景切換**：共用單一互動鍵（PC `E` / 觸控互動按鈕）。街上小物與站立 NPC 為原地互動；門 / 閘門 / 樓梯 / 窗戶則觸發場景切換。
- **背包與容器**：5×3 背包、可資料化的外部容器（白名單 / 鎖定）、物品查看 / 丟棄 / 裝備、筆記與知識系統。
- **解謎**：第一關公寓有一條完整解謎鏈（醒來失憶 → examine 取得線索 → 戴手套解碼 → 聲納揭示插槽 → 取得開門知識 → 開門）。
- **NPC 對話**：條件路由的對話樹（首見 / 重講 / 好感與情報門檻），分支與 effect 即時反映於狀態。
- **零工任務**：含任務狀態系統與**多重結局分支**（是否交還隱藏模組會影響報酬、好感與後續招呼）。
- **存檔**：10 槽手動存讀、標題畫面與暫停選單、回場座標還原。
- **跨平台輸入**：透過 Godot InputMap 抽象化，PC 鍵鼠與行動裝置觸控共用同一套 action；強制 landscape，UI 走 safe area 與 ≥44px 觸控目標。

---

## 美術方向

> **「一本 2030 年便利店架上被遺忘的廉價 cyberpunk zine 上的世界——印著美式獨立漫畫的線、染著夜班的疲憊、留著人類用過的痕跡。」**

- **風格**：Riso-inspired HD 2D Cyberpunk（非 hard pixel art、非半繪畫風）。
- **五條鐵則**：純 2D 側視（無透視）、不純白不純黑、限色 + 跳色紀律、大塊黑 + 焦點集中、平面剖面（FLAT PROFILE）。
- **橙色法則**：飽和橙是平民區「拒絕被遺忘」的敘事標記色（環境 ≤ 1–2% 面積）；**主角是全遊戲唯一橙色佔比 > 2% 的存在**。
- **族譜**：Mike Mignola / Frank Miller / Paul Pope / Sean Murphy（漫畫線條與構圖）；The Last Night / NORCO / Olija / Citizen Sleeper（遊戲視覺）。
- 視覺一致性由 `assets/art_bible/` 的 5 張錨點圖鎖定。完整規範見 [`Art Bible.md`](./Art%20Bible.md)。

---

## 技術棧

- **引擎 / 語言**：Godot 4.6.3 stable、GDScript
- **架構**：`main.tscn` 常駐宿主 + `WorldRoot` 動態關卡 + `GameUI` 常駐 CanvasLayer；所有轉場走 `scene_id + entry_point_id`
- **Autoload**：`GameState`（全域狀態）、`UIMode`（UI 模式機）、`TouchControls`（觸控層）、`QuestManager`（任務）、`SaveSystem`（存讀檔）
- **存檔格式**：Godot 原生 `var_to_str` / `str_to_var` 純文字（非 JSON、非 ResourceSaver），10 槽 `{meta, data}` header
- **素材生成**：agent-sprite-forge（`$generate2dsprite` / `$generate2dmap`），輸出落回 `assets/generated/`
- **輔助工具**：Python venv（Pillow / numpy，供素材後處理）
- **驗證**：Godot headless manual runner

---

## Quick Start

**前置要求**：Windows 10 / 11。

### 直接遊玩（最快）

執行 `builds/windows/` 內的最新 build（例如 `AfterTheModel_v0.7.11.exe`）即可進入標題畫面 → New Game。

> Build 透過 Git LFS 管理，clone 後需先 `git lfs pull` 才會取得實際 exe。

### 從原始碼開啟

1. 安裝 [Godot 4.6.3 stable](https://godotengine.org/download/archive/)（與對應 export templates）。
2. 用 Godot 開啟專案根目錄的 `project.godot`。
3. 按 F5 執行；主場景為 `scenes/ui/title_screen.tscn`。

### 操作

| Action | PC | 行動裝置 |
|---|---|---|
| 移動 | `WASD` / 方向鍵 | 左下虛擬方向鍵 |
| 互動 | `E` / 滑鼠左鍵 | 右下互動按鈕 |
| 背包 / 筆記 | `I` / `J` | 右上按鈕 |
| 選單 | `ESC` / `Tab` | 右上選單按鈕 |

---

## 目前進度

MVP 主線已推進至 **Phase 7 完成**（`PROJECT_BRIEF.md > Phase 進度` 為單一事實來源）：

| 範疇 | 狀態 |
|---|---|
| 公寓解謎鏈（B0–B9） | ✅ 完成並通過驗收 |
| 背包 / 容器 / 筆記 / 裝備 UI | ✅ 完成 |
| 開場獨白序列 | ✅ 完成 |
| 觸控化（世界 / 面板 / 對話路由） | ✅ 完成（headless PASS，部分純觸控 GUI 走查待跑） |
| 跨場景架構（SceneRouter / GameUI / contract） | ✅ 完成 |
| NPC「晚」+ 對話系統（真系統） | ✅ 完成 |
| SaveSystem（多槽 / 標題 / 暫停選單 / 邊界處理） | ✅ 完成 |
| QuestManager + 零工任務 vertical slice + 結局分支 | ✅ 完成 |

**目前可玩場景**：`apartment_room`（公寓房間）、`apartment_entrance`（公寓門廳）、`apartment_fire_escape`（火逃梯外牆）。

MVP 目標範圍：一條街 + 一個地鐵站 + 一個小公寓 + 2 NPC + 1 零工任務。後續：街道與地鐵場景、iOS 真機導出與校正。

---

## 目錄結構（精簡）

```text
.
├── project.godot
├── scenes/
│   ├── main/            # main.tscn 常駐宿主 + SceneRouter
│   ├── ui/              # 標題、GameUI、背包/容器/筆記/對話面板、Toast
│   ├── levels/apartment/    # 公寓房間 / 門廳 / 火逃梯場景
│   └── actors/player/  # 主角移動
├── scripts/
│   ├── autoload/        # game_state、ui_mode、touch_controls、quest_manager、save_system
│   └── components/      # interactable_area 互動物
├── data/dialogue/       # 對話樹資料（晚 + dialogue_db）
├── tests/manual/        # headless test_runner / verify_game_state
├── assets/
│   ├── art_bible/       # 視覺錨點與 prompt
│   └── generated/       # AI 生成 map / sprite / item icons
├── subdocs/             # 角色設定（人/）、場景規格（地點/）
├── builds/windows/      # Windows build（Git LFS）
└── 舊文件/              # 歷史 archive（忽略）
```

完整目錄與檔案說明見 [`PROJECT_BRIEF.md`](./PROJECT_BRIEF.md)。

---

## 文件導覽

| 文件 | 用途 |
|---|---|
| [`PROJECT_BRIEF.md`](./PROJECT_BRIEF.md) | **新 session 入口**；架構、Phase 進度、規格索引 |
| [`遊戲概念.md`](./遊戲概念.md) | 世界觀、玩家定位、都市調性 |
| [`技術概念.md`](./技術概念.md) | Godot 選型、MVP 技術方向、平台路線、輸入 / UI / 存檔 / debug 架構決策 |
| [`Art Bible.md`](./Art%20Bible.md) | 美術方向、限色、構圖紀律、3 個視覺錨點；任何素材工作必讀 |
| [`遊戲規格書.md`](./遊戲規格書.md) | 全遊戲通用系統規格與驗收條件、Phase 規劃 |
| [`開發設計方針.md`](./開發設計方針.md) | Phase 2 起的實作契約、API、資料欄位、接線規則 |
| [`測試指南.md`](./測試指南.md) | Headless 命令、手動驗收清單 |
| [`驗證後已知問題.md`](./驗證後已知問題.md) | 待修清單與已接受的邊界決定 |

---

## 驗證

Godot headless 手動測試：

```powershell
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/manual/test_runner.tscn
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . -s res://tests/manual/verify_game_state.gd
```

最近一次 Phase 7 結果：`test_runner.tscn` PASS、`verify_game_state.gd` PASS。

---

## 授權

本專案為個人開發中作品，目前尚未附正式授權條款（保留所有權利）。僅供開發與內部測試使用。

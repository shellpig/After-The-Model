# Agent Instructions

# After-The-Model

《After-The-Model》是一款 2D 橫向開放世界 cyberpunk 遊戲，描寫「AI 改變世界之後，普通人怎麼活下去」。

- **類型**：2D 橫向探索 / 都市漫遊 / 碎片化敘事
- **目標平台**：Steam（Windows/macOS/Linux）+ iOS + Android
- **引擎**：Godot 4.6.3 / GDScript
- **目前進度**：概念、技術方向、美術風格（HD 2D 插畫 + riso）、視角（純 2D 側捲 + light platforming）均已確認。MVP 範圍為一條街 + 一個地鐵站 + 一個小公寓 + 2 NPC + 1 零工任務。
  - **Phase 1-A** ✅ GameState autoload（credits / 背包 / 裝備 / 知識 / 筆記 / 容器 / signals）+ 公寓大門知識 gate
  - **Phase 1-B** 待開工：UIMode autoload + 背包 UI（`I`）
  - Phase 1-C / 1-D / 1-E：筆記 UI / 容器資料化 + 雙欄 / 物品操作（查看 / 丟棄 / 裝備）
  - **Phase 2** 公寓解謎（取得 `identity_door_unlock_method` 路徑設計）
  - Phase 3+：SceneRouter、第二個場景、NPC、零工
  - 詳細規劃見 `遊戲規格書.md > Phase 規劃`

## New Conversation Opening Check

At conversation start, read in this layered order. Ignore `舊文件/`.

**Layer 1 — 必讀（建立全貌）：**
1. `AGENTS.md`（本檔）
2. `遊戲概念.md`（世界觀、玩家定位、氛圍）
3. `技術概念.md`（架構、工具鏈、MVP 架構決策）
4. `Art Bible.md`（美術方向、限色、構圖紀律、3 個視覺錨點）
5. `遊戲規格書.md`（全遊戲通用系統規格與驗收條件；場景專屬規格 link 到 `subdocs/地點/`）
6. `git log --oneline -10`（近期變更）

**Layer 2 — 規劃中文件（存在則讀，目前可能尚未產出）：**
- `開發設計方針.md` — 實作細節、檔案結構、Autoload 簽名、資料契約（系統長到 3-4 個再從規格書拆出）
- `測試指南.md` — Godot 測試流程、手動驗收清單（第一個 phase 收尾時建立）
- `驗證後已知問題.md` — 待修清單與已接受的邊界決定（第一個 phase 收尾時建立）

**Layer 3 — 任務相關細節與實作參考：**

次要細節文件統一放在 `subdocs/`，按主題分子資料夾，依當前任務需要讀取：

- `subdocs/人/` — 角色設定（主角、NPC、收藏家...）
  - `主角設定.md` — 主角身份（AI 善後員 + 拾遺者）、玩法、敘事框架
- `subdocs/地點/` — 場景專屬規格（敘事、互動物、驗收方向）；只在該場景 phase 開工時新增
  - `主角公寓.md` — 第一個可玩場景（室內探索 → 取得開門知識）
- 未來會加入其他主題分類（例如 `任務/`、`對話/`、`美術/`）

實作時也會參考：
- Godot 專案 source code（建立後）
- agent-sprite-forge 工具（位置見「專案外部工具路徑」）

Report to user: current progress, and any issues with their scope of impact.

## Project Skills

This project uses local skills from `C:\_work\AI_Work\Skills\`.

Trigger rules:
- Diagnosing bugs / analyzing errors / finding root cause → read `Skills\engineering\diagnose\SKILL.md` first
- Requirements unclear / spec discussion / planning / need to ask clarifying questions → read `Skills\productivity\grill-me\SKILL.md` first
- Frontend / local web app verification, UI behavior debugging, browser screenshots, or console logs → read `Skills\engineering\webapp-testing\SKILL.md` first
- Normal state / no urgent or special situation → read `Skills\productivity\caveman\SKILL.md` first

Only modify files when user explicitly requests fix, implement, or commit. Verify/diagnose = report only.

## Generate 2D Asset Shorthand

When the user says `g2d 生 XXX 圖`, `g2d generate XXX image`, or any close shorthand:

- If `XXX` is a place, location, level, room, street, station, apartment, map, area, environment, or scene, use `$generate2dmap`.
- If `XXX` is not a place/location, use `$generate2dsprite`.
- Do not ask the user to choose between the two when the noun clearly implies one category.

Default output paths:

- Map/location outputs: `C:\_work\AI_Work\Projects\AfterTheModel\assets\generated\maps\<asset_name>\`
- Sprite/non-location outputs: `C:\_work\AI_Work\Projects\AfterTheModel\assets\generated\sprites\<asset_name>\<action_or_variant>\`

Keep generated raw images, processed transparent sheets, frame PNGs, GIF previews, prompts, and metadata inside the chosen asset folder unless the user explicitly requests a different path.

Image generation handling:

- Built-in `image_gen` may save new images under Codex's generated image cache first. After every generation, copy the actual PNG/image file back into the selected project output folder. Do not leave only the prompt text in the project folder.
- Use unique timestamp-style suffixes down to seconds for generated prompt and image filenames to avoid collisions, for example `main-character-concept-20260525-164029.png` and `main-character-concept-20260525-164029.prompt.txt`. Do not reuse generic names such as `prompt-used.txt` or `concept.png` when creating new generated assets.


## 文件

**已建立：**
- `遊戲概念.md` — 世界觀與遊戲調性
- `技術概念.md` — 引擎選型、MVP 架構決策、發佈路線
- `Art Bible.md` — 美術方向、限色、構圖紀律、視覺錨點
- `遊戲規格書.md` — 全遊戲通用系統規格與驗收條件（前身為 `遊戲架構.md`，2026-05-28 改名）
- `subdocs/地點/主角公寓.md` — 第一個場景（公寓室內探索）的敘事、互動物、驗收方向

**規劃中：**
- `開發設計方針.md` — 實作指引（檔案清單、Autoload 簽名、資料契約）。系統長到 3-4 個再從規格書拆出。
- `測試指南.md` — 測試流程與手動驗收清單。第一個 phase 收尾時建立。
- `驗證後已知問題.md` — 驗收問題追蹤與已接受的邊界決定。第一個 phase 收尾時建立。
- `PROJECT_BRIEF.md` — 專案總覽與 Phase 進度表。規格書 + 設計方針合計 > 100 KB 時才建立；在那之前 `AGENTS.md` 即事實上的 brief。

技術主線與架構決策維護在 `技術概念.md`，避免雙份內容漂移。
場景專屬規格只在該 phase 開工時才寫進 `subdocs/地點/`，完成後 freeze 為歷史快照；不預建空殼。

## 專案外部工具路徑

外部工具不放進本專案 repo，避免汙染遊戲程式碼。

| 工具 | 路徑 | 用途 |
|---|---|---|
| agent-sprite-forge | `C:\_work\AI_Work\Tools\agent-sprite-forge` | AI 生成 2D sprite / map / prop |
| Godot 4.6.3 editor | `C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64.exe` | 引擎（GUI 版） |
| Godot 4.6.3 console | `C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe` | 引擎（CLI 版，用於 `--version` / headless export） |
| Godot export templates | `C:\Users\User\AppData\Roaming\Godot\export_templates\4.6.3.stable\` | ⚠️ **待安裝**（匯出 .exe/.apk/.ipa 必需，回家裝） |
| Codex DeepSeek home | `C:\_work\AI_Work\Tools\codex-deepseek-home` | DS reviewer 環境 |

## Art Bible 規則

- 在生第 5 張 sprite 之前必須完成 art bible
- 否則 AI 生成素材風格漂移後回不去
- 內容規格見 `技術概念.md` 之「agent-sprite-forge 使用方式」段落（角色比例、色盤、線條粗細、陰影規則、富/貧區視覺差異、霓虹/雨夜/CRT 等元素）
- art bible 完成後放在專案根目錄，並列入 Layer 1 必讀


## 驗證模式規則

當使用者要求「驗證」時，只能進行檢查、讀檔、執行測試、啟動本機服務與回報結果。

除非使用者明確要求「修」、「修改」、「commit」或「提交」，否則不得：

- 修改任何程式碼或文件
- 自行套 patch
- stage 檔案
- 建立 commit

若驗證中發現問題，只列出問題、影響範圍與建議修法，等待使用者下一步指示。

## 修改程式碼授權規則

除非使用者明確要求「修」、「修改」、「實作」、「處理某個 phase」、「commit」或「提交」，否則不得修改任何程式碼、文件或設定檔。

當使用者只是描述錯誤、貼截圖、詢問原因、要求解釋、要求列出問題、要求驗證，或詢問某功能怎麼使用時，只能分析與回報，不得自行套 patch。

## Python 執行環境規則

後續執行測試、匯入驗證、腳本執行時，預設固定使用專案虛擬環境：

- `.\.venv\Scripts\python.exe`

目標是讓 Agent 與使用者看到一致結果，避免誤用其他全域或內建 runtime Python。

## DeepSeek Codex CLI Reviewer

When the user says "要 ds4 pro 做 XXX", "要 ds4 flash 做 XXX", or similar wording, run the task through Codex CLI via the local Moon Bridge DeepSeek setup.

Model mapping:
- `ds4 pro` → `deepseek-v4-pro`
- `ds4 flash` → `deepseek-v4-flash`
- If the user says `ds4` without specifying `pro` or `flash`, use `deepseek-v4-pro`.

Default mode: read-only reviewer.
- Use `CODEX_HOME=C:\_work\AI_Work\Tools\codex-deepseek-home`.
- No file writes, deletes, staging, commits, or pushes.
- Do not read `.env`, `data/`, `舊文件/`, or `C:\_work\AI_Work\Tools\`.
- Treat output as second opinion; review it before reporting.

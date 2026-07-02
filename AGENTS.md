# Agent Instructions

# After-The-Model

《After-The-Model》是一款 2D 橫向開放世界 cyberpunk 遊戲，描寫「AI 改變世界之後，普通人怎麼活下去」。

- **類型**：2D 橫向探索 / 都市漫遊 / 碎片化敘事
- **目標平台**：Steam（Windows/macOS/Linux）+ iOS + Android
- **引擎**：Godot 4.6.3 / GDScript
- **目前進度**：概念、技術方向、美術風格（HD 2D 插畫 + riso）、視角（純 2D 側捲 + light platforming）均已確認。
  - Phase 進度清單（單一事實來源）見 `PROJECT_BRIEF.md > Phase 進度`；詳細規劃見 `遊戲規格書.md > Phase 規劃`。

## New Conversation Opening Check

At conversation start, read in this layered order. Ignore `舊文件/`.

**Layer 1 — 必讀（建立全貌）：**
1. `AGENTS.md`（本檔）
2. `PROJECT_BRIEF.md`
3. `遊戲規格書.md`（全遊戲通用系統規格與驗收條件；場景專屬規格 link 到 `subdocs/地點/`）
4. `git log --oneline -10`（近期變更）

**Layer 2 — 實作 / 測試文件：**
- `開發設計方針.md` ✅ 實作細節、檔案結構、Autoload 簽名、資料契約（自 Phase 2 起新寫，不 backfill Phase 1）
- `測試指南.md` ✅ Godot 測試流程、手動驗收清單（自 Phase 2 起新寫，不 backfill Phase 1）
- `驗證後已知問題.md` — 待修清單與已接受的邊界決定

**Layer 3 — 任務相關細節與實作參考：**
- `Art Bible.md`（美術方向、限色、構圖紀律、3 個視覺錨點）

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
- Planning game specs / verification with code review → read `Skills\gamestudio\SKILL.md` first
- Frontend / local web app verification, UI behavior debugging, browser screenshots, or console logs → read `Skills\engineering\webapp-testing\SKILL.md` first


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


## 專案外部工具路徑

外部工具不放進本專案 repo，避免汙染遊戲程式碼。

| 工具 | 路徑 | 用途 |
|---|---|---|
| agent-sprite-forge | `C:\_work\AI_Work\Tools\agent-sprite-forge` | AI 生成 2D sprite / map / prop |
| Godot 4.6.3 editor | `C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64.exe` | 引擎（GUI 版） |
| Godot 4.6.3 console | `C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe` | 引擎（CLI 版，用於 `--version` / headless export） |
| Godot export templates | `C:\Users\User\AppData\Roaming\Godot\export_templates\4.6.3.stable\` | ✅ 已安裝（Windows / Linux / macOS / iOS / Android / Web 全平台 templates 齊全） |
| Codex DeepSeek home | `C:\_work\AI_Work\Tools\codex-deepseek-home` | DS reviewer 環境 |

## Art Bible 規則

- 在生第 5 張 sprite 之前必須完成 art bible
- 否則 AI 生成素材風格漂移後回不去
- 內容規格見 `技術概念.md` 之「agent-sprite-forge 使用方式」段落（角色比例、色盤、線條粗細、陰影規則、富/貧區視覺差異、霓虹/雨夜/CRT 等元素）
- art bible 完成後放在專案根目錄，並列入 Layer 1 必讀


## 重要通用規則

當使用者要求「驗證」時，只能進行檢查、讀檔、執行測試、code review、啟動本機服務與回報結果。

除非使用者明確要求「修」、「修改」、「commit」或「提交」，否則不得：

- 修改任何程式碼或文件
- 自行套 patch
- stage 檔案
- 建立 commit

若驗證中發現問題，只列出問題、影響範圍與建議修法，等待使用者下一步指示。

### Godot Headless 驗證

在目前 Windows / sandbox 環境中，Godot headless 直接在 sandbox 內執行會因無法開啟 `user://logs/godot*.log` 而 crash（signal 11）。

執行 Godot headless 驗證時，不要先跑 sandbox 版再讓它 crash；直接用 escalated 權限執行同一命令並回報這是已知 sandbox log 權限限制。

常用命令：

```powershell
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/manual/test_runner.tscn
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . -s res://tests/manual/verify_game_state.gd
```

## 修改程式碼授權規則

除非使用者明確要求「修」、「修改」、「實作」、「處理某個 phase」、「commit」或「提交」，否則不得修改任何程式碼、文件或設定檔。

實作者在寫程式碼時必須留意新的變數名稱不可以太簡單通用導致發生同名稱變數的錯誤

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

## 實作安全與編譯驗證守則

1. **避免長函式變數衝突（後綴規範）**：在大型或長函式（如 `test_runner.gd` 等集成測試檔案）中撰寫程式碼時，所有新增的變數（如 `save_dict`, `runner`, `initial_trace` 等）必須加上專屬後綴（例如以 Phase 名或特色標註，如 `save_dict_phase21`），絕不宣告簡單的同名通用變數。
2. **API 簽名預先核對**：調用任何專案內自訂腳本、Autoload、DialogueRunner 等 API 前，必須主動使用 `grep_search` 或 `view_file` 核對其最新定義、方法名稱與參數列，不憑記憶編寫調用。
3. **編譯錯誤同 Turn 自主修復**：執行測試或語法檢查指令時，將 `WaitMsBeforeAsync` 設定為最大值（如 `10000`ms），以同步模式取得編譯/測試結果。若有錯誤，必須在同一個 turn 內直接修正並重新驗證，直到測試完全通過後才結束回合，不讓編譯錯誤流向使用者。

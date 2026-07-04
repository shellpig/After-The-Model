# Agent Instructions

# After-The-Model

《After-The-Model》是一款 2D 橫向開放世界 cyberpunk 遊戲，描寫「AI 改變世界之後，普通人怎麼活下去」。

- **類型**：2D 橫向探索 / 都市漫遊 / 碎片化敘事
- **目標平台**：Steam（Windows/macOS/Linux）+ iOS + Android
- **引擎**：Godot 4.6.3 / GDScript
- **目前進度**：以 `PROJECT_BRIEF.md` 頂部「當前進度」一行與 `> Phase 進度` 表為單一事實來源；詳細規劃見 `遊戲規格書.md > Phase 規劃`。

## New Conversation Opening Check

At conversation start, read in this layered order. `舊文件/` 是本機歷史 archive（不在 repo 中），永遠忽略。

**Layer 1 — 必讀（建立全貌）：**
1. `AGENTS.md`（本檔）
2. `PROJECT_BRIEF.md`（頂部「當前進度」+ Phase 進度一行版索引 + 文件索引）
3. `git log --oneline -10`（近期變更）

**Layer 2 — 按任務讀對應段落（勿整份讀，見下方「按 Phase 查閱規則」）：**
- `遊戲規格書.md` — 全遊戲通用系統規格與各 Phase 驗收意圖（what must be true）
- `開發設計方針.md` — Phase 2 起實作契約：API、資料欄位、接線規則（自 Phase 2 起新寫，不 backfill Phase 1）
- `測試指南.md` — Godot 測試流程、各 Phase 手動驗收清單（自 Phase 2 起新寫，不 backfill Phase 1）
- `驗證後已知問題.md` — 待修清單與已接受的邊界決定；修 bug 前先看

**Layer 3 — 任務相關細節與實作參考：**
- `Art Bible.md` — 任何生圖 / 素材 / 視覺任務**必讀**（美術方向、限色、構圖紀律、視覺錨點）；其他任務不必讀
- `subdocs/` 次要細節文件，按主題分子資料夾，依當前任務需要讀取（**不逐檔枚舉，開工時 `ls subdocs/<分類>/` 再挑**）：
  - `subdocs/主線/` — 主線劇情文本與版本演進；最新定稿 `雨還沒停v2.3.md`（敘事事實來源）
  - `subdocs/人/` — 角色設定（主角、晚、鹿其琛、三張臉…）
  - `subdocs/地點/` — 場景專屬規格（敘事、互動物、驗收方向）；只在該場景 phase 開工時新增
  - `subdocs/歸檔/` — 歷史歸檔（Phase 進度詳表等）；除非考古不必讀
- Godot 專案 source code；場景註冊表在 `scenes/main/main.gd` 的 `SCENES`

Report to user: current progress, and any issues with their scope of impact.

### 按 Phase 查閱規則

三份大文件（`遊戲規格書.md` / `開發設計方針.md` / `測試指南.md`）皆數千行，**任何情況下都不要整份讀**。查 Phase N 的規格 / 契約 / 測試清單時，用標題 grep 定位、只讀該段（讀到下一個同級標題為止）：

```
grep -n "Phase N" 遊戲規格書.md 開發設計方針.md 測試指南.md   # 先看命中的標題列
```

- 三份文件的 Phase 段落標題（`##`~`####`）都含 `Phase N` 字樣；`開發設計方針.md` 的 Phase 23+ 標題格式為 `### <主題>（Phase N，實作契約）`。
- **不要依賴文件行號**——行號隨編輯漂移；一律以標題定位。
- 已完成 phase 的詳細 changelog（決策記錄、commit 對照）見 `subdocs/歸檔/PROJECT_BRIEF_phase進度詳表.md`。

## 修改授權與驗證規則

（單一事實來源；其他文件不重複本節內容。）

除非使用者明確要求「修」、「修改」、「實作」、「處理某個 phase」、「commit」或「提交」，否則不得：

- 修改任何程式碼、文件或設定檔
- 自行套 patch
- stage 檔案
- 建立 commit

當使用者要求「驗證」，或只是描述錯誤、貼截圖、詢問原因、要求解釋、要求列出問題、詢問某功能怎麼使用時：只能進行檢查、讀檔、執行測試、code review、啟動本機服務與回報結果。若發現問題，只列出問題、影響範圍與建議修法，等待使用者下一步指示。

(English mirror: only modify files when the user explicitly requests fix / implement / commit. Verify / diagnose = report only.)

## 素材生成規則

- 任何生圖 / 素材任務前必讀 `Art Bible.md`，防止 AI 生成素材風格漂移。
- 生圖輸出必須落回 `assets/generated/...`，保留 prompt / raw / processed / metadata。
- 不要把 `agent-sprite-forge` repo 放進本專案。
- 生成工具與 `g2d` shorthand 細節見下方「本機 Windows 環境專用」段。

## 實作安全與編譯驗證守則

1. **避免長函式變數衝突（後綴規範）**：在大型或長函式（如 `test_runner.gd` 等集成測試檔案）中撰寫程式碼時，所有新增的變數（如 `save_dict`, `runner`, `initial_trace` 等）必須加上專屬後綴（例如以 Phase 名或特色標註，如 `save_dict_phase21`），絕不宣告簡單通用的同名變數。
2. **API 簽名預先核對**：調用任何專案內自訂腳本、Autoload、DialogueRunner 等 API 前，必須主動 grep / 讀檔核對其最新定義、方法名稱與參數列，不憑記憶編寫調用。
3. **編譯錯誤同 Turn 自主修復**：執行測試或語法檢查指令時，以同步模式取得編譯 / 測試結果（如 `WaitMsBeforeAsync` 設最大值 `10000`ms）。若有錯誤，必須在同一個 turn 內直接修正並重新驗證，直到測試完全通過後才結束回合，不讓編譯錯誤流向使用者。

---

## 本機 Windows 環境專用

> 本段僅適用於使用者本機 Windows 環境（工具都在 `C:\`）。**remote / CI / Linux session 沒有這些路徑與工具，跳過本段**；此類 session 無法執行 Godot headless，驗證項目列出後交回本機執行。

### Project Skills

This project uses local skills from `C:\_work\AI_Work\Skills\`.

Trigger rules:
- Diagnosing bugs / analyzing errors / finding root cause → read `Skills\engineering\diagnose\SKILL.md` first
- Requirements unclear / spec discussion / planning / need to ask clarifying questions → read `Skills\productivity\grill-me\SKILL.md` first
- Planning game specs / verification with code review → read `Skills\gamestudio\SKILL.md` first
- Frontend / local web app verification, UI behavior debugging, browser screenshots, or console logs → read `Skills\engineering\webapp-testing\SKILL.md` first

### 專案外部工具路徑

外部工具不放進本專案 repo，避免汙染遊戲程式碼。

| 工具 | 路徑 | 用途 |
|---|---|---|
| agent-sprite-forge | `C:\_work\AI_Work\Tools\agent-sprite-forge` | AI 生成 2D sprite / map / prop |
| Godot 4.6.3 editor | `C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64.exe` | 引擎（GUI 版） |
| Godot 4.6.3 console | `C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe` | 引擎（CLI 版，用於 `--version` / headless export） |
| Godot export templates | `C:\Users\User\AppData\Roaming\Godot\export_templates\4.6.3.stable\` | ✅ 已安裝（全平台 templates 齊全） |
| Codex DeepSeek home | `C:\_work\AI_Work\Tools\codex-deepseek-home` | DS reviewer 環境 |

### Godot Headless 驗證

在本機 Windows / sandbox 環境中，Godot headless 直接在 sandbox 內執行會因無法開啟 `user://logs/godot*.log` 而 crash（signal 11）。執行 headless 驗證時，不要先跑 sandbox 版再讓它 crash；直接用 escalated 權限執行同一命令並回報這是已知 sandbox log 權限限制。

常用命令：

```powershell
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/manual/test_runner.tscn
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . -s res://tests/manual/verify_game_state.gd
```

搬動 `.tscn` / `.gd` 或改 CSV 翻譯後，headless 前先 `--import` 重建快取。

### Generate 2D Asset Shorthand

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

### Python 執行環境規則

執行測試、匯入驗證、腳本時，預設固定使用專案虛擬環境 `.\.venv\Scripts\python.exe`，讓 Agent 與使用者看到一致結果，避免誤用其他全域或內建 runtime Python。

### DeepSeek Codex CLI Reviewer

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

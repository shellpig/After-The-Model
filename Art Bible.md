# Art Bible — After-The-Model

> 全部美術產出（不管是 AI 生、人手繪、或外包）都要照本書走。
> 第 5 張 sprite 之前必須完成 Must 章節（已於 `AGENTS.md` 規範）。

## 章節索引（更新後請同步本段）

| # | 章節 | 狀態 |
|---|---|---|
| 1 | 核心風格宣言 | ✅ 已定稿 |
| 2 | 色盤（Palette） | ✅ 已定稿 |
| 3 | 角色（Characters） | ✅ 已定稿 |
| 4 | 環境 / 場景（Environments） | ⬜ TBD |
| 5 | 道具與機械（Props & Mechanicals） | ⚠️ 僅 MVP item icon 子集已定稿；全章 TBD |
| 6 | 光照與時段（Lighting & TimeOfDay） | ⬜ TBD |
| 7 | UI / 字體 | ⬜ Post-MVP |
| 8 | 動畫指引（Animation） | ⬜ Post-MVP |
| 9 | 特效（VFX） | ⬜ Post-MVP |
| 10 | AI prompt 模板 | ⬜ 將從 2-6 章結論濃縮 |
| 11 | 禁用清單（Anti-patterns） | ⬜ 將從各章累積 |

---

## Chapter 1 — 核心風格宣言

### 一句話定位

> **「一本 2030 年便利店架上被遺忘的廉價 cyberpunk zine 上的世界——印著美式獨立漫畫的線、染著夜班的疲憊、留著人類用過的痕跡。」**

未來生圖、發包、外部協作者讀到「這個 NPC / 場景 / 道具該怎麼畫」時，**這句話是答案的起點**。

### 視覺基底

整個遊戲的視覺像：

- **被使用過很久的物件**——磨損、刮痕、貼紙、補丁、水漬、貼上去又撕掉留下的膠帶痕。不是「污穢」，是「有人在這裡待過」。
- **美式獨立 cyberpunk 漫畫的印刷感**——手繪墨線、線條粗細變化、半色調網點（halftone）、riso 印刷套色偶爾錯位 1 像素。
- **限定色盤的紀律**——deep teal、ink purple-black、gray-blue 為基底。faded amber、burnt orange、cold cyan、magenta 只在小面積跳色。**不用純白、不用純黑**。
- **大塊黑 + 焦點集中**——Mignola 流派：用「不畫」比「畫」更說故事。大面積陰影 + 一個明確光源。
- **平面側剖（FLAT PROFILE）**——所有物件都是「貼牆的紙板剪影」，留地面通道讓角色能左右走、互動判定才乾淨。

### 三大主軸（依比例融合）

| 主軸 | 比例 | 體現方式 |
|---|---|---|
| **痕跡（對抗遺忘）** | 主 | 物件磨損、海報撕角、牆面裂縫、舊地圖、貼紙、膠帶痕、便宜合成纖維感 |
| **印刷（廉價 zine 感）** | 中 | Halftone 網點、riso 套色錯位、不純色、紙質感、手繪墨線 |
| **疲憊（夜班城市）** | 中 | 大塊陰影、雨後反光、暖光點綴在冷色海中、deep teal 主調 |

→ 這三個不是分離的選項，是**同一個美學的三個面向**。每張產出應該**同時**具備三個元素。

### 美學族譜

#### 美式獨立漫畫（線條 + 構圖）

| 作者 / 作品 | 借什麼 |
|---|---|
| **Mike Mignola**（Hellboy） | **留黑大師** — 整格 70% 純黑色塊、用「不畫」說故事 |
| **Frank Miller**（Sin City） | 強 chiaroscuro，明暗對比即敘事 |
| **Paul Pope**（THB, Battling Boy） | 手繪線條呼吸感、粗細變化 |
| **Sean Murphy**（Tokyo Ghost） | 城市質感、cyberpunk 線條張力 |
| **Brandon Graham**（King City） | 細節密度但有 negative space |
| Geof Darrow | 構圖紀律、極致細節（少量參考） |
| Tsutomu Nihei 早期 | 黑白線條張力（少量參考） |

#### 遊戲視覺族譜

| 遊戲 | 借什麼 |
|---|---|
| **The Last Night** | 視角骨幹、parallax 城市、cyberpunk 氛圍（最近的參考） |
| **NORCO** | 碎片化敘事 + 厚塗 + 平民視角 |
| **Olija** | 純橫向敘事 + 探索節奏 |
| **Citizen Sleeper** | 太空底層生存美學 |
| **Ranx (1990)** | 視角結構源頭，但調性比它柔 |
| **Hyper Light Drifter** | 色盤紀律（雖然是真 pixel art） |
| **Hollow Knight** | 室內 cross-section 構圖 + 平台跳躍 |

### 不可妥協的 5 條核心規則

1. **純 2D 側視**（orthographic）—— 沒有透視、沒有 3/4 view、沒有 vanishing point
2. **不純白不純黑** —— 最亮 = faded cream，最暗 = deep purple-black
3. **限色 + 跳色紀律** —— cyan / magenta 只能用在小面積、發光物、霓虹招牌
4. **大塊黑 + 焦點集中** —— 每張至少有一個明確的暗色塊區域和一個明確的光源
5. **平面剖面（FLAT PROFILE）** —— 所有物件側剖，給角色留地面通道

### 不可出現的元素

- ❌ 透視線、消失點
- ❌ 純白 / 純黑
- ❌ 漸層平滑過渡、反鋸齒
- ❌ Anime 風格的光、亮眼、表情
- ❌ 3D rendered look、photorealism
- ❌ 大量飽和霓虹（cyberpunk cliché）
- ❌ 過度乾淨光滑的表面
- ❌ 物件以 3/4 view 朝畫面突出
- ❌ 街道 / 走廊往內延伸的透視深度

### 視覺錨點

本章的標準由以下三張參考圖鎖定。**未來所有產出應與這三張視覺一致**：

| 錨點 | 場景類型 | 路徑 |
|---|---|---|
| Anchor 01 | 戶外街景 | `assets/art_bible/anchor-01-convenience-store-corner.jpeg` |
| Anchor 02 | 室內（小公寓） | `assets/art_bible/anchor-02-apartment-interior.jpeg` |
| Anchor 03 | 地下空間 / 走廊 | `assets/art_bible/anchor-03-subway-b1-hall.jpeg` |

對應的生成 prompt（可作為新場景的模板）：

- `assets/art_bible/anchor-01.txt` — 戶外街景結構（3 層 parallax）
- `assets/art_bible/anchor-02.txt` — 室內房間結構（cross-section + zones）
- `assets/art_bible/anchor-03.txt` — 地下走廊結構（水平 3 區 + 垂直分層）

未來生新場景時，prompt 可加入這一行：

```
matching the visual style of anchor-01, anchor-02, anchor-03
in /assets/art_bible/
```

### 對應遊戲調性

主角是 **AI 善後員 + 拾遺者**（見 `subdocs/人/主角設定.md`）。視覺風格直接呼應人物設定：

| 主角的兩面 | 視覺對應 |
|---|---|
| **善後員**（機械、冰冷、藍領） | 整體 deep teal / gray-blue 主調、灰金屬質感、磨損機械感 |
| **拾遺者**（懷舊、人性、對抗遺忘） | 牆上海報、貼紙、印刷感、人類留下的痕跡、舊物收藏 |

兩條情緒線同時存在於同一張畫面 → **「冷城市裡的暖光、機械中的人味」**。

這也對應 `技術概念.md` 的 TimeOfDay enum：
- MORNING / AFTERNOON → 主軸偏「痕跡」（看得清細節）
- EVENING / LATE_NIGHT → 主軸偏「疲憊」（黑塊主導 + 光點）

---

---

## Chapter 2 — 色盤（Palette）

### 一句話定位

> **「三個區的顏色是三種階級語言：平民褪色但守住一點橙、富人黑得硬金得亮、AI 連顏色都不需要。」**

色彩不只是裝飾 — 是**階級敘事的工具**。玩家走過三個區的瞬間，眼睛立刻讀出社會結構。

### 三區色彩階級

| 區 | 顏色策略 | 居民態度 |
|---|---|---|
| **平民區** | 一切褪色，但**橙色還在** | 「我們什麼都沒有，但招牌不能熄」 |
| **富人區** | 硬黑、亮金、銳 cyber 紫 | 「我們維持得起顏色」 |
| **AI 區** | 近乎白、無機、扁平 | 「我們不需要顏色」 |

> 越往「上」走顏色越被剝奪，但**人類的痕跡（橙色 / 平民區）反而最有體溫**。

### 三區詳細色盤

#### 平民區（Plebeian District）— 基底
- **Base**：deep teal、ink purple-black、gray-blue、faded olive（家族）
- **Black**：保留 deep ink purple-black（不要 faded）
- **Ambient neon**：cyan、magenta、optionally faded violet（小範圍霓虹、店招、廣告）— **cyberpunk 必有的紫色在這裡以舊霓虹形式存在**
- **Interior warm**：faded amber / faded cream（室內燈、CRT、便利店內、escalator 頂的「surface 暗示」）— **跟焦點橙色嚴格區分**
- **★ Signature accent ★**：**SATURATED BURNT ORANGE**（敘事標記色，見下方 ORANGE SCALE RULE）

#### 富人區（Wealthy District）— 對比硬色
- **Base**：near-pure cold ink black（最硬的黑、~2% off true #000000）+ polished slate / dark chrome 中間調
- **Primary warm**：**GOLD / champagne / brushed brass**（夜總會入口光、招牌、tower window 內部、車輛 trim）
- **Primary cool accent**：**CYBER PURPLE / UV violet**（AI 在場的指示色 — 生物識別 scanner、aerial holo ad、安全 drone）
- **Composition**：~45-50% deep cold ink black + ~25% midtone + ~25-30% bright（gold + cyber 紫）
- **跟平民區的關鍵差**：黑是「擦得發亮」（不是「被磨」）、暖色是冷感的金黃（不是有體溫的橙）

#### AI 區（AI District）— 無色支配
- **Base**：**off-white with cool blue tint**（明顯非自然光、近乎純白但永遠不是 #FFFFFF）
- **Structural accent**：cool gray-blue（門框、scanner pylon、結構線、corporate sigil）
- **Interior void**：deep ink near-black — **只藏在門內深處的走廊盡頭**（這是 AI 區 Mignola 黑色塊的唯一位置，與外觀冷白形成 inverted contrast）
- **Saturated accent**：**CYBER PURPLE / UV violet**（biometric scanner、interior server hall LED 像星星、holo ad、drone）— 這是 AI 區的 native color，不是入侵者
- **NO warm color**（無 amber、無 gold、無 orange）— 色彩飢餓本身就是訊息
- 主角的橙色進入 AI 區 → 變成整張畫面唯一的飽和暖色 → 視覺直接說「你不屬於這裡」

### ★ ORANGE SCALE RULE（跨整個遊戲的鐵則）★

**Saturated burnt orange = 平民區的敘事標記色 ≠ 一般跳色**

橙色不是裝飾，是**「人類意志拒絕被遺忘」的視覺語言**。玩家看到飽和橙色 = 立刻意識「這裡有故事、有人留下了痕跡」。

#### 硬性規則（環境物件）

| 規則 | 數字 |
|---|---|
| **單張畫面總橙色面積** | ≤ 1-2% pixels |
| **單個橙色元素最大尺寸** | ≤ 一張小海報（head-height × half-head-width） |
| **單張畫面最多橙色點數** | 2 個（PRIMARY + SUPPORTING） |
| **橙色形式** | 永遠是 SHAPE（細管、glyph、icon、stripe、small patch），永遠不是 background fill |

#### Primary + Supporting 結構

每個有橙色的場景都按這個結構配：

- **PRIMARY 橙色錨點**：場景的主焦點（便利店招牌的某個細節、樂團海報的圖形、地鐵圖手繪路線等）
- **SUPPORTING 橙色錨點**：環境中另一個小元素，呼應 primary（牆角塗鴉、收藏品上的小標籤等）

#### 例外：主角自己

**主角是全遊戲唯一橙色佔比 > 2% 的存在**（右肩 patch + 雙手手套 ≈ 3-4%）。原因：他自己就是**行走的橙色標記**，視覺上必須在 AI 區跳出來。

詳細規範見 Ch3「主角設計鎖定」與 [`assets/art_bible/main-character.txt`](assets/art_bible/main-character.txt)。

#### 跨區互斥規則

| 區 | 不准用 |
|---|---|
| **平民區** | gold / brass（富人區）、saturated cyber-UV-violet（AI 區）、cool-white LED（AI 區）|
| **富人區** | cyan / magenta / 任何 faded ambient neon（平民區）、ink purple-black（平民區用的黑）、faded amber / burnt orange / rust（平民區）|
| **AI 區** | 任何 warm color（gold / amber / orange）、cyan / magenta、ink purple-black、weathering colors |

互斥規則保證**玩家一眼能認出自己在哪一區**，不需要 UI 提示。

### 兩種「暖色」的關鍵區分（平民區內部）

平民區有兩種完全不同功能的暖色，視覺上必須分清楚：

| 類型 | 顏色 | 用途 | 飽和度 |
|---|---|---|---|
| **Interior comfort 暖光** | faded amber / faded cream | 便利店內燈、床頭燈、CRT 螢幕、escalator 頂「surface 暗示」 | LOW（褪色感）|
| **Narrative marker 焦點** | **SATURATED BURNT ORANGE** | 招牌局部、樂團海報圖形、塗鴉、地鐵圖手繪路線 | HIGH（飽滿） |

★ 不要混淆 — interior amber 是「有人住在這裡」的舒適訊號，飽和橙色是「有人留下了標記」的敘事訊號。**只有後者是 ORANGE SCALE RULE 計入的橙色**。

### 兩種「黑」（跨區）

| 用途 | 顏色 | 出現在 |
|---|---|---|
| **環境陰影** | deep ink purple-black（平民區）/ near-pure cold ink black（富人區）/ 不用（AI 區外觀）| 場景天空、陰影、暗角 |
| **結構錨點** | deep ink solid（任何區）| 建築輪廓、招牌邊框、角色輪廓、Mignola 重黑塊 |
| **內部 void** | deep ink near-black | 平民區 = 巷弄裂縫等任何深陰影；富人區 = 沉默立面；**AI 區 = 只在門內深處走廊盡頭** |

### Halftone / 印刷感（跨章節呼應）

色盤紀律本身只是一半 — 另一半是**印刷感**。所有產出（場景 + 角色）都應該帶 halftone 點點：

- **平民區 anchor**：halftone 重、明顯（riso zine 質感）
- **富人區 anchor**：halftone 輕、稀疏（glossy luxury magazine 質感）
- **AI 區 anchor**：halftone 極少或無（algorithmic clean / corporate brochure 質感）
- **角色**：halftone 在 midtone，跟所在場景的 halftone 密度一致

詳細紀律見 Ch1 「美式獨立漫畫」段。

### 具體 hex 色票

目前尚未從 anchor 圖檔抽出具體 hex 值。待後續做 Godot palette resource 時統一抽出來，以 anchor-01 ~ anchor-05 作為色票基準。

### 視覺參考檔案

- 平民區：[`assets/art_bible/anchor-01.jpeg`](assets/art_bible/anchor-01.jpeg)（街景）、[`assets/art_bible/anchor-02.jpeg`](assets/art_bible/anchor-02.jpeg)（室內）、[`assets/art_bible/anchor-03.jpeg`](assets/art_bible/anchor-03.jpeg)（地鐵）
- 富人區：[`assets/art_bible/anchor-04.jpeg`](assets/art_bible/anchor-04.jpeg)（夜總會）
- AI 區：[`assets/art_bible/anchor-05.jpeg`](assets/art_bible/anchor-05.jpeg)（設施入口）
- 主角：[`assets/art_bible/main-character.jpeg`](assets/art_bible/main-character.jpeg)（待存）

---

## Chapter 3 — 角色

### 一句話定位

> **「主角是這個冷城市裡唯一還在閃光的橙色 — 走到哪裡，他都是那個拒絕被遺忘的提醒。」**

每個角色（主角、NPC、機器人）一律依本章規則繪製：渲染風格、剪影、橙色出現與否、臉部處理。

### ★ Rendering Style 鐵則（最重要的規則）★

所有角色一律走 **flat cel-shade indie comic** 風格，跟 anchor-01 ~ anchor-05 的場景**同一個視覺世界**。否則角色站進場景會違和（已被驗證會發生）。

#### 一定要有的元素

| 元素 | 細節 |
|---|---|
| **手繪粗黑墨線** | 外輪廓粗、內部細、有機 wobble、不要 CAD 般精準 |
| **Flat cel-shade** | 每件衣物 / 表面最多 3 個色階（base + shadow + 偶爾 highlight）、硬邊轉折、無漸層 |
| **Halftone 點點** | 中間調區域可見的網點，1990 年代影印 zine 質感 |
| **Mignola 黑色塊** | 最深陰影直接畫成實心黑色塊、不畫線 |
| **臉 = ~10 個墨點** | 眼兩個點、嘴一條線、鼻幾筆、stubble 幾點、皮膚 flat base + 1 個 shadow tone |

#### 絕對不要的元素

- ❌ 漸層、airbrush、軟陰影、subsurface scattering
- ❌ Photorealistic 皮膚 / 纖維 / 髮絲
- ❌ Anime cel（線太細、太乾淨、眼太大）
- ❌ Concept art / ArtStation portrait / semi-realistic
- ❌ 3D rendered look

#### 風格族譜（與 Ch1 對齊）

- **Mike Mignola** — Hellboy 角色面板（flat color + 重黑 + 極簡臉）
- **Paul Pope** — THB / Battling Boy 角色線稿
- **Sean Murphy** — Tokyo Ghost inked figures
- **Brandon Graham** — King City 角色
- **Streets of Rage 4** — HD 2D 角色 sprite
- **Hyper Light Drifter** — 角色 portrait

### 通用角色規則

#### 比例

- 7-8 頭身（真實成人）
- 不要 chibi、不要超英比例、不要瘦長 anime
- 站姿：放鬆、weight on one leg、肩膀有點塌
- 工作姿態：彎腰 / 蹲下 / 舉手 — 不要英雄站姿

#### 視角

| 用途 | 視角 |
|---|---|
| 概念設計圖 | 3/4 微側（~30° off frontal）|
| 遊戲內 sprite | 純側視（matches 場景的 orthographic side） |

#### ★ 192px 剪影紀律 ★

所有角色設計都以「**縮成 192px 高還要讀得出來**」為試金石。

三條硬性規則：

1. **多色帶剪影** — 上半身 / 下半身 / 鞋至少要有明顯色相差，不能整身同色（連身衣感）
2. **腳踝剪影斷點** — 鞋跟褲腿之間要有明顯形狀斷點（褲腳塞進靴內 / 靴口 cuff 設計 / 戰術 strap 等）
3. **跳色錨點都在上半身** — 橙色標記只能在胸口以上 + 雙手，不能放鞋帶 / 腰帶 / 褲腳。蹲下、走動時都不會被遮

#### 裝備規則

- ✅ 工具全部塞進**斜背包 / 後背包 / 口袋**內，外觀看不到
- ❌ **不要把工具掛在身上**（無工具腰帶、無外掛手電筒、無外掛相機、無外掛筆記本）
- 拾遺者 / 工程師 / 維修工的「身份」靠**包包剪影 + 一兩個小細節**暗示，不靠配件密度

### 主角設計鎖定

主角詳細身份設定見 [`subdocs/人/主角設定.md`](subdocs/人/主角設定.md)。本節只規範**視覺**。

#### 一句話視覺定位

> **「冷城市裡走動的橙色 — 善後員制服 + 拾遺者背包 + 兩隻染橙的手套。」**

#### 服裝規格（鎖定）

| 部位 | 規格 |
|---|---|
| **外套** | 高領 + 斜拉鍊（左肩到右髖）+ 袖子捲到前臂、deep teal、hip-length |
| **內衣** | 簡單 dark purple-black T |
| **褲子** | 暖色 faded military olive / khaki-brown cargo 褲 |
| **鞋** | 高筒戰術工裝靴 + 可見鞋帶 + 橫向 strap + 厚 lugged sole |
| **包** | 斜背 messenger bag、dark teal-brown、純樸無 patch |
| **手套** | Fingerless 工作手套（雙手）、黑底 + **大塊橙色背手板**（佔 60-70%）|
| **頭部** | 護目鏡掛額頭、髮短亂、stubble、疲憊 calm 表情 |

#### 橙色標記（locked）

| 位置 | 形式 |
|---|---|
| **PRIMARY** | 右肩 patch（small-playing-card 大、saturated burnt orange 底 + 抽象地下樂團 logo 圖）|
| **SUPPORTING** | 雙手 fingerless 手套背手板（黑底大塊橙、~60-70% 手套背面）|

★ **主角是全遊戲唯一橙色佔比 > 2% 的存在** ★

環境物件遵守 ~2% 規則（見 Ch2 / anchor 系列），但**主角自己就是行走的橙色標記**。他在三區的視覺角色：

| 場景 | 主角的視覺角色 |
|---|---|
| **平民區** | 跟招牌 / 海報 / 塗鴉的橙色呼應 — 他是「街上的人」之一 |
| **富人區** | 橙色衝撞 dark marble + gold + cyber purple — 視覺上明顯是闖入者 |
| **AI 區** | 整個畫面唯一的飽和暖色 — 強烈的「你不屬於這裡」訊號 |

#### 為什麼這樣設計（敘事邏輯）

主角是 **AI 善後員（主）+ 拾遺者（副）**。設計呼應雙身份：

- 善後員 → 工裝、戰術靴、護目鏡、油污感
- 拾遺者 → 包包（裝相機 / 筆記本 / 手電筒，外觀看不到 — 是秘密的另一面）
- **橙色 patch + 手套** → 他自己縫上去 / 染上去的「我選擇的標記」，呼應拾遺者「對抗遺忘」的主題

#### 參考檔案

- 鎖定設計 prompt：`assets/art_bible/main-character.txt`（待存）
- 鎖定參考圖：`assets/art_bible/main-character.jpeg`（待存）

### NPC 視覺規則

#### 各區 NPC 密度

| 區 | NPC 規則 |
|---|---|
| **平民區** | 可有多個 NPC、市井氣、工作中、疲憊、各種職業 |
| **富人區** | 極少 NPC，常常完全沒有（「無人 = 奢侈」）— 偶爾出現的也應該是極小剪影、看不清細節 |
| **AI 區** | **無人類 NPC**（除了主角同類的維修員工）。AI / 機器人 / drone 才是主角 |

#### 各區 NPC 服裝色

跟著該區 base palette 走：

| 區 | NPC 服裝主色 |
|---|---|
| **平民區** | deep teal / gray-blue / ink purple-black / faded olive（同主角家族）|
| **富人區** | 純黑 + 金 + 偶爾 cyber 紫 — 衣服剪裁俐落、布料貴氣 |
| **AI 區員工** | 工業灰 / off-white 制服 + 可能有 cyber 紫指示條 |

#### NPC 橙色出現條件

橙色是「拒絕被遺忘」的標記 — 不是裝飾。NPC 帶橙色的條件嚴格：

| NPC 類型 | 橙色 |
|---|---|
| **平民區普通人** | **大多沒有**橙色。少數有意義的 NPC（重要對話對象、收藏家、地下文化人）可帶**一個小橙色細節**（袖章、徽章、頭巾）|
| **富人區 NPC** | **絕對沒有橙色** — 他們不需要證明自己被記得 |
| **AI 區員工**（主角同類） | 可以有小橙色 — 因為他們是「在 AI 領地工作的人類」 |
| **故障 AI / 機器人** | 沒有橙色，但可有舊貼紙 / 油漬 / 人類維修痕跡（faded amber / brown 系，非飽和橙）|

橙色 NPC 本身就是一個敘事提示：**「這個 NPC 值得你停下來看」**。

### 機器人 / AI 角色

#### 共同規則

| 元素 | 規範 |
|---|---|
| 底色 | 工業灰 / cool gray-blue / off-white |
| 狀態燈 | **cyber 紫** LED / 指示條（這是 AI 在場的訊號色）|
| 線條 | 比人類角色更幾何、更精準（但仍是手繪墨線，不是 CAD）|
| 人類痕跡 | 可有舊貼紙 / 油漬 / 凹痕 / 鏽斑 — 暗示「被維修過很多次」 |

#### 三類差異

| 類型 | 視覺 | 對應任務 |
|---|---|---|
| **服務型** | 圓潤、矮、明顯功能型（清潔機器人、販賣機、送貨無人機）| 善後員每日工作目標 |
| **監視型** | 流線、細長、cyber 紫掃描光、不接近人 | 富人區 / AI 區常見背景元素 |
| **故障型** | 服務型 + 視覺異常（破皮、線路外露、姿勢扭曲、表情怪異）| 主角接案修理對象 |

故障型機器人是遊戲的**敘事載體** — 每隻故障 AI 都是一則小故事（胡言亂語、抱著無法送達的包裹、認過時的代幣）。視覺上要保留**怪異與荒謬感**，不要單純醜化。

### 臉與表情

#### 規則

- 臉 = **約 10 個手繪墨點**（眼兩點、嘴一線、鼻幾筆、stubble 幾點）
- 飽滿表情靠**剪影與肢體**傳達，不靠臉部
- 重要對話可拉近，但臉仍維持極簡墨點（不變 anime 大特寫）
- 夜色 / 室內 / halftone 把臉壓暗 — 「看不清楚的臉」是 feature 不是 bug

#### 禁用

- ❌ Anime 大眼、星星眼
- ❌ Photoreal 寫實眼睛
- ❌ 漫畫式誇張表情（驚嚇張嘴、眼睛變 X、汗滴）
- ❌ 過度可愛 / 萌系

### Anti-patterns 禁用清單

- ❌ Painterly / concept art / photoreal / semi-realistic 任何渲染風格
- ❌ Anime / 漫畫式誇張 / chibi / 超英比例
- ❌ 外掛工具（腰帶、手電筒、相機、筆記本都不能外露）
- ❌ 單色連身衣（三色帶硬性規則）
- ❌ 橙色濫用（環境物件 ≤ 2%、NPC 大多沒有、主角才是例外）
- ❌ 在 AI 區出現帶橙色的「住戶 NPC」（AI 區無人類住戶）
- ❌ 富人 NPC 帶橙色（破壞階級對比）
- ❌ 機器人帶橙色（橙色屬於人類意志）
- ❌ 飽和度過高的角色配色（環境是 desaturated，主角 + 橙色標記是唯一例外）

---

## Chapter 5 — Item Icon（MVP）

> Chapter 5「道具與機械」全章會在 MVP 場景規格定下來後完整撰寫。本段先鎖定 **背包 / 容器格內 item icon** 的最小規格，供 Phase 1-B 起的 UI 使用。

### 一句話定位

```text
icon 是平民區的隨身物品縮影
跟主角同調，但比角色 sprite 更安靜
不搶畫面，看一眼就懂是什麼
```

### 規格

| 項目 | 規格 |
|---|---|
| 解析度 | 64×64 像素，透明 PNG |
| 背景 | **完全透明**，不留底色框 |
| 視角 | 由上往下 15° 俯視；不正側、不正視 |
| 線稿粗細 | 1–2 px，色用深褐或黑（依物品材質可調） |
| 限色 | 從 Ch2 平民區色盤挑 3–5 色，避免飽和過高 |
| 陰影 | 單側 cell shading，光源統一右上 45°；不畫漸層 |
| Halftone | 可微量保留作 riso 顆粒，**不可** 蓋過主體輪廓 |
| 構圖 | 物件置中，邊緣留 4–6 px 安全距離 |

### 橙色規則

延伸 Ch2 ORANGE SCALE RULE：

- 一般 item icon **不使用橙色**（屬環境物件）。
- 例外：**主角隨身標記物**可帶橙色點綴（例如手套背板、徽章標記），但橙色面積 ≤ icon 總面積 10%。
- 富人區 / AI 區出處的 item 不可帶橙色（後續 chapter 補）。

### 不可出現

- ❌ 寫實渲染、photoreal、AI generic icon style
- ❌ 漸層、發光、外加邊框光
- ❌ 高彩度卡通配色
- ❌ 圓角矩形背景（純透明）
- ❌ 文字、數字、品牌 logo（破破爛爛的標籤線條可，但不寫字）

### Phase 1 MVP Icon 清單

對應 `ITEMS_DB` 四個 stub 物品，依本章規格繪製，輸出 64×64 透明 PNG 到：

```text
assets/generated/sprites/items/<item_id>/icon.png
```

| item_id | 中文名 | 視覺重點 | 色彩錨點 |
|---|---|---|---|
| `old_work_badge` | 磨損的工作證 | 舊式工作識別證，照片模糊；金屬掛繩或塑膠卡套；磨損痕跡明顯 | 卡其 / 灰金 / 暗褐；可微帶主角橙（識別條） |
| `fingerless_gloves` | 無指工作手套 | 黑底耐磨工作手套，**背手板亮橙色**（主角標記）| 黑 + 暗灰 + 主角橙（背手板） |
| `canned_food` | 合成罐頭 | 便宜合成肉罐頭，標籤可破損但能辨識「肉」感 | 鋼灰 / 暗紅標籤 / 米黃高光 |
| `faded_jacket` | 隱士防風夾克 | 低調防雨夾克，深色，口袋深；鬆垂質感 | 藏青 / 深灰 / 暗褐領口 |

### 生成流程

依 AGENTS.md「Generate 2D Asset Shorthand」：

```text
$generate2dsprite
  asset_name: <item_id>
  output: assets/generated/sprites/items/<item_id>/
```

生成後將正式採用版命名為 `icon.png` 放在 `items/<item_id>/icon.png`，過程稿與 prompt 文字留在同資料夾。

### 驗收

- 4 個 icon 並排觀看時，輪廓辨識度足夠（瞇眼看仍能區分）。
- 沒有任一張用了 Ch2 限色之外的顏色。
- 沒有橙色出現在 `old_work_badge`（除小面積識別條）、`canned_food`、`faded_jacket` 上。
- 把任一 icon 放到背包 64x64 slot 中央，邊緣不貼齊也不溢出。

---

*Chapter 4「環境」會在 MVP 場景規格定下來之後再寫（目前 anchor 系列已建立 5 個錨點，可作為環境繪製的工作模板）。Chapter 5 上述段落為 MVP icon 子集，全章「道具與機械」延後。*

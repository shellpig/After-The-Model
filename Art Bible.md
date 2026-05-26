# Art Bible — After-The-Model

> 全部美術產出（不管是 AI 生、人手繪、或外包）都要照本書走。
> 第 5 張 sprite 之前必須完成 Must 章節（已於 `AGENTS.md` 規範）。

## 章節索引

| # | 章節 | 狀態 |
|---|---|---|
| 1 | 核心風格宣言 | ✅ 已定稿 |
| 2 | 色盤（Palette） | ⬜ TBD |
| 3 | 角色（Characters） | ⬜ TBD |
| 4 | 環境 / 場景（Environments） | ⬜ TBD |
| 5 | 道具與機械（Props & Mechanicals） | ⬜ TBD |
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

*Chapter 2「色盤」將從這三張錨點抽取具體色票，下一輪討論定稿。*

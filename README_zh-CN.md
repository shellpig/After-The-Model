# After-The-Model

[English](./README.md) | [繁體中文](./README_zh-TW.md) | **简体中文**

![Godot](https://img.shields.io/badge/GODOT-4.6.3-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDSCRIPT-blue)
![Platform](https://img.shields.io/badge/PLATFORM-WINDOWS%20%7C%20iOS-0078D6?logo=windows&logoColor=white)
![Genre](https://img.shields.io/badge/GENRE-2D%20SIDE--SCROLL-purple)
![Status](https://img.shields.io/badge/STATUS-MVP%20IN%20DEVELOPMENT-orange)

> 一款 2D 横向探索 cyberpunk 游戏，主题是「AI 改变世界之后，普通人怎么活下去」。

不是英雄拯救世界，也不是打倒邪恶企业。你是 AI 后时代城市里的低阶层普通人，在霓虹与雨夜之间生活、接零工、拾回被系统抹掉的记忆。

---

## ⚠️ 开发状态

本项目为**开发中的个人作品**，目前处于 MVP 阶段。可玩内容、系统与美术素材都还在迭代，存档格式、场景与数值皆可能变动。尚未发行，亦未附正式授权条款。

---

## 游戏概念

**背景时间：2030 年左右。** AI 已彻底改变社会，但世界没有进入科幻电影式的未来——科技进步了，却不平均：有些地方高度自动化、极端先进；有些地方反而比现在更破败落后。

> 「高科技与社会失能同时存在」的世界。

| 光鲜的一面 | 阴暗的一面 |
|---|---|
| 无人便利店极度先进 | 地下道塞满失业人口 |
| AI 行政系统效率惊人 | 人类客服几乎消失 |
| 每个人都有 AI 助理 | 没人能真正申诉 AI 的错误 |
| 空中广告与自动化城市随处可见 | 人与人之间变得更加孤独 |

整体调性：**都市漫游 / 生存感 / 小事件 / 社会观察 / 碎片化叙事**。玩家不是世界中心，只是努力活下去的一个普通人。主角是 **AI 善后员 + 拾遗者**——白天替系统修正错误，私下拾回被抹掉的人类痕迹。

---

## 世界的三个区

色彩即阶级语言，玩家走过三个区的瞬间，眼睛立刻读出社会结构：

| 区 | 视觉策略 | 居民态度 |
|---|---|---|
| **平民区** | 一切褪色，但**橙色还在** | 「我们什么都没有，但招牌不能熄」 |
| **富人区** | 硬黑、亮金、锐 cyber 紫 | 「我们维持得起颜色」 |
| **AI 区** | 近乎白、无机、扁平 | 「我们不需要颜色」 |

地铁是贯穿全城的「阶级流动系统」：一般车厢、AI VIP 车厢、躲票者聚集区、地下非法列车——车厢本身就是城市缩影。

---

## 玩法

- **纯 2D 侧卷**：角色只做 X 轴左右移动，搭配 light platforming（跨水沟、爬火逃梯、走天桥），服务「探索 + 漫游」而非动作挑战。
- **原地互动 vs 场景切换**：共用单一互动键（PC `E` / 触控互动按钮）。街上小物与站立 NPC 为原地互动；门 / 闸门 / 楼梯 / 窗户则触发场景切换。
- **背包与容器**：5×3 背包、可数据化的外部容器（白名单 / 锁定）、物品查看 / 丢弃 / 装备、笔记与知识系统。
- **解谜**：第一关公寓有一条完整解谜链（醒来失忆 → examine 取得线索 → 戴手套解码 → 声纳揭示插槽 → 取得开门知识 → 开门）。
- **NPC 对话**：条件路由的对话树（首见 / 重讲 / 好感与情报门槛），分支与 effect 即时反映于状态。
- **零工任务**：含任务状态系统与**多重结局分支**（是否交还隐藏模块会影响报酬、好感与后续招呼）。
- **存档**：10 槽手动存读、标题画面与暂停选单、回场坐标还原。
- **跨平台输入**：通过 Godot InputMap 抽象化，PC 键鼠与移动设备触控共用同一套 action；强制 landscape，UI 走 safe area 与 ≥44px 触控目标。

---

## 美术方向

> **「一本 2030 年便利店架上被遗忘的廉价 cyberpunk zine 上的世界——印着美式独立漫画的线、染着夜班的疲惫、留着人类用过的痕迹。」**

- **风格**：Riso-inspired HD 2D Cyberpunk（非 hard pixel art、非半绘画风）。
- **五条铁则**：纯 2D 侧视（无透视）、不纯白不纯黑、限色 + 跳色纪律、大块黑 + 焦点集中、平面剖面（FLAT PROFILE）。
- **橙色法则**：饱和橙是平民区「拒绝被遗忘」的叙事标记色（环境 ≤ 1–2% 面积）；**主角是全游戏唯一橙色占比 > 2% 的存在**。
- **谱系**：Mike Mignola / Frank Miller / Paul Pope / Sean Murphy（漫画线条与构图）；The Last Night / NORCO / Olija / Citizen Sleeper（游戏视觉）。
- 视觉一致性由 `assets/art_bible/` 的 5 张锚点图锁定。完整规范见 [`Art Bible.md`](./Art%20Bible.md)。

---

## 技术栈

- **引擎 / 语言**：Godot 4.6.3 stable、GDScript
- **架构**：`main.tscn` 常驻宿主 + `WorldRoot` 动态关卡 + `GameUI` 常驻 CanvasLayer；所有转场走 `scene_id + entry_point_id`
- **Autoload**：`GameState`（全局状态）、`UIMode`（UI 模式机）、`TouchControls`（触控层）、`QuestManager`（任务）、`SaveSystem`（存读档）
- **存档格式**：Godot 原生 `var_to_str` / `str_to_var` 纯文本（非 JSON、非 ResourceSaver），10 槽 `{meta, data}` header
- **素材生成**：agent-sprite-forge（`$generate2dsprite` / `$generate2dmap`），输出落回 `assets/generated/`
- **辅助工具**：Python venv（Pillow / numpy，供素材后处理）
- **验证**：Godot headless manual runner

---

## Quick Start

**前置要求**：Windows 10 / 11。

### 直接游玩（最快）

运行 `builds/windows/` 内的最新 build（例如 `AfterTheModel_v0.7.11.exe`）即可进入标题画面 → New Game。

> Build 通过 Git LFS 管理，clone 后需先 `git lfs pull` 才会取得实际 exe。

### 从源码打开

1. 安装 [Godot 4.6.3 stable](https://godotengine.org/download/archive/)（与对应 export templates）。
2. 用 Godot 打开项目根目录的 `project.godot`。
3. 按 F5 运行；主场景为 `scenes/ui/title_screen.tscn`。

### 操作

| Action | PC | 移动设备 |
|---|---|---|
| 移动 | `WASD` / 方向键 | 左下虚拟方向键 |
| 互动 | `E` / 鼠标左键 | 右下互动按钮 |
| 背包 / 笔记 | `I` / `J` | 右上按钮 |
| 菜单 | `ESC` / `Tab` | 右上菜单按钮 |

---

## 当前进度

MVP 主线已推进至 **Phase 7 完成**（`PROJECT_BRIEF.md > Phase 进度` 为单一事实来源）：

| 范畴 | 状态 |
|---|---|
| 公寓解谜链（B0–B9） | ✅ 完成并通过验收 |
| 背包 / 容器 / 笔记 / 装备 UI | ✅ 完成 |
| 开场独白序列 | ✅ 完成 |
| 触控化（世界 / 面板 / 对话路由） | ✅ 完成（headless PASS，部分纯触控 GUI 走查待跑） |
| 跨场景架构（SceneRouter / GameUI / contract） | ✅ 完成 |
| NPC「晚」+ 对话系统（真系统） | ✅ 完成 |
| SaveSystem（多槽 / 标题 / 暂停菜单 / 边界处理） | ✅ 完成 |
| QuestManager + 零工任务 vertical slice + 结局分支 | ✅ 完成 |

**当前可玩场景**：`apartment_room`（公寓房间）、`apartment_entrance`（公寓门厅）、`apartment_fire_escape`（火逃梯外墙）。

MVP 目标范围：一条街 + 一个地铁站 + 一个小公寓 + 2 NPC + 1 零工任务。后续：街道与地铁场景、iOS 真机导出与校正。

---

## 目录结构（精简）

```text
.
├── project.godot
├── scenes/
│   ├── main/            # main.tscn 常驻宿主 + SceneRouter
│   ├── ui/              # 标题、GameUI、背包/容器/笔记/对话面板、Toast
│   ├── levels/apartment/    # 公寓房间 / 门厅 / 火逃梯场景
│   └── actors/player/  # 主角移动
├── scripts/
│   ├── autoload/        # game_state、ui_mode、touch_controls、quest_manager、save_system
│   └── components/      # interactable_area 互动物
├── data/dialogue/       # 对话树数据（晚 + dialogue_db）
├── tests/manual/        # headless test_runner / verify_game_state
├── assets/
│   ├── art_bible/       # 视觉锚点与 prompt
│   └── generated/       # AI 生成 map / sprite / item icons
├── subdocs/             # 角色设定（人/）、场景规格（地点/）
├── builds/windows/      # Windows build（Git LFS）
└── 舊文件/              # 历史 archive（忽略）
```

完整目录与文件说明见 [`PROJECT_BRIEF.md`](./PROJECT_BRIEF.md)。

---

## 文档导览

| 文档 | 用途 |
|---|---|
| [`PROJECT_BRIEF.md`](./PROJECT_BRIEF.md) | **新 session 入口**；架构、Phase 进度、规格索引 |
| [`遊戲概念.md`](./遊戲概念.md) | 世界观、玩家定位、都市调性 |
| [`技術概念.md`](./技術概念.md) | Godot 选型、MVP 技术方向、平台路线、输入 / UI / 存档 / debug 架构决策 |
| [`Art Bible.md`](./Art%20Bible.md) | 美术方向、限色、构图纪律、3 个视觉锚点；任何素材工作必读 |
| [`遊戲規格書.md`](./遊戲規格書.md) | 全游戏通用系统规格与验收条件、Phase 规划 |
| [`開發設計方針.md`](./開發設計方針.md) | Phase 2 起的实作契约、API、数据字段、接线规则 |
| [`測試指南.md`](./測試指南.md) | Headless 命令、手动验收清单 |
| [`驗證後已知問題.md`](./驗證後已知問題.md) | 待修清单与已接受的边界决定 |

---

## 验证

Godot headless 手动测试：

```powershell
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/manual/test_runner.tscn
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . -s res://tests/manual/verify_game_state.gd
```

最近一次 Phase 7 结果：`test_runner.tscn` PASS、`verify_game_state.gd` PASS。

---

## 授权

本项目为个人开发中作品，目前尚未附正式授权条款（保留所有权利）。仅供开发与内部测试使用。

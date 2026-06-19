# After-The-Model

**English** | [繁體中文](./README_zh-TW.md) | [简体中文](./README_zh-CN.md)

![Godot](https://img.shields.io/badge/GODOT-4.6.3-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDSCRIPT-blue)
![Platform](https://img.shields.io/badge/PLATFORM-WINDOWS%20%7C%20iOS-0078D6?logo=windows&logoColor=white)
![Genre](https://img.shields.io/badge/GENRE-2D%20SIDE--SCROLL-purple)
![Status](https://img.shields.io/badge/STATUS-MVP%20IN%20DEVELOPMENT-orange)

> A 2D side-scrolling cyberpunk exploration game about how ordinary people get by *after* AI changed the world.

It's not about a hero saving the world or taking down an evil corporation. You're a low-tier ordinary person in a post-AI city — living, taking gig jobs, and reclaiming memories the system has erased, amid neon and rainy nights.

---

## ⚠️ Development Status

This is a **personal project in active development**, currently at the MVP stage. Playable content, systems, and art assets are all still iterating; save format, scenes, and values may change. Not released, and no formal license is attached yet.

---

## Concept

**Set around 2030.** AI has thoroughly reshaped society, but the world hasn't become a sci-fi-movie future — progress is real, just uneven: some places are highly automated and extremely advanced; others are more broken and run-down than today.

> A world where high tech and social dysfunction coexist.

| The shiny side | The dark side |
|---|---|
| Unmanned convenience stores are hyper-advanced | Underpasses are packed with the unemployed |
| AI administrative systems are stunningly efficient | Human customer service has all but vanished |
| Everyone has an AI assistant | No one can actually appeal an AI's mistake |
| Aerial ads and automated cities everywhere | People have grown lonelier than ever |

Overall tone: **urban wandering / a sense of survival / small incidents / social observation / fragmented narrative**. The player isn't the center of the world — just one ordinary person trying to get by. The protagonist is an **AI cleanup worker + a gleaner**: by day they fix the system's errors; on the side, they recover the human traces it erased.

---

## Three Districts

Color *is* the language of class — the moment you cross between districts, your eyes read the social structure:

| District | Visual strategy | Resident attitude |
|---|---|---|
| **Plebeian** | Everything faded, but **the orange remains** | "We have nothing, but the sign stays lit." |
| **Wealthy** | Hard black, bright gold, sharp cyber-purple | "We can afford color." |
| **AI** | Near-white, inorganic, flat | "We don't need color." |

The subway is the city-wide "class mobility system": ordinary cars, AI VIP cars, fare-dodger zones, illicit underground trains — each car is a microcosm of the city.

---

## Gameplay

- **Pure 2D side-scrolling**: the character only moves left/right on the X axis, with light platforming (hopping ditches, climbing fire escapes, crossing skyways) that serves *exploration and wandering*, not action challenge.
- **In-place interaction vs. scene transition**: a single shared interact key (`E` on PC / interact button on touch). Small street objects and standing NPCs are in-place interactions; doors / gates / stairs / windows trigger scene transitions.
- **Inventory & containers**: a 5×3 backpack, data-driven external containers (allowlist / locked), item inspect / drop / equip, plus a notes & knowledge system.
- **Puzzle**: the first level (the apartment) has a full puzzle chain — wake up amnesiac → examine for clues → put on gloves to decode → sonar reveals a hidden slot → obtain the door-unlock knowledge → open the door.
- **NPC dialogue**: a condition-routed dialogue tree (first meeting / re-talk / affinity & intel gates), with branches and effects reflected in state in real time.
- **Gig quest**: includes a quest-state system and **multiple ending branches** (whether you return a hidden module affects reward, affinity, and later greetings).
- **Save system**: 10 manual save slots, title screen and pause menu, exact position restored on load.
- **Cross-platform input**: abstracted via Godot's InputMap so PC keyboard/mouse and mobile touch share one set of actions; forced landscape, with UI respecting safe areas and ≥44px touch targets.

---

## Art Direction

> *"The world as printed on a cheap cyberpunk zine forgotten on a 2030 convenience-store shelf — inked with American indie-comic linework, dyed with night-shift fatigue, keeping the traces humans left behind."*

- **Style**: Riso-inspired HD 2D Cyberpunk (not hard pixel art, not semi-painterly).
- **Five non-negotiable rules**: pure 2D side view (no perspective); no pure white, no pure black; limited palette + accent-color discipline; large black masses + concentrated focus; flat profile.
- **The orange rule**: saturated burnt orange is the plebeian district's "refusal to be forgotten" narrative marker (≤ 1–2% of any environment frame); **the protagonist is the only entity in the whole game whose orange exceeds 2%.**
- **Lineage**: Mike Mignola / Frank Miller / Paul Pope / Sean Murphy (comic linework & composition); The Last Night / NORCO / Olija / Citizen Sleeper (game visuals).
- Visual consistency is locked by the 5 anchor images in `assets/art_bible/`. Full spec: [`Art Bible.md`](./Art%20Bible.md).

---

## Tech Stack

- **Engine / language**: Godot 4.6.3 stable, GDScript
- **Architecture**: a persistent `main.tscn` host + dynamic `WorldRoot` levels + a persistent `GameUI` CanvasLayer; all transitions go through `scene_id + entry_point_id`
- **Autoloads**: `GameState` (global state), `UIMode` (UI mode machine), `TouchControls` (touch layer), `QuestManager` (quests), `SaveSystem` (save/load)
- **Save format**: Godot-native `var_to_str` / `str_to_var` plain text (not JSON, not ResourceSaver), 10 slots with a `{meta, data}` header
- **Asset generation**: agent-sprite-forge (`$generate2dsprite` / `$generate2dmap`), output lands back in `assets/generated/`
- **Tooling**: Python venv (Pillow / numpy, for asset post-processing)
- **Validation**: Godot headless manual runner

---

## Quick Start

**Requirements**: Windows 10 / 11.

### Just play (fastest)

Run the latest build in `builds/windows/` (e.g. `AfterTheModel_v0.10.4.exe`) to reach the title screen → New Game.

> Builds are managed via Git LFS; after cloning, run `git lfs pull` to fetch the actual `.exe`.

### From source

1. Install [Godot 4.6.3 stable](https://godotengine.org/download/archive/) (and the matching export templates).
2. Open `project.godot` (at the repo root) in Godot.
3. Press F5 to run; the main scene is `scenes/ui/title_screen.tscn`.

### Controls

| Action | PC | Mobile |
|---|---|---|
| Move | `WASD` / arrow keys | Bottom-left virtual D-pad |
| Interact | `E` / left mouse | Bottom-right interact button |
| Inventory / Notes | `I` / `J` | Top-right buttons |
| Menu | `ESC` / `Tab` | Top-right menu button |

---

## Current Progress

The MVP main line has reached **Phase 10 complete**:

| Area | Status |
|---|---|
| Apartment puzzle chain (B0–B9) | ✅ Done & accepted |
| Inventory / container / notes / equipment UI | ✅ Done |
| Opening monologue sequence | ✅ Done |
| Touch support (world / panel / dialogue routing) | ✅ Done (headless PASS; some touch-only GUI walkthroughs still pending) |
| Cross-scene architecture (SceneRouter / GameUI / contract) | ✅ Done |
| NPC "Wan" + dialogue system (real system) | ✅ Done |
| SaveSystem (multi-slot / title / pause menu / edge cases) | ✅ Done |
| QuestManager + gig-quest vertical slice + ending branches | ✅ Done |
| Convenience-store vertical slice + shop system | ✅ Done |
| Gleaner / echo collection + collector | ✅ Done |
| Atmosphere & presentation pass | ✅ Done (headless PASS + GUI / device visual acceptance complete) |

**Currently playable scenes**: `apartment_room`, `apartment_entrance`, `apartment_fire_escape`, `convenience_store`, `collector_shop`.

MVP target scope: one street + one subway station + one small apartment + 2 NPCs + 1 gig quest. Next up: formalize the Phase 11+ main-story plan and start the subway / underground main-line slice.

---

## Directory Structure (condensed)

```text
.
├── project.godot
├── scenes/
│   ├── main/            # main.tscn persistent host + SceneRouter
│   ├── ui/              # title, GameUI, inventory/container/notes/dialogue panels, toast
│   ├── levels/          # apartment, street entrance, fire escape, convenience store, collector shop
│   └── actors/player/  # player movement
├── scripts/
│   ├── autoload/        # game_state, ui_mode, touch_controls, quest_manager, save_system
│   └── components/      # interactable_area
├── data/                # dialogue, quests, shops, echoes
├── tests/manual/        # headless test_runner / verify_game_state
├── assets/
│   ├── art_bible/       # visual anchors & prompts
│   └── generated/       # AI-generated maps / sprites / item icons
├── subdocs/             # character (人/) and location (地點/) specs
├── builds/windows/      # Windows builds (Git LFS)
└── 舊文件/              # historical archive (ignored)
```

See [`PROJECT_BRIEF.md`](./PROJECT_BRIEF.md) for the full directory and file reference.

---

## Documentation Guide

| Document | Purpose |
|---|---|
| [`PROJECT_BRIEF.md`](./PROJECT_BRIEF.md) | **Entry point for a new session**; architecture, phase progress, spec index |
| [`遊戲概念.md`](./遊戲概念.md) | Worldview, player positioning, urban tone |
| [`技術概念.md`](./技術概念.md) | Godot choice, MVP technical direction, platform roadmap, input / UI / save / debug architecture decisions |
| [`Art Bible.md`](./Art%20Bible.md) | Art direction, limited palette, composition discipline, 3 visual anchors; required reading for any asset work |
| [`遊戲規格書.md`](./遊戲規格書.md) | Game-wide system specs, acceptance criteria, phase planning |
| [`開發設計方針.md`](./開發設計方針.md) | Implementation contracts, APIs, data fields, wiring rules (from Phase 2 on) |
| [`測試指南.md`](./測試指南.md) | Headless commands, manual acceptance checklists |
| [`驗證後已知問題.md`](./驗證後已知問題.md) | Open items and accepted boundary decisions |

---

## Validation

Godot headless manual tests:

```powershell
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/manual/test_runner.tscn
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . -s res://tests/manual/verify_game_state.gd
```

Latest Phase 10 result: headless PASS; GUI / device visual acceptance complete.

---

## License

This is a personal project under active development with no formal license attached yet (all rights reserved). For development and internal testing only.

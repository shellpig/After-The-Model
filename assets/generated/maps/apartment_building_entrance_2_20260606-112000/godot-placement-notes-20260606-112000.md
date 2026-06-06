# Apartment Building Entrance 2 Godot Map

- Source: `assets/art_bible/map02_2_Apartment_building_entrance.png`
- Clean source: `apartment-building-entrance-2-clean-20260606-112000.png`
- Runtime background: `apartment-building-entrance-2-godot-4080x720-20260606-112000.png`
- Scene: `res://scenes/levels/apartment_entrance.tscn`
- Mode: wide side-scroll street scene with one fixed walk line.

## Image Processing

- Removed the bottom-right star watermark without cropping.
- Normalized the clean image from `4896x864` to `4080x720`.
- The guide image marks walk bounds, spawn, and interaction zones only; it is not used at runtime.

## Runtime Placement

- Background node: `Sprite2D`, `centered = false`, top-left at `(0, 0)`.
- Camera: `Camera2D` follows player X across the `4080x720` map, fixed at Y `360`.
- Player spawn `from_apartment`: `(850, 675)`.
- Player bounds: `min_x = 80`, `max_x = 4000`, `walk_line_y = 675`.
- Coarse ground guide: `StaticBody2D` rectangle centered at `(2040, 684)`, size `(3920, 16)`.

## Interactables

- `back_to_apartment`: transition to `apartment:from_street`, centered at `(908, 523)`.
- `mailboxes`: message-only examine, centered at `(585, 493)`.
- `alley_view`: message-only examine, centered at `(2630, 503)`.
- `store_front`: message-only examine, centered at `(3365, 525)`.
- `vending_machine`: message-only examine, centered at `(3920, 533)`.

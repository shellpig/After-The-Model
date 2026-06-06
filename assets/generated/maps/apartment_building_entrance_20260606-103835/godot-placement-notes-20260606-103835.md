# Apartment Building Entrance Godot Map

- Source: `assets/art_bible/map02_1_Apartment_building_entrance.jpeg`
- Runtime background: `apartment-building-entrance-godot-1280x720-20260606-103835.png`
- Scene: `res://scenes/levels/street_stub.tscn`
- Mode: side-scroll scene with one fixed walk line.

## Runtime Placement

- Canvas: `1280x720`, normalized from source image to match project viewport.
- Background node: `Sprite2D`, `centered = false`, top-left at `(0, 0)`.
- Player spawn `from_apartment`: `(482, 660)`.
- Player bounds: `min_x = 70`, `max_x = 1210`, `walk_line_y = 660`.
- Coarse ground guide: `StaticBody2D` rectangle centered at `(640, 669)`, size `(1140, 18)`.

## Interactables

- `back_to_apartment`: transition to `apartment:from_street`, centered at `(482, 527)`.
- `mailboxes`: message-only examine, centered at `(578, 511)`.
- `alley_view`: message-only examine, centered at `(1099, 516)`.

## Notes

This pass uses the supplied art as an existing asset. No new creative image generation prompt was used.
The background is baked art; gameplay data lives in separate Godot nodes and JSON metadata.

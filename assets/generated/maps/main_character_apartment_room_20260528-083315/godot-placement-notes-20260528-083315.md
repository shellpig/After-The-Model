# Main Character Apartment Room - Godot Placement Notes

Source image size: `1376 x 768`.

Use `background.jpeg` as a single baked background image. Do not split furniture into props for the MVP.

Recommended node structure:

```text
ApartmentRoom
  Background: Sprite2D
  PlayerSpawn: Marker2D
  WalkBounds: Node2D
  Collision
    LeftWallBlock: StaticBody2D
    RightWallBlock: StaticBody2D
    DeskChairPlatform: StaticBody2D optional
  Interactions
    BedArea: Area2D
    ComputerMonitorArea: Area2D
    FridgeArea: Area2D
    DoorCabinetArea: Area2D
  CameraBounds: ReferenceRect or custom data
```

Initial gameplay coordinates:

```text
primary_walk_line_y = 700
spawn_point = (690, 700)
player_origin = feet point
horizontal movement min_x = 64
horizontal movement max_x = 1312
camera bounds = Rect2(0, 0, 1376, 768)
```

The walk line can be adjusted in Godot without regenerating art.

Interaction zones are approximate and should be tuned after placing the 192px character sprite in the scene.

Optional jump support:

```text
desk_chair_platform = Rect2(690, 555, 145, 34)
```

Use this only if the room design needs a small jump-to-interact action. This is not intended to become a full platformer room.

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


SRC = Path(__file__).parent / "hires_1024"
OUT = SRC / "final_normalized"
LABELS = [
    "01_idle",
    "02_begin_turn",
    "03_full_glance_hold_a",
    "04_full_glance_hold_b",
    "05_turn_back",
    "06_idle_settle",
]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    items = []
    for index in range(1, 7):
        image = Image.open(SRC / f"wan-idle-glance-6f-{index}.png").convert("RGBA")
        bbox = image.getbbox()
        if bbox is None:
            raise RuntimeError(f"Frame {index} is empty")
        items.append(image.crop(bbox))

    cell_size = 1024
    target_height = max(crop.height for crop in items)
    top_y = 78
    frames = []

    for label, crop in zip(LABELS, items):
        scale = target_height / crop.height
        new_width = max(1, round(crop.width * scale))
        resized = crop.resize((new_width, target_height), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (cell_size, cell_size), (0, 0, 0, 0))
        canvas.alpha_composite(resized, ((cell_size - new_width) // 2, top_y))
        canvas.save(OUT / f"{label}.png")
        frames.append(canvas)

    sheet = Image.new("RGBA", (cell_size * 3, cell_size * 2), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, ((index % 3) * cell_size, (index // 3) * cell_size))
    sheet.save(OUT / "sheet-transparent.png")

    durations = [650, 150, 360, 360, 150, 520]
    frames[0].save(
        OUT / "animation-preview.gif",
        save_all=True,
        append_images=frames[1:] + [frames[0]],
        duration=durations + [650],
        loop=0,
        disposal=2,
    )

    meta = {
        "source": "../wan-idle-glance-6f-*.png",
        "normalization": "alpha crop resized to common body height, centered x, top_y=78, baseline consistent",
        "cell_size": cell_size,
        "rows": 2,
        "cols": 3,
        "frame_order": LABELS,
        "durations_ms": durations,
        "target_body_height": target_height,
    }
    (OUT / "normalization-meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()

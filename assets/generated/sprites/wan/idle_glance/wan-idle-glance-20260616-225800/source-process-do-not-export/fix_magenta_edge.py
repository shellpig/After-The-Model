from __future__ import annotations

from pathlib import Path

from PIL import Image


SRC = Path(__file__).parent / "hires_1024" / "final_normalized"
OUT = SRC / "black_edge"
FRAME_NAMES = [
    "01_idle",
    "02_begin_turn",
    "03_full_glance_hold_a",
    "04_full_glance_hold_b",
    "05_turn_back",
    "06_idle_settle",
]
DURATIONS = [650, 150, 360, 360, 150, 520]
BLACK = (5, 3, 8)


def is_magenta_fringe(r: int, g: int, b: int) -> bool:
    return r >= 85 and b >= 95 and g <= 85 and (r + b) >= (g * 2 + 120)


def near_transparent(alpha, x: int, y: int, radius: int = 3) -> bool:
    width = len(alpha[0])
    height = len(alpha)
    for yy in range(max(0, y - radius), min(height, y + radius + 1)):
        for xx in range(max(0, x - radius), min(width, x + radius + 1)):
            if alpha[yy][xx] <= 8:
                return True
    return False


def add_black_edge(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    alpha = [[pixels[x, y][3] for x in range(width)] for y in range(height)]

    output = image.copy()
    out = output.load()

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if near_transparent(alpha, x, y, radius=1):
                out[x, y] = (*BLACK, a)
                continue
            if near_transparent(alpha, x, y, radius=4) and is_magenta_fringe(r, g, b):
                out[x, y] = (*BLACK, a)

    return output


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    frames = []
    for name in FRAME_NAMES:
        fixed = add_black_edge(Image.open(SRC / f"{name}.png"))
        fixed.save(OUT / f"{name}.png")
        frames.append(fixed)

    cell_size = 1024
    sheet = Image.new("RGBA", (cell_size * 3, cell_size * 2), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, ((index % 3) * cell_size, (index // 3) * cell_size))
    sheet.save(OUT / "sheet-transparent.png")

    frames[0].save(
        OUT / "animation-preview.gif",
        save_all=True,
        append_images=frames[1:] + [frames[0]],
        duration=DURATIONS + [650],
        loop=0,
        disposal=2,
    )


if __name__ == "__main__":
    main()

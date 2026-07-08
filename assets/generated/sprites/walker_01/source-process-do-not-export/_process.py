from PIL import Image, ImageFilter
import numpy as np
import os
from collections import deque

# black outline matching main_character/combat_walk (OUTLINE_PX=4, color (10,10,12))
ERODE_PX = 2     # pull silhouette in to kill the light beige fringe
OUTLINE_PX = 4   # black ring thickness (dilations of the eroded mask)
OUTLINE_RGB = (10, 10, 12)

def add_outline(img):
    """Erode alpha to drop the light fringe, then draw a black dilated outline under the art."""
    alpha = img.getchannel("A")
    mask = alpha.point(lambda v: 255 if v > 40 else 0)
    for _ in range(ERODE_PX):
        mask = mask.filter(ImageFilter.MinFilter(3))
    img.putalpha(mask)  # tightened character silhouette (fringe removed)
    dil = mask
    for _ in range(OUTLINE_PX):
        dil = dil.filter(ImageFilter.MaxFilter(3))
    black = Image.new("RGBA", img.size, OUTLINE_RGB + (0,))
    black.putalpha(dil)
    return Image.alpha_composite(black, img)

BASE = r"C:\_work\AI_Work\Projects\AfterTheModel\assets\generated\sprites\walker_01"
FRAMES_DIR = os.path.join(BASE, "_frames")
OUT_DIR = os.path.join(BASE, "walk")
os.makedirs(OUT_DIR, exist_ok=True)

# 6 frames, start at frame 4, spaced 16 over the 96-frame loop
PICKS = [4, 20, 36, 52, 68, 84]

# --- background removal via border-connected flood fill ---
TOL = 42          # color distance threshold to count as background
FEATHER_LO = 30   # below this distance -> fully transparent
FEATHER_HI = 70   # above this distance -> fully opaque (ramp between)

def remove_bg(img):
    rgb = np.asarray(img.convert("RGB"), dtype=np.int16)
    h, w, _ = rgb.shape
    # background color = median of 4 corners
    corners = np.concatenate([
        rgb[0:8, 0:8].reshape(-1, 3),
        rgb[0:8, w-8:w].reshape(-1, 3),
        rgb[h-8:h, 0:8].reshape(-1, 3),
        rgb[h-8:h, w-8:w].reshape(-1, 3),
    ], axis=0)
    bg = np.median(corners, axis=0)
    dist = np.sqrt(((rgb - bg) ** 2).sum(axis=2))  # distance from bg color

    near = dist <= TOL
    # flood fill from borders over `near`
    visited = np.zeros((h, w), dtype=bool)
    dq = deque()
    for x in range(w):
        for y in (0, h - 1):
            if near[y, x] and not visited[y, x]:
                visited[y, x] = True; dq.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if near[y, x] and not visited[y, x]:
                visited[y, x] = True; dq.append((y, x))
    while dq:
        y, x = dq.popleft()
        for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
            ny, nx = y+dy, x+dx
            if 0 <= ny < h and 0 <= nx < w and near[ny, nx] and not visited[ny, nx]:
                visited[ny, nx] = True; dq.append((ny, nx))

    # alpha: feather based on color distance, but only inside the connected bg region
    alpha = np.clip((dist - FEATHER_LO) / (FEATHER_HI - FEATHER_LO), 0, 1)
    alpha = (alpha * 255).astype(np.uint8)
    alpha[visited] = 0  # connected background -> fully transparent
    out = np.dstack([np.asarray(img.convert("RGB")), alpha]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")

# process
cut = []
for n in PICKS:
    src = os.path.join(FRAMES_DIR, f"f_{n:03d}.png")
    cut.append(add_outline(remove_bg(Image.open(src))))

# shared bounding box across all frames (union) so the mech stays put
def bbox_of(im):
    a = np.asarray(im)[:, :, 3]
    ys, xs = np.where(a > 10)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1

boxes = [bbox_of(im) for im in cut]
x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
pad = 8
x0 = max(0, x0 - pad); y0 = max(0, y0 - pad)
x1 = min(cut[0].width, x1 + pad); y1 = min(cut[0].height, y1 + pad)
print("shared bbox", x0, y0, x1, y1, "size", x1 - x0, y1 - y0)

cropped = [im.crop((x0, y0, x1, y1)) for im in cut]
for i, (n, im) in enumerate(zip(PICKS, cropped), 1):
    im.save(os.path.join(OUT_DIR, f"walker_01-walk-{i}.png"))

# preview GIF
gif = [im.convert("RGBA") for im in cropped]
bg = Image.new("RGBA", gif[0].size, (40, 42, 48, 255))
flat = [Image.alpha_composite(bg, g).convert("P", palette=Image.ADAPTIVE) for g in gif]
flat[0].save(os.path.join(OUT_DIR, "_preview.gif"), save_all=True,
             append_images=flat[1:], duration=120, loop=0, disposal=2)

# horizontal sheet on dark bg for review
W, H = cropped[0].size
sheet = Image.new("RGBA", (W * 6, H), (40, 42, 48, 255))
for i, im in enumerate(cropped):
    sheet.alpha_composite(im, (W * i, 0))
sheet.convert("RGB").save(os.path.join(OUT_DIR, "_sheet.png"))
print("done ->", OUT_DIR)

"""Batch the attack sprite: 15 selected source frames -> transparent sprites + loop gif.

Same 'stylematch v3' pipeline as combat_walk (magenta chroma-key -> keep-largest
blob -> 1px black outline -> 3D color transfer + warm-cloth red trim), so the
attack frames match the in-use jump/walk/combat_walk palette by construction.

Frame pick (1-indexed source, 25 total @24fps): denser through the swing so the
fast crescent VFX (src f14-17) reads smoothly; every-other through windup/recover.
"""
import os
import numpy as np
from PIL import Image, ImageFilter, ImageChops

BASE = os.path.dirname(os.path.abspath(__file__))
EXTRACT = os.path.join(BASE, "..", "..", "_attack_extract")

SRC_FRAMES = [1, 3, 5, 7, 9, 11, 13, 14, 15, 16, 17, 19, 21, 23, 25]

H_LOW, H_HIGH, S_MIN, V_MIN = 200, 232, 60, 25
OUTLINE_PX = 1

# Color match (Monge-Kantorovich linear transfer): out = A(x - ms) + mt, fitted
# from THIS attack video's body pixels -> the in-use combat_walk v3 body pixels.
# Matches mean AND covariance, so the jacket lands on combat_walk's muted teal
# (not pure blue) and the pants stay warm brown. Both sets share the same
# character + gold tool, so those map correctly; the green slash VFX (which
# combat_walk lacks) was excluded from the fit. Replaces the earlier borrowed
# matrix + per-channel brightness gain that over-blued the jacket.
GRADE_A = [[0.977249, 0.099448, -0.057507],
           [0.099448, 0.781528, 0.153994],
           [-0.057507, 0.153994, 0.847073]]
GRADE_MS = [78.3037, 67.7306, 47.1557]
GRADE_MT = [78.9437, 68.9181, 50.1536]


def keep_largest(fg):
    a = np.array(fg)
    binary = a > 40
    H, W = binary.shape
    labels = np.zeros((H, W), np.int32)
    cur = 0
    best_id, best_size = 0, 0
    for sy in range(H):
        row = binary[sy]
        for sx in range(W):
            if row[sx] and labels[sy, sx] == 0:
                cur += 1
                stack = [(sy, sx)]
                labels[sy, sx] = cur
                cnt = 0
                while stack:
                    y, x = stack.pop()
                    cnt += 1
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < H and 0 <= nx < W and binary[ny, nx] and labels[ny, nx] == 0:
                            labels[ny, nx] = cur
                            stack.append((ny, nx))
                if cnt > best_size:
                    best_size, best_id = cnt, cur
    a[labels != best_id] = 0
    return Image.fromarray(a)


def chroma_key(img):
    img = img.convert("RGBA")
    h, s, v = img.convert("HSV").split()
    h_in = h.point(lambda p: 255 if H_LOW <= p <= H_HIGH else 0)
    s_in = s.point(lambda p: 255 if p >= S_MIN else 0)
    v_in = v.point(lambda p: 255 if p >= V_MIN else 0)
    bg = ImageChops.multiply(ImageChops.multiply(h_in, s_in), v_in)
    fg = ImageChops.invert(bg)
    fg = fg.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    fg = keep_largest(fg)
    fg = fg.filter(ImageFilter.GaussianBlur(0.8))
    img.putalpha(fg)
    return img


def add_outline(img, thickness):
    alpha = img.getchannel("A")
    mask = alpha.point(lambda v: 255 if v > 40 else 0)
    dil = mask
    for _ in range(thickness):
        dil = dil.filter(ImageFilter.MaxFilter(3))
    black = Image.new("RGBA", img.size, (10, 10, 12, 0))
    black.putalpha(dil)
    return Image.alpha_composite(black, img)


def style_grade(img):
    """Monge-Kantorovich linear color transfer onto the combat_walk palette.
    Alpha untouched."""
    arr = np.array(img, float)
    rgb = arr[..., :3]
    A = np.array(GRADE_A); ms = np.array(GRADE_MS); mt = np.array(GRADE_MT)
    flat = (rgb.reshape(-1, 3) - ms) @ A.T + mt
    arr[..., :3] = np.clip(flat, 0, 255).reshape(rgb.shape)
    return Image.fromarray(arr.astype("uint8"), "RGBA")


frames = []
for i, n in enumerate(SRC_FRAMES, 1):
    src = os.path.join(EXTRACT, f"f_{n:02d}.png")
    im = Image.open(src).convert("RGBA")
    im = chroma_key(im)
    im = add_outline(im, OUTLINE_PX)
    im = style_grade(im)
    dst = os.path.join(BASE, f"main-character-attack-{i}.png")
    im.save(dst)
    bg = Image.new("RGBA", im.size, (255, 0, 255, 255))
    Image.alpha_composite(bg, im).convert("RGB").save(
        os.path.join(BASE, f"main-character-attack-{i}-on-magenta.png"))
    frames.append(im)
    print(f"frame {i:2d} <- src f_{n:02d}  size={im.size}")

gif = [f.resize((320, 320)) for f in frames]
gif[0].save(os.path.join(BASE, "animation.gif"), save_all=True,
            append_images=gif[1:], duration=80, loop=0, disposal=2)
print("saved animation.gif")

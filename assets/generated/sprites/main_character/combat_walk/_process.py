"""combat_walk: chroma-key magenta bg -> transparent, add black outline, export frames + gif."""
import os
import numpy as np
from PIL import Image, ImageFilter, ImageChops

BASE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(BASE, "_raw")
OUT = BASE

# --- tunables (HSV hue-keying; PIL HSV channels are 0..255) ---
# magenta bg + its drop shadow share hue ~300deg (=213 in 0..255), high saturation.
H_LOW = 200      # ~282 deg
H_HIGH = 232     # ~327 deg
S_MIN = 60       # min saturation to count as bg (kills greyish character lineart)
V_MIN = 25       # min value (let very dark shadow still register as magenta bg)
OUTLINE_PX = 4   # outline thickness (approx, via MaxFilter(3) iterations)

# --- style grade ("stylematch v3"): match the in-use jump/walk sprite palette
# (steel-blue jacket, khaki-brown pants), NOT the magenta concept art.
# Step 1: full 3D linear color transfer (Monge-Kantorovich) fitted from these
#   combat frames -> pooled jump+walk pixels. The off-diagonal terms rotate the
#   teal jacket toward blue while keeping pants/skin intact.  out = A(x-ms)+mt
# Step 2: trim red on warm muted cloth (pants/bag) only, to drop the leftover
#   chocolate bias (brown R-G 25 -> 20, matching jump/walk). ---
GRADE_A = [[0.9407291403444692, 0.18259329993271664, -0.22178815063104393],
           [0.16847187657619583, 0.5974393564632828, 0.04937522386570008],
           [-0.08278413443074828, 0.09533396790367504, 0.6615309332650225]]
GRADE_MS = [86.62941779697181, 75.94646922539003, 63.69527003326683]
GRADE_MT = [73.05459483217824, 62.79009107871075, 46.56256312782165]
RED_TRIM = 5     # subtracted from R on warm-cloth pixels

def keep_largest(fg):
    """Keep only the largest connected blob (the character), drop stray shadow specks."""
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
    """Remove magenta background AND its darker magenta drop-shadow via HSV hue keying."""
    img = img.convert("RGBA")
    h, s, v = img.convert("HSV").split()
    h_in = h.point(lambda p: 255 if H_LOW <= p <= H_HIGH else 0)
    s_in = s.point(lambda p: 255 if p >= S_MIN else 0)
    v_in = v.point(lambda p: 255 if p >= V_MIN else 0)
    bg = ImageChops.multiply(ImageChops.multiply(h_in, s_in), v_in)  # logical AND
    fg = ImageChops.invert(bg)
    # morphological open: kill isolated specks left by shadow edges
    fg = fg.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    # drop any remaining detached fragments, keep only the character
    fg = keep_largest(fg)
    # soften the hard edge by 1px so the outline sits cleanly
    fg = fg.filter(ImageFilter.GaussianBlur(0.8))
    img.putalpha(fg)
    return img

def add_outline(img, thickness):
    """Dilate the alpha silhouette, paint it black, composite character on top."""
    alpha = img.getchannel("A")
    # binary-ish mask
    mask = alpha.point(lambda v: 255 if v > 40 else 0)
    dil = mask
    for _ in range(thickness):
        dil = dil.filter(ImageFilter.MaxFilter(3))
    # black layer shaped like dilated mask
    black = Image.new("RGBA", img.size, (10, 10, 12, 0))
    black.putalpha(dil)
    out = Image.alpha_composite(black, img)
    return out

def style_grade(img):
    """Match the in-use jump/walk palette: 3D color transfer + warm-cloth red trim.
    Alpha is left untouched."""
    arr = np.array(img, float)
    rgb = arr[..., :3]
    A = np.array(GRADE_A); ms = np.array(GRADE_MS); mt = np.array(GRADE_MT)
    flat = (rgb.reshape(-1, 3) - ms) @ A.T + mt
    rgb = np.clip(flat, 0, 255).reshape(rgb.shape)
    R, G, B, Al = rgb[..., 0], rgb[..., 1], rgb[..., 2], arr[..., 3]
    # warm muted cloth (pants/bag): exclude bright skin (R<145) and orange patch (R-B<90)
    warm = ((Al > 200) & (R > G) & (G > B) & (R > 50) & (R < 145) &
            ((R - B) < 90) & ((R - B) > 20) & (B > 25))
    rgb[..., 0] = np.where(warm, np.clip(R - RED_TRIM, 0, 255), R)
    arr[..., :3] = rgb
    return Image.fromarray(arr.astype("uint8"), "RGBA")

def autocrop_box(images, pad=12):
    """Shared bbox across all frames so the loop doesn't jitter."""
    box = None
    for im in images:
        b = im.getchannel("A").getbbox()
        if b is None:
            continue
        if box is None:
            box = list(b)
        else:
            box[0] = min(box[0], b[0]); box[1] = min(box[1], b[1])
            box[2] = max(box[2], b[2]); box[3] = max(box[3], b[3])
    return tuple(box)  # we keep full canvas; bbox only used for gif framing

raws = sorted(f for f in os.listdir(RAW) if f.endswith(".png"))
frames = []
for i, name in enumerate(raws, 1):
    src = Image.open(os.path.join(RAW, name)).convert("RGBA")
    keyed = chroma_key(src)
    final = add_outline(keyed, OUTLINE_PX)
    final = style_grade(final)
    dst = os.path.join(OUT, f"main-character-combat-walk-{i}.png")
    final.save(dst)
    frames.append(final)
    print(f"saved {os.path.basename(dst)}  size={final.size}")

# gif preview (downscaled for quick viewing, frames themselves stay 960)
gif_frames = [f.resize((320, 320)) for f in frames]
gif_path = os.path.join(OUT, "animation.gif")
gif_frames[0].save(gif_path, save_all=True, append_images=gif_frames[1:],
                   duration=120, loop=0, disposal=2)
print("saved animation.gif")

"""
Subway platform CENTRAL SCREEN — "TRAINS TEMPORARILY OUT OF SERVICE".

Clean content layer for the PlatformScreen quad in
scenes/levels/subway_station/subway_station_platform.tscn.
The runtime CRT shader (assets/shaders/billboard_screen.gdshader) adds
scanlines / flicker / RGB-shift / edge-glow / vignette, so this texture is
kept relatively clean — only soft neon bloom is baked in.

Canvas 2912 x 1440 (matches the existing Polygon2D UV, drop-in replacement).
English, system mono font (Consolas), cyberpunk palette.
"""
import os
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 2912, 1440
HERE = os.path.dirname(os.path.abspath(__file__))

# ---- palette (art-bible safe: no pure white/black, no orange on signage) ----
BG_TOP   = (11, 24, 30)
BG_BOT   = (6, 14, 19)
INK      = (8, 16, 22)
CYAN     = (102, 232, 232)
CYAN_BRT = (150, 248, 248)
CYAN_DIM = (74, 138, 148)
GRID     = (24, 52, 60)
AMBER    = (255, 182, 66)
RED      = (255, 84, 102)
CREAM    = (220, 238, 238)
ROWBG    = (15, 32, 39)

F = "C:/Windows/Fonts/consola.ttf"
FB = "C:/Windows/Fonts/consolab.ttf"
def reg(s): return ImageFont.truetype(F, s)
def bold(s): return ImageFont.truetype(FB, s)

# ---- base: vertical gradient + faint grid + vignette --------------------------
base = Image.new("RGB", (W, H), BG_BOT)
for y in range(H):
    t = y / H
    r = int(BG_TOP[0] * (1 - t) + BG_BOT[0] * t)
    g = int(BG_TOP[1] * (1 - t) + BG_BOT[1] * t)
    b = int(BG_TOP[2] * (1 - t) + BG_BOT[2] * t)
    base.paste((r, g, b), (0, y, W, y + 1))

d = ImageDraw.Draw(base, "RGBA")
# faint tile grid
for gx in range(0, W, 104):
    d.line([(gx, 0), (gx, H)], fill=GRID + (40,), width=1)
for gy in range(0, H, 104):
    d.line([(0, gy), (W, gy)], fill=GRID + (40,), width=1)

# big ghost transit glyph (watermark) behind everything
gx, gy = W - 470, H // 2 + 40
d.ellipse([gx - 230, gy - 230, gx + 230, gy + 230], outline=CYAN_DIM + (26,), width=14)
d.line([(gx - 150, gy), (gx + 150, gy)], fill=CYAN_DIM + (26,), width=14)

# ---- glow layer (blurred bloom for emissive elements) ------------------------
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)

MARGIN = 96

# ============================ HEADER BAND =====================================
hy0, hy1 = 84, 214
gd.rectangle([MARGIN, hy0, W - MARGIN, hy1], fill=CYAN + (60,))
d.rectangle([MARGIN, hy0, W - MARGIN, hy1], outline=CYAN + (90,), width=3)
# left accent block
d.rectangle([MARGIN, hy0, MARGIN + 26, hy1], fill=CYAN)
gd.rectangle([MARGIN, hy0, MARGIN + 26, hy1], fill=CYAN + (160,))

hf = bold(72)
d.text((MARGIN + 64, hy0 + 26), "CENTRAL LINE", font=hf, fill=CREAM)
sf = reg(48)
d.text((MARGIN + 64 + d.textlength("CENTRAL LINE", font=hf) + 40, hy0 + 44),
       "// PLATFORM 02", font=sf, fill=CYAN_DIM)

# right side: clock + OFFLINE pill
clk = bold(72)
clk_s = "--:--:--"
clk_w = d.textlength(clk_s, font=clk)
# offline pill
pill = bold(50)
ptxt = "OFFLINE"
pw = d.textlength(ptxt, font=pill)
px1 = W - MARGIN - 30
px0 = px1 - pw - 80
d.rounded_rectangle([px0, hy0 + 30, px1, hy1 - 30], radius=14, fill=RED + (38,), outline=RED, width=3)
gd.rounded_rectangle([px0, hy0 + 30, px1, hy1 - 30], radius=14, fill=RED + (70,))
d.ellipse([px0 + 26, (hy0 + hy1)//2 - 13, px0 + 52, (hy0 + hy1)//2 + 13], fill=RED)
d.text((px0 + 70, hy0 + 38), ptxt, font=pill, fill=RED)
d.text((px0 - clk_w - 60, hy0 + 28), clk_s, font=clk, fill=CYAN)
gd.text((px0 - clk_w - 60, hy0 + 28), clk_s, font=clk, fill=CYAN + (120,))

# ============================ CENTRAL ALERT ===================================
# warning triangle
tx, ty = MARGIN + 70, 300
size = 296
pts = [(tx + size/2, ty), (tx, ty + size*0.88), (tx + size, ty + size*0.88)]
d.polygon(pts, fill=AMBER)
gd.polygon(pts, fill=AMBER + (150,))
# inner dark triangle stroke
d.polygon(pts, outline=INK, width=10)
ef = bold(150)
exw = d.textlength("!", font=ef)
d.text((tx + size/2 - exw/2, ty + 92), "!", font=ef, fill=INK)

# title block to the right of triangle
bx = tx + size + 110
tf = bold(168)
d.text((bx, 296), "SERVICE", font=tf, fill=AMBER)
d.text((bx, 296 + 162), "SUSPENDED", font=tf, fill=AMBER)
gd.text((bx, 296), "SERVICE", font=tf, fill=AMBER + (110,))
gd.text((bx, 296 + 162), "SUSPENDED", font=tf, fill=AMBER + (110,))

stf = reg(58)
d.text((bx + 6, 296 + 162 + 176), "ALL TRAINS TEMPORARILY OUT OF SERVICE",
       font=stf, fill=CYAN_BRT)
nf = reg(44)
d.text((bx + 6, 296 + 162 + 176 + 74), "NETWORK HALTED  ·  AWAIT FURTHER NOTICE",
       font=nf, fill=CYAN_DIM)

# divider
dvy = 814
d.line([(MARGIN, dvy), (W - MARGIN, dvy)], fill=CYAN_DIM + (120,), width=3)

# ============================ DEPARTURE TABLE =================================
col_time = MARGIN + 10
col_dest = MARGIN + 360
col_stat = W - MARGIN - 560
thf = bold(46)
ty0 = dvy + 28
d.text((col_time, ty0), "DEP", font=thf, fill=CYAN_DIM)
d.text((col_dest, ty0), "DESTINATION", font=thf, fill=CYAN_DIM)
d.text((col_stat, ty0), "STATUS", font=thf, fill=CYAN_DIM)

rows = [
    ("--:--", "NORTHGATE / RIVERFRONT", "CANCELLED", RED),
    ("--:--", "CIVIC CORE / MARKET ROW", "NO SERVICE", RED),
    ("--:--", "DOWNLINE / THE SETTLEMENT", "SUSPENDED", AMBER),
    ("--:--", "OLD HARBOUR / TERMINUS", "-- -- --", CYAN_DIM),
]
rf = bold(52)
rh = 84
ry = ty0 + 74
for i, (tm, dest, stat, col) in enumerate(rows):
    if i % 2 == 0:
        d.rectangle([MARGIN, ry - 12, W - MARGIN, ry + rh - 24], fill=ROWBG)
    d.text((col_time, ry), tm, font=rf, fill=CREAM)
    d.text((col_dest, ry), dest, font=rf, fill=CYAN)
    sw = d.textlength(stat, font=rf)
    d.text((W - MARGIN - 10 - sw, ry), stat, font=rf, fill=col)
    if col == RED:
        gd.text((W - MARGIN - 10 - sw, ry), stat, font=rf, fill=RED + (90,))
    ry += rh

# ============================ FOOTER TICKER ===================================
fy0, fy1 = H - 118, H - 30
d.rectangle([MARGIN, fy0, W - MARGIN, fy1], fill=INK, outline=CYAN_DIM + (120,), width=2)
tk = reg(42)
ticker = ("SYS://transit.core  ▸  SIGNAL LOST  ▸  AUTOMATED DISPATCH OFFLINE"
          "  ▸  STAND CLEAR OF THE PLATFORM EDGE  ▸  ERR 0xT4-NOSVC  ▸  ")
d.text((MARGIN + 28, fy0 + 18), ticker, font=tk, fill=CYAN_DIM)
# blinking caret block
d.rectangle([MARGIN + 28 + d.textlength(ticker, font=tk) + 6, fy0 + 20,
             MARGIN + 28 + d.textlength(ticker, font=tk) + 30, fy1 - 18], fill=CYAN)

# ---- composite glow under sharp -----------------------------------------------
glow_b = glow.filter(ImageFilter.GaussianBlur(20))
out = base.convert("RGBA")
out = Image.alpha_composite(out, glow_b)
# re-draw nothing; sharp text already on `base` which is under glow -> instead
# composite sharp on top by pasting base's draws again is unnecessary because
# we drew sharp on `base`. To keep crisp edges above bloom, overlay base again
# masked by its own luminance difference is overkill; instead draw sharp layer.
# Simpler: blend glow ADD-style over a copy that still has the sharp marks.
out = Image.alpha_composite(base.convert("RGBA"), glow_b)

# corner UI brackets (drawn last, crisp, on top)
od = ImageDraw.Draw(out, "RGBA")
bl = 70
for (cx, cy, sx, sy) in [(40, 40, 1, 1), (W - 40, 40, -1, 1),
                         (40, H - 40, 1, -1), (W - 40, H - 40, -1, -1)]:
    od.line([(cx, cy), (cx + bl * sx, cy)], fill=CYAN, width=6)
    od.line([(cx, cy), (cx, cy + bl * sy)], fill=CYAN, width=6)

# faint baked scanlines (very subtle; shader adds the real ones)
sl = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sld = ImageDraw.Draw(sl)
for y in range(0, H, 4):
    sld.line([(0, y), (W, y)], fill=(0, 0, 0, 16), width=1)
out = Image.alpha_composite(out, sl)

# soft outer vignette
vig = Image.new("L", (W, H), 0)
vd = ImageDraw.Draw(vig)
vd.ellipse([-W*0.25, -H*0.25, W*1.25, H*1.25], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(200))
dark = Image.new("RGBA", (W, H), (0, 0, 0, 90))
out = Image.composite(out, Image.alpha_composite(out, dark), vig)

final = out.convert("RGB")
stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
name = f"subway-platform-service-suspended-{stamp}.png"
path = os.path.join(HERE, name)
final.save(path)
print(path)

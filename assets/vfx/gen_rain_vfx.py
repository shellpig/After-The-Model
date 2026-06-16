"""Phase 10 atmosphere VFX texture generator.

Deterministic, dependency-light generator for the rain particle textures.
RGB is solid white; the shape lives only in the alpha channel so the engine
tints them via GPUParticles2D modulate. Re-run to regenerate identical output.

    .\.venv\Scripts\python.exe assets/vfx/gen_rain_vfx.py
"""
import os
import numpy as np
from PIL import Image

OUT_DIR = os.path.dirname(os.path.abspath(__file__))


def smoothstep(edge0, edge1, x):
    t = np.clip((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def _save_white_alpha(alpha, path):
    a = np.clip(np.round(alpha), 0, 255).astype(np.uint8)
    h, w = a.shape
    rgba = np.empty((h, w, 4), dtype=np.uint8)
    rgba[..., 0:3] = 255            # solid white RGB; engine modulate colors it
    rgba[..., 3] = a               # shape carried by straight (non-premult) alpha
    Image.fromarray(rgba, "RGBA").save(path)
    print("wrote", path, f"({w}x{h}, peak alpha {int(a.max())})")


def rain_streak():
    W, H = 8, 64
    xs = np.arange(W)[None, :]
    ys = np.arange(H)[:, None]
    hx = np.exp(-((xs - (W - 1) / 2.0) ** 2) / (2.0 * (W / 5.0) ** 2))
    t = ys / (H - 1)
    vy = smoothstep(0.0, 0.30, t) * (1.0 - 0.25 * t)   # head faint, tail solid
    alpha = np.clip(hx * vy, 0.0, 1.0) * 200.0
    _save_white_alpha(alpha, os.path.join(OUT_DIR, "rain_streak.png"))


def rain_splash():
    S = 24
    c = (S - 1) / 2.0
    r0, sigma = 0.34 * S, 0.10 * S
    xs = np.arange(S)[None, :]
    ys = np.arange(S)[:, None]
    dx = xs - c
    dy = (ys - c) / 0.5                                 # squash vertically -> ground ellipse
    r = np.sqrt(dx ** 2 + dy ** 2)
    ring = np.exp(-((r - r0) ** 2) / (2.0 * sigma ** 2))
    alpha = np.clip(ring, 0.0, 1.0) * 150.0
    upper = (ys < c)                                    # splash crowns slightly upward
    alpha = np.where(upper, np.clip(alpha * 1.15, 0.0, 255.0), alpha)
    _save_white_alpha(alpha, os.path.join(OUT_DIR, "rain_splash.png"))


if __name__ == "__main__":
    rain_streak()
    rain_splash()

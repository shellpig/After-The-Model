from PIL import Image
import numpy as np, glob, os
d = r"C:\_work\AI_Work\Projects\AfterTheModel\assets\generated\sprites\ai_mech\_frames"
fs = sorted(glob.glob(os.path.join(d, "f_*.png")))
arr = [np.asarray(Image.open(f).convert("L").resize((139, 104)), dtype=np.float32) for f in fs]
ref = arr[3]  # f_004
print("n_frames", len(arr))
for i, a in enumerate(arr):
    print(i + 1, round(float(np.mean((a - ref) ** 2)), 1))

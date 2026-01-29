from inky import InkyImpression
from PIL import Image
import os
import time

IMAGE_DIR = "/home/rma/InkyRic/images"
SLEEP_SECONDS = 300  # 5 minutes

# Manual init instead of auto()
DISPLAY = InkyImpression("red")  # Spectra 6; use "black" if mono
DISPLAY.set_border(DISPLAY.BLACK)

if not os.path.exists(IMAGE_DIR):
    raise RuntimeError(f"Image directory does not exist: {IMAGE_DIR}")

images = sorted([
    os.path.join(IMAGE_DIR, f)
    for f in os.listdir(IMAGE_DIR)
    if f.lower().endswith((".png", ".jpg", ".jpeg", ".bmp"))
])

if not images:
    raise RuntimeError(f"No images found in {IMAGE_DIR}")

print(f"Loaded {len(images)} images")

while True:
    for img_path in images:
        print(f"Displaying {img_path}")
        img = Image.open(img_path)
        DISPLAY.set_image(img)
        DISPLAY.show()
        time.sleep(SLEEP_SECONDS)

#!/usr/bin/env python3

import os
import time
from PIL import Image
from inky.inky_impression import InkyImpression

# ======================
# Configuration
# ======================
IMAGE_DIR = "/opt/eink/images"
SLEEP_SECONDS = 300  # 5 minutes

# Inky Impression 7.3" (PIM773)
DISPLAY = InkyImpression(resolution=(800, 480))

# ======================
# Load images
# ======================
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

# ======================
# Main loop
# ======================
while True:
    for img_path in images:
        print(f"Displaying {img_path}")
        img = Image.open(img_path)
        DISPLAY.set_image(img)
        DISPLAY.show()
        time.sleep(SLEEP_SECONDS)

#!/usr/bin/env python3
import os
import time
from PIL import Image
from inky.auto import auto

# Configuration
IMAGE_DIR = "/opt/eink/images"
DISPLAY = auto()  # Automatically detect your Inky display

# Load images in folder order
images = sorted([
    os.path.join(IMAGE_DIR, f)
    for f in os.listdir(IMAGE_DIR)
    if f.lower().endswith((".png", ".jpg", ".bmp"))
])

if not images:
    print(f"No images found in {IMAGE_DIR}. Please add some and reboot.")
    exit(1)

# Main slideshow loop
while True:
    for img_path in images:
        print(f"Displaying {img_path}")
        img = Image.open(img_path)
        DISPLAY.set_image(img)
        DISPLAY.show()
        time.sleep(300)  # 5 minutes

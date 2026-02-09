#!/usr/bin/env python3

import os
import time
import logging
from PIL import Image
from config import Config
from display.display_manager import DisplayManager

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

# Configuration
IMAGE_DIR = "/home/rma/InkyRic/images"
SLEEP_SECONDS = 300  # can also be loaded from Config if desired

# Initialize device config
device_config = Config()

# Initialize display manager (chooses InkyDisplay automatically)
display_manager = DisplayManager(device_config)

# Check if image directory exists
if not os.path.exists(IMAGE_DIR):
    raise RuntimeError(f"Image directory does not exist: {IMAGE_DIR}")

# Load images
images = sorted([
    os.path.join(IMAGE_DIR, f)
    for f in os.listdir(IMAGE_DIR)
    if f.lower().endswith((".png", ".jpg", ".jpeg", ".bmp"))
])

if not images:
    raise RuntimeError(f"No images found in {IMAGE_DIR}")

logger.info(f"Loaded {len(images)} images from {IMAGE_DIR}")

# Optionally display a startup image
if device_config.get_config("startup") is True:
    logger.info("Displaying startup image")
    #from utils.app_utils import generate_startup_image
    img = generate_startup_image(device_config.get_resolution())
    display_manager.display_image(img)
    device_config.update_value("startup", False, write=True)

# Main slideshow loop
try:
    while True:
        for img_path in images:
            logger.info(f"Displaying {img_path}")
            img = Image.open(img_path)
            display_manager.display_image(img)
            time.sleep(SLEEP_SECONDS)
except KeyboardInterrupt:
    logger.info("Slideshow terminated by user")

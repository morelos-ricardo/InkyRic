import logging
from utils.image_utils import resize_image, change_orientation, apply_image_enhancement

# Only import InkyDisplay (your hardware)
from display.inky_display import InkyDisplay

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


class DisplayManager:
    """Manages the display and rendering of images on the Inky e-ink screen."""

    def __init__(self, device_config):
        """
        Initializes the display manager for the Inky display.

        Args:
            device_config (object): Configuration object containing display settings.
        """
        self.device_config = device_config
        self.display = InkyDisplay(device_config)

    def display_image(self, image, image_settings=[]):
        """
        Processes and renders the image to the Inky display.

        Args:
            image (PIL.Image): The image to be displayed.
            image_settings (list, optional): List of settings to modify image rendering.
        """
        # Save the image to current_image_file
        logger.info(f"Saving image to {self.device_config.current_image_file}")
        image.save(self.device_config.current_image_file)

        # Resize and adjust orientation
        image = change_orientation(image, self.device_config.get_config("orientation"))
        image = resize_image(image, self.device_config.get_resolution(), image_settings)
        if self.device_config.get_config("inverted_image"):
            image = image.rotate(180)
        image = apply_image_enhancement(image, self.device_config.get_config("image_settings"))

        # Render to the Inky display
        self.display.display_image(image, image_settings)

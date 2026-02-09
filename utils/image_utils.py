from PIL import Image, ImageEnhance


def change_orientation(image, orientation):
    """
    Rotate image based on orientation config.

    orientation:
        0   -> no rotation
        90  -> rotate 90 degrees
        180 -> rotate 180 degrees
        270 -> rotate 270 degrees
    """
    if orientation == 90:
        return image.rotate(90, expand=True)
    elif orientation == 180:
        return image.rotate(180, expand=True)
    elif orientation == 270:
        return image.rotate(270, expand=True)

    return image


def resize_image(image, resolution, image_settings=None):
    """
    Resize image to fit the display resolution while keeping aspect ratio.
    Image is centered on a white background if aspect ratio does not match.
    """
    target_width, target_height = resolution

    image.thumbnail((target_width, target_height), Image.LANCZOS)

    background = Image.new("RGB", (target_width, target_height), "white")
    offset_x = (target_width - image.width) // 2
    offset_y = (target_height - image.height) // 2
    background.paste(image, (offset_x, offset_y))

    return background


def apply_image_enhancement(image, settings):
    """
    Apply basic image enhancements based on config settings.
    Expected settings is a dict like:
        {
            "contrast": 1.2,
            "sharpness": 1.1
        }
    """
    if not settings:
        return image

    if "contrast" in settings:
        image = ImageEnhance.Contrast(image).enhance(settings["contrast"])

    if "sharpness" in settings:
        image = ImageEnhance.Sharpness(image).enhance(settings["sharpness"])

    return image

# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=11", "resvg-py>=0.2"]
# ///
"""Export the SVG masters in tool/branding to every platform's icon resources.

Run from any directory: uv run tool/generate_app_icons.py
Exports are committed so that builds do not need Python.
"""

import io
import json
import shutil
from pathlib import Path

import resvg_py
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "tool/branding"
RESAMPLE = Image.Resampling.LANCZOS
MASTER_SIZE = 2048

# At or below this many pixels the simplified master replaces the detailed one.
SMALL_ICON_MAX = 48

DESKTOP_FRACTION = 0.96
MAC_FRACTION = 824 / 1024  # Apple's icon grid: 824pt of art on a 1024pt canvas.
IOS_FRACTION = 0.76
ANDROID_SAFE_RADIUS_DP = 32  # Inside the 33dp safe-zone radius of the 108dp layer.
ANDROID_LAYER_DP = 108

TILE_COLOR = (253, 238, 245)

WINDOWS_SIZES = [16, 20, 24, 32, 40, 48, 64, 128, 256]
LINUX_SIZES = [16, 24, 32, 48, 64, 128, 256, 512]
ANDROID_DENSITIES = [("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2),
                     ("xxhdpi", 3), ("xxxhdpi", 4)]


def render(name):
    png = resvg_py.svg_to_bytes(svg_path=str(BRANDING / name),
                                width=MASTER_SIZE, height=MASTER_SIZE)
    return Image.open(io.BytesIO(bytes(png))).convert("RGBA")


def union_bounds(images):
    boxes = [image.getchannel("A").getbbox() for image in images]
    return (min(box[0] for box in boxes), min(box[1] for box in boxes),
            max(box[2] for box in boxes), max(box[3] for box in boxes))


def fit(image, size, fraction):
    """Centre the cropped artwork on a transparent square canvas."""
    canvas = Image.new("RGBA", (size, size))
    scale = size * fraction / max(image.size)
    artwork = image.resize((max(1, round(image.width * scale)),
                            max(1, round(image.height * scale))), RESAMPLE)
    canvas.alpha_composite(artwork, ((size - artwork.width) // 2,
                                     (size - artwork.height) // 2))
    return canvas


def tile(size):
    """A full-bleed background in the brand's pale pink."""
    return Image.new("RGBA", (size, size), (*TILE_COLOR, 255))


def safe_zone_fraction(image):
    """Scale so every visible pixel stays inside the adaptive-icon safe circle."""
    alpha = image.getchannel("A").resize((256, 256), Image.Resampling.BILINEAR)
    centre = 127.5
    pixels = alpha.load()
    radius = max(((x - centre) ** 2 + (y - centre) ** 2) ** 0.5
                 for y in range(256) for x in range(256) if pixels[x, y] >= 128)
    radius_fraction = radius / 256
    return (ANDROID_SAFE_RADIUS_DP / ANDROID_LAYER_DP) / radius_fraction


def save(image, relative):
    path = ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def pick(size, detailed, small):
    return small if size <= SMALL_ICON_MAX else detailed


def apple_catalog(directory, build):
    catalog = ROOT / directory
    entries = json.loads((catalog / "Contents.json").read_text())["images"]
    for entry in entries:
        size = round(float(entry["size"].split("x")[0]) *
                     float(entry["scale"].removesuffix("x")))
        save(build(size), catalog / entry["filename"])


def export_desktop(art, small):
    """Windows and Linux: transparent art, no tile, pixel-tuned small sizes."""
    frames = [fit(pick(size, art, small), size, DESKTOP_FRACTION)
              for size in WINDOWS_SIZES]
    frames[-1].save(ROOT / "windows/runner/resources/app_icon.ico", format="ICO",
                    sizes=[(size, size) for size in WINDOWS_SIZES],
                    append_images=frames[:-1])

    for size in LINUX_SIZES:
        save(fit(pick(size, art, small), size, DESKTOP_FRACTION),
             f"linux/icons/hicolor/{size}x{size}/apps/freepiv.png")
    scalable = ROOT / "linux/icons/hicolor/scalable/apps/freepiv.svg"
    scalable.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(BRANDING / "app_icon.svg", scalable)

    runtime = fit(art, 512, DESKTOP_FRACTION)
    save(runtime, "assets/icon-512.png")
    save(runtime, "icon-512.png")


def export_macos(art, small):
    """macOS: transparent, on Apple's icon grid."""
    master = fit(art, 1024, MAC_FRACTION)

    def build(size):
        if size <= SMALL_ICON_MAX:
            return fit(small, size, MAC_FRACTION)
        return master.resize((size, size), RESAMPLE)

    apple_catalog("macos/Runner/Assets.xcassets/AppIcon.appiconset", build)


def export_ios(art, small):
    """iOS: full-bleed and opaque; the system applies the corner mask."""
    def compose(artwork, size):
        canvas = tile(size)
        canvas.alpha_composite(fit(artwork, size, IOS_FRACTION))
        return canvas.convert("RGB")

    master = compose(art, 1024)

    def build(size):
        if size <= SMALL_ICON_MAX:
            return compose(small, size)
        return master.resize((size, size), RESAMPLE)

    apple_catalog("ios/Runner/Assets.xcassets/AppIcon.appiconset", build)


def export_android(art, mono):
    """Android: adaptive layers, themed monochrome, and a legacy pre-API-26 tile."""
    fraction = safe_zone_fraction(fit(art, 1024, 1.0))
    res = Path("android/app/src/main/res")
    for density, scale in ANDROID_DENSITIES:
        folder = res / f"mipmap-{density}"
        layer = round(ANDROID_LAYER_DP * scale)
        save(fit(art, layer, fraction), folder / "ic_launcher_foreground.png")
        save(fit(mono, layer, fraction), folder / "ic_launcher_monochrome.png")
        save(tile(layer).convert("RGB"), folder / "ic_launcher_background.png")

        size = round(48 * scale)
        supersampled = size * 4
        legacy = Image.new("RGBA", (supersampled, supersampled))
        mask = Image.new("L", (supersampled, supersampled))
        inset = round(supersampled * 0.04)
        ImageDraw.Draw(mask).rounded_rectangle(
            (inset, inset, supersampled - inset, supersampled - inset),
            radius=round(supersampled * 0.2), fill=255)
        legacy.paste(tile(supersampled), mask=mask)
        legacy.alpha_composite(fit(art, supersampled, 0.72))
        save(legacy.resize((size, size), RESAMPLE), folder / "ic_launcher.png")


def main():
    art, small, mono = (render(name) for name in (
        "app_icon.svg", "app_icon_small.svg", "app_icon_monochrome.svg"))
    # The small master has no whiskers, so it crops tighter and fills its size.
    bounds = union_bounds([art, mono])
    art, mono = art.crop(bounds), mono.crop(bounds)
    small = small.crop(union_bounds([small]))

    export_desktop(art, small)
    export_macos(art, small)
    export_ios(art, small)
    export_android(art, mono)
    print("Exported Windows, Linux, macOS, iOS, Android and in-app icons.")


if __name__ == "__main__":
    main()

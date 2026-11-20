from itertools import islice
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUTPUT_DIR = Path(__file__).resolve().parent
SCREEN_SIZE = (640, 480)
FONT_PATH = Path(r"C:\Windows\Fonts\arialbd.ttf")
WORDS_PER_LINE = 32
MAX_GAME_OVER_WIDTH = 600
GAME_OVER_WIDTH = 220


def font_for_height(text: str, target_height: int) -> ImageFont.FreeTypeFont:
    if not FONT_PATH.is_file():
        raise FileNotFoundError(f"Bold Arial font not found: {FONT_PATH}")

    measuring_draw = ImageDraw.Draw(Image.new("L", (1, 1)))
    lower, upper = 1, 512
    while lower < upper:
        size = (lower + upper) // 2
        font = ImageFont.truetype(str(FONT_PATH), size)
        bounds = measuring_draw.textbbox((0, 0), text, font=font)
        if bounds[3] - bounds[1] < target_height:
            lower = size + 1
        else:
            upper = size
    return ImageFont.truetype(str(FONT_PATH), lower)


def text_mask(text: str, target_height: int, max_width: int | None = None) -> Image.Image:
    font = font_for_height(text, target_height)
    draw = ImageDraw.Draw(Image.new("L", (1, 1)))
    left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
    mask = Image.new("L", (right - left, bottom - top), 0)
    ImageDraw.Draw(mask).text((-left, -top), text, font=font, fill=255)

    if max_width is not None and mask.width > max_width:
        mask = mask.resize(
            (max_width, mask.height),
            resample=Image.Resampling.LANCZOS,
        )
    return mask


def render_screen(
    text: str,
    color: tuple[int, int, int],
    height: int,
    max_width: int | None,
    output_width: int | None = None,
) -> Image.Image:
    image = Image.new("RGB", SCREEN_SIZE, (0, 0, 0))
    mask = text_mask(text, height, max_width)
    x = (SCREEN_SIZE[0] - mask.width) // 2
    y = (SCREEN_SIZE[1] - mask.height) // 2
    image.paste(color, (x, y), mask)
    bounds = image.getbbox()
    if bounds is None:
        raise RuntimeError(f"Rendered text is empty: {text}")
    cropped = image.crop(bounds)
    if output_width is not None and cropped.width > output_width:
        scaled_height = round(cropped.height * output_width / cropped.width)
        cropped = cropped.resize(
            (output_width, scaled_height),
            resample=Image.Resampling.LANCZOS,
        )
    return cropped


def write_coe(path: Path, image: Image.Image) -> None:
    pixels = image.load()
    width, height = image.size
    with path.open("w", encoding="ascii", newline="\n") as coe_file:
        coe_file.write("memory_initialization_radix=16;\n")
        coe_file.write("memory_initialization_vector=\n")
        words = (
            f"{((red >> 4) << 8) | ((green >> 4) << 4) | (blue >> 4):03X}"
            for y in range(height)
            for x in range(width)
            for red, green, blue in (pixels[x, y],)
        )

        line = list(islice(words, WORDS_PER_LINE))
        while line:
            next_line = list(islice(words, WORDS_PER_LINE))
            ending = "," if next_line else ";"
            coe_file.write(", ".join(line) + ending + "\n")
            line = next_line


def main() -> None:
    screens = (
        ("press_space_to_start", "press [space] to start", (255, 255, 255), 30, None, None),
        ("game_over", "GAME OVER", (255, 255, 0), 150, MAX_GAME_OVER_WIDTH, GAME_OVER_WIDTH),
        ("press_space_to_restart", "press [space] to restart", (255, 255, 255), 30, None, None),
    )

    for name, text, color, height, max_width, output_width in screens:
        image = render_screen(text, color, height, max_width, output_width)
        png_path = OUTPUT_DIR / f"{name}.png"
        coe_path = OUTPUT_DIR / f"{name}.coe"
        image.save(png_path)
        write_coe(coe_path, image)
        print(f"Generated {png_path.name} and {coe_path.name} ({image.width}x{image.height})")


if __name__ == "__main__":
    main()

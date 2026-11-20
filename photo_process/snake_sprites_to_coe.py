from pathlib import Path

from PIL import Image


SPRITE_DIR = Path(__file__).resolve().parent
SPRITES = {
    "body_up_down": ("body_up_down.png", None),
    "head_down": ("head_down.png", None),
    "tail_down": ("tail_down.png", None),
    "turn_left_down": ("turn_left_down.png", None),
    "body_left_tight": ("body_up_down.png", Image.Transpose.ROTATE_90),
    "head_up": ("head_down.png", Image.Transpose.ROTATE_180),
    "head_right": ("head_down.png", Image.Transpose.ROTATE_90),
    "head_left": ("head_down.png", Image.Transpose.ROTATE_270),
    "tail_right": ("tail_down.png", Image.Transpose.ROTATE_90),
    "tail_left": ("tail_down.png", Image.Transpose.ROTATE_270),
    "tail_up": ("tail_down.png", Image.Transpose.ROTATE_180),
    "turn_down_right": ("turn_left_down.png", Image.Transpose.ROTATE_90),
    "turn_right_up": ("turn_left_down.png", Image.Transpose.ROTATE_180),
    "turn_up_left": ("turn_left_down.png", Image.Transpose.ROTATE_270),
}
SPRITE_SIZE = (20, 20)
WORDS_PER_LINE = 20


def write_coe(path: Path, pixels: list[tuple[int, int, int]]) -> None:
    words = [
        f"{((red >> 4) << 8) | ((green >> 4) << 4) | (blue >> 4):03X}"
        for red, green, blue in pixels
    ]
    with path.open("w", encoding="ascii", newline="\n") as coe_file:
        coe_file.write("memory_initialization_radix=16;\n")
        coe_file.write("memory_initialization_vector=\n")
        for start in range(0, len(words), WORDS_PER_LINE):
            line = ", ".join(words[start : start + WORDS_PER_LINE])
            ending = ";" if start + WORDS_PER_LINE >= len(words) else ","
            coe_file.write(f"{line}{ending}\n")


def main() -> None:
    for name, (source_name, rotation) in SPRITES.items():
        source_path = SPRITE_DIR / source_name
        if not source_path.is_file():
            raise FileNotFoundError(f"Source image not found: {source_path}")

        with Image.open(source_path) as source:
            if source.size != SPRITE_SIZE:
                raise ValueError(
                    f"{source_name} must be {SPRITE_SIZE[0]}x{SPRITE_SIZE[1]}, "
                    f"got {source.size[0]}x{source.size[1]}"
                )
            image = source.convert("RGB")
            if rotation is not None:
                image = image.transpose(rotation)

        if rotation is not None:
            image.save(SPRITE_DIR / f"{name}.png")
        pixels = [
            image.getpixel((x, y))
            for y in range(image.height)
            for x in range(image.width)
        ]
        write_coe(SPRITE_DIR / f"{name}.coe", pixels)
        print(f"Generated {name}.coe")


if __name__ == "__main__":
    main()

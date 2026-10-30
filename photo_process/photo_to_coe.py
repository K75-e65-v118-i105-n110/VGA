from collections.abc import Iterable
from itertools import islice
from pathlib import Path

from PIL import Image, ImageOps


INPUT_IMAGE = Path(__file__).resolve().with_name("input.jpg")
OUTPUT_INDEX_COE = Path(__file__).resolve().with_name("photo_index4.coe")
OUTPUT_PALETTE_COE = Path(__file__).resolve().with_name("photo_palette_rgb444.coe")
IMAGE_WIDTH = 640
IMAGE_HEIGHT = 480
PALETTE_SIZE = 16
WORDS_PER_LINE = 16


def write_coe(path: Path, words: Iterable[str]) -> None:
    word_iterator = iter(words)
    with path.open("w", encoding="ascii", newline="\n") as coe_file:
        coe_file.write("memory_initialization_radix=16;\n")
        coe_file.write("memory_initialization_vector=\n")
        line = list(islice(word_iterator, WORDS_PER_LINE))
        while line:
            next_line = list(islice(word_iterator, WORDS_PER_LINE))
            ending = "," if next_line else ";"
            coe_file.write(", ".join(line) + ending + "\n")
            line = next_line


def main() -> None:
    if not INPUT_IMAGE.is_file():
        raise FileNotFoundError(
            f"Input image not found: {INPUT_IMAGE}\n"
            "Put the source image next to this script or update INPUT_IMAGE."
        )

    with Image.open(INPUT_IMAGE) as source:
        oriented = ImageOps.exif_transpose(source)
        image = ImageOps.fit(
            oriented.convert("RGB"),
            (IMAGE_WIDTH, IMAGE_HEIGHT),
            method=Image.Resampling.LANCZOS,
        )

    indexed_image = image.quantize(
        colors=PALETTE_SIZE,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.FLOYDSTEINBERG,
    )
    index_words = (f"{index:X}" for index in indexed_image.getdata())
    write_coe(OUTPUT_INDEX_COE, index_words)

    palette = indexed_image.getpalette()
    if palette is None:
        raise RuntimeError("The quantized image does not contain a color palette.")
    palette_words = []
    for offset in range(0, PALETTE_SIZE * 3, 3):
        red, green, blue = palette[offset : offset + 3]
        rgb444 = ((red >> 4) << 8) | ((green >> 4) << 4) | (blue >> 4)
        palette_words.append(f"{rgb444:03X}")
    write_coe(OUTPUT_PALETTE_COE, palette_words)

    print(
        f"Converted {INPUT_IMAGE.name} to {IMAGE_WIDTH}x{IMAGE_HEIGHT} "
        f"with a {PALETTE_SIZE}-color palette."
    )
    print(f"4-bit pixel indices: {OUTPUT_INDEX_COE}")
    print(f"RGB444 palette: {OUTPUT_PALETTE_COE}")


if __name__ == "__main__":
    main()

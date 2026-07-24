#!/usr/bin/env python3
"""Generates the graphics both stores ask for.

    python3 tool/make_store_graphics.py

Writes to `build/store/` (gitignored — one command regenerates everything, so
there is no reason to carry binaries in the repository):

* `play_icon_512.png`              Play Console, "App-Icon", 512 × 512, no alpha
* `appstore_icon_1024.png`         App Store Connect, 1024 × 1024, no alpha
* `play_feature_graphic_1024x500.png`  Play Console, "Feature-Grafik"

A script rather than a one-off in a design tool, for the same reason as
`tool/make_music.py`: when the icon or the palette changes, the store assets
should be one command behind, not a rediscovery.

The feature graphic is built from the app's own material — real coloring
pages rendered from their SVGs, the Fredoka faces the app ships, the tones
from `lib/ui/pixie_palette.dart` — so the store listing looks like the app it
is selling rather than like a stranger's poster.

Needs `rsvg-convert` (Homebrew: `brew install librsvg`) and Pillow
(`pip3 install pillow`).
"""
import pathlib
import shutil
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / 'build' / 'store'

# Straight from lib/ui/pixie_palette.dart — the one place the app's tones live.
PAPER = (255, 249, 240)
INK = (74, 58, 92)
SUNSHINE_LIGHT = (255, 233, 168)
BUBBLEGUM_LIGHT = (255, 210, 228)
GRAPE_LIGHT = (226, 213, 255)
SKY_LIGHT = (201, 236, 255)
MINT_LIGHT = (204, 243, 224)
# The adaptive-icon background from pubspec.yaml, used to flatten the icons:
# Play and Apple both want an opaque square.
ICON_BG = (237, 231, 246)

FONT_BOLD = ROOT / 'assets' / 'fonts' / 'Fredoka-Bold.ttf'
FONT_MEDIUM = ROOT / 'assets' / 'fonts' / 'Fredoka-Medium.ttf'

# Four motifs that show the range without needing a caption: a familiar
# animal, a vehicle, something from the fantasy shelf, one of the new farm
# pictures.
MOTIFS = ['cat', 'rocket', 'unicorn', 'cow']


def check_tools():
    if not shutil.which('rsvg-convert'):
        sys.exit('rsvg-convert missing — install it with: brew install librsvg')
    for font in (FONT_BOLD, FONT_MEDIUM):
        if not font.exists():
            sys.exit(f'font missing: {font}')


def flatten(image, background):
    """Puts an RGBA image on an opaque background.

    Both stores reject (Apple) or mangle (Play) transparency in the icon, and
    a PNG that merely *looks* opaque still carries an alpha channel.
    """
    flat = Image.new('RGB', image.size, background)
    flat.paste(image, mask=image.split()[-1] if image.mode == 'RGBA' else None)
    return flat


def icons():
    source = Image.open(ROOT / 'assets' / 'icon' / 'icon.png').convert('RGBA')
    for size, name in [(512, 'play_icon_512.png'),
                       (1024, 'appstore_icon_1024.png')]:
        scaled = source.resize((size, size), Image.LANCZOS)
        out = OUT / name
        flatten(scaled, ICON_BG).save(out, 'PNG')
        print(f'{out.relative_to(ROOT)}  {size}×{size}, opaque')


def render_svg(name, height):
    """Rasterizes a coloring page to a transparent PNG of the given height."""
    svg = ROOT / 'assets' / 'coloring_pages' / f'{name}.svg'
    if not svg.exists():
        sys.exit(f'no such coloring page: {svg}')
    png = OUT / f'_{name}.png'
    subprocess.run(
        ['rsvg-convert', '-h', str(height), '-o', str(png), str(svg)],
        check=True)
    return Image.open(png).convert('RGBA')


def soft_background(size):
    """Paper with four faint colour washes — the app's blob background, still."""
    width, height = size
    canvas = Image.new('RGB', size, PAPER)
    blobs = [
        ((-120, -140, 420, 320), SUNSHINE_LIGHT),
        ((width - 380, -160, width + 160, 300), BUBBLEGUM_LIGHT),
        ((-160, height - 300, 380, height + 180), MINT_LIGHT),
        ((width - 460, height - 260, width + 120, height + 200), GRAPE_LIGHT),
        ((width // 2 - 260, -220, width // 2 + 300, 200), SKY_LIGHT),
    ]
    for box, colour in blobs:
        layer = Image.new('RGB', size, PAPER)
        ImageDraw.Draw(layer).ellipse(box, fill=colour)
        # Half strength: a wash, not a shape.
        canvas = Image.blend(canvas, layer, 0.5)
    return canvas


def feature_graphic():
    """Play's 1024 × 500 banner: title on the left, four motifs on the right.

    Play crops this differently on different surfaces and can overlay the app
    icon on the left, so nothing important goes near the edges and the text
    keeps its distance from the middle.
    """
    size = (1024, 500)
    canvas = soft_background(size).convert('RGBA')

    # Four motifs on the right, as a 2 × 2 grid placed by centre point.
    #
    # Both details here are corrections of a first attempt that looked fine in
    # the code and terrible on screen: the drawings overlapped into a tangle,
    # and two of them ran off the canvas. Positioning by centre (rather than by
    # top-left) survives the size change that `rotate(expand=True)` causes, and
    # the grid keeps every motif whole with room around it.
    placements = [
        ('cat', (680, 148), -7),
        ('rocket', (900, 148), 8),
        ('cow', (680, 350), 6),
        ('unicorn', (900, 350), -6),
    ]
    for name, (cx, cy), angle in placements:
        art = render_svg(name, 150)
        art = art.rotate(angle, resample=Image.BICUBIC, expand=True)
        canvas.alpha_composite(art, (cx - art.width // 2, cy - art.height // 2))

    draw = ImageDraw.Draw(canvas)
    title = ImageFont.truetype(str(FONT_BOLD), 92)
    subtitle = ImageFont.truetype(str(FONT_MEDIUM), 38)
    draw.text((64, 150), 'PixiePaint', font=title, fill=INK)
    draw.text((66, 262), 'Malbuch für Kinder', font=subtitle, fill=INK)
    draw.text((66, 312), 'ohne Werbung · ganz offline', font=subtitle,
              fill=(INK[0], INK[1], INK[2]))

    out = OUT / 'play_feature_graphic_1024x500.png'
    canvas.convert('RGB').save(out, 'PNG')
    print(f'{out.relative_to(ROOT)}  1024×500')


def main():
    check_tools()
    OUT.mkdir(parents=True, exist_ok=True)
    icons()
    feature_graphic()
    # The intermediate SVG renders are not deliverables.
    for tmp in OUT.glob('_*.png'):
        tmp.unlink()
    print(f'\nready in {OUT.relative_to(ROOT)} — look at them before uploading;'
          '\nthese three files are pure appearance, and no test can judge that.')


if __name__ == '__main__':
    main()

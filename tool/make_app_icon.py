"""Draws the KFM app icon and writes every platform's copy (TASK-PL1).

A rounded indigo square (the app's default theme seed, #3F51B5) with a white
folder and a green check badge (the swipe "keep" green family).

Writes:
- windows/runner/resources/app_icon.ico (16..256 px)
- assets/windows/tray_sharing.ico (the icon + a "sharing" dot, tray only)
- android/app/src/main/res/mipmap-*/ic_launcher.png (legacy launcher icon)
- android/app/src/main/res/mipmap-*/ic_launcher_foreground.png +
  mipmap-anydpi-v26/ic_launcher.xml + values/ic_launcher_background.xml
  (adaptive icon, Android 8+)
- tool/app_icon_1024.png (preview / store listing source)

Run from the repo root: python tool/make_app_icon.py  (needs Pillow)
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
S = 1024  # design canvas

INDIGO_TOP = (92, 107, 192)  # #5C6BC0
INDIGO_BOTTOM = (48, 63, 159)  # #303F9F
BACKGROUND = '#3F51B5'
FOLDER_BACK = (197, 202, 233)  # #C5CAE9
FOLDER_FRONT = (255, 255, 255)
GREEN = (46, 157, 99)  # #2E9D63
SHARE_DOT = (76, 217, 100)


def gradient(size, top, bottom):
    img = Image.new('RGBA', (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / (size - 1)
        color = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
        draw.line([(0, y), (size, y)], fill=color + (255,))
    return img


def draw_glyph(img, scale=1.0, offset=(0, 0)):
    """The folder + check, designed on the 1024 canvas."""
    draw = ImageDraw.Draw(img)

    def p(x, y):
        return (offset[0] + x * scale, offset[1] + y * scale)

    def box(x0, y0, x1, y1):
        return [p(x0, y0), p(x1, y1)]

    r = 44 * scale
    # Back plate with the tab.
    draw.rounded_rectangle(box(212, 300, 500, 420), radius=r, fill=FOLDER_BACK)
    draw.rounded_rectangle(box(212, 350, 812, 760), radius=r, fill=FOLDER_BACK)
    # Front panel.
    draw.rounded_rectangle(box(212, 430, 812, 760), radius=r, fill=FOLDER_FRONT)
    # Check badge with a ring in the background colour.
    cx, cy, rad = 742, 712, 168
    ring = 30
    draw.ellipse(
        box(cx - rad - ring, cy - rad - ring, cx + rad + ring, cy + rad + ring),
        fill=INDIGO_BOTTOM,
    )
    draw.ellipse(box(cx - rad, cy - rad, cx + rad, cy + rad), fill=GREEN)
    w = round(46 * scale)
    pts = [p(cx - 78, cy + 4), p(cx - 20, cy + 62), p(cx + 86, cy - 58)]
    draw.line(pts, fill=(255, 255, 255), width=w, joint='curve')
    for x, y in (pts[0], pts[-1]):
        draw.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill='white')


def full_icon(margin=0.0):
    """The square icon at S px with [margin] (fraction) of transparent edge."""
    inner = round(S * (1 - 2 * margin))
    tile = gradient(inner, INDIGO_TOP, INDIGO_BOTTOM)
    mask = Image.new('L', (inner, inner), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, inner - 1, inner - 1], radius=round(inner * 0.22), fill=255
    )
    glyph = Image.new('RGBA', (inner, inner), (0, 0, 0, 0))
    draw_glyph(glyph, scale=inner / S)
    tile.alpha_composite(glyph)
    out = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    out.paste(tile, ((S - inner) // 2, (S - inner) // 2), mask)
    return out


def with_share_dot(icon):
    out = icon.copy()
    draw = ImageDraw.Draw(out)
    cx, cy, rad = 800, 224, 190
    draw.ellipse([cx - rad - 36, cy - rad - 36, cx + rad + 36, cy + rad + 36],
                 fill='white')
    draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=SHARE_DOT)
    return out


def foreground():
    """Adaptive icon foreground: 108dp canvas, glyph inside the 66dp safe
    zone (the launcher masks the rest)."""
    out = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    scale = 0.62
    off = (S * (1 - scale) / 2, S * (1 - scale) / 2)
    draw_glyph(out, scale=scale, offset=off)
    return out


def save_ico(img, path, sizes):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, format='ICO', sizes=[(s, s) for s in sizes])


def main():
    icon = full_icon(margin=0.03)
    icon.save(ROOT / 'tool' / 'app_icon_1024.png')
    ico_sizes = [16, 20, 24, 32, 40, 48, 64, 96, 128, 256]
    save_ico(icon, ROOT / 'windows' / 'runner' / 'resources' / 'app_icon.ico',
             ico_sizes)
    save_ico(with_share_dot(icon), ROOT / 'assets' / 'windows' /
             'tray_sharing.ico', [16, 20, 24, 32, 48, 64])

    res = ROOT / 'android' / 'app' / 'src' / 'main' / 'res'
    legacy = full_icon(margin=0.06)
    fg = foreground()
    for density, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144,
                        'xxxhdpi': 192}.items():
        folder = res / f'mipmap-{density}'
        folder.mkdir(parents=True, exist_ok=True)
        legacy.resize((px, px), Image.LANCZOS).save(folder / 'ic_launcher.png')
        fg_px = px * 108 // 48
        fg.resize((fg_px, fg_px), Image.LANCZOS).save(
            folder / 'ic_launcher_foreground.png')
    anydpi = res / 'mipmap-anydpi-v26'
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / 'ic_launcher.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Generated by tool/make_app_icon.py -->\n'
        '<adaptive-icon xmlns:android='
        '"http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n',
        encoding='utf-8',
    )
    (res / 'values' / 'ic_launcher_background.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Generated by tool/make_app_icon.py -->\n'
        '<resources>\n'
        f'    <color name="ic_launcher_background">{BACKGROUND}</color>\n'
        '</resources>\n',
        encoding='utf-8',
    )
    print('icons written')


if __name__ == '__main__':
    main()

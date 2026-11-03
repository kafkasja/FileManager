"""Generates small distinct JPEGs for the speed checks (TASK-PL1 / PL3).

    python tool/make_perf_images.py <folder> <count>

Each image is 400x300 (bigger than the 256 px thumbnail, like a photo) with
a few random coloured shapes and its number, so every Shell thumbnail
differs. Existing files are kept (re-running only adds
what is missing). Delete the folder after the check.
"""

import os
import random
import sys
from concurrent.futures import ProcessPoolExecutor

from PIL import Image, ImageDraw

W, H = 400, 300


def _make(args):
    folder, start, end = args
    for i in range(start, end):
        path = os.path.join(folder, f"IMG_{i:06d}.jpg")
        if os.path.exists(path):
            continue
        rnd = random.Random(i)
        img = Image.new("RGB", (W, H), tuple(rnd.randrange(256) for _ in range(3)))
        d = ImageDraw.Draw(img)
        for _ in range(6):
            x0, y0 = rnd.randrange(W), rnd.randrange(H)
            x1, y1 = x0 + rnd.randrange(25, 200), y0 + rnd.randrange(25, 150)
            colour = tuple(rnd.randrange(256) for _ in range(3))
            if rnd.random() < 0.5:
                d.rectangle((x0, y0, x1, y1), fill=colour)
            else:
                d.ellipse((x0, y0, x1, y1), fill=colour)
        d.text((12, 12), str(i), fill=(255, 255, 255), font_size=40)
        img.save(path, "JPEG", quality=80)
    return end - start


def main():
    folder, count = sys.argv[1], int(sys.argv[2])
    os.makedirs(folder, exist_ok=True)
    step = 1000
    jobs = [(folder, s, min(s + step, count)) for s in range(0, count, step)]
    with ProcessPoolExecutor(max_workers=min(8, os.cpu_count() or 4)) as pool:
        done = 0
        for n in pool.map(_make, jobs):
            done += n
    print(f"{count} images in {folder}")


if __name__ == "__main__":
    main()

"""Generates small distinct JPEGs for the speed checks (TASK-PL1 / PL3).

    python tool/make_perf_images.py <folder> <count>

Each image is 160x120 with a few random coloured shapes and its number, so
every Shell thumbnail differs. Existing files are kept (re-running only adds
what is missing). Delete the folder after the check.
"""

import os
import random
import sys
from concurrent.futures import ProcessPoolExecutor

from PIL import Image, ImageDraw


def _make(args):
    folder, start, end = args
    for i in range(start, end):
        path = os.path.join(folder, f"IMG_{i:06d}.jpg")
        if os.path.exists(path):
            continue
        rnd = random.Random(i)
        img = Image.new("RGB", (160, 120), tuple(rnd.randrange(256) for _ in range(3)))
        d = ImageDraw.Draw(img)
        for _ in range(6):
            x0, y0 = rnd.randrange(160), rnd.randrange(120)
            x1, y1 = x0 + rnd.randrange(10, 80), y0 + rnd.randrange(10, 60)
            colour = tuple(rnd.randrange(256) for _ in range(3))
            if rnd.random() < 0.5:
                d.rectangle((x0, y0, x1, y1), fill=colour)
            else:
                d.ellipse((x0, y0, x1, y1), fill=colour)
        d.text((6, 6), str(i), fill=(255, 255, 255))
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

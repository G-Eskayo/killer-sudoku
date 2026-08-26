#!/usr/bin/env python3
# Regenerates the app icon master image and Resources/AppIcon.icns from scratch.
# Requires Pillow (pip install Pillow) and macOS's sips/iconutil.
#
# Usage: python3 scripts/generate-icon.py   (run from the repo root)
import math
import os
import subprocess
from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

corner_radius = 185
bg_color = (23, 23, 25, 255)
draw.rounded_rectangle([(0, 0), (SIZE - 1, SIZE - 1)], radius=corner_radius, fill=bg_color)

# Bold 3x3 grid only (no fine 9x9 subdivision) -- reads cleanly at every size down to 16px,
# where a full 9x9 grid would blur into noise. Rounded cell corners echo the app's own
# selection/mistake-highlight rounded-rect style.
margin = 165
grid_size = SIZE - 2 * margin
cell = grid_size / 3
line_color = (255, 255, 255, 235)
line_width = 20

for i in range(4):
    x = margin + i * cell
    draw.line([(x, margin), (x, margin + grid_size)], fill=line_color, width=line_width)
    y = margin + i * cell
    draw.line([(margin, y), (margin + grid_size, y)], fill=line_color, width=line_width)

# One dashed "cage" spanning two cells in the top row, hinting at Killer Sudoku's defining
# mechanic -- sized against the coarser 3x3 cells so the dashes stay visible when scaled down.
inset = 34
cage_left = margin + inset
cage_top = margin + inset
cage_right = margin + 2 * cell - inset
cage_bottom = margin + cell - inset

dash_len = 34
gap_len = 24
dash_width = 14


def dashed_line(draw, p0, p1, dash_len, gap_len, color, width):
    x0, y0 = p0
    x1, y1 = p1
    length = math.hypot(x1 - x0, y1 - y0)
    if length == 0:
        return
    dx = (x1 - x0) / length
    dy = (y1 - y0) / length
    pos = 0.0
    while pos < length:
        seg_end = min(pos + dash_len, length)
        draw.line(
            [(x0 + dx * pos, y0 + dy * pos), (x0 + dx * seg_end, y0 + dy * seg_end)],
            fill=color, width=width
        )
        pos += dash_len + gap_len


dashed_line(draw, (cage_left, cage_top), (cage_right, cage_top), dash_len, gap_len, line_color, dash_width)
dashed_line(draw, (cage_left, cage_bottom), (cage_right, cage_bottom), dash_len, gap_len, line_color, dash_width)
dashed_line(draw, (cage_left, cage_top), (cage_left, cage_bottom), dash_len, gap_len, line_color, dash_width)
dashed_line(draw, (cage_right, cage_top), (cage_right, cage_bottom), dash_len, gap_len, line_color, dash_width)

repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
build_dir = os.path.join(repo_root, ".build", "icon-src")
os.makedirs(build_dir, exist_ok=True)
master_path = os.path.join(build_dir, "icon-1024.png")
img.save(master_path)
print("saved", master_path)

iconset_dir = os.path.join(build_dir, "AppIcon.iconset")
if os.path.exists(iconset_dir):
    subprocess.run(["rm", "-rf", iconset_dir], check=True)
os.makedirs(iconset_dir)

sizes = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
]
for name, px in sizes:
    subprocess.run(
        ["sips", "-z", str(px), str(px), master_path, "--out", os.path.join(iconset_dir, name)],
        check=True, stdout=subprocess.DEVNULL
    )
subprocess.run(["cp", master_path, os.path.join(iconset_dir, "icon_512x512@2x.png")], check=True)

icns_path = os.path.join(repo_root, "Resources", "AppIcon.icns")
os.makedirs(os.path.dirname(icns_path), exist_ok=True)
subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", icns_path], check=True)
print("saved", icns_path)

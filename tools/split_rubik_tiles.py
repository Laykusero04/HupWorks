from PIL import Image
from pathlib import Path

src = Path(r'c:\seve\flutter\HupWorks\images\HupWorks.png')
out = Path(r'c:\seve\flutter\HupWorks\images\rubik_tiles')
out.mkdir(parents=True, exist_ok=True)

img = Image.open(src).convert('RGBA')
w, h = img.size
print(f'source: {w}x{h}')

cw, ch = w // 3, h // 3
names = [
    'tile_0_0', 'tile_0_1', 'tile_0_2',
    'tile_1_0', 'tile_1_1', 'tile_1_2',
    'tile_2_0', 'tile_2_1', 'tile_2_2',
]

for i, name in enumerate(names):
    row, col = divmod(i, 3)
    left = col * cw
    top = row * ch
    right = w if col == 2 else (col + 1) * cw
    bottom = h if row == 2 else (row + 1) * ch
    tile = img.crop((left, top, right, bottom))
    path = out / f'{name}.png'
    tile.save(path, 'PNG')
    print(f'{name}: {tile.size[0]}x{tile.size[1]} -> {path.name}')

print('done')

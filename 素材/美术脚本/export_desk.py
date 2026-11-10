"""桌面一屏的美术导出到游戏：assets/desk/。"""
import os
import sys
from PIL import Image, ImageDraw
from faces import Pix, hx, sh, mix
import desk_art as A

OUT = sys.argv[1] + '/desk'
os.makedirs(OUT, exist_ok=True)


def save(im, name):
    im.save(f'{OUT}/{name}.png')


save(A.desk_bg(), 'desk_bg')
save(A.family_photo(), 'family_photo')
save(A.phone('down'), 'phone_down')
save(A.phone('lit', clock=None), 'phone_lit')
save(A.printer('idle'), 'printer_idle')
save(A.printer('printing'), 'printer_busy')
# 文件盒：0–10 层纸，一行 11 帧
fb = Image.new('RGBA', (86 * 11, 62))
for n in range(11):
    fb.alpha_composite(A.file_box(n), (n * 86, 0))
save(fb, 'file_box')
for k in ('pass', 'reject', 'exception'):
    save(A.stamp_tool(k), f'stamp_{k}')

# 章印的外形（白色，游戏里按墨色染）：72×72，字由游戏写
F = A.F
for k in ('pass', 'reject', 'exception'):
    m = Image.new('RGBA', (72, 72))
    d = ImageDraw.Draw(m)
    cx = cy = 36
    W = (255, 255, 255, 255)
    if k == 'pass':
        d.rounded_rectangle([cx - 30, cy - 15, cx + 29, cy + 14], 5, outline=W, width=2)
        d.rounded_rectangle([cx - 26, cy - 11, cx + 25, cy + 10], 3, outline=W, width=1)
    elif k == 'reject':
        d.rectangle([cx - 30, cy - 15, cx + 29, cy + 14], outline=W, width=3)
        d.line([cx - 26, cy + 11, cx + 25, cy - 12], fill=W, width=1)
    else:
        import math
        d.ellipse([cx - 25, cy - 25, cx + 24, cy + 24], outline=W, width=2)
        d.ellipse([cx - 21, cy - 21, cx + 20, cy + 20], outline=W, width=1)
        pts = []
        for i in range(10):
            r = 5 if i % 2 == 0 else 2
            a = -math.pi / 2 + i * math.pi / 5
            pts.append((cx + r * math.cos(a), cy - 12 + r * math.sin(a)))
        d.polygon(pts, fill=W)
        d.line([cx - 10, cy + 12, cx + 9, cy + 12], fill=W)
    save(m, f'ink_{k}')

# 小零件
clip = Image.new('RGBA', (6, 19))
P = Pix(clip)
for y in range(1, 17):
    P.p(1, y, hx('9aa2aa'))
    P.p(4, y, hx('c8d0d8'))
P.r(1, 0, 4, 1, hx('c8d0d8'))
P.r(2, 17, 2, 1, hx('c8d0d8'))
save(clip, 'paperclip')
staple = Image.new('RGBA', (7, 2))
P = Pix(staple)
P.r(0, 0, 7, 1, hx('a0a4a8'))
P.p(0, 1, hx('6a6e72'))
P.p(6, 1, hx('6a6e72'))
save(staple, 'staple')
ring = Image.new('RGBA', (12, 3))
P = Pix(ring)
P.r(0, 0, 9, 2, hx('1a1c1c'))
P.p(1, 0, hx('6a6e6e'))
P.r(9, 0, 2, 2, hx('5a605a'))
P.r(1, 2, 9, 1, (0, 0, 0, 90))
save(ring, 'ring')
# 身份证复印件的底：碳粉麻点 + 左边复印黑边
import random
rnd = random.Random(2)
idc = Image.new('RGBA', (170, 72), hx('d0d2ce'))
P = Pix(idc)
for _ in range(170 * 72 // 6):
    x, y = rnd.randrange(170), rnd.randrange(72)
    P.p(x, y, hx('c2c4c0') if rnd.random() < 0.8 else hx('a8aaa6'))
P.r(0, 0, 3, 72, hx('6a6c68'))
for y in range(72):
    if rnd.random() < 0.5:
        P.p(3, y, hx('9a9c98'))
save(idc, 'id_copy')
# 折角（协议书右下）
dog = Image.new('RGBA', (10, 10))
P = Pix(dog)
for i in range(10):
    P.r(0, 9 - i, i + 1, 1, hx('d8d2c0'))
    P.p(i, 9 - i, hx('b8b2a0'))
save(dog, 'dogear')
# 便利贴翘角
curl = Image.new('RGBA', (7, 7))
P = Pix(curl)
for i in range(7):
    P.r(0, 6 - i, i + 1, 1, hx('d8b840'))
    P.p(i, 6 - i, hx('b89820'))
save(curl, 'curl')

# 抽屉
save(A.drawer_closed(), 'drawer_closed')
base = Image.new('RGBA', (302, 138))
P = Pix(base)
P.r(2, 2, 300, 136, (0, 0, 0, 150))
P.r(0, 0, 300, 136, hx('2c2420'))
P.r(6, 6, 288, 124, hx('3a2e26'))
for y in range(6, 130):
    if y % 4 == 0:
        P.r(6, y, 288, 1, hx('34291f'))
P.r(0, 128, 300, 8, hx('242b28'))
P.r(136, 130, 28, 3, hx('8a8a84'))
save(base, 'drawer_open')
env = Image.new('RGBA', (60, 34))
P = Pix(env)
P.r(0, 0, 60, 34, hx('c8a46a'))
P.r(0, 0, 60, 1, hx('dcbc84'))
for i in range(30):
    P.p(i, i // 2, hx('a88850'))
    P.p(59 - i, i // 2, hx('a88850'))
save(env, 'envelope')
book = Image.new('RGBA', (72, 84))
P = Pix(book)
P.r(0, 0, 64, 84, hx('1e2a44'))
P.r(0, 0, 64, 1, hx('3a4a6a'))
P.r(2, 2, 2, 80, hx('16203a'))
P.r(12, 12, 40, 14, hx('e8e4d8'))
for i, c in enumerate(['e8c84a', '7fd6a4', 'c8402f', 'e8c84a', 'f0f0e0', '7fd6a4']):
    P.r(64, 6 + i * 12, 5, 7, hx(c))
save(book, 'zhou_book')
mail = Image.new('RGBA', (80, 96), hx('eef0f0'))
mp = Pix(mail)
mp.r(0, 0, 80, 10, hx('d8dcdc'))
A.greek(mp, 4, 3, 50, hx('5a6060'), rnd, 1)
A.greek(mp, 4, 14, 70, hx('6a7070'), rnd, 14, 5)
mp.r(4, 30, 46, 5, hx('f0e080'))
save(mail.rotate(-6, expand=True, resample=Image.NEAREST), 'mail_print')
card = Image.new('RGBA', (34, 22))
P = Pix(card)
P.r(0, 0, 34, 22, hx('c8402f'))
P.r(0, 0, 34, 1, hx('e86a5a'))
P.r(4, 6, 16, 2, hx('e8c84a'))
P.r(4, 14, 22, 1, hx('f0c0b0'))
save(card, 'gift_card')
# 王总的语音：转存在一个 U 盘里
usb = Image.new('RGBA', (30, 12))
P = Pix(usb)
P.r(0, 1, 22, 10, hx('2a2e34'))
P.r(0, 1, 22, 1, hx('4a5058'))
P.r(22, 3, 8, 6, hx('b8bcc0'))
P.r(24, 4, 2, 2, hx('2a2e34'))
P.r(4, 4, 10, 4, hx('e8e4d8'))
save(usb, 'usb')
print('ok')

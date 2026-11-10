"""手机微信那一套：老婆的自拍（第 1 天早上送孩子到校门口拍的）、头像。导出到 assets/phone/。"""
import math
import os
import sys
from PIL import Image
from faces import Pix, hx, sh, mix
from female import draw_female
from fcast import FEMALE

OUT = sys.argv[1] + '/phone'
os.makedirs(OUT, exist_ok=True)
WIFE = [c for c in FEMALE if c['name'] == '老婆'][0]
SMILE = dict(brows='flat', eyes='normal', mouth='smile')


def kid_head(P, x, y, grin=True):
    """孩子的头，16 宽：锅盖头、缺颗门牙在笑，脖子上系着红领巾。"""
    skin, hair = hx('ecc8a8'), hx('241c1a')
    rows = [6, 10, 12, 14, 14, 14, 14, 14, 14, 14, 13, 12, 10, 8]
    for i, w in enumerate(rows):
        P.r(x + 8 - w // 2, y + i, w, 1, skin)
    for i, w in enumerate([6, 10, 12, 14, 14, 14]):
        P.r(x + 8 - w // 2, y - 2 + i, w, 1, hair)
    P.r(x + 1, y + 4, 2, 4, hair)
    P.r(x + 13, y + 4, 2, 4, hair)
    for ex in (x + 4, x + 10):
        P.r(ex, y + 6, 2, 2, hx('2a2020'))
        P.p(ex, y + 6, hx('ffffff'))
    P.r(x + 3, y + 9, 2, 1, mix(skin, hx('e88078'), 0.4))
    P.r(x + 11, y + 9, 2, 1, mix(skin, hx('e88078'), 0.4))
    P.r(x + 5, y + 10, 6, 2, hx('8a3030'))
    P.r(x + 6, y + 10, 4, 1, hx('ffffff'))
    P.p(x + 7, y + 10, hx('6a2a2a'))    # 缺的那颗
    # 校服领 + 红领巾
    P.r(x + 1, y + 14, 14, 6, hx('3a6ab8'))
    P.r(x + 5, y + 14, 6, 2, hx('f0f0f0'))
    P.r(x + 6, y + 15, 4, 2, hx('d83a2a'))
    P.r(x + 7, y + 17, 2, 3, hx('c8302a'))


def selfie():
    """72×96 竖图：早上的校门口，老婆举着手机自拍，孩子从右下角挤进来比个耶。"""
    W, H = 72, 96
    img = Image.new('RGBA', (W, H))
    P = Pix(img)
    for y in range(H):
        P.r(0, y, W, 1, mix(hx('b8d8ec'), hx('e8eef0'), min(1, y / 40)))
    # 校门：红柱子、金色校牌、电动伸缩门
    P.r(0, 28, 10, 50, hx('a83a2a'))
    P.r(62, 28, 10, 50, hx('a83a2a'))
    P.r(0, 26, 72, 6, hx('8a2a20'))
    P.r(20, 18, 32, 9, hx('c89a3a'))
    P.r(21, 19, 30, 7, hx('e0b84a'))
    for i in range(5):
        P.r(24 + i * 6, 21, 4, 3, hx('8a2a20'))
    P.r(10, 60, 52, 18, hx('9aa0a4'))
    for x in range(10, 62, 4):
        P.r(x, 60, 1, 18, hx('6a7074'))
    # 地面
    P.r(0, 78, 72, 18, hx('b8b0a0'))
    # 老婆：近、偏左，画大一点（64 的头像放在照片里）
    face = Image.new('RGBA', (64, 64))
    draw_female(face, 0, 0, WIFE, SMILE, bg=(0, 0, 0, 0))
    img.alpha_composite(face, (-2, 34))
    # 自拍的手臂：从左下伸出画外
    for i in range(12):
        P.r(0, 84 - i // 2, 6 + i // 3, 1, hx('ecccb0'))
    # 孩子：右下，脸比老婆小，比个耶
    kid = Image.new('RGBA', (16, 22))
    kid_head(Pix(kid), 0, 2)
    img.alpha_composite(kid, (48, 66))
    P.r(64, 60, 2, 7, hx('ecc8a8'))
    P.r(67, 59, 2, 8, hx('ecc8a8'))
    P.r(63, 66, 7, 5, hx('ecc8a8'))
    # 早上的太阳在镜头里打的一块光
    for i in range(10):
        P.p(60 + i // 2, 6 + i, (255, 255, 240, 80))
    return img


def wife_avatar(size):
    face = Image.new('RGBA', (64, 64))
    draw_female(face, 0, 0, WIFE, SMILE, bg=hx('c8dce8'))
    box = {28: (18, 10, 46, 38), 24: (20, 13, 44, 37)}[size]
    return face.crop(box)


def kid_avatar(size):
    a = Image.new('RGBA', (size, size), hx('f0d878'))
    P = Pix(a)
    kid = Image.new('RGBA', (16, 22))
    kid_head(Pix(kid), 0, 2)
    a.alpha_composite(kid, ((size - 16) // 2, (size - 20) // 2 + (2 if size > 24 else 0)))
    return a


def lotus(size):
    """你爸的头像：一朵荷花，长辈的标配。"""
    a = Image.new('RGBA', (size, size), hx('5a8aa8'))
    P = Pix(a)
    k = size / 28
    for y in range(int(18 * k), size):
        P.r(0, y, size, 1, hx('4a7a98'))
    P.r(int(2 * k), int(19 * k), int(12 * k), int(4 * k), hx('3a7a4a'))
    P.r(int(15 * k), int(21 * k), int(11 * k), int(3 * k), hx('4a8a5a'))
    cx, cy = size // 2, int(12 * k)
    for (dx, dy, w, h) in ((-5, -2, 4, 8), (1, -2, 4, 8), (-2, -5, 4, 9), (-8, 1, 5, 5), (3, 1, 5, 5)):
        P.r(cx + int(dx * k), cy + int(dy * k), max(2, int(w * k)), max(2, int(h * k)), hx('f0a0b8'))
    P.r(cx - int(1 * k), cy - int(4 * k), max(1, int(2 * k)), max(3, int(8 * k)), hx('f8d0dc'))
    P.r(cx - 1, cy + int(5 * k), 2, int(6 * k), hx('3a6a3a'))
    return a


selfie().save(f'{OUT}/selfie_d1.png')
for s in (28, 24):
    wife_avatar(s).save(f'{OUT}/avatar_wife_{s}.png')
    kid_avatar(s).save(f'{OUT}/avatar_me_{s}.png')
    lotus(s).save(f'{OUT}/avatar_dad_{s}.png')
print('ok')

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


def kid_face(P, x, y):
    """孩子的脸，22 宽（比老婆的脸小一圈，跟她 64 的脸一个比例）：锅盖头、缺颗门牙在笑，校服 + 红领巾。"""
    skin, hair, dark = hx('ecc8a8'), hx('241c1a'), hx('2a2020')
    widths = [10, 14, 18, 20, 20, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 21, 20, 19, 17, 15, 13]
    for i, w in enumerate(widths):
        P.r(x + 11 - w // 2, y + i, w, 1, skin)
    P.r(x - 1, y + 10, 2, 3, sh(skin, 0.92))           # 耳朵
    P.r(x + 21, y + 10, 2, 3, sh(skin, 0.92))
    # 锅盖头：顶上一圈，齐刘海，两边盖到耳朵上面
    for i, w in enumerate([10, 16, 20, 22, 24, 24, 24]):
        P.r(x + 11 - w // 2, y - 2 + i, w, 1, hair)
    P.r(x + 1, y + 5, 20, 1, hair)
    P.r(x - 1, y + 5, 3, 5, hair)
    P.r(x + 20, y + 5, 3, 5, hair)
    P.r(x + 5, y - 1, 5, 1, hx('4a3a34'))              # 头发上的光
    # 眉、眼
    P.r(x + 4, y + 8, 3, 1, sh(hair, 1.4))
    P.r(x + 15, y + 8, 3, 1, sh(hair, 1.4))
    for ex in (x + 5, x + 15):
        P.r(ex, y + 10, 2, 2, dark)
        P.p(ex, y + 10, hx('ffffff'))
    P.r(x + 2, y + 13, 3, 1, mix(skin, hx('e88078'), 0.45))
    P.r(x + 17, y + 13, 3, 1, mix(skin, hx('e88078'), 0.45))
    P.p(x + 10, y + 13, sh(skin, 0.88))                # 鼻子
    # 咧嘴笑，缺一颗门牙
    P.r(x + 7, y + 15, 8, 2, hx('8a3030'))
    P.r(x + 8, y + 15, 6, 1, hx('ffffff'))
    P.p(x + 10, y + 15, hx('6a2a2a'))
    P.r(x + 9, y + 17, 4, 1, hx('c85a5a'))
    P.r(x + 8, y + 21, 6, 1, sh(skin, 0.85))           # 脖子
    # 校服 + 白领 + 红领巾
    for i in range(30):
        w = min(34, 18 + i * 3)
        P.r(x + 11 - w // 2, y + 22 + i, w, 1, hx('3a6ab8'))
    P.r(x + 4, y + 22, 5, 2, hx('f0f0f0'))
    P.r(x + 13, y + 22, 5, 2, hx('f0f0f0'))
    P.r(x + 9, y + 22, 4, 3, hx('d83a2a'))
    P.r(x + 10, y + 25, 2, 6, hx('c8302a'))


def selfie():
    """72×96 竖图：早上的校门口，老婆举着手机自拍，孩子凑过来脸贴脸、比个耶。两张脸一个比例。"""
    W, H = 72, 96
    img = Image.new('RGBA', (W, H))
    P = Pix(img)
    for y in range(H):
        P.r(0, y, W, 1, mix(hx('b8d8ec'), hx('e8eef0'), min(1, y / 40)))
    # 校门在后面：红柱子、金色校牌、电动伸缩门；远处一棵树
    P.r(0, 22, 9, 60, hx('a83a2a'))
    P.r(63, 22, 9, 60, hx('a83a2a'))
    P.r(0, 20, 72, 5, hx('8a2a20'))
    P.r(20, 9, 32, 9, hx('c89a3a'))
    P.r(21, 10, 30, 7, hx('e0b84a'))
    for i in range(5):
        P.r(24 + i * 6, 12, 4, 3, hx('8a2a20'))
    P.r(9, 46, 54, 16, hx('9aa0a4'))
    for x in range(9, 63, 4):
        P.r(x, 46, 1, 16, hx('6a7074'))
    P.r(9, 25, 54, 21, hx('d8e4e0'))                   # 门里的操场，曝光过了
    P.r(46, 28, 10, 10, hx('8aa88a'))
    P.r(50, 38, 2, 8, hx('6a5a4a'))
    P.r(0, 62, 72, 34, hx('b8b0a0'))
    # 老婆：近、偏左，自拍的距离；肩膀往右下斜（胳膊举着手机）
    face = Image.new('RGBA', (64, 64))
    draw_female(face, 0, 0, WIFE, SMILE, bg=(0, 0, 0, 0))
    img.alpha_composite(face, (-12, 22))
    P.r(0, 86, 44, 10, hx(WIFE['cloth']))            # 衣服接到照片底边
    # 举手机那只胳膊：从左下角伸出画外
    for i in range(22):
        P.r(0, 74 + i, 3 + i // 3, 1, sh(hx('8a9a7a'), 0.9))
    # 孩子：凑在她右边、低半个头，脸贴着她的头发
    kid_face(P, 38, 44)
    # 比耶的手：从他右肩举起来
    skin = hx('ecc8a8')
    P.r(63, 58, 5, 20, sh(hx('3a6ab8'), 0.9))
    P.r(62, 51, 6, 7, skin)
    P.r(62, 44, 2, 7, skin)
    P.r(66, 43, 2, 8, skin)
    P.r(64, 53, 2, 1, sh(skin, 0.85))
    # 早上的太阳在镜头里打的一块光
    for i in range(10):
        P.p(60 + i // 2, 2 + i, (255, 255, 240, 80))
    return img


def wife_avatar(size):
    face = Image.new('RGBA', (64, 64))
    draw_female(face, 0, 0, WIFE, SMILE, bg=hx('c8dce8'))
    # 往外多带一圈（整颗头进框），再按面积平均缩回 size：脸比直接裁小一号
    box = {28: (15, 10, 49, 44), 24: (17, 11, 47, 41)}[size]
    return face.crop(box).resize((size, size), Image.BOX)


STUDIO = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


def kid_avatar(size):
    """你的头像：儿子在影楼拍的艺术照。灰蓝布景、左上打光；三七分梳得整整齐齐，
    小西装马甲、白衬衫、红领结；抿着嘴笑（门牙还缺着，不张嘴），脸上打了腮红。"""
    a = Image.new('RGBA', (28, 28))
    P = Pix(a)
    # 布景：中间一团亮、四角暗，档与档之间抖一下
    lit, dim = hx('c4d4e2'), hx('46566e')
    for y in range(28):
        for x in range(28):
            v = min(1, (((x - 11) / 19) ** 2 + ((y - 8) / 21) ** 2) ** 0.5) * 5
            lo = int(v)
            f = v - lo
            if f >= 0.65 or (f > 0.35 and (f - 0.35) / 0.3 > (STUDIO[(y % 4) * 4 + x % 4] + 0.5) / 16):
                lo += 1
            P.p(x, y, mix(lit, dim, min(5, lo) / 5))
    skin, hair = hx('efcdb0'), hx('241c1a')
    shade = sh(skin, 0.88)
    shirt, tie = hx('f4f2ec'), hx('c8302a')
    # 马甲、衬衫领口、领结
    for i, w in enumerate([12, 16, 20, 22, 24, 24, 24]):
        P.r(14 - w // 2, 21 + i, w, 1, hx('2c3a5a'))
    P.r(11, 21, 6, 7, shirt)
    P.r(11, 21, 2, 1, sh(shirt, 0.85)); P.r(15, 21, 2, 1, sh(shirt, 0.85))
    P.r(14, 24, 1, 4, sh(shirt, 0.85))
    P.r(10, 21, 1, 3, tie); P.r(11, 22, 2, 1, tie); P.p(11, 21, tie); P.p(11, 23, tie)
    P.r(17, 21, 1, 3, tie); P.r(15, 22, 2, 1, tie); P.p(16, 21, tie); P.p(16, 23, tie)
    P.r(13, 22, 2, 1, sh(tie, 0.75))
    P.r(12, 19, 4, 2, shade)                                  # 脖子
    # 脸、耳朵
    for i, w in enumerate([8, 12, 14, 14, 14, 14, 14, 14, 13, 12, 10, 8]):
        P.r(14 - w // 2, 7 + i, w, 1, skin)
    P.r(6, 12, 1, 3, shade); P.r(21, 12, 1, 3, shade)
    # 头发：三七分，刘海往右扫，头顶一道弧光
    for i, (x0, x1) in enumerate([(10, 18), (8, 20), (7, 21), (6, 22)]):
        P.r(x0, 3 + i, x1 - x0, 1, hair)
    P.r(6, 7, 3, 5, hair); P.r(20, 7, 2, 4, hair)
    P.r(12, 7, 9, 1, hair)
    P.r(15, 8, 6, 1, hair)
    P.r(18, 9, 2, 1, hair)
    P.p(11, 5, sh(hair, 0.7)); P.p(11, 6, sh(hair, 0.7))
    P.r(9, 4, 3, 1, hx('6a544a')); P.p(8, 5, hx('6a544a'))
    P.r(13, 5, 4, 1, hx('4a3a34'))
    # 眉、眼（看镜头，眼睛里一点光）
    P.r(9, 10, 3, 1, sh(hair, 1.6)); P.r(16, 10, 3, 1, sh(hair, 1.6))
    for ex in (9, 16):
        P.r(ex, 12, 3, 2, hx('2a2020'))
        P.p(ex + 2, 12, hx('ffffff'))
    # 腮红、鼻子、抿着嘴笑；额头上顶光的一块亮
    P.r(8, 15, 2, 1, mix(skin, hx('e8707a'), 0.5)); P.r(18, 15, 2, 1, mix(skin, hx('e8707a'), 0.5))
    P.p(14, 14, shade)
    P.p(12, 16, hx('a85050')); P.r(13, 17, 3, 1, hx('a85050')); P.p(16, 16, hx('a85050'))
    P.r(10, 8, 3, 1, mix(skin, hx('ffffff'), 0.35))
    return a if size == 28 else a.crop((2, 2, 26, 26))


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

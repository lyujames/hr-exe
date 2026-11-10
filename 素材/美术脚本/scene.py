"""回家一屏的场景图：640×196，三个时间版本。"""
import random
from PIL import Image, ImageDraw
from faces import Pix, hx, sh, mix

W, H = 640, 196


def scene(variant):
    """variant: '1930' 一家人都在 / '2030' 孩子睡了 / '2230' 灯都关了"""
    lit = variant != '2230'
    img = Image.new('RGBA', (W, H))
    P = Pix(img)
    dark = variant == '2230'
    wall_a = hx('6a5644') if lit else hx('232831')
    wall_b = hx('3a3029') if lit else hx('1a1d24')
    if variant == '2030':
        wall_a = hx('5a4a3c')
    # 墙：灯下暖，往两边暗
    lamp_x = 300
    for x in range(W):
        t = min(1, abs(x - lamp_x) / 300)
        c = mix(wall_a, wall_b, t ** 0.8)
        P.r(x, 0, 1, 150, c)
    # 踢脚线 + 地板
    floor = hx('4a3a2e') if lit else hx('1c1c20')
    for y in range(150, H):
        P.r(0, y, W, 1, mix(floor, sh(floor, 0.7), (y - 150) / 46))
    P.r(0, 148, W, 3, sh(wall_b, 0.7))
    for y in (162, 178):
        P.r(0, y, W, 1, sh(floor, 0.8))
    for x in range(30, W, 90):
        P.r(x, 151, 1, 11, sh(floor, 0.8))
        P.r(x + 45, 163, 1, 15, sh(floor, 0.8))

    # 窗：夜里的楼，亮着的窗
    wx, wy, ww, wh = 28, 26, 116, 86
    P.r(wx - 3, wy - 3, ww + 6, wh + 6, hx('2a2724') if lit else hx('15171b'))
    for y in range(wh):
        P.r(wx, wy + y, ww, 1, mix(hx('1d2740'), hx('2e2a3e'), y / wh))
    rnd = random.Random(7)
    bx = wx
    while bx < wx + ww:
        bw = rnd.randint(14, 26)
        bh = rnd.randint(30, 70)
        P.r(bx, wy + wh - bh, bw, bh, hx('141a28'))
        for yy in range(wy + wh - bh + 4, wy + wh - 2, 5):
            for xx in range(bx + 2, bx + bw - 2, 4):
                on = rnd.random() < (0.45 if not dark else 0.12)
                if on:
                    P.r(xx, yy, 2, 2, hx('e8c870') if rnd.random() < 0.8 else hx('a8d0e8'))
        bx += bw + 1
    P.r(wx + ww // 2 - 1, wy, 2, wh, hx('2a2724') if lit else hx('15171b'))
    P.r(wx, wy + wh // 2, ww, 2, hx('2a2724') if lit else hx('15171b'))
    # 窗帘
    cur = hx('7a5a48') if lit else hx('2a2628')
    P.r(wx - 14, wy - 8, 12, wh + 22, cur)
    for k in range(0, 12, 4):
        P.r(wx - 14 + k, wy - 8, 1, wh + 22, sh(cur, 0.8))

    # 餐边柜 + 电饭煲（保温红灯）
    P.r(160, 112, 52, 38, hx('5e4a3a') if lit else hx('22201f'))
    P.r(160, 112, 52, 2, hx('7a6450') if lit else hx('2c2a28'))
    P.r(185, 118, 1, 30, sh(hx('5e4a3a'), 0.7) if lit else hx('1a1918'))
    P.r(168, 98, 22, 14, hx('dcdcd4') if lit else hx('3a3c3e'))
    P.r(170, 96, 18, 3, hx('c4c4bc') if lit else hx('34363a'))
    P.r(176, 104, 6, 3, hx('5a6a68') if lit else hx('22262a'))
    P.r(185, 106, 2, 2, hx('ff4a3a'))   # 保温灯
    if dark:
        for r in range(1, 5):
            for dx in range(-r, r + 2):
                P.p(185 + dx, 106 - r, mix(P.get(185 + dx, 106 - r), hx('ff4a3a'), 0.08))

    # 墙上：孩子画的“我的爸爸”（结局伏笔）+ 挂历
    P.r(222, 40, 34, 28, hx('e8e4d6') if lit else hx('3c3c3e'))
    if lit:
        fig = hx('3a6ac8')
        P.r(236, 46, 6, 6, fig)
        P.r(238, 52, 2, 9, fig)
        P.r(234, 54, 10, 1, fig)
        P.p(236, 62, fig); P.p(241, 62, fig)
        P.r(246, 48, 6, 10, hx('c8402f'))   # 爸爸手里的“简历”
        P.r(225, 64, 8, 2, hx('e8c84a'))
    P.r(222, 40, 34, 1, sh(hx('e8e4d6'), 0.8))
    P.r(238, 37, 2, 3, hx('c8402f'))       # 磁贴

    # 吊灯 + 光锥
    P.r(lamp_x, 0, 1, 50, hx('1e1a18'))
    shade = hx('d8b878') if lit else hx('2c2a28')
    for k in range(10):
        P.r(lamp_x - 8 - k, 50 + k, 17 + 2 * k, 1, shade if k < 9 else sh(shade, 0.8))
    if lit:
        P.r(lamp_x - 8, 60, 17, 2, hx('fff2c8'))
        cone = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        cd = ImageDraw.Draw(cone)
        strength = 48 if variant == '1930' else 30
        cd.polygon([(lamp_x - 16, 61), (lamp_x + 17, 61), (lamp_x + 120, 150), (lamp_x - 119, 150)], fill=(255, 226, 160, strength))
        cd.ellipse([lamp_x - 130, 138, lamp_x + 130, 168], fill=(255, 226, 160, strength))
        img.alpha_composite(cone)

    # 餐桌
    tx0, tx1, ty = 214, 388, 118
    top_c = hx('8a6a4c') if lit else hx('2a2622')
    P.r(tx0, ty, tx1 - tx0, 5, top_c)
    P.r(tx0, ty, tx1 - tx0, 1, mix(top_c, hx('ffffff'), 0.2))
    P.r(tx0 + 2, ty + 5, tx1 - tx0 - 4, 3, sh(top_c, 0.7))
    for lx in (tx0 + 6, tx1 - 10):
        P.r(lx, ty + 8, 4, 152 - ty, sh(top_c, 0.75))

    def chair(x, facing, color=hx('6a503c') if lit else hx('242120'), pushed_in=False):
        cy = 128 if not pushed_in else 128
        P.r(x, cy, 18, 3, color)
        P.r(x + (0 if facing > 0 else 15), cy - 26, 3, 26, color)
        P.r(x + 1, cy + 3, 2, 154 - cy - 3, sh(color, 0.8))
        P.r(x + 15, cy + 3, 2, 154 - cy - 3, sh(color, 0.8))

    def person(x, kind, pose='sit'):
        # 不给正脸：侧影 / 背影，只看见头发和一点侧脸
        if kind == 'wife':
            body, hair, skin = hx('9a8a6a'), hx('2a2220'), hx('d8b494')
            P.r(x, 96, 16, 32, body)            # 上身
            P.r(x + 2, 128, 22, 6, sh(body, 0.85))   # 腿
            P.r(x + 3, 80, 13, 16, hair)         # 头（背侧）
            P.r(x + 13, 85, 3, 7, skin)          # 侧脸一点
            P.r(x + 3, 92, 4, 8, hair)           # 低马尾
            P.r(x + 14, 104, 12, 3, skin)        # 手伸向桌面
        if kind == 'kid':
            body, hair, skin = hx('3a6ac8'), hx('1c1a1a'), hx('e6c4a4')
            P.r(x, 106, 13, 22, body)
            P.r(x + 1, 108, 11, 2, hx('e8e4d6'))   # 校服条
            P.r(x - 4, 128, 16, 5, hx('2a3040'))
            P.r(x, 92, 12, 13, hair)
            P.r(x, 97, 3, 6, skin)
            P.r(x - 10, 112, 11, 3, skin)          # 手在写作业
        if kind == 'wife_phone':
            body, hair, skin = hx('9a8a6a'), hx('2a2220'), hx('d8b494')
            P.r(x, 98, 16, 30, body)
            P.r(x + 2, 128, 22, 6, sh(body, 0.85))
            P.r(x + 4, 84, 13, 15, hair)          # 低着头
            P.r(x + 14, 91, 3, 6, skin)
            P.r(x + 3, 94, 4, 8, hair)
            P.r(x + 14, 112, 10, 3, skin)

    # 椅子：左妈妈，右孩子，中间你的（空）
    chair(240, 1)
    chair(350, -1)
    chair(292, 1, pushed_in=True)
    if variant == '1930':
        person(244, 'wife')
        person(356, 'kid')
    if variant == '2030':
        person(244, 'wife_phone')

    # 桌面上的东西
    def bowl(x, covered=False, steam=False):
        c = hx('e6e2d6') if lit else hx('3a3c3e')
        P.r(x, ty - 4, 10, 4, c)
        P.r(x + 1, ty - 1, 8, 1, sh(c, 0.85))
        if covered:
            P.r(x - 2, ty - 8, 14, 4, hx('c8c8c0') if lit else hx('34363a'))
            P.r(x + 3, ty - 9, 4, 1, hx('a8a8a0') if lit else hx('2c2e30'))
        if steam:
            for k, (dx, dy) in enumerate([(3, -7), (4, -10), (3, -13), (6, -9), (7, -12)]):
                P.p(x + dx, ty + dy, hx('e8e4dc', 255))

    if variant == '1930':
        bowl(258, steam=True)
        bowl(296, steam=True)           # 你的那碗，热的
        P.r(310, ty - 2, 10, 1, hx('3a2a1a'))   # 筷子
        bowl(340)
        P.r(316, ty - 3, 18, 3, hx('d06a3a'))  # 一盘菜
        P.r(318, ty - 4, 14, 1, hx('7aa04a'))
        P.r(362, ty - 2, 14, 2, hx('f2f0e8'))  # 听写本
        P.r(362, ty - 2, 7, 2, hx('e8e4d6'))
    if variant == '2030':
        bowl(296, covered=True)         # 你的那碗扣着盘子
        P.r(266, ty - 2, 10, 2, hx('1a1c1d'))  # 手机扣在桌上
        P.r(267, ty - 2, 8, 1, hx('3a3e40'))
    if variant == '2230':
        bowl(296, covered=True)
        P.r(312, ty - 3, 9, 3, hx('6a6030'))   # 便签（暗）
    # 孩子房门（右）
    dx0 = 452
    door = hx('7a6450') if lit else hx('26221f')
    P.r(dx0, 40, 44, 110, sh(door, 0.7))
    if variant == '1930':
        # 门开着一条缝，屋里灯亮
        P.r(dx0 + 2, 42, 40, 106, hx('f0d890'))
        P.r(dx0 + 2, 42, 30, 106, door)
        P.r(dx0 + 29, 92, 2, 4, hx('c8b080'))
    else:
        P.r(dx0 + 2, 42, 40, 106, door)
        P.r(dx0 + 34, 92, 4, 3, hx('c8b080') if lit else hx('3a3630'))
        # 门缝底下：关着的灯 = 一条黑
        P.r(dx0 + 2, 148, 40, 2, hx('0e0d0c'))
    for yy in (52, 98):
        P.r(dx0 + 6, yy, 32, 1, sh(door, 0.85))
        P.r(dx0 + 6, yy + 36, 32, 1, sh(door, 0.85))
    # 门上贴的课程表
    P.r(dx0 + 12, 60, 18, 12, hx('e8e4d6') if lit else hx('34342f'))

    # 玄关：鞋柜、拖鞋、地上的听写本
    P.r(530, 116, 70, 34, hx('6a5644') if lit else hx('201e1c'))
    P.r(530, 116, 70, 2, hx('86705a') if lit else hx('2a2826'))
    P.r(600, 20, 40, 130, hx('4a3c30') if lit else hx('18181a'))   # 入户门
    P.r(604, 80, 3, 8, hx('c8b080') if lit else hx('3a3630'))
    P.r(546, 154, 12, 4, hx('5a7ab0') if lit else hx('22262e'))     # 你的拖鞋
    P.r(560, 156, 12, 4, hx('5a7ab0') if lit else hx('22262e'))
    if variant in ('1930', '2030'):
        P.r(574, 152, 14, 9, hx('f2f0e8'))   # 摊开的英语听写本
        P.r(581, 152, 1, 9, hx('c8c4b8'))
        for k in range(3):
            P.r(576, 154 + k * 2, 4, 1, hx('3a6ac8'))
            P.r(583, 154 + k * 2, 3, 1, hx('c8402f') if k == 1 else hx('3a6ac8'))
    if dark:
        # 只有窗外和红灯：整体再压一层蓝
        ov = Image.new('RGBA', (W, H), (10, 14, 30, 70))
        img.alpha_composite(ov)
        P.r(185, 106, 2, 2, hx('ff4a3a'))
    return img

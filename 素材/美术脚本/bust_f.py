"""面试间半身像：何静，128×128，单独画，不是 64 放大。"""
from PIL import Image
from faces import Pix, hx, sh, mix

SKIN = hx('ecccb0')
SKIN_D = sh(SKIN, 0.87)
SKIN_DD = sh(SKIN, 0.74)
SKIN_O = sh(SKIN, 0.6)
HAIR = hx('2a201e')
HAIR_L = hx('4a3c36')
HAIR_D = hx('1c1716')
CARD = hx('9a6a6e')
CARD_D = sh(CARD, 0.78)
CARD_L = mix(CARD, hx('ffffff'), 0.15)
INNER = hx('e2ddd0')
INK = hx('1e1a18')


def bust(ex, size=128, bg_wall=True):
    img = Image.new('RGBA', (size, size), hx('4a5450'))
    P = Pix(img)
    # 背景：会议室墙 + 白板边 + 窗光
    for y in range(size):
        P.r(0, y, size, 1, mix(hx('56605c'), hx('3c4441'), y / size))
    P.r(86, 6, 42, 50, hx('6c7672'))
    P.r(88, 8, 40, 46, hx('8a9490'))
    for k in range(0, 40, 6):
        P.r(90 + k, 10 + k // 3, 3, 1, hx('a4aeaa'))
    # 椅背
    P.r(30, 70, 68, 40, hx('2a2f2d'))
    P.r(32, 72, 64, 2, hx('3a403d'))

    from female import rows_for
    cx, top = 62, 16
    rows = rows_for(cx, top, 2.1)
    hw = rows[top + 20][1] - cx + 1
    H = len(rows)
    chin = top + H
    eye_y = top + 32

    # 后层头发（右边垂到下巴）
    import math
    def dome(y, r_add=0):
        cy0, r = top + 24, hw + 4 + r_add
        d2 = r * r - (y - cy0) ** 2
        if d2 <= 0:
            return None
        h = int(math.sqrt(d2))
        return cx - h, cx + h - 1
    for y in range(top - 8, chin - 6):
        ab = dome(y)
        if ab is None:
            continue
        a, b = ab
        if y > top + 24:
            a, b = rows.get(y, (a, b))[0] - 4, rows.get(y, (a, b))[1] + 4
        P.r(a, y, b - a + 1, 1, HAIR)
    for y in range(top + 20, chin - 2):
        P.r(rows.get(y, (0, cx + hw))[1] - 4, y, 9, 1, HAIR)
    # 脖子
    P.r(cx - 7, chin - 10, 14, 20, SKIN_D)
    P.r(cx - 7, chin, 14, 2, mix(SKIN_D, SKIN_DD, 0.5))
    P.r(cx + 3, chin + 2, 4, 8, SKIN_DD)
    # 肩 / 开衫
    sy = chin + 6
    for y in range(sy, size):
        t = y - sy
        w = min(58, 20 + int(t * 3.0))
        P.r(cx - w, y, 2 * w, 1, CARD)
        P.r(cx + w - 8, y, 7, 1, CARD_D)
        P.p(cx - w, y, CARD_D)
        # 针织纹
        if y % 3 == 0:
            for x in range(cx - w + 2, cx + w - 2, 4):
                P.p(x, y, CARD_L)
        iw = 9 + t // 2
        P.r(cx - iw, y, 2 * iw, 1, INNER)
        P.p(cx - iw - 1, y, CARD_D)
        P.p(cx + iw, y, CARD_D)
    # 内搭圆领
    for x in range(cx - 9, cx + 9):
        d = abs(x - cx)
        P.p(x, sy + 3 - d // 4, sh(INNER, 0.85))
    for k in range(3):
        P.r(cx - 9 - 3 - k * 2, sy + 8 + k * 7, 2, 2, hx('e9e4d4'))
    # 工牌挂绳（访客证）
    # 桌沿和手
    P.r(0, 112, size, 16, hx('5e4c3c'))
    P.r(0, 112, size, 1, hx('8a7058'))
    P.r(0, 113, size, 1, hx('76604c'))
    # 扣着的手机
    P.r(78, 108, 22, 7, hx('1a1c1d'))
    P.r(79, 108, 20, 1, hx('3a3e40'))
    # 双手交握
    for (x, y, w, h) in [(44, 104, 26, 9), (46, 102, 22, 3)]:
        P.r(x, y, w, h, SKIN)
    P.r(44, 112, 26, 1, SKIN_DD)
    for k in range(4):
        P.r(48 + k * 5, 104, 1, 6, SKIN_D)
    P.r(66, 101, 6, 3, SKIN_D)
    P.r(30, 106, 16, 7, CARD)
    P.r(68, 106, 14, 7, CARD_D)

    # 耳朵（左边别在耳后，露出来，戴小耳钉）
    P.r(cx - hw - 4, eye_y - 2, 5, 14, SKIN_D)
    P.r(cx - hw - 3, eye_y, 2, 8, SKIN_DD)
    P.p(cx - hw - 3, eye_y + 12, hx('e8c84a'))

    # 脸
    for y, (a, b) in rows.items():
        P.r(a, y, b - a + 1, 1, SKIN)
        P.p(a, y, SKIN_O)
        P.p(b, y, SKIN_O)
        if y > top + 16:
            P.r(b - 4, y, 4, 1, SKIN_D)
        pass
    a, b = rows[top + H - 1]
    P.r(a, top + H - 1, b - a + 1, 1, SKIN_D)
    P.r(cx - 3, chin - 4, 4, 1, mix(SKIN, hx('fff6ee'), 0.4))

    look = ex.get('eyes', 'normal')
    brows = ex.get('brows', 'flat')
    mouth = ex.get('mouth', 'flat')

    # 眼袋、法令纹（35 岁，带两个孩子）
    if ex.get('tired'):
        for ex0 in (cx - 18, cx + 6):
            P.r(ex0 + 2, eye_y + 7, 8, 1, mix(SKIN, hx('7a6a8a'), 0.3))
    bl = mix(SKIN, hx('e88078'), 0.28)
    P.r(cx - 20, eye_y + 9, 7, 2, bl)
    P.r(cx + 13, eye_y + 9, 7, 2, bl)

    # 眼睛
    for i, ex0 in enumerate((cx - 18, cx + 6)):
        P.r(ex0 + 2, eye_y - 4, 8, 1, SKIN_DD)   # 双眼皮褶
        if look == 'closed':
            P.r(ex0, eye_y + 2, 11, 1, INK)
            continue
        lid = 0
        if look == 'down':
            lid = 2
        if look == 'wide':
            lid = -1
        # 眼白
        P.r(ex0 + 1, eye_y + lid, 10, 5 - lid, hx('f2f0ea'))
        # 虹膜
        shift = {'side_l': -2, 'side_r': 2}.get(look, 0)
        iy = eye_y + (1 if look == 'down' else 0)
        ix = ex0 + 3 + shift
        P.r(ix, max(iy, eye_y + lid), 6, 5 - max(0, lid), hx('5a3a2a'))
        P.r(ix + 1, max(iy, eye_y + lid), 4, 1, hx('3a2620'))
        P.r(ix + 2, max(iy + 1, eye_y + lid), 2, 3, hx('16100e'))
        if look != 'down':
            P.r(ix + 1, iy + 1, 2, 1, hx('fbfaf4'))
            P.p(ix + 4, iy + 3, hx('a07a60'))
        # 上眼睑（粗）
        P.r(ex0, eye_y + lid - 1, 12, 2, INK)
        wx = ex0 + 12 if i else ex0 - 1
        P.r(wx - (0 if i else 1), eye_y + lid - 2, 2, 1, INK)
        P.p(wx + (2 if i else -2), eye_y + lid - 3, INK)
        # 下眼睑 + 一点下睫毛
        P.r(ex0 + 2, eye_y + 5, 8, 1, mix(SKIN, SKIN_O, 0.4))
        P.p(ex0 + (10 if i else 1), eye_y + 4, INK)
    # 眉
    for i, bx in enumerate((cx - 18, cx + 6)):
        for k in range(12):
            inner = (k >= 8) if i == 0 else (k <= 3)
            outer = (k <= 2) if i == 0 else (k >= 9)
            dy = 0
            if brows == 'worried':
                dy = -2 if inner else (1 if outer else 0)
            if brows == 'angry':
                dy = 2 if inner else 0
            if brows == 'raised':
                dy = -2
            arch = -1 if 3 < k < 9 else 0
            th = 2 if 4 < k < 9 else 1
            P.r(bx + k, eye_y - 9 + dy + arch, 1, th, mix(HAIR, SKIN, 0.2))
    # 鼻
    for y in range(eye_y + 6, eye_y + 12):
        P.p(cx + 2, y, SKIN_D)
    P.p(cx - 1, eye_y + 6, mix(SKIN, hx('fff6ee'), 0.4))
    P.r(cx - 2, eye_y + 12, 5, 1, SKIN_D)
    P.p(cx - 2, eye_y + 13, SKIN_DD)
    P.p(cx + 3, eye_y + 13, SKIN_DD)
    # 嘴
    my = eye_y + 19
    LIP = hx('b0505a')
    LIP_L = hx('d88080')
    if mouth == 'open':
        P.r(cx - 3, my - 1, 7, 4, hx('5a2a2e'))
        P.r(cx - 2, my - 1, 5, 1, hx('f0e8e0'))
        P.r(cx - 2, my + 3, 5, 1, LIP_L)
    else:
        P.r(cx - 4, my, 9, 1, LIP)
        P.r(cx - 3, my + 1, 7, 2, LIP_L)
        P.p(cx - 1, my + 1, mix(LIP_L, hx('ffffff'), 0.3))
        P.r(cx - 2, my - 1, 2, 1, mix(SKIN, LIP, 0.6))
        P.r(cx + 1, my - 1, 2, 1, mix(SKIN, LIP, 0.6))
        if mouth == 'smile':
            P.p(cx - 5, my - 1, LIP)
            P.p(cx + 5, my - 1, LIP)
        if mouth == 'forced':
            P.p(cx + 5, my - 1, LIP)
            P.p(cx + 6, my - 2, LIP)
            P.p(cx - 5, my + 1, SKIN_D)
        if mouth == 'tight':
            P.r(cx - 4, my + 1, 9, 1, sh(LIP, 0.85))
            P.r(cx - 4, my + 2, 9, 1, SKIN)
    if ex.get('blush'):
        bl = mix(SKIN, hx('d0605a'), 0.25)
        P.r(cx - 20, eye_y + 10, 6, 2, bl)
        P.r(cx + 12, eye_y + 10, 6, 2, bl)

    # 前层头发：右侧垂下，左侧别到耳后
    T = top
    for y in range(T - 8, T + 9):
        ab = dome(y, -1)
        if ab is None:
            continue
        a, b = ab
        if y in rows:
            a, b = min(a, rows[y][0] - 2), max(b, rows[y][1] + 2)
        P.r(a, y, b - a + 1, 1, HAIR)
    # 侧分：额前一缕斜扫，发尾弯一下
    for k in range(14):
        P.r(cx - 14 + k + (k * k) // 30, T + 8 + k // 2, 32 - k - (k * k) // 14, 1, HAIR)
    for k in range(10):
        P.p(cx - 13 + k * 2, T + 4 + k // 2, HAIR_D)
    for y in range(T + 6, T + 22):
        a, b = rows[y]
        P.r(a - 2, y, 4, 1, HAIR)
    for y in range(T + 8, chin - 4):
        a, b = rows.get(y, (cx - hw, cx + hw))
        P.r(b - 3, y, 7, 1, HAIR)
    # 发丝高光与暗线
    for x in range(cx - 20, cx + 18):
        ab = dome(T - 5 + abs(x - cx) // 6, -1)
        P.p(x, T - 3 + (abs(x - cx) ** 2) // 60, HAIR_L)
    for y in range(T + 10, chin - 6, 3):
        P.p(rows.get(y, (0, cx + hw))[1] + 1, y, HAIR_D)
        P.p(rows.get(y, (0, cx + hw))[1] - 1, y + 1, HAIR_L)
    # 几根白头发
    for (dx, dy) in [(-8, -3), (3, -2), (11, 1), (20, 12), (22, 24)]:
        P.p(cx + dx, T + dy, hx('bab6ae'))

    if ex.get('sweat'):
        blue, hi = hx('8fc8e8'), hx('ffffff')
        x, y = cx + 15, T + 14
        P.p(x + 1, y, blue)
        P.r(x, y + 1, 3, 3, blue)
        P.r(x - 1, y + 2, 5, 2, blue)
        P.p(x, y + 2, hi)
        P.r(cx - 22, T + 22, 2, 3, blue)
    return img

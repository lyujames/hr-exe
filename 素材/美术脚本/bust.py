"""面试间半身像：何静，128×128，单独画，不是 64 放大。"""
from PIL import Image
from faces import Pix, hx, sh, mix

SKIN = hx('dcb898')
SKIN_D = sh(SKIN, 0.87)
SKIN_DD = sh(SKIN, 0.74)
SKIN_O = sh(SKIN, 0.6)
HAIR = hx('2c2422')
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

    cx, top, hw, H = 62, 14, 26, 64
    rows = {}
    for i in range(H):
        w = hw
        if i < 10:
            w = hw - round(((10 - i) / 10) ** 2 * 10)
        k = i - (H - 22)
        if k > 0:
            w = hw - round((k / 22) ** 1.5 * 12)
        rows[top + i] = (cx - w, cx + w - 1)
    chin = top + H
    eye_y = top + 31

    # 后层头发（右边垂到下巴）
    for y in range(top - 4, chin - 6):
        a, b = rows.get(y, (cx - hw + 8, cx + hw - 8))
        P.r(a - 4, y, b - a + 9, 1, HAIR)
    for y in range(top + 20, chin - 2):
        P.r(rows.get(y, (0, cx + hw))[1] - 4, y, 9, 1, HAIR)
    # 脖子
    P.r(cx - 9, chin - 10, 18, 22, SKIN_D)
    P.r(cx - 9, chin - 1, 18, 4, SKIN_DD)
    P.r(cx + 4, chin, 5, 12, SKIN_DD)
    # 肩 / 开衫
    sy = chin + 8
    for y in range(sy, size):
        t = y - sy
        w = min(60, 22 + int(t * 3.2))
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
        if eye_y + 9 < y < eye_y + 19 and y % 2 == 0:
            # 颧骨下阴影（很淡）
            P.p(a + 2 + (y - eye_y - 8) // 3, y, mix(SKIN, SKIN_D, 0.5))
    a, b = rows[top + H - 1]
    P.r(a, top + H - 1, b - a + 1, 1, SKIN_O)

    look = ex.get('eyes', 'normal')
    brows = ex.get('brows', 'flat')
    mouth = ex.get('mouth', 'flat')

    # 眼袋、法令纹（35 岁，带两个孩子）
    bag = mix(SKIN, hx('6a5a7a'), 0.22 if not ex.get('tired') else 0.36)
    for ex0 in (cx - 17, cx + 6):
        P.r(ex0 + 2, eye_y + 6, 7, 1, bag)
        if ex.get('tired'):
            P.r(ex0 + 3, eye_y + 7, 5, 1, mix(SKIN, hx('6a5a7a'), 0.18))
    for k in range(3):
        P.p(cx - 8 - k // 2, eye_y + 17 + k, mix(SKIN, SKIN_D, 0.6))
        P.p(cx + 9 + k // 2, eye_y + 17 + k, mix(SKIN, SKIN_D, 0.6))

    # 眼睛
    for i, ex0 in enumerate((cx - 17, cx + 6)):
        P.r(ex0 + 2, eye_y - 3, 7, 1, SKIN_D)   # 双眼皮褶
        if look == 'closed':
            P.r(ex0, eye_y + 2, 11, 1, INK)
            continue
        lid = 0
        if look == 'down':
            lid = 2
        if look == 'wide':
            lid = -1
        # 眼白
        P.r(ex0 + 1, eye_y + lid, 9, 4 - lid, hx('ece9e2'))
        # 虹膜
        shift = {'side_l': -2, 'side_r': 2}.get(look, 0)
        iy = eye_y + (1 if look == 'down' else 0)
        ix = ex0 + 3 + shift
        P.r(ix, max(iy, eye_y + lid), 5, 4 - max(0, lid - 0), hx('4a3428'))
        P.r(ix + 1, max(iy + 1, eye_y + lid), 3, 2, hx('16100e'))
        if look != 'down':
            P.p(ix + 1, iy, hx('fbfaf4'))
        # 上眼睑（粗）
        P.r(ex0, eye_y + lid - 1, 11, 2, INK)
        P.p(ex0 + (10 if i else 0) + (1 if i else -1), eye_y + lid - 2, INK)
        # 下眼睑
        P.r(ex0 + 2, eye_y + 4, 7, 1, SKIN_DD)
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
            th = 2 if 2 < k < 10 else 1
            P.r(bx + k, eye_y - 8 + dy, 1, th, HAIR)
    # 鼻
    for y in range(eye_y + 4, eye_y + 14):
        P.p(cx + 2, y, SKIN_D)
    P.r(cx - 3, eye_y + 14, 8, 1, SKIN_D)
    P.p(cx - 3, eye_y + 15, SKIN_O)
    P.p(cx + 4, eye_y + 15, SKIN_O)
    P.r(cx - 2, eye_y + 16, 6, 1, SKIN_DD)
    # 嘴
    my = eye_y + 22
    LIP = hx('8a4a48')
    LIP_L = hx('b8706a')
    if mouth == 'open':
        P.r(cx - 5, my - 1, 11, 5, hx('3a1c1c'))
        P.r(cx - 4, my - 1, 9, 1, hx('e8e2d8'))
        P.r(cx - 3, my + 4, 7, 1, LIP_L)
    else:
        P.r(cx - 6, my, 13, 1, LIP)
        P.r(cx - 4, my + 1, 9, 2, LIP_L)
        P.r(cx - 3, my - 1, 7, 1, mix(SKIN, LIP, 0.5))
        if mouth == 'smile':
            P.p(cx - 7, my - 1, LIP)
            P.p(cx + 7, my - 1, LIP)
            P.p(cx - 8, my - 2, SKIN_D)
            P.p(cx + 8, my - 2, SKIN_D)
        if mouth == 'forced':
            P.p(cx + 7, my - 1, LIP)
            P.p(cx + 8, my - 2, LIP)
            P.p(cx - 7, my + 1, SKIN_D)
        if mouth == 'tight':
            P.r(cx - 4, my + 1, 9, 1, sh(LIP, 0.85))
            P.r(cx - 4, my + 2, 9, 1, SKIN)
    if ex.get('blush'):
        bl = mix(SKIN, hx('d0605a'), 0.25)
        P.r(cx - 20, eye_y + 10, 6, 2, bl)
        P.r(cx + 12, eye_y + 10, 6, 2, bl)

    # 前层头发：右侧垂下，左侧别到耳后
    T = top
    for y in range(T - 4, T + 8):
        a, b = rows.get(y, (cx - hw + 10, cx + hw - 10))
        P.r(a - 2, y, b - a + 5, 1, HAIR)
    # 侧分：额前一缕斜扫
    for k in range(18):
        P.r(cx - 6 + k, T + 8 + k // 3, 22 - k, 1, HAIR) if k < 14 else None
    for y in range(T + 6, T + 22):
        a, b = rows[y]
        P.r(a - 2, y, 4, 1, HAIR)
    for y in range(T + 8, chin - 4):
        a, b = rows.get(y, (cx - hw, cx + hw))
        P.r(b - 3, y, 7, 1, HAIR)
    # 发丝高光与暗线
    for k in range(14):
        P.p(cx - 14 + k, T - 2 + (k // 5), HAIR_L)
        P.p(cx + 4 + k, T + (k // 4), HAIR_L)
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

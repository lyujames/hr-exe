"""像素头像：64×64（S=1）和面试半身像（S=2，细节仍是 1px）。"""
from PIL import Image, ImageDraw


def hx(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def sh(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + (255,)


def mix(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3)) + (255,)


class Pix:
    def __init__(self, img):
        self.img = img
        self.d = ImageDraw.Draw(img)
        self.w, self.h = img.size

    def p(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((int(x), int(y)), c)

    def r(self, x, y, w, h, c):
        if w <= 0 or h <= 0:
            return
        self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)

    def get(self, x, y):
        return self.img.getpixel((int(x), int(y)))


INK = hx('1e2220')
WHITE_EYE = hx('eef0ec')


def head_rows(cx, top, hw, H, jaw, S):
    rows = {}
    cap = [4 * S, 2 * S, 1 * S, S // 2] if S > 1 else [4, 2, 1, 0]
    capn = 4 * S
    for i in range(H):
        if i < capn:
            # 圆顶
            t = 1 - (i / capn)
            w = hw - round((t ** 2) * 4.5 * S)
        else:
            w = hw
        k = i - (H - 9 * S)
        if k > 0:
            w = hw - round((k / (9 * S)) ** 1.6 * jaw * S)
        if i == H - 1:
            w -= S
        rows[top + i] = (cx - w, cx + w - 1)
    return rows


def draw_face(img, ox, oy, spec, ex, S=1, size=None, bg=None):
    """img: 整张画布；(ox,oy) 头像左上角。size 默认 64*S。"""
    size = size or 64 * S
    sub = Image.new('RGBA', (size, size), bg or hx(spec.get('bg', '5a6763')))
    P = Pix(sub)
    u = lambda v: int(round(v * S))
    skin = hx(spec['skin'])
    skin_d = sh(skin, 0.86)
    skin_o = sh(skin, 0.62)
    hair = hx(spec['hair'])
    hair_l = mix(hair, hx('ffffff'), 0.18)
    hair_d = sh(hair, 0.7)
    cx = size // 2 + (spec.get('cx_off', 0) * S)
    top = u(spec.get('top', 13)) + (oy_shift := 0)
    if S > 1:
        top = u(spec.get('top', 13)) - 4
    hw = u(spec.get('hw', 12.5))
    H = u(spec.get('H', 29))
    jaw = spec.get('jaw', 4)
    rows = head_rows(cx, top, hw, H, jaw, S)
    chin = top + H

    # 背景淡渐变（证件照背景）
    for y in range(size):
        if y % (2 * S) == 0 and y > size * 0.55:
            pass

    hairstyle = spec['hair_style']
    # —— 后层头发 ——
    if hairstyle == 'bob':
        P.r(cx - hw - u(3), top - u(2), 2 * hw + u(6), u(30), hair)
        P.r(cx - hw - u(2), top + u(28), u(5), u(3), hair_d)
        P.r(cx + hw - u(3), top + u(28), u(5), u(3), hair_d)
    if hairstyle == 'ponytail':
        # 低马尾在右肩后露一截
        P.r(cx + hw - u(2), top + u(16), u(5), u(20), hair_d)
        P.r(cx + hw - u(1), top + u(30), u(4), u(8), hair_d)
    if hairstyle == 'tucked':
        P.r(cx - hw - u(2), top + u(2), 2 * hw + u(4), u(24), hair)
    if hairstyle == 'tied':
        P.r(cx + hw - u(1), top + u(6), u(3), u(6), hair_d)

    # —— 衣服 ——
    cloth = hx(spec['cloth'])
    cloth_d = sh(cloth, 0.78)
    cloth_l = mix(cloth, hx('ffffff'), 0.14)
    sy = chin + u(3)
    neck_w = u(5)
    # 脖子
    P.r(cx - neck_w, chin - u(6), 2 * neck_w, u(12), skin_d)
    P.r(cx - neck_w, chin - u(1), 2 * neck_w, u(2), sh(skin, 0.74))
    # 肩
    for y in range(sy, size):
        t = y - sy
        w = min(u(27), u(13) + int(t * 2.6))
        P.r(cx - w, y, 2 * w, 1, cloth)
        P.p(cx - w, y, cloth_d)
        P.p(cx + w - 1, y, cloth_d)
    # 右侧暗面
    for y in range(sy + u(2), size):
        t = y - sy
        w = min(u(27), u(13) + int(t * 2.6))
        P.r(cx + w - u(5), y, u(4), 1, cloth_d)
    cs = spec['cloth_style']
    if cs in ('shirt', 'logo_shirt', 'polo'):
        col = hx(spec.get('collar', 'e4e6e0'))
        for i in range(u(5)):
            P.r(cx - neck_w - u(2) + i, sy - u(1) + i, u(2), 1, col)
            P.r(cx + neck_w - i, sy - u(1) + i, u(2), 1, col)
        P.r(cx - 1, sy + u(4), 2, size, sh(cloth, 0.85))
        if cs == 'polo':
            P.p(cx, sy + u(6), hx('d0d0c8'))
            P.p(cx, sy + u(9), hx('d0d0c8'))
        if cs == 'logo_shirt':
            # 胸口刺绣小马标：一眼看出贵
            lx, ly = cx + u(8), sy + u(7)
            for (dx, dy, c) in [(0, 0, 'b33a3a'), (1, 0, 'b33a3a'), (2, 1, '2f5d9a'), (1, 1, 'b33a3a'), (0, 2, '2f5d9a')]:
                P.p(lx + dx, ly + dy, hx(c))
            # 第二颗扣子金色
            P.p(cx, sy + u(9), hx('e8c84a'))
    if cs == 'hoodie':
        hood = cloth_d
        P.r(cx - neck_w - u(5), sy - u(2), u(5), u(5), hood)
        P.r(cx + neck_w, sy - u(2), u(5), u(5), hood)
        P.r(cx - u(3), sy + u(4), 1, u(8), hx('e4e6e0'))
        P.r(cx + u(3), sy + u(4), 1, u(9), hx('e4e6e0'))
    if cs == 'check':
        lines = sh(cloth, 0.72)
        for y in range(sy, size):
            t = y - sy
            w = min(u(27), u(13) + int(t * 2.6))
            for x in range(cx - w + 1, cx + w - 1):
                if (x - cx) % u(4) == 0 or (y - sy) % u(4) == 0:
                    P.p(x, y, lines)
        col = hx('cfd4e0')
        for i in range(u(4)):
            P.r(cx - neck_w - u(1) + i, sy - u(1) + i, u(2), 1, col)
            P.r(cx + neck_w - u(1) - i, sy - u(1) + i, u(2), 1, col)
    if cs == 'turtle':
        P.r(cx - neck_w - u(1), chin - u(1), 2 * neck_w + u(2), u(5), cloth)
        P.r(cx - neck_w - u(1), chin + u(1), 2 * neck_w + u(2), 1, cloth_d)
        P.r(cx - neck_w - u(1), chin + u(3), 2 * neck_w + u(2), 1, cloth_d)
    if cs == 'cardigan':
        inner = hx(spec.get('inner', 'd8d4c8'))
        for y in range(sy, size):
            t = y - sy
            iw = u(5) + t // 3
            P.r(cx - iw, y, 2 * iw, 1, inner)
            P.p(cx - iw - 1, y, cloth_d)
            P.p(cx + iw, y, cloth_d)
        for k in range(3):
            P.p(cx - u(7) - 1, sy + u(5) + k * u(4), hx('e9e4d4'))
    if cs == 'suit':
        shirt = hx('dfe2dc')
        for y in range(sy, size):
            t = y - sy
            iw = u(4) + t // 2
            P.r(cx - iw, y, 2 * iw, 1, shirt)
            P.p(cx - iw - 1, y, sh(cloth, 0.6))
            P.p(cx + iw, y, sh(cloth, 0.6))
        tie = hx(spec.get('tie', '7a2e2e'))
        P.r(cx - u(1), sy, u(2) + (1 if S == 1 else 0), u(2), tie)
        for y in range(sy + u(2), size):
            P.r(cx - u(1) - (1 if (y - sy) > u(5) else 0), y, u(2) + (2 if (y - sy) > u(5) else 0) - (0 if S == 1 else 0), 1, tie)
    if cs == 'vest':
        # 毛衣背心套衬衫：老周
        shirt = hx('d3d6cf')
        for i in range(u(4)):
            P.r(cx - neck_w - u(1) + i, sy - u(1) + i, u(2), 1, shirt)
            P.r(cx + neck_w - u(1) - i, sy - u(1) + i, u(2), 1, shirt)
        for y in range(sy, sy + u(9)):
            t = y - sy
            iw = max(1, u(5) - t // 2)
            P.r(cx - iw, y, 2 * iw, 1, shirt)
        for y in range(sy + u(2), size, 2):
            P.r(cx - u(10), y, u(20), 1, cloth_l)
        # 衬衫袖露出
        for y in range(sy + u(4), size):
            t = y - sy
            w = min(u(27), u(13) + int(t * 2.6))
            P.r(cx - w, y, u(4), 1, shirt)
            P.r(cx + w - u(4), y, u(4), 1, sh(shirt, 0.86))
    if spec.get('lanyard'):
        lc = hx(spec['lanyard'])
        for i in range(u(10)):
            P.p(cx - neck_w - u(1) + i // 2, sy + i, lc)
            P.p(cx + neck_w + u(1) - i // 2 - 1, sy + i, lc)
        P.r(cx - u(3), sy + u(10), u(6), u(8), hx('e9ecea'))
        P.r(cx - u(2), sy + u(12), u(4), u(2), hx('4f7f68'))

    # —— 耳朵 ——
    ey = top + int(H * 0.47)
    for side in (-1, 1):
        x0 = cx - hw - u(2) if side < 0 else cx + hw
        P.r(x0, ey - u(1), u(2), u(6), skin_d)
        P.p(x0 + (0 if side < 0 else u(2) - 1), ey + u(1), skin_o)
    # —— 头 ——
    for y, (x0, x1) in rows.items():
        P.r(x0, y, x1 - x0 + 1, 1, skin)
        P.p(x0, y, skin_o)
        P.p(x1, y, skin_o)
        # 右脸暗面
        if y > top + u(10):
            P.r(x1 - u(2), y, u(2), 1, skin_d)
    # 下巴轮廓
    lastx0, lastx1 = rows[top + H - 1]
    P.r(lastx0, top + H - 1, lastx1 - lastx0 + 1, 1, skin_o)
    # 下巴下阴影
    P.r(cx - neck_w, chin, 2 * neck_w, u(2), sh(skin, 0.7))

    # —— 年龄、胡茬、黑眼圈 ——
    eye_y = ey
    lx, rx = cx - u(7), cx + u(4)
    ew = u(3)
    if spec.get('stubble'):
        st = sh(skin, 0.78)
        for y in range(eye_y + u(9), chin - 1):
            x0, x1 = rows.get(y, (cx, cx))
            for x in range(x0 + 2, x1 - 1):
                if (x * 7 + y * 3) % 4 == 0 and not (abs(x - cx) < u(3) and y < eye_y + u(12)):
                    P.p(x, y, st)
    if spec.get('lines'):
        lc = sh(skin, 0.8)
        P.p(cx - u(4), eye_y + u(8), lc)
        P.p(cx - u(5), eye_y + u(9), lc)
        P.p(cx + u(4), eye_y + u(8), lc)
        P.p(cx + u(5), eye_y + u(9), lc)
        P.r(cx - u(3), top + u(7), u(6), 1, sh(skin, 0.9))
    if spec.get('bags') or ex.get('tired'):
        bc = mix(skin, hx('6a5a7a'), 0.25)
        P.r(lx, eye_y + u(3), ew + 1, 1, bc)
        P.r(rx, eye_y + u(3), ew + 1, 1, bc)
    if spec.get('blush') or ex.get('blush'):
        bc = mix(skin, hx('d0605a'), 0.28)
        P.r(lx - u(2), eye_y + u(5), u(3), 1, bc)
        P.r(rx + u(2), eye_y + u(5), u(3), 1, bc)

    # —— 眼睛 ——
    look = ex.get('eyes', 'normal')
    for i, ex0 in enumerate((lx, rx)):
        lash = INK
        if look == 'closed':
            P.r(ex0, eye_y + u(1), ew + 1, 1, lash)
            continue
        if look == 'down':
            P.r(ex0, eye_y + u(1), ew + 1, 1, lash)
            P.r(ex0 + (1 if S == 1 else u(1)), eye_y + u(2), ew - (0 if S == 1 else 1), 1, INK)
            continue
        h = u(2) + (1 if look == 'wide' else 0)
        P.r(ex0, eye_y + 1 - (1 if look == 'wide' else 0), ew + 1, h, WHITE_EYE)
        P.r(ex0 - (1 if spec.get('female') and i == 0 else 0), eye_y - (1 if look == 'wide' else 0), ew + 1 + (1 if spec.get('female') else 0), 1, lash)
        if spec.get('female') and i == 1:
            P.p(ex0 + ew + 1, eye_y - (1 if look == 'wide' else 0), lash)
        shift = {'left': 0, 'right': ew - u(2) + 1, 'side_l': 0, 'side_r': ew - u(2) + 1}.get(look, (ew + 1 - u(2)) // 2)
        P.r(ex0 + shift, eye_y + 1, u(2), h, hx(spec.get('iris', '2a2420')))
        if S > 1:
            P.p(ex0 + shift, eye_y + 1, hx('f6f6f0'))
            P.r(ex0, eye_y + 1 + h, ew + 1, 1, sh(skin, 0.8))
    # —— 眉 ——
    brow = ex.get('brows', 'flat')
    bc = sh(hair, 0.9) if spec['hair'] != '8a8d8a' else hx('5a5650')
    for side, bx in ((-1, lx), (1, rx)):
        by = eye_y - u(3)
        for k in range(ew + 2):
            x = bx - 1 + k
            inner = (k >= ew) if side < 0 else (k <= 1)
            outer = (k <= 1) if side < 0 else (k >= ew)
            dy = 0
            if brow == 'worried' and inner:
                dy = -1
            if brow == 'worried' and outer:
                dy = 1 if S > 1 else 0
            if brow == 'angry' and inner:
                dy = 1
            if brow == 'raised':
                dy = -1
            if brow == 'one_up' and side > 0:
                dy = -2 if outer else -1
            P.r(x, by + dy, 1, max(1, u(1)), bc)
    # —— 眼镜 ——
    g = spec.get('glasses')
    if g:
        gc = hx({'black': '1a1c1c', 'metal': 'a9b0b0', 'rimless': 'c8d0d0'}[g])
        for ex0 in (lx, rx):
            x0, y0, w, h = ex0 - u(2), eye_y - u(1), ew + u(4), u(5)
            if g != 'rimless':
                P.r(x0, y0, w, 1, gc)
                P.r(x0, y0 + h - 1, w, 1, gc)
                P.r(x0, y0, 1, h, gc)
                P.r(x0 + w - 1, y0, 1, h, gc)
            else:
                P.r(x0, y0 + h - 1, w, 1, gc)
            P.p(x0 + 1, y0 + 1, hx('ffffff', 255))
        P.r(lx + ew + u(2), eye_y, rx - lx - ew - u(4), 1, gc)
        P.r(cx - hw, eye_y, u(2), 1, gc)
        P.r(cx + hw - u(2), eye_y, u(2), 1, gc)
    # —— 鼻 ——
    ny = eye_y + u(4)
    P.r(cx + 1, ny, 1, u(3), skin_d)
    P.r(cx - u(1), ny + u(3), u(3), 1, sh(skin, 0.78))
    # —— 嘴 ——
    my = eye_y + u(9)
    lip = mix(sh(skin, 0.55), hx('8a3a3a'), 0.4 if spec.get('female') else 0.15)
    m = ex.get('mouth', 'flat')
    mw = u(5)
    mx = cx - mw // 2
    if m == 'flat':
        P.r(mx, my, mw, 1, lip)
    elif m == 'smile':
        P.r(mx + 1, my, mw - 2, 1, lip)
        P.p(mx, my - 1, lip)
        P.p(mx + mw - 1, my - 1, lip)
    elif m == 'forced':
        P.r(mx + 1, my, mw - 1, 1, lip)
        P.p(mx + mw - 1 + (1 if S > 1 else 0), my - 1, lip)
    elif m == 'tight':
        P.r(mx + 1, my, mw - 2, 1, sh(lip, 0.8))
        P.p(mx, my + 1, sh(skin, 0.85))
    elif m == 'open':
        P.r(mx + 1, my - (1 if S > 1 else 0), mw - 2, u(2), hx('4a2626'))
    elif m == 'frown':
        P.r(mx + 1, my, mw - 2, 1, lip)
        P.p(mx, my + 1, lip)
        P.p(mx + mw - 1, my + 1, lip)
    elif m == 'wavy':
        for k in range(mw):
            P.p(mx + k, my + (k % 2), lip)
    if S > 1 and m in ('flat', 'smile', 'forced', 'frown'):
        P.r(mx + u(1), my + u(1), mw - u(2), 1, mix(skin, lip, 0.3))

    # —— 前层头发 ——
    T = top
    def cap(depth, x0=None, x1=None):
        for y in range(T - u(3), T + depth):
            if y in rows:
                a, b = rows[y]
            else:
                a, b = cx - hw + u(3), cx + hw - u(3)
            a = a - 1 if x0 is None else x0
            b = b + 1 if x1 is None else x1
            P.r(a, y, b - a + 1, 1, hair)
    if hairstyle == 'ponytail':
        cap(u(6))
        for y in range(T + u(2), T + u(13)):
            a, b = rows[y]
            P.r(a - 1, y, u(3), 1, hair)
            P.r(b - u(2) + 1, y, u(3), 1, hair)
        # 中分线 + 高光
        P.r(cx, T - u(2), 1, u(5), hair_d)
        P.r(cx - u(6), T - u(1), u(4), 1, hair_l)
        P.r(cx + u(3), T - u(1), u(4), 1, hair_l)
        # 发圈
        P.r(cx + hw, T + u(15), u(3), u(2), hx('c8402f'))
    elif hairstyle == 'bob':
        cap(u(8))
        for k, x in enumerate(range(cx - hw - 1, cx + hw + 1)):
            if k % u(3) == 0:
                P.p(x, T + u(8), hair)
        for y in range(T + u(3), T + u(24)):
            a, b = rows.get(y, (cx - hw, cx + hw))
            P.r(a - u(2), y, u(4), 1, hair)
            P.r(b - u(1), y, u(4), 1, hair)
        P.r(cx - u(8), T - u(1), u(10), 1, hair_l)
        # 发夹
        P.r(cx + u(6), T + u(4), u(4), 1, hx('e8c84a'))
    elif hairstyle == 'side_part':
        cap(u(5))
        part = cx - u(5)
        P.r(part, T - u(3), 1, u(5), hair_d)
        for y in range(T + u(2), T + u(7)):
            a, b = rows[y]
            P.r(part, y, b - part - u(3) - (y - T - u(2)) * 2, 1, hair)
        P.r(rows[T + u(4)][0] - 1, T + u(4), u(2), u(8), hair)
        P.r(rows[T + u(4)][1], T + u(4), u(2), u(8), hair)
        P.r(part + u(2), T - u(2), u(8), 1, hair_l)
    elif hairstyle == 'messy':
        cap(u(5))
        spikes = [(-10, 3), (-7, 5), (-4, 2), (-1, 6), (2, 3), (5, 5), (8, 2), (10, 4)]
        for dx, h in spikes:
            P.r(cx + u(dx), T - u(3) - u(h) // 2, u(2), u(h) // 2 + u(1), hair)
        fringe = [(-9, 8), (-6, 10), (-3, 7), (0, 11), (3, 8), (6, 10), (9, 6)]
        for dx, d in fringe:
            P.r(cx + u(dx), T, u(2), u(d), hair)
        for y in range(T + u(2), T + u(14)):
            a, b = rows[y]
            P.r(a - 1, y, u(2), 1, hair)
            P.r(b, y, u(2), 1, hair)
        P.p(cx - u(5), T - u(4), hair_l)
        P.p(cx + u(4), T - u(3), hair_l)
    elif hairstyle == 'tied':
        cap(u(4))
        for y in range(T + u(1), T + u(10)):
            a, b = rows[y]
            P.r(a - 1, y, u(2), 1, hair)
            P.r(b, y, u(2), 1, hair)
        # 散下来的几缕
        for k in range(u(9)):
            P.p(cx - hw + u(1) + (k // u(4)), T + u(4) + k, hair_d)
        for k in range(u(6)):
            P.p(cx + u(2) + k // u(3), T + u(3) + k, hair_d)
        P.r(cx - u(6), T - u(2), u(12), 1, hair_l)
        for k in range(0, u(10), u(2)):
            P.p(cx - u(5) + k, T - u(1), hair_d)
    elif hairstyle == 'tucked':
        cap(u(5))
        # 左边别到耳后，露耳朵；右边垂下
        for y in range(T + u(2), T + u(10)):
            a, b = rows[y]
            P.r(a - 1, y, u(2), 1, hair)
        for y in range(T + u(2), T + u(24)):
            a, b = rows.get(y, (cx - hw, cx + hw))
            P.r(b - u(2), y, u(5), 1, hair)
        P.r(cx - u(9), T + u(4), u(10), u(2), hair)
        # 几根白头发
        grey = hx('b8b8b0')
        for (dx, dy) in [(-4, -2), (2, -1), (7, 0), (9, 6), (10, 12)]:
            P.p(cx + u(dx), T + u(dy), grey)
        P.r(cx - u(7), T - u(2), u(6), 1, hair_l)
    elif hairstyle == 'receding':
        for y in range(T - u(3), T + u(3)):
            a, b = rows.get(y, (cx - hw + u(3), cx + hw - u(3)))
            P.r(a - 1, y, b - a + 3, 1, hair)
        # M 形发际线：两侧额角秃进去
        P.r(cx - u(8), T + u(1), u(4), u(3), skin)
        P.r(cx + u(4), T + u(1), u(4), u(3), skin)
        P.r(cx - u(3), T + u(3), u(6), 1, hair)
        for y in range(T + u(3), T + u(11)):
            a, b = rows[y]
            P.r(a - 1, y, u(2), 1, hair)
            P.r(b, y, u(2), 1, hair)
        P.r(cx - u(2), T - u(2), u(5), 1, hair_l)
    elif hairstyle == 'slick':
        cap(u(5))
        P.r(cx - u(10), T - u(5), u(18), u(3), hair)
        part = cx - u(6)
        P.r(part, T - u(5), 1, u(6), skin_d)
        P.r(part + u(2), T - u(4), u(10), 1, mix(hair, hx('ffffff'), 0.35))
        P.r(part + u(3), T - u(3), u(7), 1, hair_l)
        for y in range(T + u(2), T + u(9)):
            a, b = rows[y]
            P.r(a - 1, y, u(2), 1, hair)
            P.r(b, y, u(2), 1, hair)
    elif hairstyle == 'crew':
        cap(u(3))
        for y in range(T + u(2), T + u(8)):
            a, b = rows[y]
            P.r(a - 1, y, u(2), 1, hair)
            P.r(b, y, u(2), 1, hair)
        for k in range(0, u(18), 2):
            P.p(cx - u(9) + k, T - u(3), hair_l)
    elif hairstyle == 'back_grey':
        cap(u(4))
        for y in range(T + u(2), T + u(10)):
            a, b = rows[y]
            P.r(a - 1, y, u(2), 1, hair)
            P.r(b, y, u(2), 1, hair)
        for k in range(0, u(18), u(3)):
            P.r(cx - u(9) + k, T - u(2), 1, u(4), hair_d)
        P.r(cx - u(9), T - u(4), u(18), 1, hair_l)
    elif hairstyle == 'grey_thin':
        cap(u(3))
        for y in range(T + u(2), T + u(10)):
            a, b = rows[y]
            P.r(a - 1, y, u(2), 1, hair)
            P.r(b, y, u(2), 1, hair)
        for k in range(0, u(16), 2):
            P.p(cx - u(8) + k, T - u(2), sh(hair, 0.8))

    # 老花镜推在额头上
    if spec.get('readers_up'):
        gc = hx('7a5a3a')
        for ex0 in (lx, rx):
            P.r(ex0 - u(2), T + u(1), ew + u(4), 1, gc)
            P.r(ex0 - u(2), T + u(4), ew + u(4), 1, gc)
            P.r(ex0 - u(2), T + u(1), 1, u(4), gc)
            P.r(ex0 + ew + u(1), T + u(1), 1, u(4), gc)

    # —— 汗 ——
    if ex.get('sweat'):
        dx = cx + hw - u(5)
        dy = top + u(5)
        blue = hx('8fc8e8')
        P.p(dx + u(1), dy, blue)
        P.r(dx, dy + 1, u(2) + 1, u(2) + 1, blue)
        P.p(dx + 1, dy + 1, hx('ffffff'))
        P.p(dx - u(13), dy + u(4), blue)
        P.r(dx - u(13) - 1, dy + u(4) + 1, 2, 2, blue)
    if ex.get('tear'):
        blue = hx('8fc8e8')
        P.r(lx + 1, eye_y + u(3), 1, u(3), blue)

    img.alpha_composite(sub, (ox, oy))
    return sub

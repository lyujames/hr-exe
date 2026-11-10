"""女性头像改版：鹅蛋 / 小 V 脸、大一点的眼睛、有层次的头发。S=1 是 64×64，S=2 是 128 半身像。"""
import math
from PIL import Image
from faces import Pix, hx, sh, mix

# 64 像素下每一行的半宽（31 行）：额头圆，颧骨处最宽，下巴收窄成小尖
PROFILE = [7, 9, 10, 11, 11.5, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 11.5, 11, 10.5, 10, 9.5, 8.5, 7.5, 6.5, 5.5, 4.5, 3.5, 2.5]


def rows_for(cx, top, S, width=1.0, length=1.0):
    rows = {}
    n = len(PROFILE)
    total = int(round(n * S * length))
    for i in range(total):
        f = i / (S * length)
        k = min(n - 1, int(f))
        t = f - k
        a = PROFILE[k]
        b = PROFILE[min(n - 1, k + 1)]
        w = (a * (1 - t) + b * t) * S * width
        w = max(1, int(round(w)))
        rows[top + i] = (cx - w, cx + w - 1)
    return rows


def draw_female(img, ox, oy, spec, ex, S=1, size=None, body=True, bg=None):
    size = size or 64 * S
    sub = Image.new('RGBA', (size, size), bg or hx(spec.get('bg', '5a6763')))
    P = Pix(sub)
    u = lambda v: int(round(v * S))
    skin = hx(spec['skin'])
    skin_d = sh(skin, 0.9)
    skin_dd = sh(skin, 0.8)
    skin_o = sh(skin, 0.66)
    skin_hi = mix(skin, hx('fff6ee'), 0.35)
    hair = hx(spec['hair'])
    hair_l = mix(hair, hx(spec.get('hair_hi', 'b08a70')), 0.35)
    hair_d = sh(hair, 0.65)
    cx = size // 2
    top = u(13) + spec.get('dy', 0) * S
    rows = rows_for(cx, top, S, spec.get('width', 1.0), spec.get('length', 1.0))
    ys = sorted(rows)
    chin = ys[-1] + 1
    H = chin - top
    eye_y = top + u(15)
    hs = spec['hair_style']
    cheek = rows[eye_y]

    def edge(y):
        # 脸边：下巴以上贴着脸，下巴以下按颧骨宽度往外散
        if y < top + u(10):
            cy0 = top + u(10)
            r = u(12)
            d2 = r * r - (y - cy0) ** 2
            h = int(math.sqrt(max(1, d2)))
            return cx - h, cx + h - 1
        if y in rows and y < eye_y + u(4):
            return rows[y]
        f = max(0, y - (eye_y + u(4))) * 0.35
        return int(cheek[0] - f * 0.3), int(cheek[1] + f * 0.3)
    long_to = spec.get('long_to', None)

    # ───── 后层头发 ─────
    def back(to_y, extra=3, flare=0.0, wave=False):
        for y in range(top - u(2), to_y):
            a, b = edge(y)
            e = u(extra) + int(max(0, y - eye_y) * flare)
            if y > chin - u(6):
                e = e + 0
            off = int(round(math.sin(y / (2.5 * S)) * S)) if wave else 0
            P.r(a - e + off, y, (b - a + 1) + 2 * e, 1, hair)
        # 发尾一圈暗
        for y in range(max(top, to_y - u(2)), to_y):
            a, b = edge(y)
            e = u(extra) + int(max(0, y - eye_y) * flare)
            P.r(a - e, y, u(2), 1, hair_d)
            P.r(b + e - u(2) + 1, y, u(2), 1, hair_d)
        # 竖向发丝
        for y in range(eye_y, to_y):
            a, b = edge(y)
            e = u(extra) + int(max(0, y - eye_y) * flare)
            pass

    if hs == 'ponytail':
        P.r(cx + u(9), top + u(14), u(4), u(26), hair)
        P.r(cx + u(10), top + u(16), u(2), u(22), hair_l)
        P.r(cx + u(12), top + u(18), u(1), u(20), hair_d)
    if hs == 'bob':
        back(top + u(30), extra=3, flare=0.12)
    if hs == 'tucked':
        back(top + u(27), extra=2, flare=0.1)
    if hs == 'long':
        back(long_to or (size), extra=3, flare=0.18, wave=spec.get('wave', False))
    if hs == 'half_up':
        back(size, extra=3, flare=0.15)
    if hs == 'shoulder':
        back(top + u(37), extra=3, flare=0.2)
    if hs == 'curly':
        for y in range(top - u(5), top + u(24)):
            a, b = rows.get(y, (cx - u(8), cx + u(8) - 1))
            e = u(5) - (u(2) if y > top + u(18) else 0)
            P.r(a - e, y, b - a + 1 + 2 * e, 1, hair)
    if hs == 'pixie':
        back(top + u(18), extra=2)

    # ───── 衣服 / 脖子 ─────
    if body:
        cloth = hx(spec['cloth'])
        cloth_d = sh(cloth, 0.8)
        cloth_l = mix(cloth, hx('ffffff'), 0.18)
        nw = u(4)
        P.r(cx - nw, chin - u(5), 2 * nw, u(10), skin_d)
        P.r(cx - nw, chin, 2 * nw, u(1), mix(skin_d, skin_dd, 0.5))
        sy = chin + u(4)
        for y in range(sy, size):
            t = (y - sy) / S
            w = min(u(26), u(11) + int(t * 2.6 * S))
            P.r(cx - w, y, 2 * w, 1, cloth)
            P.r(cx + w - u(4), y, u(3), 1, cloth_d)
            P.p(cx - w, y, cloth_d)
        # 锁骨
        P.r(cx - u(6), sy + u(1), u(3), 1, skin_dd) if spec.get('neckline') == 'open' else None
        cs = spec['cloth_style']
        if cs == 'shirt':
            col = hx(spec.get('collar', 'f4f4ee'))
            for i in range(u(5)):
                P.r(cx - nw - u(2) + i, sy - u(1) + i, u(2), 1, col)
                P.r(cx + nw - i, sy - u(1) + i, u(2), 1, col)
            P.r(cx, sy + u(4), 1, size, sh(cloth, 0.88))
        if cs == 'hoodie':
            P.r(cx - nw - u(5), sy - u(2), u(5), u(5), cloth_d)
            P.r(cx + nw, sy - u(2), u(5), u(5), cloth_d)
            P.r(cx - u(3), sy + u(4), 1, u(8), hx('f2efe6'))
            P.r(cx + u(2), sy + u(4), 1, u(9), hx('f2efe6'))
        if cs == 'cardigan':
            inner = hx(spec.get('inner', 'ece8dc'))
            for y in range(sy - u(1), size):
                t = (y - sy) / S
                iw = u(4) + int(t * 0.6 * S)
                P.r(cx - iw, y, 2 * iw, 1, inner)
                P.p(cx - iw - 1, y, cloth_d)
                P.p(cx + iw, y, cloth_d)
            for k in range(3):
                P.p(cx - u(5) - 1, sy + u(5) + k * u(4), hx('f0e8d8'))
        if cs == 'blouse':
            # 圆领，领口一圈细边
            for x in range(cx - u(6), cx + u(6)):
                dy = int(((x - cx) / (6 * S)) ** 2 * 3 * S)
                P.p(x, sy + u(3) - dy, mix(cloth, hx('ffffff'), 0.4))
                for y in range(sy - u(1), sy + u(3) - dy):
                    P.p(x, y, skin_d)
        if cs == 'blazer':
            inner = hx(spec.get('inner', 'ece8dc'))
            for y in range(sy - u(1), size):
                t = (y - sy) / S
                iw = u(4) + int(t * 0.7 * S)
                P.r(cx - iw, y, 2 * iw, 1, inner)
                P.r(cx - iw - u(2), y, u(2), 1, cloth_l)   # 翻领高光
                P.r(cx + iw, y, u(2), 1, cloth_d)
        if cs == 'turtle':
            P.r(cx - nw - u(1), chin, 2 * nw + u(2), u(6), cloth)
            P.r(cx - nw - u(1), chin + u(2), 2 * nw + u(2), 1, cloth_d)
        if cs == 'sport':
            P.r(cx - u(1), sy - u(1), u(2), size, hx('d8d8d0'))   # 拉链
            for i in range(u(4)):
                P.r(cx - nw - u(2) + i, sy - u(2) + i, u(2), 1, cloth_l)
                P.r(cx + nw - i, sy - u(2) + i, u(2), 1, cloth_l)
            P.r(cx - u(16), sy + u(4), u(2), size, hx('e8e4d8'))
            P.r(cx + u(14), sy + u(4), u(2), size, hx('e8e4d8'))
        if spec.get('headset'):
            c = hx('2a2c2e')
            for x in range(cx - u(8), cx + u(8)):
                dy = int(((x - cx) / (8 * S)) ** 2 * 4 * S)
                P.p(x, sy - dy + u(1), c)
            P.r(cx - u(9), sy - u(3), u(3), u(3), c)
            P.r(cx + u(6), sy - u(3), u(3), u(3), c)
        if spec.get('necklace'):
            for x in range(cx - u(4), cx + u(4)):
                dy = int(((x - cx) / (4 * S)) ** 2 * 2 * S)
                P.p(x, sy + u(3) - dy, hx('e0d0a0'))
            P.p(cx, sy + u(4), hx('f0e0b0'))

    # ───── 耳 ─────
    for side in (-1, 1):
        ex0 = rows[eye_y][0] - u(1) if side < 0 else rows[eye_y][1]
        P.r(ex0, eye_y - u(1), u(2), u(5), skin_d)
        if spec.get('earring'):
            P.p(ex0 + (0 if side < 0 else u(1)), eye_y + u(4), hx(spec['earring']))
            if spec.get('earring_drop'):
                P.p(ex0 + (0 if side < 0 else u(1)), eye_y + u(5), hx(spec['earring']))

    # ───── 脸 ─────
    for y, (a, b) in rows.items():
        P.r(a, y, b - a + 1, 1, skin)
        P.p(a, y, skin_o)
        P.p(b, y, skin_o)
        if y > top + u(12):
            P.r(b - u(1), y, u(1), 1, skin_d)
    a, b = rows[ys[-1]]
    P.r(a, ys[-1], b - a + 1, 1, skin_o)
    
    # 下巴高光、鼻梁高光
    P.p(cx - u(1), chin - u(2), skin_hi)
    # 腮红
    blush = mix(skin, hx('e0807a'), 0.35 if ex.get('blush') or spec.get('blush') else 0.18)
    P.r(cx - u(8), eye_y + u(4), u(3), u(1), blush)
    P.r(cx + u(5), eye_y + u(4), u(3), u(1), blush)
    if spec.get('tired') or ex.get('tired'):
        bc = mix(skin, hx('7a6a8a'), 0.28)
        P.r(cx - u(7), eye_y + u(3), u(4), 1, bc)
        P.r(cx + u(3), eye_y + u(3), u(4), 1, bc)
    if spec.get('age_lines'):
        lc = mix(skin, skin_dd, 0.6)
        P.p(cx - u(4), eye_y + u(7), lc)
        P.p(cx + u(4), eye_y + u(7), lc)

    # ───── 眼 ─────
    LASH = hx('231a1a')
    IRIS = hx(spec.get('iris', '4a3026'))
    PUP = hx('1a1210')
    WHITE = hx('f2f0ea')
    look = ex.get('eyes', 'normal')
    ew = u(4)          # 眼白宽
    eh = u(2)          # 眼白高
    for side in (-1, 1):
        x0 = cx - u(8) if side < 0 else cx + u(4)
        y0 = eye_y
        if look == 'closed':
            P.r(x0, y0 + u(1), ew + 1, 1, LASH)
            P.p(x0 - 1 if side < 0 else x0 + ew + 1, y0, LASH)
            continue
        if look == 'smile_closed':
            # 弯月眼
            P.r(x0 + 1, y0, ew - 1, 1, LASH)
            P.p(x0, y0 + 1, LASH)
            P.p(x0 + ew, y0 + 1, LASH)
            continue
        lid = 0
        if look == 'down':
            lid = u(1)
        if look == 'wide':
            lid = -1
        # 眼白
        P.r(x0, y0 + lid, ew + 1, eh - lid + (1 if S == 1 else 0), WHITE)
        # 虹膜
        iw = u(2) + (1 if S == 1 else 0)
        shift = {'side_l': 0, 'side_r': ew + 1 - iw}.get(look, (ew + 1 - iw) // 2 + (0 if side < 0 else 0))
        ih = eh + (1 if S == 1 else 0) - max(0, lid)
        iy = y0 + max(0, lid)
        P.r(x0 + shift, iy, iw, ih, IRIS)
        if S > 1:
            P.r(x0 + shift + u(1) - 1, iy + 1, u(2) - 1, ih - 2, PUP)
        P.p(x0 + shift, iy, hx('fbfaf6'))
        if S > 1:
            P.p(x0 + shift + 1, iy, hx('fbfaf6'))
            P.p(x0 + shift + iw - 2, iy + ih - 2, mix(IRIS, WHITE, 0.4))
        # 上眼线：粗一点，眼尾上挑
        lh = 1 if S == 1 else 2
        P.r(x0 - (1 if side < 0 else 0), y0 + lid - 1, ew + 2, lh, LASH)
        wing_x = x0 - 1 - (1 if S > 1 else 0) if side < 0 else x0 + ew + 1 + (1 if S > 1 else 0)
        P.p(wing_x, y0 + lid - 2, LASH)
        if S > 1:
            P.p(wing_x + (1 if side < 0 else -1), y0 + lid - 2, LASH)
            P.p(wing_x + (-1 if side < 0 else 1), y0 + lid - 3, LASH)
        # 下眼睑
        P.r(x0 + 1, y0 + eh + (1 if S == 1 else 0), ew - 1, 1, mix(skin, skin_o, 0.4))
        # 双眼皮
        if S > 1:
            P.r(x0 + u(1), y0 + lid - u(2) - 1, ew - u(1), 1, skin_dd)
    # ───── 眉：细、弯 ─────
    brow = ex.get('brows', 'flat')
    bc = mix(hair, skin, 0.25)
    for side in (-1, 1):
        x0 = cx - u(9) if side < 0 else cx + u(4)
        bw = u(5) + 1
        for k in range(bw):
            xx = x0 + k
            kk = k / (bw - 1)
            inner_t = (1 - kk) if side > 0 else kk
            arch = -1 if 0.35 < kk < 0.75 else 0
            dy = arch
            if brow == 'worried':
                dy = int(round(-inner_t * 2 * S + (1 - inner_t) * S * 0.5))
            if brow == 'angry':
                dy = int(round(inner_t * 1.5 * S))
            if brow == 'raised':
                dy = arch - S
            if brow == 'one_up' and side > 0:
                dy = arch - S
            th = 1 if S == 1 or k in (0, bw - 1) else 2
            P.r(xx, eye_y - u(4) + dy, 1, th, bc)
    # ───── 鼻：只要一点阴影 ─────
    ny = eye_y + u(5)
    P.p(cx, ny, skin_d)
    P.r(cx - u(1), ny + u(1), u(2), 1, skin_dd) if S > 1 else P.p(cx, ny + 1, skin_dd)
    if S > 1:
        P.r(cx + u(1), eye_y + u(1), 1, u(4), skin_d)
        P.p(cx - u(2), ny + u(1), skin_o)
        P.p(cx + u(1), ny + u(1), skin_o)
    # ───── 嘴 ─────
    lip_u = hx(spec.get('lip', 'b8575c'))
    lip_l = mix(lip_u, hx('f0a0a0'), 0.4)
    my = eye_y + u(9)
    m = ex.get('mouth', 'flat')
    mw = u(4)
    mx = cx - mw // 2
    if m == 'open':
        P.r(mx, my - (1 if S > 1 else 0), mw, u(2), hx('5a2a2e'))
        P.r(mx + 1, my - (1 if S > 1 else 0), mw - 2, 1, hx('f0e8e0')) if S > 1 else None
        P.r(mx + 1, my + u(2) - (1 if S > 1 else 0), mw - 2, 1, lip_l)
    else:
        P.r(mx, my, mw, 1, lip_u)
        P.r(mx + (1 if S == 1 else u(1)), my + 1, mw - (2 if S == 1 else u(2)), 1 if S == 1 else u(1), lip_l)
        if S > 1:
            P.p(cx - 1, my - 1, mix(skin, lip_u, 0.5))
            P.p(cx, my - 1, mix(skin, lip_u, 0.5))
        if m == 'smile':
            P.p(mx - 1, my - 1, lip_u)
            P.p(mx + mw, my - 1, lip_u)
        if m == 'forced':
            P.p(mx + mw, my - 1, lip_u)
            P.p(mx - 1, my + 1, skin_dd)
        if m == 'tight':
            P.r(mx, my, mw, 1, sh(lip_u, 0.85))
            P.r(mx + 1, my + 1, mw - 2, 1, mix(skin, lip_l, 0.4))
        if m == 'frown':
            P.p(mx - 1, my + 1, lip_u)
            P.p(mx + mw, my + 1, lip_u)

    # ───── 前层头发 ─────
    T = top

    def dome(y, extra):
        cy0 = T + u(10)
        r = u(12) + extra
        d2 = r * r - (y - cy0) ** 2
        if d2 <= 0:
            return None
        h = int(math.sqrt(d2))
        return cx - h, cx + h - 1

    def cap(depth, extra=2):
        depth = depth + u(2)
        for y in range(T + u(10) - u(12) - extra, T + depth):
            ab = dome(y, extra)
            if ab is None:
                continue
            a, b = ab
            if y in rows:
                a = min(a, rows[y][0] - extra)
                b = max(b, rows[y][1] + extra)
            P.r(a, y, b - a + 1, 1, hair)
        # 发际线下沿一行暗，显出层次
        for x in range(cx - u(8), cx + u(8)):
            if P.get(x, T + depth) != hair and P.get(x, T + depth - 1) == hair:
                P.p(x, T + depth - 1, hair_d)

    def frame_strands(to_y, w=2, both=True, left=True, right=True):
        # 贴着脸颊垂下的两缕：脸看起来更窄
        for y in range(T + u(3), to_y):
            a, b = edge(y)
            below = y >= eye_y + u(4)
            grow = min(u(5), max(0, (y - eye_y - u(4))) // 2) if below else 0
            sw = u(w) + grow
            if left:
                x0 = a - u(1) - grow // 2
                P.r(x0, y, sw, 1, hair)
                if sw > u(3):
                    P.p(x0 + sw // 2, y, hair_d)
                    if (y // S) % 5 == 0:
                        P.p(x0 + 1, y, hair_l)
            if right:
                x1 = b + u(1) + grow // 2
                P.r(x1 - sw + 1, y, sw, 1, hair)
                if sw > u(3):
                    P.p(x1 - sw // 2, y, hair_d)
                    if (y // S) % 5 == 2:
                        P.p(x1 - 1, y, hair_l)

    def gloss(y, x0, x1):
        # 头顶一圈高光（天使圈）
        for x in range(x0, x1):
            P.p(x, y + int(abs(x - (x0 + x1) / 2) / (4 * S)), hair_l)

    if hs == 'ponytail':
        cap(u(5))
        # 侧分斜刘海
        for k in range(u(10)):
            P.r(cx - u(8) + k, T + u(4) + k // (2 * S), u(12) - k, 1, hair)
        frame_strands(eye_y + u(6), w=1)
        P.r(cx - u(2), T - u(3), 1, u(5), hair_d)
        gloss(T - u(1), cx - u(8), cx + u(8))
        P.r(cx + u(10), T + u(13), u(3), u(2), hx(spec.get('tie', 'c8402f')))
    elif hs == 'bob':
        cap(u(4))
        # 空气刘海：一缕一缕，中间透出额头
        for dx, d in [(-9, 7), (-7, 8), (-5, 9), (-3, 8), (-1, 9), (1, 8), (3, 9), (5, 8), (7, 7), (9, 6)]:
            P.r(cx + u(dx), T + u(2), u(1) + (1 if S == 1 else 0), u(d) - (u(1) if dx % 4 == 1 else 0), hair)
        frame_strands(T + u(27), w=1.5)
        gloss(T - u(1), cx - u(8), cx + u(8))
        if spec.get('clip'):
            P.r(cx + u(6), T + u(3), u(4), u(1), hx(spec['clip']))
    elif hs == 'tucked':
        cap(u(5))
        # 侧分，右边一大片斜下来，左边别到耳后
        for k in range(u(12)):
            P.r(cx - u(3) + k // 2, T + u(4) + k // (2 * S), u(13) - k // 2, 1, hair)
        frame_strands(T + u(25), w=1.5, left=False)
        P.r(rows[eye_y][0] - u(1), T + u(3), u(2), u(9), hair)
        P.r(cx - u(4), T - u(3), 1, u(5), hair_d)
        gloss(T - u(1), cx - u(9), cx + u(7))
        for (dx, dy) in spec.get('greys', []):
            P.p(cx + u(dx), T + u(dy), hx('c8c4bc'))
    elif hs == 'long':
        cap(u(4))
        part = cx + u(spec.get('part', 0))
        P.r(part, T - u(3), 1, u(6), skin_d)
        for k in range(u(8)):
            P.p(part - 1 - k, T + u(2) + k, hair)
            P.p(part + 1 + k, T + u(2) + k, hair)
        frame_strands(long_to or size, w=1.5)
        gloss(T - u(1), cx - u(8), cx + u(8))
    elif hs == 'half_up':
        cap(u(4))
        for k in range(u(9)):
            P.r(cx - u(8) + k, T + u(4) + k // (2 * S), u(10) - k, 1, hair)
        frame_strands(size, w=1)
        gloss(T - u(1), cx - u(8), cx + u(8))
        P.r(cx - u(3), T - u(5), u(6), u(3), hair)   # 头顶小揪
        P.r(cx - u(2), T - u(5), u(4), 1, hair_l)
    elif hs == 'shoulder':
        cap(u(4))
        for k in range(u(11)):
            P.r(cx - u(10) + k // 2, T + u(4) + k // (2 * S), u(12) - k, 1, hair)
        frame_strands(T + u(34), w=1.5)
        gloss(T - u(1), cx - u(8), cx + u(8))
    elif hs == 'low_bun':
        cap(u(4), extra=0)
        P.r(cx + u(1), T - u(3), 1, u(5), hair_d)
        frame_strands(eye_y + u(4), w=1, right=False)
        # 碎发：随手扎的
        for (dx, dy) in [(-11, 6), (-11, 9), (-12, 12), (11, 5), (12, 8)]:
            P.p(cx + u(dx), T + u(dy), hair)
        gloss(T - u(1), cx - u(7), cx + u(7))

    elif hs == 'curly':
        cap(u(4), extra=2)
        for (dx, dy) in [(-10, -3), (-6, -5), (-1, -6), (4, -5), (8, -3), (-12, 4), (11, 4), (-12, 12), (11, 12), (-11, 19), (10, 19)]:
            P.r(cx + u(dx), T + u(dy), u(3), u(3), hair)
            P.p(cx + u(dx) + 1, T + u(dy) + 1, hair_l)
        for (dx, dy) in [(-7, 2), (-3, 3), (1, 2), (5, 3)]:
            P.r(cx + u(dx), T + u(dy), u(3), u(2), hair)
            P.p(cx + u(dx), T + u(dy), hair_l)
    elif hs == 'pixie':
        cap(u(4))
        for k in range(u(10)):
            P.r(cx - u(9) + k, T + u(3) + k // (3 * S), u(9) - k // 2, 1, hair)
        frame_strands(eye_y + u(2), w=1)
        gloss(T - u(1), cx - u(8), cx + u(8))

    # ───── 眼镜 ─────
    g = spec.get('glasses')
    if g:
        gc = hx({'thin': '8a7a6a', 'black': '1a1c1c', 'gold': 'c8a860'}[g])
        for side in (-1, 1):
            x0 = cx - u(9) if side < 0 else cx + u(3)
            w, h = u(6) + 1, u(4)
            P.r(x0, eye_y - u(1), w, 1, gc)
            P.r(x0, eye_y - u(1) + h, w, 1, gc)
            P.r(x0, eye_y - u(1), 1, h + 1, gc)
            P.r(x0 + w - 1, eye_y - u(1), 1, h + 1, gc)
        P.r(cx - u(2), eye_y, u(4) - 1, 1, gc)

    if ex.get('sweat'):
        blue = hx('8fc8e8')
        x, y = cx + u(7), T + u(6)
        P.p(x + u(1), y, blue)
        P.r(x, y + 1, u(2) + 1, u(2) + 1, blue)
        P.p(x + 1, y + 1, hx('ffffff'))
    img.alpha_composite(sub, (ox, oy))
    return sub

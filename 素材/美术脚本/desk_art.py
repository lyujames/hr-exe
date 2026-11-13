"""桌面一屏的美术：桌面、全家福、手机、打印机、文件盒、印章、抽屉、七种纸、印章墨迹。全部按 1 个游戏像素画。"""
import math
import random
from PIL import Image, ImageDraw, ImageFont
from faces import Pix, hx, sh, mix

F = ImageFont.truetype('fp12.otf', 12)
SHADOW = (0, 0, 0, 140)


def text(img, x, y, s, c):
    d = ImageDraw.Draw(img)
    d.fontmode = '1'
    d.text((x, y), s, font=F, fill=c)


def greek(P, x, y, w, c, rnd, lines=3, lh=4, short=0.6):
    """看不清的字：一行一行灰条，长短不一。"""
    for i in range(lines):
        ww = int(w * (short + (1 - short) * rnd.random())) if i == lines - 1 else int(w * (0.82 + 0.18 * rnd.random()))
        xx = x
        while xx < x + ww:
            seg = rnd.randint(3, 9)
            P.r(xx, y + i * lh, min(seg, x + ww - xx), 1, c)
            xx += seg + 1
    return y + lines * lh


# ───────────── 桌面 ─────────────
def desk_bg(W=640, H=360):
    img = Image.new('RGBA', (W, H))
    P = Pix(img)
    rnd = random.Random(3)
    base = hx('2e3633')
    # 大块明暗：台灯在右上，左下暗
    for y in range(H):
        for x in range(0, W, 4):
            t = min(1, math.hypot(x - 470, y - 40) / 620)
            P.r(x, y, 4, 1, mix(sh(base, 1.12), sh(base, 0.82), t))
    # 三聚氰胺板的细斑点
    for _ in range(W * H // 28):
        x, y = rnd.randrange(W), rnd.randrange(H)
        c = img.getpixel((x, y))
        P.p(x, y, sh(c, 1.08 if rnd.random() < 0.5 else 0.93))
    # 长划痕：几道浅的
    for _ in range(9):
        x, y = rnd.randrange(100, 560), rnd.randrange(30, 330)
        L = rnd.randint(14, 40)
        dx = rnd.choice([1, 1, 2])
        for i in range(L):
            c = img.getpixel((min(W - 1, x + i * dx), y + i // 5))
            P.p(x + i * dx, y + i // 5, sh(c, 1.14))
    # 台垫：深绿皮革，四角压皮，放简历的地方
    bx, by, bw, bh = 98, 20, 238, 282
    P.r(bx + 2, by + 2, bw, bh, (0, 0, 0, 90))
    P.r(bx, by, bw, bh, hx('243a32'))
    for _ in range(bw * bh // 18):
        x, y = bx + rnd.randrange(bw), by + rnd.randrange(bh)
        P.p(x, y, hx('29413a') if rnd.random() < 0.6 else hx('20342d'))
    P.r(bx, by, bw, 1, hx('3a5a4c'))
    P.r(bx, by, 1, bh, hx('34514a'))
    P.r(bx, by + bh - 1, bw, 1, hx('16241f'))
    P.r(bx + bw - 1, by, 1, bh, hx('1a2a24'))
    # 磨亮的一块：每天盖章的地方
    for y in range(by + 200, by + 262):
        for x in range(bx + 30, bx + 200):
            if rnd.random() < 0.18 * (1 - abs(x - bx - 115) / 90) * (1 - abs(y - by - 231) / 34):
                P.p(x, y, hx('2e4a40'))
    for (cx, cy, fx, fy) in ((bx, by, 1, 1), (bx + bw - 1, by, -1, 1), (bx, by + bh - 1, 1, -1), (bx + bw - 1, by + bh - 1, -1, -1)):
        for i in range(14):
            for j in range(14 - i):
                P.p(cx + fx * j, cy + fy * i, hx('3a2a22') if (i + j) < 13 else hx('2a1e18'))
        for i in range(12):
            P.p(cx + fx * (12 - i), cy + fy * i, hx('5a4232'))
    # 咖啡杯印：半个圈，右边
    cx, cy, r = 470, 338, 11
    for a in range(0, 360, 2):
        if 30 < a < 300:
            x = cx + r * math.cos(math.radians(a))
            y = cy + r * math.sin(math.radians(a)) * 0.9
            c = img.getpixel((int(x), int(y)))
            P.p(x, y, mix(c, hx('4a3a2a'), 0.45))
            if a % 6 == 0:
                P.p(x + 1, y, mix(c, hx('4a3a2a'), 0.25))
    # 桌面前沿：一条亮边 + 压暗
    P.r(0, H - 4, W, 1, hx('46504c'))
    P.r(0, H - 3, W, 3, hx('1a201e'))
    return img


# ───────────── 全家福 ─────────────
D35 = {'0': ['111', '101', '101', '101', '111'], '1': ['010', '110', '010', '010', '111'], '2': ['111', '001', '111', '100', '111'],
       '3': ['111', '001', '111', '001', '111'], '5': ['111', '100', '111', '001', '111'], '8': ['111', '101', '111', '101', '111']}


def digits(P, x, y, s, c):
    for ch in s:
        if ch == ' ':
            x += 2
            continue
        for j, row in enumerate(D35[ch]):
            for i, b in enumerate(row):
                if b == '1':
                    P.p(x + i, y + j, c)
        x += 4


def family_photo(W=72, H=56):
    """国庆在公园拍的四口人，午后斜光，树梢刚开始黄。你爸坐长椅中间，花白头发、灰开衫、手放膝盖；
    你站左后、深蓝 polo、分头，一只手搭在他肩上；老婆站右后，齐肩黑发、灰绿上衣、金项链；
    孩子在前面偏左，蓝外套，攥着跳绳的红把手，缺颗门牙在笑。右下角老相机的橙色日期。这是你爸生病前最后一张合影。"""
    img = Image.new('RGBA', (W + 2, H + 2))
    P = Pix(img)
    rnd = random.Random(10)
    P.r(2, 2, W, H, (0, 0, 0, 140))

    # ── 相框：胡桃木，左上受光，四角斜接 ──
    wood, wood_d, wood_l = hx('6e4a32'), hx('42291a'), hx('9a6e4c')
    P.r(0, 0, W, H, wood)
    for y in range(H):
        for x in range(W):
            if min(x, y, W - 1 - x, H - 1 - y) < 5 and rnd.random() < 0.22:
                P.p(x, y, mix(wood, wood_d, 0.35) if (x + y * 3) % 5 else mix(wood, wood_l, 0.3))
    P.r(0, 0, W, 1, wood_l)
    P.r(0, 0, 1, H, wood_l)
    P.r(1, 1, W - 2, 1, mix(wood, wood_l, 0.5))
    P.r(0, H - 1, W, 1, wood_d)
    P.r(W - 1, 0, 1, H, wood_d)
    for i in range(5):
        P.p(i, i, mix(wood_l, wood, 0.4))
        P.p(W - 1 - i, H - 1 - i, wood_d)
    # 内沿：一圈暗槽
    P.r(4, 4, W - 8, 1, wood_d)
    P.r(4, 4, 1, H - 8, wood_d)
    P.r(4, H - 5, W - 8, 1, mix(wood, wood_l, 0.4))
    P.r(W - 5, 4, 1, H - 8, mix(wood, wood_l, 0.4))
    # 白卡纸衬边
    P.r(5, 5, W - 10, H - 10, hx('ece6d6'))
    P.r(5, 5, W - 10, 1, hx('d6cfbd'))
    P.r(5, 5, 1, H - 10, hx('d6cfbd'))

    px, py, pw, ph = 7, 7, W - 14, H - 14       # 照片 58×42
    OY = [0]   # 画人时整体上移

    def p(x, y, c):
        y += OY[0]
        if 0 <= x < pw and 0 <= y < ph:
            P.p(px + x, py + y, c)

    def r(x, y, w, h, c):
        y += OY[0]
        x0, y0 = max(0, x), max(0, y)
        x1, y1 = min(pw, x + w), min(ph, y + h)
        P.r(px + x0, py + y0, x1 - x0, y1 - y0, c)

    # ── 天：暖白往上转淡蓝 ──
    for y in range(14):
        r(0, y, pw, 1, mix(hx('9cc0d8'), hx('f0e6cc'), y / 13))
    # 远树：灰绿一层
    for x in range(pw):
        t = 9 + int(1.6 * math.sin(x / 3.1) + 1.2 * math.sin(x / 1.3 + 2))
        r(x, t, 1, 20 - t, hx('8aa48a'))
    # 近树：深绿，树冠一团一团，个别泛黄
    # 近树：一排圆树冠，有树干，中间两棵已经黄了
    crowns = [(1, 11, 6), (11, 9, 6), (21, 12, 5), (30, 8, 6), (40, 11, 6), (50, 9, 6), (59, 12, 5)]
    for (cx, cy, rr) in crowns:
        r(cx, cy + rr - 1, 1, 23 - cy - rr, hx('4a3a2a'))
    for (cx, cy, rr) in crowns:
        gold = cx in (11, 50)
        base = hx('c8a038') if gold else hx('527e4a')
        lite = hx('ecc858') if gold else hx('7eaa66')
        dark = hx('8e6e28') if gold else hx('3a5e3a')
        for y in range(cy - rr - 1, cy + rr + 1):
            for x in range(cx - rr - 1, cx + rr + 2):
                d = math.hypot(x - cx, (y - cy) * 1.15)
                if d <= rr + 0.7 * math.sin(x * 1.9 + y * 1.3):
                    t = (x - cx) * 0.7 + (y - cy)
                    c = lite if t < -rr * 0.55 else dark if t > rr * 0.45 else base
                    p(x, y, c)
    # 树后面的一溜灌木，接地
    for x in range(pw):
        t = 19 + int(1.3 * math.sin(x / 2.3))
        r(x, t, 1, 23 - t, hx('46703e'))
        p(x, t, hx('5e8a4c'))
    for _ in range(40):
        x, y = rnd.randrange(pw), rnd.randrange(4, 22)
        c = P.get(px + x, py + y)
        if c[1] > c[2] + 20:
            p(x, y, sh(c, 1.15 if rnd.random() < 0.6 else 0.85))
    # 地面：草坪，近处更亮，带一条小路的暖色
    for y in range(22, ph):
        t = (y - 22) / (ph - 22)
        r(0, y, pw, 1, mix(hx('6e9850'), hx('94b862'), t))
    r(0, 22, pw, 1, hx('5a8044'))
    for _ in range(70):
        x, y = rnd.randrange(pw), rnd.randrange(23, ph)
        p(x, y, hx('aacc78') if rnd.random() < 0.6 else hx('5e8844'))
    for _ in range(10):   # 落叶
        p(rnd.randrange(pw), rnd.randrange(26, ph), hx('e0b840'))

    SK = hx('e0b898')    # 你
    SK_W = hx('eec6aa')  # 老婆
    SK_O = hx('d0a482')  # 你爸
    SK_K = hx('f0caa8')  # 孩子
    EYE = hx('2a2020')

    def head(x, y, skin, hair, style, mouth='smile', w=7):
        """x,y 是脸左上（不含头发）。w 宽 7，高 7。"""
        sd = sh(skin, 0.86)
        hl = mix(hair, hx('ffffff'), 0.22)
        # 脸
        r(x + 1, y, w - 2, 1, skin)
        r(x, y + 1, w, 5, skin)
        r(x + 1, y + 6, w - 2, 1, skin)
        r(x + w - 1, y + 1, 1, 5, sd)     # 右侧背光
        p(x + w - 2, y + 6, sd)
        p(x - 1, y + 3, sd)                 # 耳朵
        p(x + w, y + 3, sd)
        # 头发
        r(x + 1, y - 2, w - 2, 1, hair)
        r(x, y - 1, w, 1, hair)
        if style == 'side':          # 你：左分，刘海往右扫
            r(x, y, w, 1, hair)
            r(x + 3, y + 1, w - 3, 1, hair)
            p(x, y + 1, hair)
            p(x + 1, y - 2, hl); p(x + 2, y - 2, hl); p(x + 1, y - 1, hl)
            p(x + 2, y, sd)
        elif style == 'kid':         # 孩子：锅盖头
            r(x, y, w, 2, hair)
            r(x - 1, y, 1, 3, hair)
            r(x + w, y, 1, 3, hair)
            p(x + 2, y - 1, hl); p(x + 3, y - 1, hl)
        elif style == 'grey':        # 你爸：花白，往后梳，发际线高
            gr = hair
            r(x + 1, y - 2, w - 2, 1, gr)
            r(x, y - 1, w, 1, gr)
            p(x, y, gr); p(x + w - 1, y, gr); p(x - 1, y + 1, gr); p(x + w, y + 1, gr)
            p(x + 2, y - 2, hx('f0f0ea')); p(x + 3, y - 1, hx('f0f0ea'))
            p(x + 4, y, sd)              # 抬头纹
            r(x + 2, y + 1, 3, 1, mix(skin, sd, 0.5))
        elif style == 'long':        # 老婆：齐肩，中分
            r(x - 1, y - 1, 1, 9, hair)
            r(x + w, y - 1, 1, 9, hair)
            r(x, y, 3, 1, hair)
            r(x + 4, y, 3, 1, hair)
            p(x, y + 1, hair); p(x + w - 1, y + 1, hair)
            r(x, y + 6, 1, 2, hair)
            r(x + w - 1, y + 6, 1, 2, hair)
            p(x - 1, y + 8, sh(hair, 0.8)); p(x + w, y + 8, sh(hair, 0.8))
            p(x + 2, y - 2, hl); p(x + 1, y - 1, hl)
        # 眼睛、腮红、嘴
        ey = y + 3
        if style == 'grey':          # 笑眯了
            r(x + 1, ey, 2, 1, mix(skin, EYE, 0.7))
            r(x + 4, ey, 2, 1, mix(skin, EYE, 0.7))
        else:
            p(x + 2, ey, EYE)
            p(x + 4, ey, EYE)
        p(x + 1, ey + 1, mix(skin, hx('e87870'), 0.35))
        p(x + 5, ey + 1, mix(skin, hx('e87870'), 0.35))
        my = y + 5
        if mouth == 'smile':
            r(x + 2, my, 3, 1, mix(skin, hx('8a3030'), 0.5))
        elif mouth == 'gap':         # 缺颗门牙
            r(x + 2, my, 3, 1, hx('fffaf0'))
            p(x + 3, my, hx('6a2424'))
            p(x + 3, my + 1, mix(skin, hx('8a3030'), 0.4))
        elif mouth == 'grin':
            r(x + 2, my, 3, 1, hx('f4ece0'))
            p(x + 1, my - 1, mix(skin, sd, 0.6)); p(x + 5, my - 1, mix(skin, sd, 0.6))

    def torso(x, y, w, h, c, collar=None):
        """左上受光：左一列亮，右两列暗。"""
        r(x + 1, y, w - 2, 1, c)
        r(x, y + 1, w, h - 1, c)
        r(x, y + 1, 1, h - 1, mix(c, hx('ffffff'), 0.12))
        r(x + w - 2, y + 1, 2, h - 1, sh(c, 0.8))

    OY[0] = -4
    # ── 你：左后，站着，深蓝 polo ──
    for x in range(8, 52):       # 三个人和长椅落在草上的影子
        for y in (34, 35):
            p(x, y + 4, mix(P.get(px + x, py + y), hx('2a4020'), 0.3 if y == 34 else 0.15))
    r(11, 33, 4, 4, hx('3a3a40')); r(16, 33, 4, 4, hx('3a3a40'))   # 你的裤子
    r(15, 33, 1, 3, hx('2a2a30'))
    r(10, 37, 5, 1, hx('1a1a1c')); r(16, 37, 5, 1, hx('1a1a1c'))
    torso(10, 17, 11, 17, hx('2f4a6a'))
    r(13, 17, 5, 2, hx('3e5c80'))                 # polo 领
    p(15, 18, SK); p(15, 19, sh(SK, 0.86))
    r(15, 19, 1, 3, hx('243a54'))                 # 门襟
    p(15, 20, hx('d8d4c8'))
    r(10, 25, 1, 9, sh(hx('2f4a6a'), 0.75))       # 左臂垂下
    r(9, 33, 2, 2, SK)
    head(12, 9, SK, hx('1e1c1c'), 'side')
    # ── 老婆：右后，站着，灰绿上衣，金项链 ──
    r(38, 33, 4, 4, hx('4a4640')); r(43, 33, 4, 4, hx('4a4640'))   # 老婆的长裤
    r(42, 33, 1, 3, hx('36322e'))
    r(38, 37, 4, 1, hx('2a2220')); r(43, 37, 4, 1, hx('2a2220'))
    torso(37, 18, 11, 16, hx('8a9a78'))
    r(41, 18, 3, 1, SK_W)
    p(41, 19, hx('d8b84a')); p(43, 19, hx('d8b84a')); p(42, 20, hx('f8e070'))
    r(47, 25, 1, 9, sh(hx('8a9a78'), 0.78))
    r(47, 33, 2, 2, SK_W)
    head(39, 10, SK_W, hx('2a201e'), 'long')

    # ── 长椅：木条椅背 + 铸铁腿，在两人前、你爸后 ──
    bw_c, bw_l, bw_d, iron = hx('9a6a42'), hx('b8885a'), hx('6a4428'), hx('2e2e30')
    for yy in (24, 27):
        r(12, yy, 36, 2, bw_c)
        r(12, yy, 36, 1, bw_l)
    r(11, 31, 38, 2, bw_c)                        # 座面
    r(11, 31, 38, 1, bw_l)
    r(11, 33, 38, 1, bw_d)
    for lx in (12, 46):
        r(lx, 23, 2, 15, iron)
        p(lx, 23, hx('4a4a4e'))
        r(lx - 1, 37, 4, 1, iron)

    # ── 你爸：坐中间，灰开衫，白衬衫领，深色裤子，手放膝盖 ──
    cg = hx('7a7468')
    torso(24, 22, 13, 11, cg)
    r(29, 22, 3, 3, hx('ece8dc'))                 # 衬衫领
    p(30, 25, hx('ece8dc'))
    r(28, 23, 1, 9, sh(cg, 0.82)); r(32, 23, 1, 9, sh(cg, 0.82))   # 开衫门襟
    p(28, 27, hx('c8c0a8')); p(32, 27, hx('c8c0a8'))
    pants = hx('3a3e48')
    r(23, 32, 15, 3, pants)                        # 大腿往前
    r(23, 32, 15, 1, sh(pants, 1.2))
    r(25, 35, 4, 4, pants); r(32, 35, 4, 4, pants) # 小腿
    r(29, 35, 3, 4, sh(pants, 0.7))
    r(24, 39, 5, 1, hx('1a1a1c')); r(32, 39, 5, 1, hx('1a1a1c'))   # 鞋
    r(25, 31, 3, 2, SK_O); r(34, 31, 3, 2, SK_O)   # 手在膝盖上
    p(27, 32, sh(SK_O, 0.85)); p(36, 32, sh(SK_O, 0.85))
    r(23, 23, 1, 8, sh(cg, 0.9)); r(37, 23, 1, 8, sh(cg, 0.75))
    head(27, 14, SK_O, hx('bcbab2'), 'grey', 'smile')
    p(28, 21, sh(SK_O, 0.86)); p(32, 21, sh(SK_O, 0.86))           # 脖子
    # 你的手搭在他左肩
    r(20, 22, 3, 2, sh(hx('2f4a6a'), 0.85))
    r(23, 22, 3, 1, SK)
    r(23, 23, 2, 1, sh(SK, 0.86))
    # 老婆的手搭他右肩
    r(37, 22, 1, 2, hx('7c8c6a'))
    r(35, 22, 2, 1, SK_W)
    p(36, 23, sh(SK_W, 0.86))

    OY[0] = -2
    # ── 孩子：前面偏左，蓝外套，红把手跳绳，缺颗门牙 ──
    kc = hx('3a6ab8')
    torso(3, 34, 9, 6, kc)
    r(6, 34, 3, 1, hx('f4f0e8'))                    # 白领口
    r(7, 35, 1, 5, hx('2c5498'))                    # 拉链
    r(4, 40, 3, 2, hx('2a2e3a')); r(8, 40, 3, 2, hx('2a2e3a'))
    r(4, 42, 3, 1, hx('d0d0d0')); r(8, 42, 3, 1, hx('d0d0d0'))   # 白球鞋
    head(4, 26, SK_K, hx('241c1a'), 'kid', 'gap')
    r(0, 36, 2, 3, hx('c8402f')); p(0, 36, hx('e86a50'))
    r(12, 36, 2, 3, hx('c8402f')); p(12, 36, hx('e86a50'))
    r(1, 37, 2, 1, SK_K); r(11, 37, 2, 1, SK_K)
    for i in range(13):
        p(1 + i, 39 + int(2.2 * math.sin(math.pi * i / 12)), hx('f8f0d0'))
    # 人脚下的影子
    for x in range(3, 13):
        if P.get(px + x, py + 43) [1] > 100:
            p(x, 43, mix(P.get(px + x, py + 43), hx('203018'), 0.4))

    # ── 冲印：暖光偏色 + 四角压暗 + 一点颗粒 ──
    for y in range(ph):
        for x in range(pw):
            c = P.get(px + x, py + y)
            d = math.hypot((x - pw / 2) / (pw / 2), (y - ph / 2) / (ph / 2))
            k = 1 - max(0, d - 0.85) * 0.35
            c = mix(c, hx('ffd890'), 0.10)
            c = sh(c, k * (1 + (rnd.random() - 0.5) * 0.05))
            P.p(px + x, py + y, c)
    # 橙色日期：25 10 03
    digits(P, px + pw - 30, py + ph - 7, '25 10 03', hx('ff8a3a'))
    # 玻璃反光：左上一道斜线
    for i in range(9):
        P.p(px + 1 + i, py + 10 - i, mix(P.get(px + 1 + i, py + 10 - i), hx("ffffff"), 0.35))
        P.p(px + 2 + i, py + 10 - i, mix(P.get(px + 2 + i, py + 10 - i), hx("ffffff"), 0.15))
    return img



# ───────────── 手机 ─────────────
def phone(state='down', sms='', clock='18:05'):
    W, H = 30, 52
    img = Image.new('RGBA', (W + 2, H + 2))
    P = Pix(img)

    def rr(x, y, w, h, c, r=2):
        for i in range(r):
            P.r(x + r - i, y + i, w - 2 * (r - i), 1, c)
            P.r(x + r - i, y + h - 1 - i, w - 2 * (r - i), 1, c)
        P.r(x, y + r, w, h - 2 * r, c)

    rr(2, 2, W, H, (0, 0, 0, 140), 3)
    if state == 'down':
        # 背面朝上：深蓝硅胶壳、镜头模组、壳上一张贴纸（孩子贴的小火箭）
        rr(0, 0, W, H, hx('1a2230'), 3)
        rr(1, 1, W - 2, H - 2, hx('2a3a52'), 3)
        P.r(2, 2, W - 4, 1, hx('3a4e6a'))
        rr(4, 4, 11, 13, hx('1a2230'), 2)
        for (x, y) in ((6, 6), (6, 11)):
            P.r(x, y, 4, 4, hx('0e1218'))
            P.p(x + 1, y + 1, hx('5a6a8a'))
        P.r(11, 7, 2, 2, hx('e8e0c0'))
        # 贴纸：小火箭
        P.r(17, 30, 4, 8, hx('f0f0e8'))
        P.r(18, 28, 2, 2, hx('c8402f'))
        P.r(16, 36, 1, 3, hx('c8402f'))
        P.r(21, 36, 1, 3, hx('c8402f'))
        P.p(18, 32, hx('3a6ab8'))
        P.r(18, 39, 2, 2, hx('e8a83a'))
        return img
    # 亮屏：黑面板、挖孔、锁屏时间、一条通知
    rr(0, 0, W, H, hx('59626a'), 3)
    rr(1, 1, W - 2, H - 2, hx('0e1214'), 3)
    sx, sy, sw, shh = 3, 3, W - 6, H - 6
    for y in range(shh):
        P.r(sx, sy + y, sw, 1, mix(hx('1e3a4a'), hx('0e1a22'), y / shh))
    P.r(W // 2 - 1, 4, 2, 2, hx('000000'))
    # 时间 3×5 点阵：18:05
    DIG = {'1': ['010', '110', '010', '010', '111'], '8': ['111', '101', '111', '101', '111'], '0': ['111', '101', '101', '101', '111'], '5': ['111', '100', '111', '001', '111']}
    x = 6
    for ch in (clock or ''):
        if ch == ':':
            P.p(x, 11, hx('d8e8e8'))
            P.p(x, 13, hx('d8e8e8'))
            x += 2
            continue
        for j, row in enumerate(DIG[ch]):
            for i, b in enumerate(row):
                if b == '1':
                    P.p(x + i, 9 + j, hx('d8e8e8'))
        x += 4
    # 通知卡片
    P.r(sx + 1, 20, sw - 2, 13, hx('d8dcd8'))
    P.r(sx + 2, 21, 3, 3, hx('7fd6a4'))
    P.r(sx + 6, 21, 10, 1, hx('3a3e3c'))
    P.r(sx + 2, 25, sw - 5, 1, hx('6a706c'))
    P.r(sx + 2, 27, sw - 8, 1, hx('6a706c'))
    P.r(sx + 2, 29, sw - 10, 1, hx('6a706c'))
    # 底部横条
    P.r(W // 2 - 4, H - 6, 8, 1, hx('8a9a9a'))
    # 屏幕反光
    for i in range(7):
        P.p(sx + sw - 3 - i, sy + 34 + i, (255, 255, 255, 40))
    return img


def buzz(img, x, y, h):
    """震动：手机两边各两道短弧。"""
    P = Pix(img)
    for k in (0, 1):
        for i in range(h):
            P.p(x - 3 - k * 2 - (1 if i in (0, h - 1) else 0), y + i, hx('7fd6a4', 200 - k * 80))
            P.p(x + 33 + k * 2 + (1 if i in (0, h - 1) else 0), y + i, hx('7fd6a4', 200 - k * 80))


# ───────────── 打印机 ─────────────
def printer(state='idle', out=0):
    """针式打印机，俯视偏前：米灰机壳、深色出纸口、两侧拖纸齿轮。out：吐出来几像素纸。"""
    W, H = 100, 32
    img = Image.new('RGBA', (W + 2, H + 2 + out))
    P = Pix(img)
    oy = out
    P.r(2, oy + 2, W, H, (0, 0, 0, 140))
    body, body_d, body_l = hx('b8b4a8'), hx('8a867c'), hx('d8d4c8')
    P.r(0, oy, W, H, body)
    P.r(0, oy, W, 1, body_l)
    P.r(0, oy + H - 1, W, 1, body_d)
    P.r(0, oy, 1, H, body_l)
    P.r(W - 1, oy, 1, H, body_d)
    # 顶盖：透明烟色罩
    P.r(6, oy + 3, 88, 12, hx('6a6e6a'))
    P.r(7, oy + 4, 86, 10, hx('545854'))
    for i in range(0, 86, 7):
        P.p(7 + i, oy + 4, hx('7a7e7a'))
    # 出纸口
    P.r(8, oy + 5, 84, 2, hx('1a1c1a'))
    # 两侧拖纸轮
    for x in (3, 93):
        P.r(x, oy + 4, 4, 10, hx('3a3a3a'))
        for j in range(0, 10, 2):
            P.p(x + 1, oy + 4 + j, hx('8a8a8a'))
    # 前面板：牌子、指示灯、按钮
    P.r(6, oy + 18, 88, 10, hx('a8a498'))
    P.r(10, oy + 21, 20, 1, hx('6a665c'))
    P.r(10, oy + 24, 14, 1, hx('6a665c'))
    P.r(62, oy + 21, 3, 2, hx('7fd6a4') if state == 'idle' else hx('3a5a4a'))
    P.r(68, oy + 21, 3, 2, hx('c8402f') if state == 'printing' else hx('5a3a32'))
    for i in range(3):
        P.r(76 + i * 6, oy + 20, 4, 4, hx('8a867c'))
        P.r(76 + i * 6, oy + 20, 4, 1, hx('d0ccc0'))
    # 出纸格栅
    for i in range(12):
        P.r(36 + i * 2, oy + 28, 1, 2, body_d)
    if out:
        slip = violation_slip(78, out + 7, torn_top=True, short=True)
        img.alpha_composite(slip, (11, 0))
    return img


# ───────────── 文件盒（待处理） ─────────────
def file_box(n=6):
    """牛皮纸文件盒，从斜上方看：后壁、两侧、里面一摞简历（剩得越多纸面越高、纸边越多），前壁贴一张白标签（游戏在上面写“待处理 N”）。"""
    W, H = 84, 60
    img = Image.new('RGBA', (W + 2, H + 2))
    P = Pix(img)
    P.r(2, 2, W, H, (0, 0, 0, 140))
    k, kd, kl, kdd = hx('b08a5a'), hx('8a6a40'), hx('caa676'), hx('5a4428')
    FRONT = 40
    # 后壁内侧（背光，暗）和盒底
    P.r(0, 0, W, FRONT, kdd)
    P.r(3, 3, W - 6, 6, hx('6a5232'))
    P.r(0, 0, W, 1, kl)
    P.r(0, 0, 3, FRONT, kd)
    P.r(W - 3, 0, 3, FRONT, kd)
    # 纸：最多十层，一层 3 像素；纸面越往上越高
    layers = min(n, 10)
    if layers:
        top = FRONT - 6 - layers * 3
        for i in range(layers):
            y = FRONT - 3 - i * 3
            P.r(5, y, W - 10, 3, hx('d8d4c8') if i % 2 else hx('cac6ba'))
            P.r(5, y, W - 10, 1, hx('eeeae0'))
        # 最上面那张：只看得见上半截，几行字
        P.r(6, top, W - 12, FRONT - 3 - (layers - 1) * 3 - top, hx('ece8dc'))
        P.r(6, top, W - 12, 1, hx('faf6ec'))
        rnd = random.Random(2)
        greek(P, 12, top + 3, W - 28, hx('8a8e88'), rnd, max(1, min(3, (FRONT - 3 - (layers - 1) * 3 - top - 4) // 3)), 3)
    # 前壁：牛皮纸，上沿一道亮边，正中一张白标签
    P.r(0, FRONT, W, H - FRONT, k)
    P.r(0, FRONT, W, 1, kl)
    P.r(0, H - 1, W, 1, kd)
    for x in range(0, W, 5):
        P.p(x + 2, FRONT + 3 + (x % 3), hx('a4804e'))
    P.r(10, FRONT + 3, W - 20, 14, hx('ece6d0'))
    P.r(10, FRONT + 3, W - 20, 1, hx('fffaf0'))
    P.r(10, FRONT + 16, W - 20, 1, hx('c8c0a8'))
    return img


# ───────────── 印章 ─────────────
INKS = {'pass': hx('2f8a5e'), 'reject': hx('c23a2a'), 'exception': hx('c8901e')}
BODY = {'pass': hx('3e6a54'), 'reject': hx('7a2e26'), 'exception': hx('8a6a22')}
LABEL = {'pass': '通过', 'reject': '拒绝', 'exception': '破格'}


def stamp_tool(kind, lift=0, squash=0):
    """侧视：漆木把手（圆头、细颈、往下张开）、铜箍、方印身、橡胶印面沾着墨。lift：离桌面几像素（影子跟着变）；squash：压下去时印身被压扁几像素。"""
    W, H = 92, 48
    img = Image.new('RGBA', (W, H))
    P = Pix(img)
    ink, body = INKS[kind], BODY[kind]
    base_y = H - 4
    sw = 72 - lift * 4
    P.r((W - sw) // 2, base_y + 1, sw, 3, (0, 0, 0, max(30, 150 - lift * 20)))
    by = base_y - lift
    # 橡胶印面：比印身窄一点，边上沾的墨
    P.r(12, by - 3, 68, 3, hx('2a2622'))
    P.r(12, by - 1, 68, 1, ink)
    P.p(11, by - 1, sh(ink, 0.8))
    P.p(80, by - 1, sh(ink, 0.8))
    # 印身
    bh = 16 - squash
    top = by - 3 - bh
    P.r(10, top, 72, bh, body)
    P.r(10, top, 72, 1, sh(body, 1.4))
    P.r(10, by - 4, 72, 1, sh(body, 0.6))
    P.r(10, top, 1, bh, sh(body, 1.2))
    P.r(81, top, 1, bh, sh(body, 0.7))
    # 标签：白纸贴在印身正面
    lh = min(14, bh - 2)
    P.r(30, top + (bh - lh) // 2, 32, lh, hx('ece8dc'))
    P.r(30, top + (bh - lh) // 2, 32, 1, hx('ffffff'))
    text(img, 34, top + (bh - lh) // 2 + (lh - 14) // 2, LABEL[kind], hx('1e2220'))
    # 铜箍
    P.r(34, top - 3, 24, 3, hx('a8884a'))
    P.r(34, top - 3, 24, 1, hx('e0c070'))
    # 把手：从下往上 张开 → 细颈 → 圆头
    wood, wood_l, wood_d = hx('4a3226'), hx('7a5a44'), hx('2e1e16')
    prof = [20, 16, 12, 9, 8, 8, 8, 9, 12, 14, 14, 14, 12, 8]
    for i, w in enumerate(prof):
        y = top - 4 - i
        x0 = 46 - w // 2
        P.r(x0, y, w, 1, wood)
        P.p(x0, y, wood_d)
        P.p(x0 + w - 1, y, wood_d)
        P.p(x0 + 2, y, wood_l)
    P.r(44, top - 4 - 12, 2, 2, hx('a07a5a'))
    return img


def impression(kind, seed=0, strength=1.0, skew=0, double=0):
    """盖下去的墨迹，透明底。通过 = 圆角双框，拒绝 = 方框加斜杠，破格 = 圆章。
    strength：墨多墨少（越小缺得越多）；skew：盖歪的角度；double：手抖重影的偏移。"""
    rnd = random.Random(seed)
    ink = INKS[kind]
    S = 72
    m = Image.new('L', (S, S), 0)
    d = ImageDraw.Draw(m)
    d.fontmode = '1'
    cx = cy = S // 2
    if kind == 'pass':
        d.rounded_rectangle([cx - 30, cy - 15, cx + 29, cy + 14], 5, outline=255, width=2)
        d.rounded_rectangle([cx - 26, cy - 11, cx + 25, cy + 10], 3, outline=255, width=1)
        d.text((cx - 12, cy - 7), '通过', font=F, fill=255)
    elif kind == 'reject':
        d.rectangle([cx - 30, cy - 15, cx + 29, cy + 14], outline=255, width=3)
        d.text((cx - 12, cy - 7), '拒绝', font=F, fill=255)
        d.line([cx - 26, cy + 11, cx + 25, cy - 12], fill=255, width=1)
    else:
        d.ellipse([cx - 25, cy - 25, cx + 24, cy + 24], outline=255, width=2)
        d.ellipse([cx - 21, cy - 21, cx + 20, cy + 20], outline=255, width=1)
        # 五角星 + 字
        pts = []
        for i in range(10):
            r = 5 if i % 2 == 0 else 2
            a = -math.pi / 2 + i * math.pi / 5
            pts.append((cx + r * math.cos(a), cy - 11 + r * math.sin(a)))
        d.polygon(pts, fill=255)
        d.text((cx - 12, cy - 3), '破格', font=F, fill=255)
        d.text((cx - 12, cy + 7), '', font=F, fill=255)
        d.line([cx - 10, cy + 13, cx + 9, cy + 13], fill=255)
    if skew:
        m = m.rotate(skew, resample=Image.NEAREST)
    out = Image.new('RGBA', (S, S))
    P = Pix(out)
    # 墨量：中间实，边缘和一侧缺；橡胶纹理（小块缺墨）
    side = rnd.uniform(-1, 1)
    holes = set()
    for _ in range(int(70 * (1.25 - strength))):
        hx0, hy0 = rnd.randrange(S), rnd.randrange(S)
        for _ in range(rnd.randint(2, 6)):
            holes.add((hx0 + rnd.randint(-2, 2), hy0 + rnd.randint(-1, 1)))
    for y in range(S):
        for x in range(S):
            if m.getpixel((x, y)) < 128:
                continue
            fade = 0.5 + 0.5 * side * (x - cx) / 30
            p = 0.97 * strength - 0.55 * fade * (1.15 - strength)
            if (x, y) in holes or rnd.random() > p:
                continue
            a = int(200 + 50 * rnd.random() * strength)
            c = sh(ink, 0.92 + 0.16 * rnd.random())
            P.p(x, y, c[:3] + (a,))
    if double:
        ghost = out.copy()
        g = Image.new('RGBA', (S, S))
        g.paste(ghost, (double, 1))
        g.putalpha(g.getchannel('A').point(lambda v: v * 45 // 100))
        g.alpha_composite(out)
        out = g
    # 盖得重的地方往外洇一点
    if strength > 0.95:
        for _ in range(10):
            x, y = rnd.randrange(S), rnd.randrange(S)
            if out.getpixel((x, y))[3] > 0:
                P.p(x + rnd.choice([-1, 1]), y, ink[:3] + (90,))
    return out


# ───────────── 纸 ─────────────
def _paper(W, H, col, edge=None, speck=0, seed=0):
    img = Image.new('RGBA', (W + 2, H + 2))
    P = Pix(img)
    P.r(2, 2, W, H, (0, 0, 0, 120))
    P.r(0, 0, W, H, col)
    rnd = random.Random(seed)
    for _ in range(speck):
        P.p(rnd.randrange(W), rnd.randrange(H), sh(col, rnd.choice([0.94, 1.04])))
    if edge:
        P.r(0, 0, W, 1, sh(col, 1.05))
        P.r(0, H - 1, W, 1, sh(col, 0.9))
        P.r(W - 1, 0, 1, H, sh(col, 0.92))
    return img, P, rnd


def resume_paper(W=120, H=90):
    """简历：暖白复印纸，左上角回形针，照片位、横线分栏。"""
    img, P, rnd = _paper(W, H, hx('e8e4d8'), edge=True, speck=W * H // 30, seed=1)
    P.r(8, 8, 18, 22, hx('b8beb8'))
    P.r(8, 8, 18, 1, hx('a0a6a0'))
    greek(P, 32, 10, 60, hx('5a605c'), rnd, 1)
    greek(P, 32, 16, 40, hx('8a908a'), rnd, 2)
    P.r(6, 34, W - 12, 1, hx('b0b4ac'))
    y = 39
    for _ in range(4):
        P.r(8, y, 12, 1, hx('6a706a'))
        greek(P, 26, y, W - 36, hx('8a908a'), rnd, 1)
        y += 6
    greek(P, 8, y + 2, W - 16, hx('9aa09a'), rnd, max(4, (H - y - 10) // 5), 5)
    # 回形针：压在左上角，跨过纸边
    for y in range(-3, 14):
        P.p(4, 1 + y, hx('9aa2aa'))
        P.p(7, 1 + y, hx('c8d0d8'))
    P.r(4, -2, 4, 1, hx('c8d0d8'))
    P.r(5, 14, 2, 1, hx('c8d0d8'))
    return img


def id_copy(W=120, H=72):
    """身份证复印件：灰白，复印机的碳粉麻点，证件外框是灰的，边上一道复印机留下的黑边。"""
    img, P, rnd = _paper(W, H, hx('d4d6d2'), speck=0, seed=2)
    for _ in range(W * H // 7):
        x, y = rnd.randrange(W), rnd.randrange(H)
        P.p(x, y, hx('c4c6c2') if rnd.random() < 0.8 else hx('a8aaa6'))
    P.r(0, 0, 3, H, hx('6a6c68'))
    for y in range(H):
        if rnd.random() < 0.5:
            P.p(3, y, hx('9a9c98'))
    # 证件：圆角灰框
    cx0, cy0, cw, ch = 14, 10, 92, 54
    P.r(cx0 + 1, cy0, cw - 2, ch, hx('bcbeba'))
    P.r(cx0, cy0 + 1, cw, ch - 2, hx('bcbeba'))
    P.r(cx0 + 1, cy0 + 1, cw - 2, ch - 2, hx('c8cac6'))
    P.r(cx0 + cw - 30, cy0 + 8, 22, 28, hx('8a8c88'))
    P.r(cx0 + cw - 26, cy0 + 12, 14, 14, hx('9c9e9a'))
    greek(P, cx0 + 6, cy0 + 8, 50, hx('6a6c68'), rnd, 4, 6)
    P.r(cx0 + 6, cy0 + ch - 9, 70, 2, hx('5a5c58'))
    # 复印出来的“仅供 XX 使用”手写斜字：用一道蓝灰笔画代替
    for i in range(40):
        P.p(cx0 + 20 + i, cy0 + 40 - i // 5, hx('4a5a8a'))
    return img


def handbook(W=120, H=90):
    """招聘规范手册：淡绿内页，左边黑色线圈，右边伸出一个彩色索引签。"""
    img, P, rnd = _paper(W, H, hx('d8dfd0'), edge=True, speck=W * H // 40, seed=3)
    P.r(0, 0, W, 12, hx('3e5a4e'))
    P.r(14, 4, 46, 1, hx('d8dfd0'))
    P.r(14, 7, 30, 1, hx('a8c0b0'))
    # 线圈
    for y in range(6, H - 4, 7):
        P.r(-2, y, 9, 2, hx('1a1c1c'))
        P.p(-1, y, hx('6a6e6e'))
        P.r(8, y, 2, 2, hx('6a706a'))
    greek(P, 14, 18, W - 26, hx('4a5650'), rnd, 1)
    greek(P, 14, 24, W - 26, hx('7a8680'), rnd, 4, 5)
    # 新加的一条：黄底
    P.r(12, 48, W - 22, 18, hx('e8d070'))
    greek(P, 15, 51, W - 30, hx('5a4a1a'), rnd, 3, 5)
    greek(P, 14, 72, W - 26, hx('7a8680'), rnd, max(3, (H - 80) // 5), 5)
    # 索引签
    P.r(W - 1, 20, 5, 10, hx('c8402f'))
    P.r(W - 1, 34, 5, 10, hx('e8c84a'))
    P.r(W - 1, 48, 5, 10, hx('4f7f68'))
    return img


def jd_paper(W=106, H=90):
    """岗位 JD：激光打印的冷白纸，公司抬头（蜂巢六边形），左上角一颗订书钉。"""
    img, P, rnd = _paper(W, H, hx('e6eaec'), edge=True, seed=4)
    P.r(0, 0, W, 14, hx('e8c84a'))
    # 六边形
    for i, w in enumerate([3, 5, 7, 7, 5, 3]):
        P.r(8 - w // 2, 4 + i, w, 1, hx('2a2e2c'))
    P.r(16, 5, 30, 1, hx('2a2e2c'))
    P.r(16, 8, 20, 1, hx('5a5a40'))
    greek(P, 6, 20, W - 12, hx('3a3e40'), rnd, 1)
    P.r(6, 26, 40, 1, hx('c8402f'))
    y = 32
    for _ in range(5):
        P.p(7, y, hx('3a3e40'))
        greek(P, 10, y, W - 22, hx('6a7074'), rnd, 1)
        y += 6
    greek(P, 6, y + 4, W - 12, hx('9aa0a4'), rnd, max(3, (H - y - 10) // 5), 5)
    # 订书钉
    P.r(4, 3, 7, 1, hx('a0a4a8'))
    P.p(4, 4, hx('6a6e72'))
    P.p(10, 4, hx('6a6e72'))
    return img


def violation_slip(W=78, H=90, torn_top=False, short=False):
    """违规单：针式打印的连续纸，两边齿孔，淡绿横条，顶上一道撕开的锯齿。"""
    img = Image.new('RGBA', (W + 2, H + 2))
    P = Pix(img)
    P.r(2, 2, W, H, (0, 0, 0, 110))
    base = hx('eeecdc')
    P.r(0, 0, W, H, base)
    for y in range(0, H, 12):
        P.r(8, y + 6, W - 16, 6, hx('d8e6d0'))
    for y in range(3, H, 6):
        for x in (2, W - 5):
            P.r(x, y, 3, 3, hx('3a403c'))
            P.r(x, y, 3, 1, hx('1a1e1c'))
    P.r(7, 0, 1, H, hx('d0ceb8'))
    P.r(W - 8, 0, 1, H, hx('d0ceb8'))
    if torn_top:
        for x in range(W):
            if (x // 2) % 2 == 0:
                P.p(x, 0, (0, 0, 0, 0))
    rnd = random.Random(5)
    # 点阵字：红抬头、黑正文
    for x in range(12, 46, 2):
        P.p(x, 4, hx('c23a2a'))
        P.p(x + 1, 5, hx('c23a2a'))
    if not short:
        for row in range(6):
            y = 12 + row * 6
            for x in range(12, 12 + rnd.randint(30, W - 26), 2):
                if rnd.random() < 0.85:
                    P.p(x, y, hx('3a3e3a'))
                    P.p(x + (row % 2), y + 1, hx('3a3e3a'))
        # 罚款金额：粗一点
        for x in range(12, 40):
            if x % 2 == 0:
                P.r(x, 52, 1, 3, hx('1a1e1a'))
        for x in range(10, W - 10, 3):
            P.p(x, H - 6, hx('9a9a88'))
    else:
        for row in range(2):
            for x in range(12, 50, 2):
                P.p(x, 10 + row * 4, hx('3a3e3a'))
    return img


def agreement(W=120, H=90):
    """协商解除劳动合同协议书：厚一点的米色 A4，标题居中，右下折角，左上两颗订书钉，乙方签名栏空着。"""
    img, P, rnd = _paper(W, H, hx('f0ece0'), edge=True, speck=W * H // 40, seed=6)
    P.r(30, 7, 60, 2, hx('2a2826'))
    P.r(40, 12, 40, 1, hx('7a7670'))
    greek(P, 10, 20, W - 20, hx('6a6660'), rnd, 6, 5)
    # 补偿那一格：方框
    P.r(10, 52, W - 20, 12, hx('e4dccc'))
    P.r(10, 52, W - 20, 1, hx('9a948a'))
    P.r(10, 63, W - 20, 1, hx('9a948a'))
    P.r(14, 56, 26, 1, hx('3a3632'))
    P.r(70, 55, 20, 3, hx('3a3632'))
    # 甲方公章：淡红圆
    cx, cy = 30, 76
    for a in range(0, 360, 6):
        P.p(cx + 9 * math.cos(math.radians(a)), cy + 9 * math.sin(math.radians(a)), hx('d07060'))
    P.r(cx - 2, cy - 2, 4, 4, hx('d88878'))
    # 乙方签名栏：空线
    P.r(70, 80, 38, 1, hx('5a5650'))
    # 订书钉两颗
    for y in (4, 9):
        P.r(4, y, 1, 6, hx('a0a4a8'))
    # 折角
    for i in range(10):
        P.r(W - 10 + i, H - 1 - i, 10 - i, 1, (0, 0, 0, 0))
        P.r(W - 10, H - 10 + i, i + 1, 1, hx('d8d2c0'))
    for i in range(10):
        P.p(W - 10 + i, H - 1 - i, hx('b8b2a0'))
    return img


def sticky(W=124, H=30, msg='附言：第一次投简历'):
    """黄色附言小纸条：便利贴，顶上一条胶，右下角翘起来（影子）。"""
    img = Image.new('RGBA', (W + 3, H + 3))
    P = Pix(img)
    P.r(2, 3, W, H, (0, 0, 0, 100))
    col = hx('f0d45a')
    P.r(0, 0, W, H, col)
    P.r(0, 0, W, 4, hx('e4c64a'))
    for y in range(H):
        for x in range(W - 7, W):
            if x - (W - 7) + y - (H - 7) > 6:
                P.p(x, y, (0, 0, 0, 0))
    for i in range(7):
        P.r(W - 7 + i, H - 1 - (6 - i) + (6 - i), 1, 1, hx('d8b840'))
    for i in range(7):
        P.p(W - 7 + i, H - 1 - i + 0, hx('c8a830'))
    text(img, 4, 8, msg, hx('3a3010'))
    return img


# ───────────── 抽屉 ─────────────
def drawer_closed(W=96, H=22):
    img = Image.new('RGBA', (W, H))
    P = Pix(img)
    P.r(0, 0, W, H, hx('242b28'))
    P.r(0, 0, W, 1, hx('3a4440'))
    P.r(2, 3, W - 4, H - 5, hx('2c3431'))
    P.r(2, 3, W - 4, 1, hx('3e4844'))
    # 拉手 + 锁眼
    P.r(W // 2 - 12, 9, 24, 3, hx('8a8a84'))
    P.r(W // 2 - 12, 9, 24, 1, hx('c8c8c0'))
    P.r(W - 14, 9, 3, 4, hx('b0904a'))
    P.p(W - 13, 10, hx('1a1a1a'))
    P.p(W - 13, 11, hx('1a1a1a'))
    return img


def drawer_open(W=300, H=136, items=('book', 'mail', 'envelope', 'envelope', 'card')):
    """拉开的抽屉，俯视：深色木底、侧板，证据一样一样压着放。"""
    img = Image.new('RGBA', (W + 2, H + 2))
    P = Pix(img)
    P.r(2, 2, W, H, (0, 0, 0, 150))
    P.r(0, 0, W, H, hx('2c2420'))
    P.r(6, 6, W - 12, H - 12, hx('3a2e26'))
    rnd = random.Random(8)
    for y in range(6, H - 6):
        if y % 4 == 0:
            P.r(6, y, W - 12, 1, hx('34291f'))
    P.r(0, H - 8, W, 8, hx('242b28'))
    P.r(W // 2 - 14, H - 6, 28, 3, hx('8a8a84'))
    # 信封：牛皮纸，压在最底下
    def envelope(x, y, amt):
        P.r(x, y, 60, 34, hx('c8a46a'))
        P.r(x, y, 60, 1, hx('dcbc84'))
        for i in range(30):
            P.p(x + i, y + i // 2, hx('a88850'))
            P.p(x + 59 - i, y + i // 2, hx('a88850'))
        text(img, x + 6, y + 18, amt, hx('5a3a1a'))
    envelope(16, 60, '¥300')
    envelope(30, 92, '¥100')
    # 小刘家的购物卡
    P.r(254, 90, 34, 22, hx('c8402f'))
    P.r(254, 90, 34, 1, hx('e86a5a'))
    P.r(258, 96, 16, 2, hx('e8c84a'))
    P.r(258, 104, 22, 1, hx('f0c0b0'))
    # 王总邮件打印件：A4 白纸，斜放
    mail = Image.new('RGBA', (80, 96), hx('eef0f0'))
    mp = Pix(mail)
    mp.r(0, 0, 80, 10, hx('d8dcdc'))
    greek(mp, 4, 3, 50, hx('5a6060'), rnd, 1)
    greek(mp, 4, 14, 70, hx('6a7070'), rnd, 8, 5)
    mp.r(4, 30, 46, 5, hx('f0e080'))
    mail = mail.rotate(-6, expand=True, resample=Image.NEAREST)
    img.alpha_composite(mail, (100, 18))
    # 老周的手抄规则本：深蓝硬皮本，贴满小标签
    P.r(178, 20, 64, 84, hx('1e2a44'))
    P.r(178, 20, 64, 1, hx('3a4a6a'))
    P.r(180, 22, 2, 80, hx('16203a'))
    P.r(190, 32, 40, 12, hx('e8e4d8'))
    text(img, 192, 31, '规则', hx('1e2a44'))
    for i, c in enumerate(['e8c84a', '7fd6a4', 'c8402f', 'e8c84a', 'f0f0e0', '7fd6a4']):
        P.r(242, 26 + i * 12, 5, 7, hx(c))
    return img

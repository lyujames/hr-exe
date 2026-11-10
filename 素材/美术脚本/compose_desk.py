import sys
from PIL import Image, ImageDraw
from faces import hx
import desk_art as A

F = A.F
DESK = hx('2b3230')
DARK = hx('1f2523')
GREEN = hx('7fd6a4')
GREEN_DIM = hx('4f7f68')
TEXT = hx('d7dfda')
DIM = hx('8c9992')
YELLOW = hx('e8c84a')
RED = hx('c8402f')

SW = 930
img = Image.new('RGBA', (SW, 2400), hx('262c2a'))
d = ImageDraw.Draw(img)
d.fontmode = '1'


def t(x, y, s, c=TEXT):
    d.text((x, y), s, font=F, fill=c)


def wrap(s, w):
    out, line = [], ''
    for ch in s:
        if F.getlength(line + ch) > w and ch not in '，。、：；）”》……':
            out.append(line)
            line = ch
        else:
            line += ch
    if line:
        out.append(line)
    return out


def para(x, y, s, w, c=TEXT, lh=15):
    for ln in wrap(s, w):
        t(x, y, ln, c)
        y += lh
    return y


def mark(x, y, n):
    d.rectangle([x, y, x + 9, y + 11], fill=RED)
    t(x + 2, y - 1, str(n), hx('ffffff'))


def frame(x, y, w, h, fill=DESK):
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=fill, outline=GREEN_DIM)


def notes(x, y, items, w=250, tail=None, start=1):
    for i, s in enumerate(items):
        mark(x, y + 2, i + start)
        y = para(x + 16, y, s, w - 16) + 6
    if tail:
        y = para(x, y + 2, tail, w, DIM)
    return y


def paste(im, x, y, k=1):
    if k != 1:
        im = im.resize((im.width * k, im.height * k), Image.NEAREST)
    img.alpha_composite(im, (int(x), int(y)))


L, NX = 8, 660
t(L, 4, '样板图 · 桌面一屏：桌面、全家福、手机、打印机、文件盒、印章、抽屉 / 七种纸 / 印章墨迹（640×360 原尺寸，按 2 倍放大看）', GREEN)

# ── 一、桌面全景 ──
y = 24
t(L, y, '一 · 桌面全景（第 3 天上午，东西都在默认位置）', DIM)
ay = y + 18
frame(L - 1, ay - 1, 642, 362)
desk = A.desk_bg()
dp = A.Pix(desk)
# 顶上状态条照旧
dp.r(0, 0, 640, 18, DARK)
dd = ImageDraw.Draw(desk)
dd.fontmode = '1'
dd.text((6, 2), '第 3 天   2026-03-04', font=F, fill=TEXT)
dd.text((304, 2), '08:01', font=F, fill=GREEN)
dd.text((468, 2), '存款 ¥200 / 月供 ¥1750', font=F, fill=TEXT)
dd.text((10, 22), '待处理 6', font=F, fill=TEXT)
desk.alpha_composite(A.file_box(6), (6, 38))
desk.alpha_composite(A.family_photo(), (10, 106))
desk.alpha_composite(A.phone('down'), (34, 174))
desk.alpha_composite(A.stamp_tool('exception'), (2, 284))
desk.alpha_composite(A.drawer_closed(), (0, 336))
desk.alpha_composite(A.resume_paper(226, 252), (104, 26))
desk.alpha_composite(A.sticky(), (106, 272))
desk.alpha_composite(A.handbook(184, 210), (346, 26))
desk.alpha_composite(A.jd_paper(102, 228), (534, 26))
desk.alpha_composite(A.id_copy(168, 70), (350, 246))
desk.alpha_composite(A.printer('idle'), (536, 262))
desk.alpha_composite(A.stamp_tool('pass'), (112, 306))
desk.alpha_composite(A.stamp_tool('reject'), (216, 306))
paste(desk, L, ay)
mark(L + 336, ay + 290, 1)
mark(L + 88, ay + 30, 2)
mark(L + 82, ay + 100, 3)
mark(L + 66, ay + 172, 4)
mark(L + 98, ay + 340, 5)
mark(L + 626, ay + 250, 6)
mark(L + 312, ay + 312, 7)
notes(NX, ay, [
    '桌面：还是现在这一系深灰绿（2b3230 附近），加质感：三聚氰胺板的细斑点、几道浅划痕，台灯在右上，右上亮、左下暗。',
    '文件盒：牛皮纸档案盒，剩几份简历就露几层纸边，不看数字也知道今天还剩多少。',
    '全家福放大到 72×56（现在 64×50），见下面特写。',
    '手机平时扣着，背面朝上；来消息才翻过来亮屏。',
    '抽屉在左下角：拉手、锁眼。第三个月起往里放东西，点开是下面那张俯视图。',
    '打印机：针式，违规单从顶上一截一截吐出来。',
    '印章：漆木把手、铜箍、印身贴标签，三种颜色也是三种印形。',
], tail='简历底下垫一块深绿皮台垫，四角压皮。盖章那块被磨得发亮。整张桌子都是旧的，用了好些年。')

# ── 二、物件特写 ──
y = ay + 360 + 14
t(L, y, '二 · 物件特写（放大看细节；游戏里按 1 倍画）', DIM)
by = y + 18
bh = 470
frame(L, by, 640, bh)
# 全家福 3 倍
paste(A.family_photo(), L + 10, by + 10, 3)
t(L + 10, by + 190, '全家福 72×56（×3）', DIM)
mark(L + 10, by + 8, 1)
# 手机两态 2 倍
px0 = L + 250
ph_down = A.phone('down')
ph_lit = A.phone('lit')
paste(ph_down, px0, by + 16, 2)
lit_canvas = Image.new('RGBA', (44, 56))
lit_canvas.alpha_composite(ph_lit, (6, 0))
A.buzz(lit_canvas, 6, 18, 12)
paste(lit_canvas, px0 + 76, by + 16, 2)
t(px0, by + 130, '扣着', DIM)
t(px0 + 88, by + 130, '来消息：', YELLOW)
t(px0 + 88, by + 144, '翻过来、震两下', YELLOW)
mark(px0 + 160, by + 14, 2)
# 打印机两态 2 倍
pr = L + 250
paste(A.printer('idle'), pr, by + 158, 2)
paste(A.printer('printing', 24), L + 40, by + 230, 2)
t(pr, by + 228, '待机：绿灯', DIM)
t(L + 40, by + 350, '打印违规单：红灯，纸一截一截往上走', YELLOW)
mark(L + 230, by + 228, 3)
# 文件盒：剩两份 / 剩九份
fx = L + 470
paste(A.file_box(9), fx, by + 10)
paste(A.file_box(2), fx, by + 84)
t(fx + 92, by + 34, '九份', DIM)
t(fx + 92, by + 108, '两份', DIM)
mark(fx - 14, by + 10, 4)
# 抽屉：关 / 开
paste(A.drawer_closed(), L + 290, by + 252, 2)
t(L + 290, by + 302, '关着', DIM)
paste(A.drawer_open(), L + 330, by + 326 - 0)
t(L + 290, by + 446, '拉开（第三个月末）', YELLOW)
mark(L + 618, by + 324, 5)
notes(NX, by, [
    '全家福是你自己的家：公园长椅，你爸坐中间，你站左后、手搭他肩上，老婆站右后，孩子在前。和第 1 天的伏笔对上：孩子攥着跳绳（“一分钟一百六十个”），缺颗门牙在笑（“牙刚补完”）；老婆的齐肩发、项链、绿上衣和回家那一屏是同一套。右下角橙色日期 25 10 03：去年国庆，你爸还没生病。第二个月他“比上次见瘦了一圈”，回头看这张就对上了。主角也只在这张照片里露脸。',
    '手机壳背面贴着孩子贴的小火箭。亮屏只显示时间和“谁发来的”，点开才看内容。',
    '打印机：待机绿灯；打印时红灯，纸每截往上走 6px，带齿孔。',
    '文件盒：剩几份就叠几层纸边。',
    '抽屉拉开是俯视图，结局直接用它。信封压在最底下（李哲他爸 ¥300、表哥 ¥100），老周的手抄规则本贴满小标签，王总邮件的打印件上有一道荧光笔，小刘家的购物卡是红的。东西是按游戏里实际放进去的生成，没有的就不画。',
])

# ── 三、纸张 ──
y = by + bh + 14
t(L, y, '三 · 七种纸：一眼分得出是哪种，靠纸色加一个标志，不靠读字', DIM)
cy = y + 18
ch = 286
frame(L, cy, 640, ch)
papers = [
    ('简历', '暖白 + 回形针', A.resume_paper()),
    ('身份证复印件', '灰 + 碳粉麻点 + 复印黑边', A.id_copy()),
    ('规则手册', '淡绿 + 线圈 + 索引签', A.handbook()),
    ('岗位 JD', '冷白 + 黄抬头 + 订书钉', A.jd_paper()),
    ('违规单', '连续纸 + 齿孔 + 绿横条', A.violation_slip()),
    ('协议书', '米色厚纸 + 两颗钉 + 折角', A.agreement()),
    ('附言小纸条', '便利贴 + 翘角', A.sticky()),
]
pos = [(10, 10), (168, 10), (326, 10), (484, 10), (10, 146), (168, 146), (326, 170)]
for (name, sub, im), (x, yy) in zip(papers, pos):
    paste(im, L + x, cy + yy)
    t(L + x, cy + yy + im.height + 1, name, TEXT)
    t(L + x, cy + yy + im.height + 15, sub, DIM)
# 违规单那张说明在它右边空着，补一张“简历盖了章”的样子放右下
res = A.resume_paper()
res.alpha_composite(A.impression('reject', 4, 0.85, -5), (40, 10))
paste(res, L + 484, cy + 146)
t(L + 484, cy + 146 + res.height + 1, '盖过章的简历', TEXT)
notes(NX, cy, [
    '简历：暖白复印纸，回形针夹在左上角、伸出纸边。',
    '身份证复印件：灰，碳粉麻点，左边一道复印机的黑边，证件外框也是灰的，上面一道“仅供应聘使用”的蓝笔。',
    '规则手册：淡绿内页，左边黑线圈，右边伸出红黄绿三个索引签。新加的规则是黄底。',
    'JD：冷白激光纸，黄色公司抬头带蜂巢六边形，左上角一颗订书钉。',
    '违规单：针式打印的连续纸，两边齿孔，淡绿横条，顶上一道撕开的锯齿，字是点阵的。',
    '协议书：米色厚纸，两颗订书钉，右下折角。甲方的章已经盖好，乙方签字那栏空着。',
    '附言小纸条：黄色便利贴，顶上的胶条颜色深一点，右下角翘起来，有影子。',
])

# ── 四、印章 ──
y = cy + ch + 14
t(L, y, '四 · 印章：三种印形、每次不一样的墨迹、盖下去的四帧', DIM)
sy = y + 18
shh = 540
frame(L, sy, 640, shh)
for i, k in enumerate(['pass', 'reject', 'exception']):
    paste(A.stamp_tool(k), L + 10 + i * 210, sy + 8, 2)
mark(L + 10, sy + 6, 1)
# 墨迹：每行一种章，列：正常 / 墨少 / 盖歪 / 手抖重影 / 盖在简历上
cols = ['正常', '墨少', '盖歪', '按得急：重影', '盖在简历上']
gy = sy + 116
for j, c in enumerate(cols):
    t(L + 14 + j * 124, gy, c, DIM)
paper_bg = hx('e8e4d8')
for i, k in enumerate(['pass', 'reject', 'exception']):
    row_y = gy + 16 + i * 84
    for j in range(5):
        x = L + 10 + j * 124
        d.rectangle([x, row_y, x + 112, row_y + 78], fill=paper_bg)
        if j == 4:
            rr = A.Pix(img)
            rnd = A.random.Random(i)
            for q in range(7):
                A.greek(rr, x + 6, row_y + 6 + q * 10, 100, hx('8a908a'), rnd, 1)
        args = [(1.0, 0, 0), (0.62, 0, 0), (0.95, 4 if i != 1 else -4, 0), (0.9, -2, 3), (0.9, -3, 0)][j]
        imp = A.impression(k, seed=i * 10 + j, strength=args[0], skew=args[1], double=args[2])
        img.alpha_composite(imp, (x + 20, row_y + 3))
mark(L + 10 + 124 + 100, gy + 14, 2)
mark(L + 10 + 124 * 3 + 100, gy + 14, 3)
# 盖章四帧
fy = gy + 16 + 3 * 84 + 6
t(L + 10, fy, '盖章四帧（拒绝章）', DIM)
seq = [(10, 0, False, '悬空'), (3, 0, False, '落下'), (0, 4, False, '压扁：咚'), (9, 0, True, '抬起，墨迹留下')]
for i, (lift, sq, show, lab) in enumerate(seq):
    x = L + 10 + i * 156
    cell = Image.new('RGBA', (120, 100), (0, 0, 0, 0))
    cp = A.Pix(cell)
    cp.r(0, 64, 120, 36, hx('d8d4c8') if sq else paper_bg)
    if show:
        imp = A.impression('reject', seed=77, strength=0.9, skew=-3).crop((4, 19, 68, 53))
        cell.alpha_composite(imp, (28, 65))
    st = A.stamp_tool('reject', lift=lift, squash=sq)
    cell.alpha_composite(st, (14, 64 - 44 - 0))
    if sq:
        for k in range(4):
            cp.p(10 - k * 2, 60 - k, hx('c23a2a'))
            cp.p(110 + k * 2, 60 - k, hx('c23a2a'))
            cp.p(8 - k, 64 + k, hx('c23a2a'))
    paste(cell, x, fy + 16)
    t(x, fy + 120, lab, YELLOW if i == 2 else DIM)
mark(L + 10 + 2 * 156 + 110, fy + 14, 4)
notes(NX, sy, [
    '三个章三种印形：通过是圆角双框，拒绝是方框带一道斜杠，破格是带星的圆章（像公章，是“特批”的分量）。色弱的玩家看形状也分得开。',
    '墨迹每盖一次都不一样：随机抽墨量、缺墨的位置、歪 ±4°。盖得多了印泥变淡，一天里越往后章越浅，下班前那几份能看出来。',
    '拖得快、松手急的那一下出重影。盖在简历上的墨迹半透明，压着字，字还看得见。',
    '盖章四帧，一共约 0.25 秒：悬空（影子大而淡）→ 落下（影子收紧）→ 压扁 4px，纸面一暗，墨点溅开，配“咚”和一下屏幕震 1px → 抬起，墨迹留在纸上。',
], tail='墨色比 UI 的绿、红、黄暗一点、灰一点（通过 2f8a5e、拒绝 c23a2a、破格 c8901e），像真的印泥，不像按钮。')

final_h = sy + shh + 8
img = img.crop((0, 0, SW, final_h))
img.resize((SW * 2, final_h * 2), Image.NEAREST).save(sys.argv[1])
print(sys.argv[1], img.size)

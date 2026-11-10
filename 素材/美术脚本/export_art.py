"""把样板图的画法导出成游戏用的图：
portraits/<key>.png   320×64，五帧：平常 / 眨眼 / 看左 / 看右 / 冒汗（对应 PortraitFactory.Frame）
portraits/pool_m.png, pool_f.png   随机路人，每行一个人五帧
portraits/bust_<key>.png   640×128，半身像五帧
home/home_1930.png 等   回家一屏的场景
"""
import os
import random
import sys
from PIL import Image
from faces import draw_face, hx
from female import draw_female
from cast import CAST, STAFF
from fcast import FEMALE
from bust_f import bust as bust_hejing
from scene import scene

OUT = sys.argv[1]
os.makedirs(f'{OUT}/portraits', exist_ok=True)
os.makedirs(f'{OUT}/home', exist_ok=True)

N = dict(brows='flat', eyes='normal', mouth='flat')
SM = dict(brows='flat', eyes='normal', mouth='smile')


def frames(f1):
    return [f1, {**f1, 'eyes': 'closed'}, {**f1, 'eyes': 'side_l'}, {**f1, 'eyes': 'side_r'}, {**f1, 'sweat': True}]


def strip(spec, female, f1=None):
    img = Image.new('RGBA', (320, 64))
    draw = draw_female if female else draw_face
    for i, ex in enumerate(frames(f1 or spec['f1'])):
        draw(img, i * 64, 0, spec, ex)
    return img


# ── 剧情里有名字的人 ──
by_name_m = {c['name']: c for c in CAST + STAFF if not c.get('female')}
by_name_f = {}
for c in FEMALE:
    by_name_f.setdefault(c['name'], c)
shenwen_photo = [c for c in FEMALE if c['name'] == '沈雯'][0]
shenwen_now = [c for c in FEMALE if c['name'] == '沈雯'][1]

MALE_EXTRA = {
    '程野': dict(skin='e0bf9c', hair='1e1c1c', hair_style='side_part', cloth='4a5a4a', cloth_style='hoodie', hw=12.5, H=30, jaw=4, f1=N),
    '宋知遥': dict(skin='e8cbb0', hair='22201e', hair_style='messy', cloth='2a3a5a', cloth_style='hoodie', hw=12, H=29, jaw=5, f1=N),
    '孙浩': dict(skin='dcb494', hair='1a1a1c', hair_style='slick', cloth='e4e6ee', cloth_style='shirt', collar='f4f4f8', hw=13, H=30, jaw=3, f1=SM),
    '魏来': dict(skin='c99b78', hair='1e1e1e', hair_style='crew', cloth='3a5068', cloth_style='shirt', collar='4a6078', stubble=True, hw=13.5, H=30, jaw=3, f1=N),
    '李哲': dict(skin='e6c8aa', hair='1c1c20', hair_style='side_part', cloth='2a2e3a', cloth_style='suit', tie='2a4a8a', hw=12, H=29, jaw=5, f1=N),
    '王凯': dict(skin='cfa585', hair='2a2826', hair_style='receding', cloth='5a5048', cloth_style='polo', collar='6a6058', lines=True, bags=True, hw=13.5, H=31, jaw=2, f1=N),
    '顾全': dict(skin='ecd2b8', hair='141418', hair_style='slick', cloth='2a2e3a', cloth_style='suit', tie='6a2a2a', hw=12, H=29, jaw=5, f1=SM),
    '林川': dict(skin='e0c0a0', hair='1c1c1e', hair_style='crew', cloth='3a4a5a', cloth_style='hoodie', glasses='black', hw=12.5, H=30, jaw=3, f1=N),
    '唐敏': dict(skin='d8b494', hair='22201e', hair_style='messy', cloth='5a6a8a', cloth_style='check', bags=True, hw=13, H=30, jaw=3, f1=N),
    '许言': dict(skin='dcb898', hair='1a1a1a', hair_style='side_part', cloth='d4d8d2', cloth_style='shirt', collar='e4e8e2', hw=13, H=31, jaw=2, f1=N),
    '叶青': dict(skin='ecd0b8', hair='2a2422', hair_style='tied', cloth='6a5a8a', cloth_style='hoodie', hw=12, H=29, jaw=5, f1=N),
}

NAMED = {
    'fangxiao': ('方晓', True), 'qinxiaoman': ('覃小满', True), 'hejing': ('何静', True),
    'qiaoan': ('乔安', True), 'zhouyining': ('周以宁', True), 'hanlei': ('韩蕾', True), 'gemin': ('葛敏', True),
    'lixiuying': ('李秀英', True), 'zhoulan': ('周岚', True),
    'xujiahe': ('许嘉禾', False), 'sujianqing': ('苏见青', False), 'chenmo': ('陈默', False), 'shaodong': ('邵东', False),
    'liuziang': ('刘子昂', False), 'wangzong': ('王总', False), 'zhao': ('赵主管', False), 'laozhou': ('老周', False),
    'xiaomeng': ('小孟', False),
    'chengye': ('程野', False), 'songzhiyao': ('宋知遥', False), 'sunhao': ('孙浩', False), 'weilai': ('魏来', False),
    'lizhe': ('李哲', False), 'wangkai': ('王凯', False), 'guquan': ('顾全', False), 'linchuan': ('林川', False),
    'tangmin': ('唐敏', False), 'xuyan': ('许言', False), 'yeqing': ('叶青', False),
}
for key, (name, female) in NAMED.items():
    spec = by_name_f[name] if female else (by_name_m.get(name) or MALE_EXTRA[name])
    # 平常那帧不带剧情表情：f1 里只保留眉眼嘴
    strip(spec, female).save(f'{OUT}/portraits/{key}.png')
strip(shenwen_now, True).save(f'{OUT}/portraits/shenwen.png')
strip(shenwen_photo, True).save(f'{OUT}/portraits/shenwen_photo.png')

# ── 随机路人：同一套画法、同一套部件 ──
SKINS = ['f0d6c0', 'ecc8a8', 'e6c4a6', 'e0c0a2', 'dcb494', 'd8b292', 'cfa585', 'c99b78']
HAIRS = ['1c1a1a', '2a2022', '3a2620', '2c2422', '4a3428', '1e1c1e']
CLOTH = ['3b4a57', '4a4f55', '2f3a3a', '57606a', '39453f', '6a5a4a', '5a6a7a', '7a5a6a', 'a87478', 'd0c8b8', '2a2e34', '8a9a7a']
MOUTHS = ['flat', 'flat', 'smile']
rnd = random.Random(20260301)
POOL = 24


def male_spec():
    style = rnd.choice(['side_part', 'messy', 'tied', 'crew', 'slick', 'side_part', 'crew', 'receding'])
    s = dict(skin=rnd.choice(SKINS), hair=rnd.choice(HAIRS), hair_style=style,
             cloth=rnd.choice(CLOTH), cloth_style=rnd.choice(['shirt', 'polo', 'hoodie', 'check', 'turtle', 'cardigan', 'shirt']),
             hw=rnd.choice([12, 12.5, 13, 13.5]), H=rnd.choice([29, 30, 31]), jaw=rnd.choice([2, 3, 4, 5]))
    s['collar'] = s['cloth']
    if rnd.random() < 0.35:
        s['glasses'] = rnd.choice(['black', 'metal', 'rimless'])
    if rnd.random() < 0.15:
        s['stubble'] = True
    if style == 'receding':
        s['lines'] = True
    return s


def female_spec():
    s = dict(skin=rnd.choice(SKINS), hair=rnd.choice(HAIRS),
             hair_style=rnd.choice(['ponytail', 'bob', 'long', 'half_up', 'shoulder', 'low_bun', 'curly', 'pixie', 'tucked', 'long', 'shoulder']),
             cloth=rnd.choice(CLOTH), cloth_style=rnd.choice(['shirt', 'hoodie', 'cardigan', 'blouse', 'blazer', 'turtle', 'sport']),
             lip=rnd.choice(['b05a5a', 'b85a5e', 'c05a60', 'a85a5a']), inner='e4e0d8', collar='f0f0ec', tie=rnd.choice(['2a2a2a', '5a6a7a', '6a5a4a']))
    if s['hair_style'] == 'long':
        s['wave'] = rnd.random() < 0.4
        s['part'] = rnd.choice([-3, 0, 3])
    if rnd.random() < 0.6:
        s['hair_hi'] = rnd.choice(['9a7060', 'a07858', '806a70', 'b07a50'])
    if rnd.random() < 0.25:
        s['glasses'] = rnd.choice(['thin', 'black', 'gold'])
    if rnd.random() < 0.3:
        s['earring'] = rnd.choice(['e8c84a', 'f0f0f0', 'c8c8c8'])
    return s


for tag, make, female in (('m', male_spec, False), ('f', female_spec, True)):
    sheet = Image.new('RGBA', (320, 64 * POOL))
    for i in range(POOL):
        sheet.alpha_composite(strip(make(), female, dict(N, mouth=rnd.choice(MOUTHS))), (0, i * 64))
    sheet.save(f'{OUT}/portraits/pool_{tag}.png')

# ── 半身像：何静 ──
b = Image.new('RGBA', (640, 128))
for i, ex in enumerate(frames(dict(brows='flat', eyes='normal', mouth='smile'))):
    b.alpha_composite(bust_hejing(ex), (i * 128, 0))
b.save(f'{OUT}/portraits/bust_hejing.png')

# ── 离职谈话：实习生三人挤在一张桌子前（128×128，五帧）──
def interns(ex_i):
    canvas = Image.new('RGBA', (128, 128), hx('5a6763'))
    left = dict(skin='e8cbb0', hair='1c1c20', hair_style='side_part', cloth='4a5a6a', cloth_style='hoodie', hw=12, H=29, jaw=5)
    right = dict(skin='ecd0b8', hair='2a2022', hair_style='bob', cloth='a87478', cloth_style='cardigan', lip='b85a5e', inner='e4e0d8')
    fx = [c for c in FEMALE if c['name'] == '方晓'][0]
    ex = frames(N)[ex_i]
    exf = frames(dict(brows='worried', eyes='down', mouth='tight'))[ex_i]
    # 不缩放（像素不能拉伸）：两边的人靠后、低一点，方晓在中间、在前面
    for (spec, female, x, y, e2) in ((left, False, -6, 46, ex), (right, True, 70, 46, ex), (fx, True, 32, 40, exf)):
        face = Image.new('RGBA', (64, 64))
        (draw_female if female else draw_face)(face, 0, 0, spec, e2, bg=(0, 0, 0, 0))
        canvas.alpha_composite(face, (x, y))
    # 前面一张桌子，上面摊着一份协议
    from faces import Pix
    P = Pix(canvas)
    P.r(0, 104, 128, 24, hx('5a4a3c'))
    P.r(0, 104, 128, 1, hx('7a6450'))
    P.r(0, 127, 128, 1, hx('3a2e26'))
    P.r(40, 108, 46, 16, hx('f0ece0'))
    P.r(40, 108, 46, 1, hx('ffffff'))
    for yy in (112, 115, 118):
        P.r(44, yy, 30, 1, hx('9a948a'))
    return canvas


strip_i = Image.new('RGBA', (640, 128))
for i in range(5):
    strip_i.alpha_composite(interns(i), (i * 128, 0))
strip_i.save(f'{OUT}/portraits/bust_interns.png')
strip_i.resize((320, 64), Image.NEAREST).save(f'{OUT}/portraits/interns.png')

# ── 回家 ──
for v in ('1930', '2030', '2230'):
    scene(v).save(f'{OUT}/home/home_{v}.png')
print('ok')

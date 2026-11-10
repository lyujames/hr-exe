"""角色设定：每人一套外形 + 两帧表情（第二帧都有剧情理由）。"""

N = {'brows': 'flat', 'eyes': 'normal', 'mouth': 'flat'}

CAST = [
    dict(name='方晓', tag='2004 · 实习', female=True, skin='e6c9ae', hair='2a2224', hair_style='ponytail',
         cloth='dfe2dc', cloth_style='shirt', collar='f2f3ee', hw=12, H=29, jaw=5,
         f1=N, f2=dict(brows='worried', eyes='down', mouth='tight'), f2_note='转正取消：低头'),
    dict(name='覃小满', tag='2004 · 专升本', female=True, skin='d9b08e', hair='3a2a22', hair_style='bob',
         cloth='c79a3a', cloth_style='hoodie', hw=13, H=28, jaw=4, blush=True,
         f1=dict(brows='raised', eyes='normal', mouth='smile'), f2=dict(brows='worried', eyes='wide', mouth='open', sweat=True),
         f2_note='被问学历：冒汗'),
    dict(name='许嘉禾', tag='2004 · 没项目', female=False, skin='e3c4a6', hair='1c1d20', hair_style='side_part',
         cloth='5a7aa8', cloth_style='check', glasses='black', hw=12.5, H=30, jaw=3,
         f1=N, f2=dict(brows='worried', eyes='side_l', mouth='wavy'), f2_note='问到项目：眼神飘'),
    dict(name='苏见青', tag='2005 · 哲学', female=False, skin='e9d2bd', hair='18191c', hair_style='messy',
         cloth='26282a', cloth_style='turtle', bags=True, hw=11.5, H=30, jaw=5,
         f1=N, f2=dict(brows='one_up', eyes='normal', mouth='forced'), f2_note='反问你：挑眉'),
    dict(name='陈默', tag='1996 · 肄业', female=False, skin='c99b78', hair='22201e', hair_style='tied',
         cloth='5c6266', cloth_style='hoodie', stubble=True, hw=13, H=30, jaw=4,
         f1=N, f2=dict(brows='flat', eyes='down', mouth='flat'), f2_note='被问学历：低头'),
    dict(name='何静', tag='1991 · 孩子上小学', female=True, skin='dcb898', hair='2c2422', hair_style='tucked',
         cloth='9a6a6e', cloth_style='cardigan', inner='e2ddd0', bags=True, hw=12.5, H=30, jaw=4,
         f1=dict(brows='flat', eyes='normal', mouth='smile'), f2=dict(brows='worried', eyes='normal', mouth='forced', tired=True),
         f2_note='问婚育：硬撑着笑'),
    dict(name='邵东', tag='1988 · 高级全栈', female=False, skin='cfa585', hair='2a2826', hair_style='receding',
         cloth='2f3c58', cloth_style='polo', collar='3a4a6a', glasses='metal', lines=True, bags=True, hw=13.5, H=31, jaw=3,
         f1=N, f2=dict(brows='worried', eyes='normal', mouth='frown', sweat=True), f2_note='听到“35 岁”：冒汗'),
    dict(name='刘子昂', tag='1999 · 小刘', female=False, skin='e8cbb0', hair='14161a', hair_style='slick',
         cloth='bcd2e8', cloth_style='logo_shirt', collar='d8e6f2', hw=12.5, H=30, jaw=4,
         f1=dict(brows='flat', eyes='normal', mouth='smile'), f2=dict(brows='flat', eyes='side_r', mouth='smile'),
         f2_note='笑着侧眼：暗线'),
]

STAFF = [
    dict(name='王总', tag='老板', female=False, skin='d4a888', hair='1e1e1e', hair_style='back_grey',
         cloth='23262b', cloth_style='suit', tie='6a2a2a', lines=True, hw=14.5, H=31, jaw=1,
         f1=dict(brows='flat', eyes='normal', mouth='smile'), f2=dict(brows='angry', eyes='normal', mouth='smile'),
         f2_note='笑，眼睛不笑'),
    dict(name='赵主管', tag='直属上司', female=False, skin='dcb494', hair='202224', hair_style='crew',
         cloth='3b4a57', cloth_style='shirt', collar='cfd4cf', glasses='rimless', hw=13, H=30, jaw=3,
         f1=N, f2=dict(brows='angry', eyes='side_l', mouth='flat'), f2_note='看手机：不耐烦'),
    dict(name='老周', tag='47 · 前任', female=False, skin='c8a080', hair='8a8d8a', hair_style='grey_thin',
         cloth='6b5a44', cloth_style='vest', readers_up=True, lines=True, bags=True, hw=13, H=31, jaw=3,
         f1=N, f2=dict(brows='worried', eyes='down', mouth='flat'), f2_note='说起闺女：低头'),
    dict(name='小孟', tag='内部系统组长', female=False, skin='e0bf9c', hair='26221f', hair_style='side_part',
         cloth='3f4a44', cloth_style='hoodie', lanyard='4f7f68', glasses='black', hw=12.5, H=29, jaw=4,
         f1=N, f2=dict(brows='raised', eyes='normal', mouth='smile'), f2_note='推眼镜：“不加班”'),
]

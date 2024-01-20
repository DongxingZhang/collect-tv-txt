# -*- coding: utf-8 -*-

import sys
import os

tvlist = [
    "/短刀行",
    "/蝉翼传奇AI修复",
    "/雪山飞狐孟飞",
    "/射雕英雄传朱茵",
    "/士兵突击",
    "/德鲁比",
    "/拳赌双至尊",
    "/上海风云",
    "/洛神",
    "/龙兄虎弟",
    "/圆桌派",
    "/百家讲坛"
]


for tv in tvlist:
    os.system("python3 ./tools/sync.py download  tv /mnt/share1" + tv) 

# -*- coding: utf-8 -*-

import sys
import os

tvlist = [
    ["/射雕英雄传朱茵","/mnt/share1/movies"],
    ["/圆桌派","/mnt/share2/movies"],
    ["/百家讲坛/百家讲坛2021","/mnt/share3/movies/百家讲坛"],
]


for tv in tvlist:
    print('python3 ./tools/sync.py download "' + tv[0] + '" "' + tv[1] + tv[0] + '"') 
    os.system('python3 ./tools/sync.py download "' + tv[0] + '" "' + tv[1] + tv[0] + '"') 

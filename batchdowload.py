# -*- coding: utf-8 -*-

import sys
import os

tvlist = [
    ["/洛神","/mnt/share1/movies"],
    ["/圆桌派","/mnt/share2/movies"],
    ["/百家讲坛","/mnt/share3/movies"],
]


for tv in tvlist:
    os.system("python3 ./tools/sync.py download " + tv[0] + " " + tv[1] + tv[0]) 

# -*- coding: utf-8 -*-

import sys
import os

tvlist = [
    ["/下载5/今晚开放麦2023/","/mnt/data/"],
]#


for tv in tvlist:
    print('python3 ./tools/sync.py download "' + tv[0] + '" "' + tv[1] + tv[0] + '"') 
    os.system('python3 ./tools/sync.py download "' + tv[0] + '" "' + tv[1] + tv[0] + '"') 

# -*- coding: utf-8 -*-

import sys
import os

tvlist = [
    ["/下载10","/mnt/data/tv/dl"],
]#


for tv in tvlist:
    print('python3 ./tools/sync.py download "' + tv[0] + '" "' + tv[1] + tv[0] + '"') 
    os.system('python3 ./tools/sync.py download "' + tv[0] + '" "' + tv[1] + tv[0] + '"') 

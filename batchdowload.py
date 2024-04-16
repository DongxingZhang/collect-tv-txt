# -*- coding: utf-8 -*-

import sys
import os

tvlist = [
    ["/末代皇帝陈道明版","/mnt/data/tv/"],
]#


for tv in tvlist:
    print('python3 ./tools/sync.py download "' + tv[0] + '" "' + tv[1] + tv[0] + '"') 
    os.system('python3 ./tools/sync.py download "' + tv[0] + '" "' + tv[1] + tv[0] + '"') 

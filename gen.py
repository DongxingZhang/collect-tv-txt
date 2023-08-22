# -*- coding: utf-8 -*-

import sys
import os   


if __name__ == '__main__':    
    base_dir = '\\\\192.168.1.3\\Data-Unsecure\\电视剧'
    files = [os.path.join(base_dir, file) for file in os.listdir(base_dir) if os.path.isdir(base_dir + os.sep + file)]
    for file in files:
        filea=file.split("\\")
        filename=filea[-1]
        ##print(filename)
        if not os.path.isdir('\\\\192.168.1.6\\share1\\tv\\'+filename) and not os.path.isdir('\\\\192.168.1.6\\share2\\tv\\'+filename):
            #print("cp -r /mnt/share3/share3/" + filename + ' .')
            print("scp -P 8022 -r  dx@192.168.1.3://mnt/smb/电视剧/" + filename + " .")





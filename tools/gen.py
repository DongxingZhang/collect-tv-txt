# -*- coding: utf-8 -*-

import sys
import os   


def gen():
    base_dir = '\\\\192.168.1.3\\Data-Unsecure\\电视剧'
    files = [os.path.join(base_dir, file) for file in os.listdir(base_dir) if os.path.isdir(base_dir + os.sep + file)]
    for file in files:
        filea=file.split("\\")
        filename=filea[-1]
        ##print(filename)
        if not os.path.isdir('\\\\192.168.1.6\\share1\\tv\\'+filename) and not os.path.isdir('\\\\192.168.1.6\\share2\\tv\\'+filename):
            #print("cp -r /mnt/share3/share3/" + filename + ' .')
            print("scp -P 8022 -r  dx@192.168.1.3://mnt/smb/电视剧/" + filename + " .")

def parseplaylist(playlist, idx):
    playlistn=[]
    line="123"
    with open(playlist, encoding='utf-8') as f2:
        while line: 
            line = f2.readline()
            contentsa = line.split("|")
            if len(contentsa) >= idx + 1:
                tvname=contentsa[idx].split("/")
                filepath=""
                if os.path.isdir('/mnt/share1/tv/' + tvname[-1]):
                    filepath='/mnt/share1/tv/' + tvname[-1]
                elif os.path.isdir('/mnt/share2/tv/' + tvname[-1]):
                    filepath='/mnt/share2/tv/' + tvname[-1]
                elif os.path.isdir('/mnt/share3/tv/' + tvname[-1]):
                    filepath='/mnt/share3/tv/' + tvname[-1]
                else:
                    filepath=""
                if filepath != "":
                    line2=line.replace(contentsa[idx], filepath)
                    playlistn.append(line2)
    return  playlistn

def writeplaylist(playlist, playlist_array):
    with open(playlist, 'w', encoding='utf-8') as f2:
        f2.writelines(playlist_array)
       

def find_new_tv(arg):
    folders = [
        '/mnt/share1/tv/',
        '/mnt/share2/tv/',
        '/mnt/share3/tv/'
    ]
    cont=''
    with open('../list/playlist.txt', encoding='utf-8') as f:
        cont+=f.read()
    with open('../list/playlist2.txt', encoding='utf-8') as f:
        cont+=f.read()
    for dir in folders:
        files = [file for file in os.listdir(dir) if os.path.isdir(dir + os.sep + file)] 
        for filepath in files:
            if not filepath in cont:
                #print(filepath) 
                if arg=="":
                    print("0|000|F|F|F|0|" + filepath + "|" + filepath)
                else:
                    print("0|000|F|F|F|0|" + filepath + "|"+ filepath  +"              from: " + dir)
if __name__ == '__main__':    
    #p1=parseplaylist("./list/playlist.txt", 6)
    #writeplaylist("./list/playlist.txt", p1)
    #p2=parseplaylist("./list/playlist_done.txt", 1)
    #writeplaylist("./list/playlist_done.txt", p2)
    if len(sys.argv) == 1:
        find_new_tv("")
    else:
        find_new_tv(sys.argv[0])
    pass








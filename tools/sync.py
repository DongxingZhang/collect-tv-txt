# -*- coding: utf-8 -*-

from aligo import Aligo
import sys
import os

#定义上传同步函数
def upsync(ali,local_folder,yun_folder):
    #上传同步：1本地为主上传，2并将云端多余的文件删除，3最后再进行一次双端同步
    #1 以本地为主上传
    print('\n以本地为主上传文件\n')
    remote_folder=ali.get_folder_by_path(yun_folder)
    ali.sync_folder(local_folder,remote_folder.file_id,True)
    
    #2 然后比较两端文件差异,比较A和cloud的差异，然后删除cloud文件
    print('\n比较本地文件和云端文件差异，并删除云端多余文件\n')
    # 获取local_folder下的所有文件 # 转为 {文件名:文件路径} 字典模式
    local_files = {}
    for f in os.listdir(local_folder):
        local_file = os.path.join(local_folder, f)
        local_files[f] = local_file
    # 获取remote_folder下的所有文件 # 转为 {文件名:BaseFile对象} 字典模式
    remote_files={}
    for f in ali.get_file_list(remote_folder.file_id):
        remote_file = f.name
        remote_files[remote_file] = f   
    #进行比较,删除云端文件到回收站
    for f in remote_files:
        remote_file = remote_files[f]
        # 如果云端文件存在，且在本地也存在
        if f not in local_files:
            # 本地不存在，删除云端文件
            ali.move_file_to_trash(remote_file.file_id)
            print(f'删除云端文件 {remote_file.name}')
    print('\n云端删除结束\n')
    #再次双端同步以防改动
    print('\n再次双端校验\n')
    ali.sync_folder(local_folder,remote_folder.file_id)
    print('\n双端校验完毕\n')
    
#下载同步，应该以云端为主，将本地没有的文件从云端下载
def downsync(ali,local_folder,yun_folder):
    print('\n以云端为主同步文件\n')
    remote_folder=ali.get_folder_by_path(yun_folder)
    ali.sync_folder(local_folder,remote_folder.file_id,False)
    print('\n云端文件下载完毕\n')
    # 获取local_folder下的所有文件 # 转为 {文件名:文件路径} 字典模式
    local_files = {}
    for f in os.listdir(local_folder):
        local_file = os.path.join(local_folder, f)
        local_files[f] = local_file
    # 获取remote_folder下的所有文件 # 转为 {文件名:BaseFile对象} 字典模式
    remote_files={}
    for f in ali.get_file_list(remote_folder.file_id):
        remote_file = f.name
        remote_files[remote_file] = f 
    print('\n检查本地文件是否需要删除\n')
    #进行比较,删除本地文件到回收站
    print('\n检查本地文件处理完毕\n')


#下载同步，应该以云端为主，将本地没有的文件从云端下载
def downsynccheck(ali,local_folder,yun_folder):
    print('\n以云端为主同步文件\n')
    remote_folder=ali.get_folder_by_path(yun_folder)
    # 获取remote_folder下的所有文件 # 转为 {文件名:BaseFile对象} 字典模式
    remote_files={}
    for f in ali.get_file_list(remote_folder.file_id):
        remote_file = f.name
        remote_files[remote_file] = f
    filecount=len(remote_files)
    cwd = os.getcwd()
    curfile=0
    for f in ali.get_file_list(remote_folder.file_id):
        remote_file = f.name
        remote_file_id = f.file_id
        curfile=curfile+1
        local_file = os.path.join(local_folder, remote_file)
        print("checking " + local_file + " " + str(curfile) + "/" + str(filecount))
        while not os.path.exists(local_file):
            print("start to download " + remote_file + " " + str(curfile) + "/" + str(filecount))
            ali.download_file(file=f, local_folder=local_folder)
            curfile=curfile+1
            print("download completed")
            size = os.path.getsize(local_file)
            if (size < 3000000):
                print(local_file + " size is too small, delete it and retry")
                os.remove(local_file)
                continue

    #ali.sync_folder(local_folder,remote_folder.file_id,False)
    print('\n云端文件下载完毕\n')
    # 获取local_folder下的所有文件 # 转为 {文件名:文件路径} 字典模式
    local_files = {}
    retry_files = {}
    for f in os.listdir(local_folder):
        local_file = os.path.join(local_folder, f)
        size = os.path.getsize(local_file)
        if (size < 5000000):
            os.remove(local_file)
            retry_files[f]  = local_file
            continue
        local_files[f] = local_file
    # 获取remote_folder下的所有文件 # 转为 {文件名:BaseFile对象} 字典模式
    remote_files={}
    for f in ali.get_file_list(remote_folder.file_id):
        remote_file = f.name
        remote_files[remote_file] = f
    print('\n检查本地文件是否需要删除\n')
    #进行比较,删除本地文件到回收站
    #for key, value in retry_files.items():
    print('\n检查本地文件处理完毕\n')


def listsync(ali,yun_folder):
    print('\n以云端为主同步文件\n')
    remote_folder=ali.get_folder_by_path(yun_folder)        
    # 获取remote_folder下的所有文件 # 转为 {文件名:BaseFile对象} 字典模式
    remote_files={}
    for f in ali.get_file_list(remote_folder.file_id):
        remote_file = f.name
        remote_files[remote_file] = f 
        print(yun_folder + "/" + remote_file + "\n")
    


if __name__ == '__main__':    
    print("options: upload download list dlcheck")
    ali = Aligo()    
    print(sys.argv)
    func=sys.argv[1]
    yun_folder=sys.argv[2]
    local_folder=sys.argv[3]
    
    if func == "upload":
        upsync(ali,local_folder,yun_folder)
    elif func == "download":
        downsync(ali,local_folder,yun_folder)
    elif func == "dlcheck":
        downsynccheck(ali,local_folder,yun_folder)
    else:
        listsync(ali,yun_folder)

import urllib.request
import re #正则
import os
from datetime import datetime
import requests
import time
from txt2m3u import m3u_to_txt
import sys
import cv2
import ffmpeg
import numpy as np
import subprocess
from bs4 import BeautifulSoup
import zhconv
import uuid
import sys

def time_str(fmt=None):
    if fmt is None:
        fmt = '%Y%m%d%H%M%S'
    return datetime.now().strftime(fmt)
       

def process_name_string(input_str):
    parts = input_str.split(',')
    processed_parts = []
    for part in parts:
        processed_part = process_part(part)
        processed_parts.append(processed_part)
    result_str = ','.join(processed_parts)
    return result_str

def process_part(part_str):
    # 处理逻辑
    if "CCTV" in part_str:
        part_str=part_str.replace("IPV6", "")  #先剔除IPV6字样
        filtered_str = ''.join(char for char in part_str if char.isdigit() or char == 'K' or char == '+')
        if not filtered_str.strip(): #处理特殊情况，如果发现没有找到频道数字返回原名称
            filtered_str=part_str.replace("CCTV", "")
        return "CCTV-"+filtered_str 
        
    elif "卫视" in part_str or "衛視" in part_str:
        # 定义正则表达式模式，匹配“卫视”后面的内容
        pattern = r'卫视「.*」'
        # 使用sub函数替换匹配的内容为空字符串
        result_str = re.sub(pattern, '卫视', part_str)
        return result_str
    
    return part_str



def tra_sim_convert(text): 
    return zhconv.convert(text, 'zh-hant')


#def verify_link2(link):
#    headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36'}
#    now=time.time()
#    try:
#        startTime = int(round(time.time() * 1000))
#        res=requests.get(link,headers=headers,timeout=5,stream=True)
#        if res.status_code == 200:
#            for k in res.iter_content(chunk_size=500000):
#                endTime = int(round(time.time() * 1000))
#                useTime = int(endTime - startTime)
#                if k and useTime <= 5000:
#                    return verify_link2(link)
#                elif useTime > 5000:
#                    return False
#                else:
#                    continue
#    except Exception:
#        pass
#    return False


#########################################图片比较
#均值哈希算法
def aHash(img):
    #缩放为8*8
    img=cv2.resize(img,(8,8),interpolation=cv2.INTER_CUBIC)
    #转换为灰度图
    gray=cv2.cvtColor(img,cv2.COLOR_BGR2GRAY)
    #s为像素和初值为0，hash_str为hash值初值为''
    s=0
    hash_str=''
    #遍历累加求像素和
    for i in range(8):
        for j in range(8):
            s=s+gray[i,j]
    #求平均灰度
    avg=s/64
    #灰度大于平均值为1相反为0生成图片的hash值
    for i in range(8):
        for j in range(8):
            if  gray[i,j]>avg:
                hash_str=hash_str+'1'
            else:
                hash_str=hash_str+'0'
    return hash_str

#差值感知算法
def dHash(img):
    #缩放8*8
    img=cv2.resize(img,(9,8),interpolation=cv2.INTER_CUBIC)
    #转换灰度图
    gray=cv2.cvtColor(img,cv2.COLOR_BGR2GRAY)
    hash_str=''
    #每行前一个像素大于后一个像素为1，相反为0，生成哈希
    for i in range(8):
        for j in range(8):
            if   gray[i,j]>gray[i,j+1]:
                hash_str=hash_str+'1'
            else:
                hash_str=hash_str+'0'
    return hash_str
 
#Hash值对比
def cmpHash(hash1,hash2):
    n=0
    #hash长度不同则返回-1代表传参出错
    if len(hash1)!=len(hash2):
        return -1
    #遍历判断
    for i in range(len(hash1)):
        #不相等则n计数+1，n最终为相似度
        if hash1[i]!=hash2[i]:
            n=n+1
    return n

#########################################

def check_pic_valid(oper, pic_path):
    hash1 = aHash(cv2.resize(cv2.imread(pic_path), (100, 100)))    
    dirs = os.listdir("./invalid_pic/")
    for file in dirs:
        hash2 = aHash(cv2.resize(cv2.imread('./invalid_pic/' + file), (100, 100)))
        n=cmpHash(hash1,hash2)
        #log=pic_path + " VS " + file + " score = " + str(n)
        #print(log)
        #log_write(oper, log)
        if n < 9:
            return False
    return True

def verify_link(channel_type, oper, channel_name, link, useTime=-1, redirect=False):
    useTime = -1
    try:
        jpg_name = str(uuid.uuid4())
        startTime = int(round(time.time() * 1000))
        output_img_path='./' + oper + '_pic/' + jpg_name + '.jpg'
        ffmpeg_command = 'ffmpeg -i "' + link + '" -vf "select=\'eq(n,0)\'" -err_detect ignore_err -vframes 1 -y ' + output_img_path
        print(ffmpeg_command)
        log = channel_type + "," + channel_name + "," + link + "," + output_img_path
        print(log)
        log_write(oper, log)
        process = subprocess.Popen(ffmpeg_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)  
        stdout, stderr = process.communicate(timeout=20)
        if process.returncode == 0:
            endTime = int(round(time.time() * 1000))
            useTime = int(endTime - startTime)
            if not check_pic_valid(oper, output_img_path) and os.path.exists(output_img_path):
                log = "删除: " + output_img_path
                print(log)
                log_write(oper, log)
                os.remove(output_img_path)
                return ["", useTime]
            log = channel_type + "," + channel_name + "," + link + "," + output_img_path + ",PASS"
            print(log)
            log_write(oper, log)
            return [link, useTime]
        else:
            return ["", useTime]
    except Exception as e:
        print(str(e))
        return ["", useTime]
        

def write_file(str,filename, mode):
    with open(filename, mode, encoding='utf-8') as file:
        file.write(str+"\n")

def log_init(oper):
    write_file("",oper + ".log","w")

def read_file(file_name):
    lines = []
    with open(file_name, 'r', encoding='utf-8') as oper_log:
        lines = oper_log.readlines()
        lines = [x.strip() for x in lines if x.strip()! = '']
    return lines

def log_write(oper,string):
    write_file(string, oper + ".log","a")

def get_uniq_type(ctype):
    global chtype
    for key in chtype.keys():
        for l in chtype[key]:
            if l in ctype:
                return key
    return ctype

def check_exclude(ctype):
    global excludetype
    for ex in excludetype:
        if ex in ctype:
            return True
    return False

def check_exists(mydict, link):    
    for values in mydict.values():
        for line in values:
            channel_address=line.split(",")[1]
            if link == channel_address:
                return True
    return False    

type_mapping = {
    "Entertainment" : "綜藝",
    "Generic" : "綜合",
    "Kids" : "兒童",
    "Knowledge" : "知識",
    "Movies" : "電影",
    "News" : "新聞",
    "Other" : "其它",
    "Sports" : "運動",
    "Music" : "音乐",
}

def get_channel_type(type_name):
    if type_name in type_mapping.keys():
        return type_mapping[type_name]
    else:
        return type_name


def process_url(mydict, lines, url):     
    channel_name=""
    channel_address=""
    channel_type="未知"
    # 逐行处理内容            
    for line in lines:
        line=line.strip()
        if line.startswith('#'):
            continue
        if  "#genre#" in line and "," in line:
            channel_type=line.split(",")[0].strip()
            channel_type=get_channel_type(get_uniq_type(channel_type))
            continue
        if  "#genre#" not in line and "," in line and ":" in line:
            channel_name=remove_brackets(line.split(',')[0].strip())
            channel_address=line.split(',')[1].strip().replace('https://raw.githubusercontent.com/','https://hub.gitmirror.com/https://raw.githubusercontent.com/')
            if any(sub_string in channel_name for sub_string in ["Playboy"]):
                continue
            if len(channel_name) == 0 or check_exclude(channel_type) or check_exists(mydict, channel_address):
                continue
            if channel_type not in mydict.keys():
                mydict[channel_type] = []
            mydict[channel_type].append(process_name_string(channel_name + "," + channel_address))
            continue


def process_tvname_url(mydict, lines, url, skip=False):     
    channel_name=""
    channel_address=""
    channel_type="未分类"
    # 逐行处理内容            
    for line in lines:
        line=line.strip()
        if line.startswith('#'):
            continue
        if  "#genre#" in line and "," in line:
            continue
        if  "#genre#" not in line and "," in line and ":" in line:
            channel_name=remove_brackets(line.split(',')[0].strip())
            channel_address=line.split(',')[1].strip().replace('https://raw.githubusercontent.com/','https://hub.gitmirror.com/https://raw.githubusercontent.com/')
            if len(channel_name) == 0 or check_exists(mydict, channel_address):
                continue
            if any(sub_string in channel_name for sub_string in ["Playboy"]):
                continue
            if any(sub_string in channel_name.upper() for sub_string in ["CCTV", '央视']):
                channel_type="央视频道"
            elif any(sub_string in channel_name.upper() for sub_string in ["卫视", '衛視', 'brtv']):
                channel_type="卫视频道"
            elif any(sub_string in channel_name.lower() for sub_string in ["bloomberg", 'news']):
                channel_type="新聞"
            elif any(sub_string in channel_name.lower() for sub_string in ['chc影迷电影', "star", 'sony', 'nick', "mytime", 'fox', "astro", "tvb", '星光视界']):
                channel_type="電影"
            elif any(sub_string in channel_name.lower() for sub_string in ["中天", "港台电视", "緯來精采", '红牛', '凤凰', '新加坡', '日本', '星空卫视', '星空衛視', '映画']):
                channel_type="綜合"
            elif any(sub_string in channel_name.lower() for sub_string in ['美国', '電影', '武侠', '电影', '影视', '故事', '港片', '热播', '电视剧', '百家讲坛', '知否知否', '科幻', '红楼梦', '经典', '剧集', '叛逆者', '易中天品三国']):
                channel_type="特色"            
            else:
                channel_type="未分类"
                if skip:
                    continue
            channel_type=get_channel_type(channel_type)
            if channel_type not in mydict.keys():
                mydict[channel_type] = []
            mydict[channel_type].append(process_name_string(channel_name + "," + channel_address))        


#current_directory = os.getcwd()  #准备读取txt

#读取文本方法
#def read_txt_to_array(file_name):
#    try:
#        with open(file_name, 'r', encoding='utf-8') as file:
#            lines = file.readlines()
#            lines = [line.strip() for line in lines]
#            return lines
#    except FileNotFoundError:
#        print(f"File '{file_name}' not found.")
#        return []
#    except Exception as e:
#        print(f"An error occurred: {e}")
#        return []


def verify(channel_type, oper, lines):
    sub_channel={}
    print(channel_type + " 频道数：" + str(len(lines)) + "\n")
    cur=1
    for line in lines:
        linesa=line.split(',')
        print("正在检查：" + str(cur) + "/" + str(len(lines)) + "\n")
        cur = cur + 1
        if len(linesa)<2:
            continue
        channel_name=linesa[0].strip()
        channel_address=linesa[1].strip()
        [redirect_url, useTime] = verify_link(channel_type, oper, channel_name, channel_address)
        if len(redirect_url) > 0 and useTime > -1 and useTime < 15000:
            if channel_name not in sub_channel.keys():
                sub_channel[channel_name]=[]
            else:
                pass
            sub_channel[channel_name].append([channel_name, redirect_url, useTime])
    for k in sub_channel.keys():
        sub_channel[k]=sorted(sub_channel[k], key=lambda t: t[2])
    ch_name_list=sorted(sub_channel.keys())
    print(ch_name_list)
    channel_list = []
    for ch in ch_name_list:
        channel_list = channel_list + [ item_list[0] + ',' + item_list[1] + ',' + str(item_list[2]) for item_list in sub_channel[ch]]
    return channel_list

# 定义一个函数，提取每行中逗号前面的数字部分作为排序的依据
def extract_number(s):
    num_str = s.split(',')[0].split('-')[1]  # 提取逗号前面的数字部分
    numbers = re.findall(r'\d+', num_str)   #因为有+和K
    return int(numbers[-1]) if numbers else 999

# 定义一个自定义排序函数
def custom_sort(s):
    if "CCTV-4K" in s:
        return 1  # 将包含 "4K" 的字符串排在后面
    elif "CCTV-8K" in s:
        return 2  # 将包含 "8K" 的字符串排在后面
    else:
        return 0  # 其他字符串保持原顺序

import re
 
def remove_brackets(s):
    return re.sub(r'\[.*?\]|{.*}|\(.*\)|「.*」|【.*】|', '', s)

def get_redirect_url(url):
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36'
    }
    response = requests.get(url,headers=headers,timeout=10,stream=True)
    return response.url

def delete_tree(root):
    for root, dirs, files in os.walk(root, topdown=False):
        for name in files:
            if not name.endswith("me"):
                os.remove(os.path.join(root, name))
        for name in dirs:
            os.rmdir(os.path.join(root, name))

def check_output_image(oper, channels, ch_type):    
    def check_link_exists_in_array(channels, link):
        for cha in channels:
            if "," + link + "," in cha:
                return True
        return False
    output_img_path=oper + ".log"
    print(output_img_path)
    with open(output_img_path, 'r', encoding='utf-8') as oper_log:
        lines = oper_log.readlines()
        for line in lines:
            linesa=line.split(',')
            if len(linesa) < 4:
                continue
            channel_type=linesa[0].strip()
            channel_name=linesa[1].strip()
            channel_address=linesa[2].strip()            
            channel_img=linesa[3].strip()
            if channel_type == ch_type and os.path.exists(channel_img) and not check_link_exists_in_array(channels, channel_address):
                log="增补:" + channel_type + "," + channel_name + "," + channel_address
                print(log)
                log_write(oper, log)
                channels.append(channel_name + "," + channel_address + ",10")
    return channels


#####开始#################################

# 定义要访问的多个URL
urls = read_file("channels.txt")
m3u_urls = read_file("channels.m3u")

chtype={}
chtype['卫视频道']=['🇨🇳｜卫视频道', '🇨🇳｜卫视蓝光频道', '卫视频道', '卫视', '•卫视「IPV6」', '卫视台', '未知']
chtype['央视频道']=['🇨🇳｜央视频道', '央视频道', 'CCTV', '数字频道', '综合', '央视', '数字', '•央视「IPV6」', '央视台', '数字电视', '央视其他']
chtype['港澳台']=['港台', '🇨🇳｜港澳台', '港·澳·台', '港澳频道', '台湾频道', '港澳台', '凤凰', '香港']
chtype['影视']=['4K', '4K频道', '🇨🇳｜蓝光频道', '埋堆堆', '电视剧']
chtype['体育频道']=['🇨🇳｜体育频道', '体育频道']
chtype['春晚']=['春晚', '历年春晚', '历届春晚']
chtype['NEWTV']=['NEWTV', '•NewTV「IPV6」', '未来电视']
chtype['少儿动画']=['🇨🇳｜少儿动画', '少儿动画']
chtype['电台']=['🇨🇳•电台', '电台']
chtype['地方']=['广东', '湖南', '福建', '江苏', '云南', '四川', '安徽', '山西', '河北', '天津', '北京', '重庆', '陕西', '其他频道']
chtype['世界']=['世界', '国际台', '全球']
chtype['记录']=['记录', '记录片']
excludetype=['玩偶', '麻豆-MSD', 'rostelekom', '胡志良', 'Adult', '成人点播', '日本', '欧美', '肥羊', '更新时间', 'YouTube', '特色频道', '埋推推', '解说频道', '虎牙斗鱼', '•游戏赛事', '春晚', '历年春晚', '历届春晚', 'BESTV']

def refresh(oper, func):
    #    print("使用方法：")
    #    print("       python3 main.py init           #初始化并验证github频道列表")
    #    print("       python3 main.py checkvalid     #检查频道源有效频道数")
    #    print("       python3 main.py epgpw download #下载并验证epg.pw频道列表") 
    #    print("       python3 main.py epgpw skip     #不下载并验证epg.pw频道列表") 
    #    sys.exit()
    mydict = {}
    delete_tree("./" + oper + "_pic/")
    log_init(oper)
    
    if oper == "init":
        files=['dog.txt']
        for f in files:
            with open(f, 'r', encoding='utf-8') as file:
               lines = file.readlines()
               process_url(mydict, lines, f)
    
        #循环处理每个URL
        for url in urls:
            url=url.replace('https://raw.githubusercontent.com/','https://hub.gitmirror.com/https://raw.githubusercontent.com/')
            #url=url.replace('githubusercontent.com','staticdn.net')
            #打开URL并读取内容
            #os.system('wget ' + url + " -O my.txt")
            print("downloading... " + url + "\n")
            os.system('curl ' + url + " -o my.txt")
            with open('my.txt', 'r', encoding='utf-8') as file:
               lines = file.readlines()
               process_url(mydict, lines, url)
        
        #循环处理每个M3U URL
        for url in m3u_urls:
            url=url.replace('https://raw.githubusercontent.com/','https://hub.gitmirror.com/https://raw.githubusercontent.com/')
            #url=url.replace('githubusercontent.com','staticdn.net')
            #打开URL并读取内容
            print("downloading... " + url + "\n")
            os.system('curl ' + url + " -o my.m3u")
            m3u_to_txt('my.m3u', 'my.txt')
            with open('my.txt', 'r', encoding='utf-8') as file:
               lines = file.readlines()
               process_url(mydict, lines, url)
    
        
        #files = os.listdir("./history/")
        #for file in files:
        #    #print(file)
        #    if os.path.isfile("./history/" + file):
        #        with open("./history/" + file, 'r', encoding='utf-8') as file:
        #            lines = file.readlines()
        #            process_url(mydict, lines, file)
        
        
        print("start=======================================================")
        # 合并所有对象中的行文本（去重，排序后拼接）
        version=time_str() + ",url"
        all_lines =  ["更新时间,#genre#"] +[version] 
        
        for key in mydict.keys():
            log_write(oper, key)
            channels=verify(key, oper, set(mydict[key]))
            channels=check_output_image(oper, channels, key)
            channels=sorted(channels)
            if len(channels) > 0:
                all_lines = all_lines + ['\n'] + [key + ",#genre#"] + channels
        
        # 将合并后的文本写入文件
        output_file = '../../mysite/dog.txt'
        output_file2 = 'dog.txt'
        output_file_bak = './history/dog_' + time_str() + '.txt'
        with open(output_file, 'w', encoding='utf-8') as f, open(output_file_bak, 'w', encoding='utf-8') as fb, open(output_file2, 'w', encoding='utf-8') as f2:
            for line in all_lines:
                linea=line.split(',')
                if len(linea) >= 2:
                    channel_name=linea[0].strip()
                    channel_address=linea[1].strip()                
                    if len(linea) >= 3:
                        channel_source=linea[2].strip()
                        f.write(channel_name + "," + channel_address + '\n')
                        fb.write(channel_name + "," + channel_address + '\n')
                        f2.write(channel_name + "," + channel_address + '\n')
                    else:
                        f.write(channel_name + "," + channel_address + '\n')
                        fb.write(channel_name + "," + channel_address + '\n')
                        f2.write(channel_name + "," + channel_address + '\n')
                else:
                    f.write(line.strip() + '\n')
                    fb.write(line.strip() + '\n')
                    
        print(f"合并后的文本已保存到文件: {output_file}, {output_file_bak}")
        print("done=======================================================")
    elif oper == "check":
        files=['test.txt']
        for f in files:
            with open(f, 'r', encoding='utf-8') as file:
               lines = file.readlines()
               process_url(mydict, lines, f)
        
        # 合并所有对象中的行文本（去重，排序后拼接）
        version=time_str() + ",url"
        all_lines =  ["更新时间,#genre#"] +[version] 
    
        for key in mydict.keys():
            log_write(oper, key)
            channels=verify(key, oper, set(mydict[key]))
            channels=check_output_image(oper, channels, key)
            channels=sorted(channels)
            if len(channels) > 0:
                print(channels)
                all_lines = all_lines + ['\n'] + [key + ",#genre#"] + channels
    
        print(all_lines)
    
        # 将合并后的文本写入文件
        output_file = 'test.txt'
    
        with open(output_file, 'w', encoding='utf-8') as f:
            for line in all_lines:
                linea=line.split(',')
                if len(linea) >= 2:
                    channel_name=linea[0].strip()
                    channel_address=linea[1].strip()                
                    if len(linea) >= 3:
                        channel_source=linea[2].strip()
                        f.write(channel_name + "," + channel_address + '\n')
                    else:
                        f.write(channel_name + "," + channel_address + '\n')
                else:
                    f.write(line.strip() + '\n')                
        print(f"合并后的文本已保存到文件: {output_file}")
        print("done=======================================================")
    
    elif oper == "checkvalid":    
        #获取所有的有效的链接
        all_valid=[]
        files=['dog.txt', 'output.txt']
        for f in files:
            with open(f, 'r', encoding='utf-8') as file:
               lines = file.readlines()
               for line in lines:
                   linea=line.split(',')
                   if len(linea) >= 2:
                       all_valid.append(linea[1].strip())
        print(all_valid)
        #循环处理每个URL
        for url in urls:
            url=url.replace('https://raw.githubusercontent.com/','https://hub.gitmirror.com/https://raw.githubusercontent.com/')
            #url=url.replace('githubusercontent.com','staticdn.net')
            #打开URL并读取内容
            #os.system('wget ' + url + " -O my.txt")
            print("downloading... " + url + "\n")
            os.system('curl ' + url + " -o my.txt")
            with open('my.txt', 'r', encoding='utf-8') as file:
                valid_count=0
                lines = file.readlines()
                for line in lines:
                    linea=line.split(',')
                    if len(linea) >= 2 and linea[1].strip() != '#genre#' and linea[1].strip() in all_valid:
                       #print(line)
                       valid_count = valid_count + 1
                print(url + ": " + str(valid_count))
        
        #循环处理每个M3U URL
        for url in m3u_urls:
            url=url.replace('https://raw.githubusercontent.com/','https://hub.gitmirror.com/https://raw.githubusercontent.com/')
            #url=url.replace('githubusercontent.com','staticdn.net')
            #打开URL并读取内容
            print("downloading... " + url + "\n")
            os.system('curl ' + url + " -o my.m3u")
            m3u_to_txt('my.m3u', 'my.txt')
            with open('my.txt', 'r', encoding='utf-8') as file:
                lines = file.readlines()
                valid_count=0
                for line in lines:
                    linea=line.split(',')
                    if len(linea) >= 2 and linea[1].strip() != '#genre#' and linea[1].strip() in all_valid:
                       #print(line)
                       valid_count = valid_count + 1
                print(url + ": " + str(valid_count))
    elif oper == "test":
        #print(get_redirect_url('https://stream.freetv.fun/tvbs-4.ctv'))
        #print(get_redirect_url('https://stream.freetv.fun/ph-rock-entertainment-1.ctv'))
        #print(get_redirect_url('https://stream.freetv.fun/hgtv-8.ctv'))
        #print(get_redirect_url('https://stream.freetv.fun/cctv-3-14.m3u8'))
        #print(get_redirect_url('https://stream.freetv.fun/viutv-1.ctv'))
        import uuid
        print((uuid.uuid4()))
        print((uuid.uuid4()))
        print((uuid.uuid4()))
    elif oper == "epgpw":
        all_types=['中國大陸', '频道不符合任何EPG', '台灣', '香港', '澳門', '美國', '新加坡', '英國', '澳大利亞', '加拿大', '新西蘭']
        file_prefix = os.path.dirname(os.path.abspath(__file__)) + "/epgpw/"
        if func == "download":
            #下载所有频道
            all_links={}
            x = requests.get('https://epg.pw/test_channel_page.html?lang=zh-hans')
            #print(x.text)
            soup = BeautifulSoup(x.text, 'html5lib')
            all_trs = soup.find_all('tr')
            print(os.path.dirname(os.path.abspath(__file__)))
            for tr in all_trs:
                all_tds = tr.find_all('td')
                if len(all_tds) == 3:
                    link=all_tds[0].text.strip()
                    type_name=all_tds[2].text.strip()
                    file_name= file_prefix + all_tds[2].text.strip() + ".txt"
                    if not link.endswith("_original_new.txt") and \
                            link.endswith("_new.txt") and \
                            type_name in all_types and \
                            "banned" not in link and \
                            link not in all_links.values():
                        all_links[type_name]=link                
                        print(all_tds[2].text.strip())
                        print("downloading... " + link + "\n")
                        os.system('curl ' + link + " -o " + file_name) 
                        time.sleep(5)
            for key, value in all_links.items():
                print(key + " : " + value + "\n")
    
    
        files=['gat.txt']
        for f in files:
            with open(f, 'r', encoding='utf-8') as file:
               lines = file.readlines()
               process_url(mydict, lines, f)
               
        ##中国大陆
        #china_main=['中國大陸']
        #files=[file_prefix + type + ".txt" for type in  china_main]
        #print(files)
        #for f in files:
        #    with open(f, 'r', encoding='utf-8') as file:
        #        lines = file.readlines()
        #        process_tvname_url(mydict, lines, f)
    
        #大陆港澳台世界
        gat_types=['中國大陸', '台灣', '香港', '澳門', '美國', '新加坡', '英國', '澳大利亞', '加拿大', '新西蘭']
        mydict={}
        files=[file_prefix + type + ".txt" for type in  gat_types]
        print(files)
        for f in files:
            with open(f, 'r', encoding='utf-8') as file:
                lines = file.readlines()
                process_url(mydict, lines, f)
        
        #其他
        unclassfied=['频道不符合任何EPG']
        files=[file_prefix + type + ".txt" for type in unclassfied]
        print(files)
        for f in files:
            with open(f, 'r', encoding='utf-8') as file:
                lines = file.readlines()
                process_tvname_url(mydict, lines, f, skip=True)
        
        # 合并所有对象中的行文本（去重，排序后拼接）
        version=time_str() + ",url"
        all_lines =  ["更新时间,#genre#"] +[version] 
    
        for key in mydict.keys():
            log_write(oper, key)
            channels=verify(key, oper, set(mydict[key]))
            channels=check_output_image(oper, channels, key)
            channels=sorted(channels)
            if len(channels) > 0:
                print(channels)
                all_lines = all_lines + ['\n'] + [key + ",#genre#"] + channels
    
        print(all_lines)
    
        # 将合并后的文本写入文件
        output_file = './history/gat_epgpw_' + time_str() + '.txt'
        output_file2 = 'gat.txt'
        output_mysite_file = "../../mysite/gat.txt"
    
        with open(output_file, 'w', encoding='utf-8') as f, open(output_mysite_file, 'w', encoding='utf-8') as fmysite, open(output_file2, 'w', encoding='utf-8') as f2:
            for line in all_lines:
                linea=line.split(',')
                if len(linea) >= 2:
                    channel_name=linea[0].strip()
                    channel_address=linea[1].strip()                
                    if len(linea) >= 3:
                        channel_source=linea[2].strip()
                        f.write(channel_name + "," + channel_address +  "," + channel_source + '\n')
                        fmysite.write(channel_name + "," + channel_address + '\n')
                        f2.write(channel_name + "," + channel_address + '\n')
                    else:
                        f.write(channel_name + "," + channel_address + '\n')
                        fmysite.write(channel_name + "," + channel_address + '\n')
                        f2.write(channel_name + "," + channel_address + '\n')
                else:
                    f.write(line.strip() + '\n')                
        print(f"合并后的文本已保存到文件: {output_file} {output_mysite_file}")
    
    
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

def time_str(fmt=None):
    if fmt is None:
        fmt = '%Y_%m_%d_%H_%M_%S'
    return datetime.datetime.today().strftime(fmt)
       

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
        
    elif "卫视" in part_str:
        # 定义正则表达式模式，匹配“卫视”后面的内容
        pattern = r'卫视「.*」'
        # 使用sub函数替换匹配的内容为空字符串
        result_str = re.sub(pattern, '卫视', part_str)
        return result_str
    
    return part_str


def verify_link(link):
    headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36'}
    se=requests.Session()     
    now=time.time()
    try:
        startTime = int(round(time.time() * 1000))
        res=se.get(link,headers=headers,timeout=8,stream=True)
        if res.status_code == 200:
            for k in res.iter_content(chunk_size=500000):
                endTime = int(round(time.time() * 1000))
                useTime = int(endTime - startTime)
                if k and useTime <= 5000:
                    return verify_link2(link)
                elif useTime > 5000:
                    return False
                else:
                    continue
    except Exception:
        pass
    return False

def verify_link2(link):
    try:
        probe = ffmpeg.probe(link)
        cap_info = next(x for x in probe['streams'] if x['codec_type'] == 'video')
        print("fps: {}".format(cap_info['r_frame_rate']))
        width = cap_info['width']           # 获取视频流的宽度
        height = cap_info['height']         # 获取视频流的高度
        up, down = str(cap_info['r_frame_rate']).split('/')
        fps = eval(up) / eval(down)
        print("fps: {}".format(fps))
        ffmpeg_command = 'ffmpeg -i "' + link + '" -vf "select=\'eq(n,0)\'" -vframes 1 -y output.jpg'
        print(ffmpeg_command)
        process = subprocess.Popen(ffmpeg_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)  
        stdout, stderr = process.communicate(timeout=5)
        if process.returncode == 0:  
            print("=== ffmpeg转码完成 ====")    
            print(stdout.decode())
            return True                     
        else:
            print("=== 转换失败！=== ")
            print(stderr.decode())
            return False
    except:
        return False

def write_file(str,filename, mode):
    with open(filename, mode, encoding='utf-8') as file:
        file.write(str+"\n")

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

def check_exists(link):
    global mydict
    for value in mydict.values():
        if link in value:
            return True
    return False    
    

def process_url(lines, url):
    global mydict
    try:
        channel_name=""
        channel_address=""
        channel_type="其他"
        # 逐行处理内容            
        for line in lines:
            line=line.strip()
            if  "#genre#" in line and "," in line:
                channel_type=line.split(",")[0].strip()
                channel_type=get_uniq_type(channel_type)
                continue
            if  "#genre#" not in line and "," in line and ":" in line:
                channel_name=line.split(',')[0].strip()
                channel_address=line.split(',')[1].strip()
                if len(channel_name) == 0 or check_exclude(channel_type) or check_exists(channel_address):
                    continue
                if channel_type not in mydict.keys():
                    mydict[channel_type] = []
                write_file(line.strip() + "\n","my.log","w")
                mydict[channel_type].append(process_name_string(line.strip()))
                continue
    except Exception as e:
        print(f"处理URL时发生错误：{e}")

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


def verify(lines):
    lines2=[]
    for line in lines:
        linesa=line.split(',')
        if len(linesa)<2:
            continue
        channel_name=linesa[0].strip()
        channel_address=linesa[1].strip()
        if verify_link(channel_address):
            lines2.append(line)
    return lines2


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


#####开始#################################

# 定义要访问的多个URL
urls = [
    'https://raw.githubusercontent.com/Supprise0901/TVBox_live/main/live.txt',
    'https://raw.githubusercontent.com/Guovin/TV/gd/result.txt', #1天自动更新1次
    'https://raw.githubusercontent.com/ssili126/tv/main/itvlist.txt',
    'https://raw.githubusercontent.com/gaotianliuyun/gao/master/list.txt',
    'https://raw.githubusercontent.com/mlvjfchen/TV/main/iptv_list.txt',
    'https://raw.githubusercontent.com/fenxp/iptv/main/live/ipv6.txt',  #1小时自动更新1次11:11 2024/05/13
    'https://raw.githubusercontent.com/fenxp/iptv/main/live/tvlive.txt', #1小时自动更新1次11:11 2024/05/13
    'https://raw.githubusercontent.com/qist/tvbox/master/list.txt',
    'https://raw.githubusercontent.com/qist/tvbox/master/listx.txt',
    'https://raw.githubusercontent.com/qist/tvbox/master/radio.txt',
    'https://raw.githubusercontent.com/qist/tvbox/master/tvboxtv.txt',
    'https://raw.githubusercontent.com/qist/tvbox/master/tvlive.txt',
    'https://m3u.ibert.me/txt/fmml_ipv6.txt',
    'https://m3u.ibert.me/txt/ycl_iptv.txt',
    'https://m3u.ibert.me/txt/y_g.txt',
    'https://m3u.ibert.me/txt/j_home.txt',
    'https://gitee.com/xxy002/zhiboyuan/raw/master/zby.txt',
]

m3u_urls = [
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/GSYD-IPV6.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/IPTV.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/IPV6.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/SXYD.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/aishang.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/bestv.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/cqyx.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/douyuyqk.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/dzh.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/ghyx.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/gudou.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/gudouexample.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/hbgd.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/huyayqk.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/itouch.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/msp.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/newbestv.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/sxg.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/yqgd.m3u',
    'https://raw.githubusercontent.com/Ftindy/IPTV-URL/main/yylunbo.m3u',
]

mydict = {}

chtype={}
chtype['卫视频道']=['卫视频道', '卫视', '•卫视「IPV6」', '卫视台']
chtype['央视频道']=['央视频道', 'CCTV', '数字频道', '综合', '央视', '数字', '•央视「IPV6」', '央视台', '数字电视', '央视其他']
chtype['港澳台']=['港台', '港·澳·台', '港澳频道', '台湾频道', '港澳台', '凤凰', '香港']
chtype['4K频道']=['4K', '4K频道']
#chtype['世界']=['世界', '国际台', '国际']
chtype['春晚']=['春晚', '历年春晚', '历届春晚']
chtype['NEWTV']=['NEWTV', '•NewTV「IPV6」']


excludetype=['玩偶', '麻豆-MSD', 'rostelekom', '胡志良', 'Adult', '成人点播', '日本', '欧美', '肥羊', '更新时间', 'YouTube', '特色频道', '埋推推', '解说频道', '虎牙斗鱼', '•游戏赛事']

import sys
oper=sys.argv[1]

#初始化
if oper == "init":
    #循环处理每个URL
    for url in urls:
        url=url.replace('https://raw.githubusercontent.com/','https://hub.gitmirror.com/https://raw.githubusercontent.com/')
        #url=url.replace('githubusercontent.com','staticdn.net')
        #打开URL并读取内容
        #os.system('wget ' + url + " -O my.txt")
        os.system('curl ' + url + " -o my.txt")
        with open('my.txt', 'r', encoding='utf-8') as file:
           lines = file.readlines()
           process_url(lines, url)
    
    #循环处理每个M3U URL
    for url in m3u_urls:
        url=url.replace('https://raw.githubusercontent.com/','https://hub.gitmirror.com/https://raw.githubusercontent.com/')
        #url=url.replace('githubusercontent.com','staticdn.net')
        #打开URL并读取内容
        os.system('curl ' + url + " -o my.m3u")
        m3u_to_txt('my.m3u', 'my.txt')
        with open('my.txt', 'r', encoding='utf-8') as file:
           lines = file.readlines()
           process_url(lines, url)
    
    
    
    files=['output.txt', 'dog.txt']
    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
           lines = file.readlines()
           process_url(lines, f)
    
    #files = os.listdir("./history/")
    #for file in files:
    #    #print(file)
    #    if os.path.isfile("./history/" + file):
    #        with open("./history/" + file, 'r', encoding='utf-8') as file:
    #            lines = file.readlines()
    #            process_url(lines, file)
    
    
    write_file("","my.log","w")
    
    print("start=======================================================")
    # 合并所有对象中的行文本（去重，排序后拼接）
    version=datetime.now().strftime("%Y%m%d")+",url"
    all_lines =  ["更新时间,#genre#"] +[version] 
    
    for key in mydict.keys():
        write_file(key + "\n","my.log","w")
        channels=verify(sorted(set(mydict[key])))
        if len(channels) > 2:
            all_lines = all_lines + ['\n'] + [key + ",#genre#"] + channels
    
    # 将合并后的文本写入文件
    output_file = 'output.txt'
    output_file_bak = './history/output_' + datetime.now().strftime('%Y%m%d') + '.txt'
    with open(output_file, 'w', encoding='utf-8') as f, open(output_file_bak, 'w', encoding='utf-8') as fb:
        for line in all_lines:
            linea=line.split(',')
            if len(linea) >= 2:
                channel_name=linea[0].strip()
                channel_address=linea[1].strip()                
                if len(linea) >= 3:
                    channel_source=linea[2].strip()
                    f.write(channel_name + "," + channel_address + '\n')
                    fb.write(channel_name + "," + channel_address + "," + channel_source + '\n')
                else:
                    f.write(channel_name + "," + channel_address + '\n')
                    fb.write(channel_name + "," + channel_address + '\n')
            else:
                f.write(line.strip() + '\n')
                fb.write(line.strip() + '\n')
                
    print(f"合并后的文本已保存到文件: {output_file}, {output_file_bak}")
    print("done=======================================================")
elif oper == "check":
    files=['dog.txt']
    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
           lines = file.readlines()
           process_url(lines, f)
    
    # 合并所有对象中的行文本（去重，排序后拼接）
    version=datetime.now().strftime("%Y%m%d")+",url"
    all_lines =  ["更新时间,#genre#"] +[version] 

    for key in mydict.keys():
        write_file(key + "\n","my.log","w")
        channels=verify(sorted(set(mydict[key])))
        if len(channels) > 0:
            all_lines = all_lines + ['\n'] + [key + ",#genre#"] + channels

    print(all_lines)

    # 将合并后的文本写入文件
    output_file = 'dog2.txt'

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
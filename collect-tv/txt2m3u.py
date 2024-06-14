import os

def remove_duplicates_and_sort(lst):
    # 使用set去除重复元素，然后转换回列表
    unique_elements = sorted(list(set(lst)))
    return unique_elements
 

# M3U转TXT
def m3u_to_txt(m3u_path, txt_path):
    cur_type=""
    cur_name=""
    is_tag=False
    mydict={}
    with open(m3u_path, 'r', encoding='utf-8') as m3u_file:
        for line in m3u_file:
            line = line.strip()
            if line.startswith('#EXTINF:'):
                attrs=line.split(' ')
                is_tag=True
                for attr in attrs:
                    if 'tvg-name' in attr:
                        #tvg-name="CCTV1"
                        cur_name=attr.strip().replace('tvg-name=','').replace('"','').strip()
                    elif 'group-title' in attr:
                        #group-title="央视",CCTV-1 综合 
                        cur_type=attr.strip().replace('group-title=','').split(",")[0].replace('"','').strip()  
            elif line.startswith('http') and is_tag:
                is_tag=False
                if cur_type not in mydict.keys():
                    mydict[cur_type]=[]
                mydict[cur_type].append(cur_name + ',' + line)
            else:
                is_tag=False

    for key in mydict.keys():
        mydict[key] = remove_duplicates_and_sort(mydict[key])

    with open(txt_path, 'w', encoding='utf-8') as txt_file:
        for key in mydict.keys():
            txt_file.write(key + ",#genre#\n\n")
            for line in mydict[key]:
                txt_file.write(line + "\n")
            txt_file.write("\n")            
    print('Done!')

                


            
 
# TXT转M3U
def txt_to_m3u(txt_path, m3u_path):
    with open(txt_path, 'r', encoding='utf-8') as txt_file, open(m3u_path, 'w', encoding='utf-8') as m3u_file:
        cur_type=""
        m3u_file.write("#EXTM3U\n")
        for line in txt_file:
            line = line.strip()
            attrs=line.split(",")
            if len(attrs)==2:
                if '#genre#' in attrs[1]:
                    cur_type=attrs[0].strip()
                else:
                    cur_name=attrs[0].strip()
                    cur_link=attrs[1].strip()
                    if cur_type=="":
                        continue
                    m3u_file.write('#EXTINF:-1,tvg-id="' + cur_name + '" tvg-name="' + cur_name + '" tvg-logo="" group-title="' + cur_type + '",' +  cur_name  + '\n')
                    m3u_file.write(cur_link+"\n")
    print('Done!')


## 示例使用
#import sys
#oper=sys.argv[1] 
#m3u_file_path = sys.argv[2]
#txt_file_path = sys.argv[3]
#
#if oper=="txt2m3u":
#    txt_to_m3u(txt_file_path, m3u_file_path)
#elif oper=="m3u2txt":
#    m3u_to_txt(m3u_file_path, txt_file_path)
#else:
#    print("txt2m3u 操作类别（txt2m3u, m3u2txt） m3u文件名 txt文件名")
#
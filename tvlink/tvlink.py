# -*- coding: utf-8 -*-
import re
import sys
import time
import requests
import os
import shutil
 
from collections import OrderedDict

from playwright.sync_api import Playwright, sync_playwright, expect


#excluded_resource_types = ["stylesheet", "script", "image", "font"] 
excluded_resource_types = ["stylesheet", "image", "font"]

def block_aggressively(route): 
	if (route.request.resource_type in excluded_resource_types): 
		route.abort() 
	else: 
		route.continue_()	

def search(playwright: Playwright, filename, keyword, mode) -> None:
    browser = playwright.chromium.launch(headless=False)
    context = browser.new_context()
    page = context.new_page()

    # 注入阻止 window.load 事件的脚本
    #page.evaluate('''() => {
    #        window.addEventListener('load', function(event) {
    #            console.log('Window load event is prevented');
    #            event.preventDefault();
    #            event.stopPropagation();
    #        }, { once: true });
    #    }''')
    
    
    write_log("正在搜索关键字："+keyword)
    url="http://tonkiang.us"
    page.route("**/*", block_aggressively) 
    page.goto(url, timeout=100000)    
    page.locator("#search").click()
    page.locator("#search").fill(keyword)
    page.get_by_role("button", name="Submit").click(timeout=100000)
    page.wait_for_load_state('load')    
    page.evaluate(
            """() => {
                // 自定义阻止元素加载的函数
                function removeElement(tagName) {
                    const elements = document.querySelectorAll(tagName);
                    elements.forEach(element => element.remove());
                }
                // 在document上添加一个属性来调用这个函数
                document.blockElement = (tagName) => removeElement(tagName);
            }"""
        )
    page.evaluate('document.blockElement("iframe")')
    #print(page.content())    

    page_count=1

    tvstation=[]
    tvlinks=[]

    while True:
        tvs=page.locator('//div[@class="resultplus"]')
        tvcount=tvs.count()        
        
        if tvcount==1:
            break
        
        for i in range(tvcount):
            tv=tvs.nth(i)
            print(i)        
            tvname_div=tv.locator('//div[@class="channel"]')
            if tvname_div.count()!=1:
                continue
            tvlink_div=tv.locator('//tba')        
            if tvlink_div.count()!=2:
                continue
            tvname=tvname_div.inner_text()
            tvlink=tvlink_div.nth(1).inner_text()
            tvstation.append(tvname.strip())
            if verify_link(tvlink.strip()):
                tvlinkstr = tvname.strip() + "," + tvlink.strip() + ",PASS"
                tvlinks.append(tvlinkstr)
                print(tvlinkstr)
                write_log("发现："+tvlinkstr)

        print("done this page " + str(page_count) + "|" + str(tvcount))
        page_count = page_count+1

        if tvcount < 31:
            break
        while True:
            try:
                print("Loading... page " + str(page_count))
                #page.get_by_role("link", name=str(page_count), exact=True).click(timeout=100000)
                url="http://tonkiang.us/?page=" + str(page_count) + "&channel=" + keyword
                page.route("**/*", block_aggressively) 
                page.goto(url, timeout=100000)
                break                
            except:
                print("Retry... page " + str(page_count))
                continue            
        page.wait_for_load_state('load')
        page.evaluate(
            """() => {
                // 自定义阻止元素加载的函数
                function removeElement(tagName) {
                    const elements = document.querySelectorAll(tagName);
                    elements.forEach(element => element.remove());
                }
                // 在document上添加一个属性来调用这个函数
                document.blockElement = (tagName) => removeElement(tagName);
            }"""
        )
        page.evaluate('document.blockElement("iframe")')        
        #page.frame_locator("iframe[name=\"aswift_6\"]").get_by_label("Close ad").click()
        #page.frame_locator("iframe[name=\"aswift_5\"]").frame_locator("iframe[name=\"ad_iframe\"]").get_by_label("Close ad").click()

    tvstation.sort()
    tvlinks.sort()
    if mode == "w":
        with open(filename + '_电视台.txt', mode, encoding='utf-8') as file:
            for ts in tvstation:
                file.write(ts+"\n")
    
    with open(filename + '.txt', mode, encoding='utf-8') as file:
        for tl in tvlinks:
            file.write(tl+"\n")
    
    context.close()
    browser.close()
    
    #shutil.copy(filename + '.txt', filename + '_bak.txt')
    remove_duplicates(filename + '.txt', filename + '.txt')



def remove_duplicates(in_file, out_file):
    with open(in_file, 'r', encoding='utf-8') as file:
        unique_lines = OrderedDict.fromkeys(file)
 
    with open(out_file, 'w', encoding='utf-8') as file:
        file.writelines(unique_lines)


def verify_link(link):
    headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36'}
    se=requests.Session()
     
    now=time.time()
    try:
        res=se.get(link,headers=headers,timeout=5,stream=True)
        if res.status_code==200:
            for k in res.iter_content(chunk_size=1048576):
                # 这里的chunk_size是1MB，每次读取1MB测试视频流
                # 如果能获取视频流，则输出读取的时间以及链接
                if k:
                    print(k)
                    return True
                    #print(f'{time.time()-now:.2f}\t{link}')
                    #break
    except Exception:
        # 无法连接并超时的情况下输出“X”
        #print(f'X\t{link}')
        pass
    
    return False


def write_log(str):
    with open('tvlink.log', "a", encoding='utf-8') as file:
        file.write(str+"\n")


print(sys.argv)
oper=sys.argv[1] 
if oper=="search":
    filename=sys.argv[2] #文件名
    keyword=sys.argv[3] #关键字
    mode=sys.argv[4] #文件模式w:重写 a:增加
    with sync_playwright() as playwright:
        search(playwright, filename, keyword, mode)
elif oper=="searchf":    
    filename=sys.argv[2] #文件名
    keyword=sys.argv[3] #搜索关键字文件名
    mode=sys.argv[4] #文件模式w:重写 a:增加
    keywordf=keyword + "_电视台.txt"
    keywordlist=[]
    if os.path.exists(keywordf):
        with open(keywordf, 'r', encoding='utf-8') as file:
            for line in file:
                keywordlist.append(line.strip())
    for k in keywordlist:
        print(k)
        with sync_playwright() as playwright:
            search(playwright, filename, k, mode)    
elif oper=="check":
    file_link=sys.argv[2]
    #verify_link_test(file_link)

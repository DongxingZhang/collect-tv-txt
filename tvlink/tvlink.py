# -*- coding: utf-8 -*-
import re
import sys
import time
from playwright.sync_api import Playwright, sync_playwright, expect


#excluded_resource_types = ["stylesheet", "script", "image", "font"] 
excluded_resource_types = ["script"]

def block_aggressively(route): 
	if (route.request.resource_type in excluded_resource_types): 
		route.abort() 
	else: 
		route.continue_()	

def search(playwright: Playwright, filename, keyword, mode) -> None:
    browser = playwright.chromium.launch(headless=False)
    context = browser.new_context()
    page = context.new_page()
    url="http://tonkiang.us"
    #page.route("**/*", block_aggressively) 
    page.goto(url)
    page.locator("#search").click()
    page.locator("#search").fill(keyword)
    page.get_by_role("button", name="Submit").click()
    page.wait_for_load_state('load')
    time.sleep(5)

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
            print("=================================================")
            print(i)        
            tvname_div=tv.locator('//div[@class="channel"]')
            if tvname_div.count()!=1:
                continue        
            tvlink_div=tv.locator('//tba')        
            if tvlink_div.count()!=2:
                continue
            tvname=tvname_div.inner_text()
            #print(tv.inner_html())
            tvlink=tvlink_div.nth(1).inner_text()
            print(tvname)
            print(tvlink)
            tvstation.append(tvname.strip())
            tvlinks.append(tvname.strip() + "|" + tvlink.strip()+"|UNTESTED")
            print("-------------------------------------------------")

        print("done this page " + str(page_count) + "/" + str(tvcount))
        page_count = page_count+1

        if tvcount < 31:
            break

        page.get_by_role("link", name=str(page_count), exact=True).click()
        page.wait_for_load_state('load')
        time.sleep(5)


    tvstation.sort()
    tvlinks.sort()
    with open(filename + '_电视台.txt', mode, encoding='utf-8') as file:
        for ts in tvstation:
            file.write(ts+"\n")
    
    with open(filename + '.txt', mode, encoding='utf-8') as file:
        for tl in tvlinks:
            file.write(tl+"\n")
    
    context.close()
    browser.close()


print(sys.argv)
oper=sys.argv[1] #操作：search搜索链接  test测试链接 
filename=sys.argv[2] #文件名

if oper=="search":
    keyword=sys.argv[3] #搜索关键字文件名或者关键字
    mode=sys.argv[4] #文件模式w:重写 a:增加
    with sync_playwright() as playwright:
        search(playwright, filename, keyword, mode)    
else:
    pass

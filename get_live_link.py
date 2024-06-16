# -*- coding: utf-8 -*-
import time
from playwright.sync_api import sync_playwright
# 这是一个示例函数，用于演示如何使用Playwright的自定义拦截器
def run(playwright, link, routef):
    # 启动浏览器
    #browser = playwright.chromium.launch(headless=False)  # headless=False 表示显示浏览器窗口
    browser = playwright.firefox.launch(headless=True)  # headless=False 表示显示浏览器窗口
    page = browser.new_page()
    # 设置自定义拦截器
    def intercept_request(route, request):
        #if request.url.startswith(regx):
        if ".flv" in request.url or ".m3u" in request.url or ".m3u8" in request.url:
            print(f"拦截到的请求: {request.url}")            
            if link.startswith("https://www.yy.com/") and request.url.startswith("https://aliyun-flv-ipv6.yy.com/live/"):
                write_file(request.url, routef,"w")
            elif link.startswith("https://live.bilibili.com/") and ".bilivideo.com/live-bvc/" in request.url and request.url.startswith("https://d1--cn-gotcha"):
                write_file(request.url, routef,"w")
            route.abort("aborted")
        else:
            route.continue_()
    page.route("**/*", intercept_request)
    # 访问一个网页
    page.goto(link, timeout=200000)
    time.sleep(9)
    page.wait_for_load_state('load')
    # 关闭浏览器
    browser.close()


def write_file(str,filename, mode):
    with open(filename, mode, encoding='utf-8') as file:
        file.write(str+"\n")

import sys
link=sys.argv[1]
routef=sys.argv[2]
write_file("", routef,"w")
# 运行Playwright
with sync_playwright() as p:
    run(p, link, routef)


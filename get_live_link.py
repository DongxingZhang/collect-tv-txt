# -*- coding: utf-8 -*-

from playwright.sync_api import sync_playwright
# 这是一个示例函数，用于演示如何使用Playwright的自定义拦截器
def run(playwright, link, regx):
    # 启动浏览器
    #browser = playwright.chromium.launch(headless=False)  # headless=False 表示显示浏览器窗口
    browser = playwright.firefox.launch(headless=True)  # headless=False 表示显示浏览器窗口
    page = browser.new_page()
    # 设置自定义拦截器
    def intercept_request(route, request):
        #if request.url.startswith(regx):
        if regx in request.url:
            print(f"拦截到的请求: {request.url}")
            route.abort("aborted")
            write_file(request.url, "route.txt","w")
        else:
            route.continue_()
    page.route("**/*", intercept_request)
    # 访问一个网页
    page.goto(link, timeout=200000)
    page.wait_for_load_state('load')
    # 关闭浏览器
    browser.close()


def write_file(str,filename, mode):
    with open(filename, mode, encoding='utf-8') as file:
        file.write(str+"\n")

import sys
mapping = {
    'https://www.yy.com/': 'https://aliyun-flv-ipv6.yy.com/live/',
    'https://live.bilibili.com/': 'bilivideo.com/live-bvc/',
}
link=sys.argv[1]
write_file("", "route.txt","w")
for key, value in mapping.items():
    if key in link:
        regx=value
        break
# 运行Playwright
with sync_playwright() as p:
    run(p, link, regx)    

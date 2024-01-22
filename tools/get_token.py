#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Software: PyCharm
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from time import sleep
import json
def browser_initial():
    chrome_options = Options()
    prefs={
        'profile.default_content_setting_values': {
            'images': 2,
            'javascript':2
        }
    }
    #chrome_options.add_experimental_option('prefs',prefs)
    # chrome_options.add_argument('--headless')
    # browser = webdriver.Chrome(options=chrome_options)
    s = Service(r'/mnt/share/live-tool/tools/chromedriver')
    browser = webdriver.Chrome(service=s,options=chrome_options)
    browser.maximize_window()
    browser.get('https://www.douyu.com/')
    #browser.get('https://www.douyu.com/creator/main/live')
    return browser

def log_csdn(browser):
    with open('/mnt/share/live-tool/tools/cookies.txt', 'r', encoding='utf8') as f:
        listCookies = json.loads(f.read())
    #print(listCookies)
    # 往browser里添加cookies
    for cookie in listCookies:
        cookie_dict = {
            'domain': '.douyu.com',
            'name': cookie.get('name'),
            'value': cookie.get('value'),
            "expires": '',
            'path': '/',
            'httpOnly': False,
            'HostOnly': False,
            'Secure': False
        }
        print(cookie_dict)
        browser.add_cookie(cookie_dict)
    browser.refresh()  
    sleep(5)
    browser.get('https://www.douyu.com/creator/main/live')
    sleep(8)
    earr=browser.find_elements(By.XPATH,'//*[@class="itemWrap--2f8TJ3y"]')
    ret=''
    if len(earr) == 3:
        rtmp1=earr[1]
        rtmp_token=rtmp1.find_element(By.XPATH,'//*[@class="svgIcon--2ypAR1M svg--2uID9Py"]')
        if rtmp_token is not None:
            #ret=rtmp_token.Click()
            print(123)
    print(ret)
    return ret

if __name__ == "__main__":
    browser = browser_initial()
    log_csdn(browser)
    sleep(10000)

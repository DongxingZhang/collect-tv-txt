#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Time    : 2020/12/29 11:01
# @Author  : huni
# @File    : Я��cookies��½����.py
# @Software: PyCharm
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import json
def browser_initial():
    # chrome_options = Options()
    # chrome_options.add_argument('--headless')
    # browser = webdriver.Chrome(options=chrome_options)
    browser = webdriver.Chrome(executable_path='./chromedriver.exe')
    browser.maximize_window()
    browser.get(
        'https://www.douyu.com/')
    return browser

def log_csdn(browser):
    with open('����_cookies.txt', 'r', encoding='utf8') as f:
        listCookies = json.loads(f.read())

    # ��browser������cookies
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
        browser.add_cookie(cookie_dict)
    browser.refresh()  # ˢ����ҳ,cookies�ųɹ�

if __name__ == "__main__":
    browser = browser_initial()
    log_csdn(browser)
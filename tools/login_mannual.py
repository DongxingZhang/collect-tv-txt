#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Time    : 2020/12/29 10:58
# @Author  : huni
# @File    : ??cookies.py
# @Software: PyCharm
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from time import sleep
import json
if __name__ == '__main__':
    s = Service(r'/mnt/share/live-tool/tools/chromedriver')
    driver = webdriver.Chrome(service=s)
    driver.maximize_window()
    driver.get('https://www.douyu.com/')
    sleep(60)
    # driver.switch_to.frame(driver.find_element_by_xpath('//*[@id="anony-reg-new"]/div/div[1]/iframe'))  
    #driver.find_element(By.XPATH,'//*[@id="js-header"]/div/div/div[3]/div[7]/div/div/a/span').click()
    sleep(10)
    dictCookies = driver.get_cookies()  
    jsonCookies = json.dumps(dictCookies) 
    with open('/mnt/share/live-tool/tools/cookies.txt', 'w') as f:
        f.write(jsonCookies)
    print('cookies!')

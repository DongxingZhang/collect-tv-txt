import wininet
import pythoncom
 
class NetworkInterceptor:
    def __init__(self):
        # 初始化COM库
        pythoncom.CoInitialize()
        # 创建一个Internet Session对象
        self.internet = wininet.InternetOpen("Interceptor", wininet.INTERNET_OPEN_TYPE_PRECONFIG, None, None, 0)
 
    def set_url_filter(self, hostname, url):
        # 设置URL过滤器
        self.hostname = hostname
        self.url = url
        # 注册URL过滤器
        wininet.InternetSetOption(0, wininet.INTERNET_OPTION_SET_URL_PREFIX_W, self.hostname, len(self.hostname)*2+2)
        wininet.InternetSetOption(0, wininet.INTERNET_OPTION_SET_URL_PREFIX_W, self.url, len(self.url)*2+2)
 
    def close(self):
        # 关闭Internet Session对象
        self.internet.CloseHandle()
        # 取消注册URL过滤器
        wininet.InternetSetOption(0, wininet.INTERNET_OPTION_SET_URL_PREFIX_W, None, 0)
        wininet.InternetSetOption(0, wininet.INTERNET_OPTION_SET_URL_PREFIX_W, None, 0)
        # 关闭COM库
        pythoncom.CoUninitialize()
 
# 使用示例
interceptor = NetworkInterceptor()
interceptor.set_url_filter(b"https://www.ott.pm", b"https://www.ott.pm")
 
# 在这里运行第三方应用程序，请求会被拦截
 
interceptor.close()
from main import refresh
import os
from datetime import datetime
import time
while True:
    refresh("init", None)
    refresh("epgpw", "download")
    os.system("git add history")
    message=datetime.now().strftime('%Y%m%d%H%M%S')
    os.system("git commit -a -s -m '" + message + "'")
    os.system("git push")
    time.sleep(1800)


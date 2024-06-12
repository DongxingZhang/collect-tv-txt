# -*- coding: utf-8 -*-
import re
import sys
import time
import requests
import os
import shutil
 
from collections import OrderedDict


def remove_duplicates(in_file, out_file):
    with open(in_file, 'r', encoding='utf-8') as file:
        unique_lines = OrderedDict.fromkeys(file)
 
    with open(out_file, 'w', encoding='utf-8') as file:
        file.writelines(unique_lines)


filename=sys.argv[1]
remove_duplicates(filename, filename)
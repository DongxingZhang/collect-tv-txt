# LivePushTool

#### 介绍
自动化直播推流工具

#### 软件架构
基于FFMPEG自动化推流到直播推流链接


#### 安装教程

1.  使用linux shell编写，直接拷贝到本地

#### 使用说明

1.  配置list/list.txt保存所有影片库
2.  配置不同的平台的播放列表list/huya_list.txt  list/bili_list.txt  
3.  xxx_rtmp_pass.txt配置推流密码
4.  根据不同平台运行huya.sh/bili.sh/qq.sh bg/fg/stop 720
    参数1: bg，后台推流
          fg, 前台推流
          stop 停止推流
    参数2： 推流分辨率



pip install ffmpeg-python
pip install ffmpeg
pip install opencv-python
 pip install numpy





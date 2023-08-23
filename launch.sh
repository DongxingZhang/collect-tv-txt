#!/bin/bash

mode=$1
mvsource=$2
subfile=$3
config=$4
playlist=$5
playlist_done=$6
rtmp=$7
ffmpeglog=$8

echo $mode
echo ${mode:0:4}
echo $subfile
echo $config
echo $playlist
echo $playlist_done
echo $rtmp
echo $ffmpeglog

if [ "${mode:0:4}" != "test" ];then    
    while true; do
        arr=`ps -ef | grep "${rtmp}" | grep pb.sh | grep -v grep | grep -v bash | awk '{print $2}'`
        echo $arr
        if [ "${arr}" = "" ]; then
            break
        fi
        for i in "${arr[@]}" ; do
            echo killing the thread $i
            kill -9 $i
        done
        #killall ffmpeg
        sleep 3
    done
    #killall ffmpeg
    #killall pb.sh
    sleep 4    
    ps -elf | grep ffmpeg 
    ps -elf | grep pb.sh
fi
#read -p "请输入任意继续:" any
if [ "${mode:0:4}" = "test" ]; then
  echo "test pushing"
  bash ./pb.sh 2 "${mode}" "${mvsource}" "${subfile}"  "${config}"  "${playlist}"  "${playlist_done}" "${rtmp}" 
else
  echo "foreground pushing"
  bash ./pb.sh 2 "${mode}" "${mvsource}" "${subfile}"  "${config}"  "${playlist}"  "${playlist_done}" "${rtmp}"
fi


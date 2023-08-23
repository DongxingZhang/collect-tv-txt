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
    #ps -ef | grep "${rtmp}"| grep ffmpeg | grep -v grep | grep -v $$  | awk '{print $2}' | xargs kill -9
    killall ffmpeg
    killall pb.sh
    sleep 4    
    ps -elf | grep ffmpeg 
    ps -elf | grep pb.sh
fi
#read -p "请输入任意继续:" any
if [ "${mode:0:2}" = "bg" ]; then
  echo "background pushing"
  nohup ./pb.sh 2 "{mode}" "${mvsource}" "${subfile}"  "${config}"  "${playlist}"  "${playlist_done}" "${rtmp}" >  ${ffmpeglog}  2>&1 &
  sleep 2
  ps -elf | grep ffmpeg
  ps -elf | grep pb.sh
elif [ "${mode:0:2}" = "fg" ]; then
  echo "foreground pushing"
  ./pb.sh 2 "${mode}" "${mvsource}" "${subfile}"  "${config}"  "${playlist}"  "${playlist_done}" "${rtmp}"  
elif [ "${mode:0:4}" = "test" ]; then
  echo "test pushing"
  ./pb.sh 2 "${mode}" "${mvsource}" "${subfile}"  "${config}"  "${playlist}"  "${playlist_done}" "${rtmp}" 
else
  echo "exit"
fi


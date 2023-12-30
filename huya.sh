#!/bin/bash
curdir=$(pwd)
mode=$1
mvsource=2
sheight=$2
subfile="${curdir}/sub/huya_sub.srt"
config="${curdir}/list/huya_config.txt"
playlist="${curdir}/list/huya_list.txt"
playlist_done="${curdir}/list/huya_list_done.txt"
ffmpeglog="${curdir}/log/huya.log"
news="${curdir}/log/huya_news.txt"

rtmp="${curdir}/huya_rtmp_pass.txt"
rtmp_link="rtmp://al.direct.huya.com/huyalive/"
rtmp_token=$(cat ${rtmp})

kill_app() {
  app=$1
  while true; do
    pidlist=$(ps -ef | grep "${rtmp_link}" | grep "${app}" | grep -v "ps -ef" | grep -v grep | awk '{print $2}')
    echo ${pidlist}
    arr=($pidlist)
    if [ ${#arr[@]} -eq  0 ]; then
      break
    fi
    for i in "${arr[@]}"; do
      echo killing the thread $i
      kill -9 $i
    done
    sleep 3
  done
}


kill_app "launch.sh"
pidlist=$(ps -ef | grep "${rtmp_link}" | grep "${app}" | grep -v "ps -ef" | grep -v grep | awk '{print $2}')
echo ${pidlist}

./launch.sh "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp}" "${news}" "${sheight}" "${rtmp_link}" "${ffmpeglog}"


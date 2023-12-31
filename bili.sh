#!/bin/bash
curdir=$(pwd)
mode=$1
mvsource=2
sheight=$2
subfile="${curdir}/sub/bili_sub.srt"
config="${curdir}/list/bili_config.txt"
playlist="${curdir}/list/bili_list.txt"
playlist_done="${curdir}/list/bili_list_done.txt"
ffmpeglog="${curdir}/log/bili.log"
news="${curdir}/log/bili_news.txt"

rtmp="${curdir}/bili_rtmp_pass.txt"
rtmp_link="rtmp://live-push.bilivideo.com/live-bvc/"
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


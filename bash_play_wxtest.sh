#!/bin/bash
curdir=$(pwd)
mode=$1
sheight=$2
mvsource=2
subfile="${curdir}/sub/sub4.srt"
config="${curdir}/list/config4.txt"
playlist="${curdir}/list/playlist2.txt"
playlist_done="${curdir}/list/playlist_done2.txt"
ffmpeglog="${curdir}/log/ffmpeg4.log"
news="${curdir}/log/news4.txt"
rtmp="${curdir}/rtmp_pass4.txt"
rtmp_link="rtmp://www.tomandjerry.work/live/livestream"
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

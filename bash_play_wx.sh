#!/bin/bash
curdir=$(pwd)
mode=$1
sheight=$2
mvsource=2
subfile="${curdir}/sub/sub.srt"
config="${curdir}/list/config.txt"
playlist="${curdir}/list/playlist.txt"
playlist_done="${curdir}/list/playlist_done.txt"
ffmpeglog="${curdir}/log/ffmpeg.log"
news="${curdir}/log/news.txt"
rtmp="rtmp://qqgroup.6721.livepush.ilive.qq.com/trtc_1400526639/$(cat ${curdir}/rtmp_pass.txt)"


kill_app() {
  rtmp=$1
  app=$2
  while true; do
    pidlist=$(ps -ef | grep "${rtmp}" | grep "${app}" | grep -v "ps -ef" | grep -v grep | awk '{print $2}')
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


kill_app "${rtmp}" "launch.sh"


if [ "${mode:0:2}" = "bg" ]; then
	nohup bash ./launch.sh "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp}" "${news}" "${sheight}" > ${ffmpeglog} &
else
	bash ./launch.sh "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp}" "${news}" "${sheight}"
fi


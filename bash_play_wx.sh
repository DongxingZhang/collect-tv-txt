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

if [ "${mode:0:2}" = "bg" ]; then
	nohup bash ./launch.sh "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp}" "${news}" "${sheight}" > ${ffmpeglog} &
else
	bash ./launch.sh "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp}" "${news}" "${sheight}"
fi


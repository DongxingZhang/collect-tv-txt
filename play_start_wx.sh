#!/bin/bash
curdir=$(pwd)
mode=$1  
mvsource=$2
subfile="${curdir}/sub/sub.srt"
config="${curdir}/list/config.txt"
playlist="${curdir}/list/playlist.txt"
playlist_done="${curdir}/list/playlist_done.txt"
ffmpeglog="${curdir}/log/ffmpeg.log"
rtmp="rtmp://qqgroup.6721.livepush.ilive.qq.com/trtc_1400526639/$(cat ${curdir}/rtmp_pass.txt)"
./launch.sh "${mode}" "${mvsource}" "${subfile}"  "${config}"  "${playlist}"  "${playlist_done}" "${rtmp}" "${ffmpeglog}"

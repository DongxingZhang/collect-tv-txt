#!/bin/bash
curdir=$(pwd)
mode=$1  
mvsource=$2
subfile="${curdir}/sub/sub2.srt"
config="${curdir}/list/config2.txt"
playlist="${curdir}/list/playlist2.txt"
playlist_done="${curdir}/list/playlist_done2.txt"
ffmpeglog="${curdir}/log/ffmpeg2.log"
rtmp="rtmp://qqgroup.6721.livepush.ilive.qq.com/trtc_1400526639/$(cat ${curdir}/rtmp_pass2.txt)"


if [ "${mode:0:2}" = "bg" ]; then
    nohup bash ./launch.sh "${mode}" "${mvsource}" "${subfile}"  "${config}"  "${playlist}"  "${playlist_done}" "${rtmp}" "${ffmpeglog}" > ${ffmpeglog} 2$>1 &
else
    bash ./launch.sh "${mode}" "${mvsource}" "${subfile}"  "${config}"  "${playlist}"  "${playlist_done}" "${rtmp}" "${ffmpeglog}"
fi


#!/bin/bash
curdir=$(pwd)
mode=$1
mvsource=2
subfile="${curdir}/sub/sub2.srt"
config="${curdir}/list/config2.txt"
playlist="${curdir}/list/playlist2.txt"
playlist_done="${curdir}/list/playlist_done2.txt"
ffmpeglog="${curdir}/log/ffmpeg2.log"
news="${curdir}/log/news2.txt"

#rtmp="rtmp://qqgroup.6721.livepush.ilive.qq.com/trtc_1400526639/$(cat ${curdir}/rtmp_pass2.txt)"
addr="rtmp://sendtc3.douyu.com/live/"
live="1077252rMdSYl1pK?wsSecret=411348d7c30cab183a0eb8e800d0f8fd&wsTime=64ee15ad&wsSeek=off&wm=0&tw=0&roirecognition=0&record=flv&origin=tct&txHost=sendtc3a.douyu.com"
rtmp=${addr}${live}

if [ "${mode:0:2}" = "bg" ]; then
	nohup ./launch.sh "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp}" "${news}"  > ${ffmpeglog} &
else
	./launch.sh "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp}" "${news}"
fi

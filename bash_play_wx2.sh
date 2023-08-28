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
live="1077252r6BAm3CVt?wsSecret=31b1c1116ac7ef0893f6617db015e7f9&wsTime=64ebedfc&wsSeek=off&wm=0&tw=0&roirecognition=0&record=flv&origin=tct&txHost=sendtc3.douyu.com"
live="1077252r6BAm3CVt?wsSecret=b93bbf660d16963da5ed142dc7017078&wsTime=64ed343b&wsSeek=off&wm=0&tw=0&roirecognition=0&record=flv&origin=tct&txHost=sendtc3.douyu.com"
rtmp=${addr}${live}

if [ "${mode:0:2}" = "bg" ]; then
	nohup ./launch.sh "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp}" "${news}"  > ${ffmpeglog} &
else
	./launch.sh "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp}" "${news}"
fi

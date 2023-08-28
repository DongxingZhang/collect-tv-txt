#!/bin/bash

mode=$1
mvsource=$2
subfile=$3
config=$4
playlist=$5
playlist_done=$6
rtmp=$7
news=$8
sheight=$9

echo $mode
echo ${mode:0:4}
echo $subfile
echo $config
echo $playlist
echo $playlist_done
echo $rtmp
echo $news
echo $sheight

kill_app() {
	rtmp=$1
	app=$2
	while true; do
		pidlist=$(ps -ef | grep "${rtmp}" | grep "${app}" | grep -v "ps -ef" | grep -v grep | awk '{print $2}')
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

if [ "${mode:0:4}" != "test" ]; then
    kill_app "${rtmp}" "ffmpeg -re"
	kill_app "${rtmp}" "pb.sh" 
	sleep 4
	ps -elf | grep ffmpeg
	ps -elf | grep pb.sh
fi
#read -p "请输入任意继续:" any
if [ "${mode:0:4}" = "test" ]; then
	echo "test pushing"
	./pb.sh 2 "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp}" "${news}" "${sheight}"
elif [ "${mode:0:2}" = "fg" ] || [  "${mode:0:2}" = "bg"   ] ; then
	echo "foreground pushing"
	./pb.sh 2 "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp}" "${news}" "${sheight}"
fi

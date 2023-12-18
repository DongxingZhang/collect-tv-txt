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
rtmp_link=${10}
log=${11}
echo mode=$mode
echo mode=${mode:0:4}
echo subfile=$subfile
echo config=$config
echo playlist=$playlist
echo playlist_done=$playlist_done
echo rtmp_token=$rtmp
echo news=$news
echo sheight=$sheight
echo rtmp_link=$rtmp_link
echo log=$log

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

while true; do
  if [ "${mode:0:4}" != "test" ] && [ "${mode:0:4}" != "list" ]; then
    kill_app "ffmpeg -re"
    sleep 3
    kill_app "pb.sh" 
    sleep 3
  fi

  echo pb.sh=`ps -ef | grep "${rtmp_link}" | grep "pb.sh"  | grep -v "ps -ef" | grep -v grep | awk '{print $2}'`
  echo ffmpeg=`ps -ef | grep "${rtmp_link}" | grep "ffmpeg -re"  | grep -v "ps -ef" | grep -v grep | awk '{print $2}'`

  rtmp_push="${rtmp_link}$(cat ${rtmp})"
  echo rtmp_push=${rtmp_push}

  #read -p "请输入任意继续:" any
  if [ "${mode:0:4}" = "test" ]; then
    echo "test pushing"
    ./pb.sh 2 "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp_link}" "${news}" "${sheight}" "${rtmp}"
  elif [ "${mode:0:2}" = "fg" ]; then
    echo "foreground pushing"
    ./pb.sh 2 "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp_link}" "${news}" "${sheight}" "${rtmp}"
  elif [ "${mode:0:2}" = "bg" ]; then
    echo "background pushing"
    nohup ./pb.sh 2 "${mode}" "${mvsource}" "${subfile}" "${config}" "${playlist}" "${playlist_done}" "${rtmp_link}" "${news}" "${sheight}" "${rtmp}"  > "${log}"  &
  fi
  echo 启动完毕 
  sleep 3
  break
done





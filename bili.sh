#!/bin/bash
curdir=$(pwd)
mode=$1
rtmp_link="rtmp://live-push.bilivideo.com/live-bvc/"
rtmp_token="${curdir}/bili_rtmp_pass.txt"
sheight=$2
token=bili

kill_app() {
  app=$1
  while true; do
    pidlist=$(ps -ef | grep "${rtmp_link}" | grep "${app}" | grep -v "ps -ef" | grep -v grep | awk '{print $2}')
    echo ${pidlist}
    arr=($pidlist)
    if [ ${#arr[@]} -eq 0 ]; then
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

./launch.sh "${mode}" "${rtmp_link}" "$(cat ${rtmp_token})" "${token}" "${sheight}" 

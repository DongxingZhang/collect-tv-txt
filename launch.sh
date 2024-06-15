#!/bin/bash
curdir=$(pwd)
mode=$1
rtmp_link=$2
rtmp_token=$3
token=$4
sheight=$5


echo mode=$mode
echo mode=${mode:0:4}
echo rtmp_link=$rtmp_link
echo rtmp_token=$rtmp_token
echo sheight=$sheight
echo token=$token

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

while true; do
  if [ "${mode:0:4}" != "test" ] && [ "${mode:0:4}" != "list" ]; then
    kill_app "ffmpeg -re"
    sleep 3
    kill_app "pb.sh"
    sleep 3
  fi

  echo pb.sh=$(ps -ef | grep "${rtmp_link}" | grep "pb.sh" | grep -v "ps -ef" | grep -v grep | awk '{print $2}')
  echo ffmpeg=$(ps -ef | grep "${rtmp_link}" | grep "ffmpeg -re" | grep -v "ps -ef" | grep -v grep | awk '{print $2}')

  rtmp_push="${rtmp_link}${rtmp_token}"

  echo rtmp_push=${rtmp_push}

  #read -p "请输入任意继续:" any
  if [ "${mode:0:4}" = "test" ]; then
    echo "test pushing"
    bash ./pb.sh "${mode}" "${rtmp_link}" "${rtmp_token}" "${token}" "${sheight}"
  elif [ "${mode:0:2}" = "fg" ]; then
    echo "foreground pushing"
    bash ./pb.sh "${mode}" "${rtmp_link}" "${rtmp_token}" "${token}" "${sheight}"
  elif [ "${mode:0:2}" = "bg" ]; then
    echo "background pushing"
    nohup bash ./pb.sh "${mode}" "${rtmp_link}" "${rtmp_token}" "${token}" "${sheight}" >"${curdir}/log/${token}.log"  2>&1  &
  fi
  echo 启动完毕
  sleep 3
  break
done

#!/bin/bash
token=$1
rootdir=`pwd`
echo ${rootdir}
bash ${rootdir}/${token}.sh bg 750
while true; do
    log=$(cat "${rootdir}/log/${token}.log" | grep -a "invalid dropping" | grep -a "DTS" | head -3)
    echo ===============$log
    if [ "${log}" != "" ]; then        
        bash ${rootdir}/${token}.sh bg 750
    fi
    sleep 15
    log=$(cat "${rootdir}/log/${token}.log" | grep -a "frame=" | grep -a "bitrate=" | grep -a "time=" | grep -a "size=" | grep -a "fps=" | head -3)
    echo --------------$log
    if [ "${log}" = "" ]; then
        bash ${rootdir}/${token}.sh bg 750
    fi
    sleep 15
done

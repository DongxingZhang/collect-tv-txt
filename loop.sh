#!/bin/bash
token=$1
rootdir=`pwd`

echo ${rootdir}
bash ${rootdir}/${token}.sh bg 750

prev_frame_log=
while true; do
    crash=$(cat "${rootdir}/log/${token}.log" | grep -a "invalid dropping" | grep -a "DTS" | tail -1)
    echo ===============${crash}
    if [ "${crash}" != "" ]; then
        bash ${rootdir}/${token}.sh bg 750
    fi
    sleep 20

    #frame_log=$(cat "${rootdir}/log/${token}.log" | grep -a "frame=" | grep -a "bitrate=" | grep -a "time=" | grep -a "size=" | grep -a "fps=" | tail -1 | awk -F'dup' '{print $1}')
    #echo --------------${frame_log}
    #if [ "${frame_log}" = "" ]; then
    #    bash ${rootdir}/${token}.sh bg 750
    #fi
    #if [ "${frame_log}" != "" ] && [ "${prev_frame_log}" = "${frame_log}" ]; then
    #    bash ${rootdir}/${token}.sh bg 750
    #fi
    #prev_frame_log=${frame_log}
    #sleep 20
done

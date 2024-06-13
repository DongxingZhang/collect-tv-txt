#!/bin/bash
token=$1
./${token}.sh bg 750
while true; do
    log=$(cat "./log/${token}.log" | grep -a "invalid dropping" | grep -a "\[warning\] DTS" | head -1)
    echo $log
    if [ "${log}" != "" ]; then
        echo 11111
	    ./${token}.sh bg 750
	fi
    sleep 5
done


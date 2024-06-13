#!/bin/bash
token=$1
while true; do
    log=$(cat ""./log/${token}.log"" | grep "invalid dropping" | grep "\[warning\] DTS" | head -1)
    if [ "${log}" != "" ]; then
	    ./${token}.sh bg 750 
	fi
    sleep 5
done

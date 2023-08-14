

    loop=0
    while true
    do
        if [ ${loop} -gt 50  ];then
            break
        fi
        loop=$(expr ${loop} + 1)
        if [ ${loop} -lt 10  ];then
            loop=`echo 0${loop}`
        fi

        #echo "D:\Mkvmerge_GUI\mkvmerge.exe" -o "C:\\Users\\dx\\Downloads\\${loop}.mkv"  "--forced-track" "0:no" "--forced-track" "1:no" "-a" "1" "-d" "0" "-S" "-T" "--no-global-tags" "--no-chapters" "(" "C:\\Users\\dx\\Downloads\\义不容情\\${loop}.ts" ")" "--forced-track" "0:no" "-s" "0" "-D" "-A" "-T" "--no-global-tags" "--no-chapters" "(" "C:\\Users\\dx\\Downloads\\义不容情\\外挂字幕\\${loop}.srt" ")" "--track-order" "0:0,0:1,1:0"
        echo mv "'/mnt/smb/电视剧/楚汉骄雄/楚汉骄雄 (${loop}).ts'" "'/mnt/smb/电视剧/楚汉骄雄/楚汉骄雄${loop}.ts'"
    done


     #vncserver :2 -geometry 1920x1080 -localhost no

https://qqgroup.6721.liveplay.ilive.qq.com/live/6721_10bd33d77ea8f2512206003b782da42c_1080p4000k.flv?txSecret=093736e8e78a258e60de4e9b626623f2&txTime=64DA2370
https://qqgroup.6721.liveplay.ilive.qq.com/live/6721_d14cc94308e33157bd1d2eb3bc31f458_1080p4000k.flv?txSecret=22ceae68e499fc6919c22d67a092dfec&txTime=64DA27DF
tvb1="https://al.flv.huya.com/src/1199561177177-1199561177177-5434428961511702528-2399122477810-10057-A-0-1.flv"
tvb2="https://al.flv.huya.com/src/1199561463578-1199561463578-5435659044440244224-2399123050612-10057-A-0-1.flv"
tvb3="https://al.flv.huya.com/src/1199563486009-1199563486009-5444345319443660800-2399127095474-10057-A-0-1.flv"
tvb4="https://al.flv.huya.com/src/1199563493375-1199563493375-5444376956172763136-2399127110206-10057-A-0-1.flv"
tvb5="https://al.flv.huya.com/src/1199563481280-1199563481280-5444325008543318016-2399127086016-10057-A-0-1.flv"
tvb6="https://al.flv.huya.com/src/1199561244004-1199561244004-5434715981291192320-2399122611464-10057-A-0-1.flv"


rtmp="rtmp://www.tomandjerry.work/live/livestream"
stream=${tvb1}
#ffmpeg -loglevel repeat+level+warning -re -i "${stream}" -preset ultrafast -filter_complex "[0:v:0]eq=contrast=1[bg1];[0:a:0]volume=1.0[bga];" -map [bg1] -map [bga] -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y ${rtmp}

ffmpeg -loglevel repeat+level+warning -re -i "${stream}" -c copy -f flv -y ${rtmp}
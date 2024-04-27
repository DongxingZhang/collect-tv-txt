

    loop=0
    while true
    do
        if [ ${loop} -gt 100  ];then
            break
        fi
        loop=$(expr ${loop} + 1)
        if [ ${loop} -lt 10  ];then
            loop=`echo 0${loop}`
        fi

        #echo "D:\Mkvmerge_GUI\mkvmerge.exe" -o "C:\\Users\\dx\\Downloads\\${loop}.mkv"  "--forced-track" "0:no" "--forced-track" "1:no" "-a" "1" "-d" "0" "-S" "-T" "--no-global-tags" "--no-chapters" "(" "C:\\Users\\dx\\Downloads\\义不容情\\${loop}.ts" ")" "--forced-track" "0:no" "-s" "0" "-D" "-A" "-T" "--no-global-tags" "--no-chapters" "(" "C:\\Users\\dx\\Downloads\\义不容情\\外挂字幕\\${loop}.srt" ")" "--track-order" "0:0,0:1,1:0"
        #echo mv "'${loop}【微信公众号：宁彩彩】.mkv'" "'EP${loop}.ts'"
        echo mv "'知否知否应是绿肥红瘦 ${loop}.mp4'" "'EP${loop}.mkv'" 
    done


     #vncserver :2 -geometry 1920x1080 -localhost no


#合并视频先转mpg再合并
ffmpeg -i a1.mp4 -qscale 4 a1.mpg
ffmpeg -i a2.mp4 -qscale 4 a2.mpg
cat a1.mpg a2.mpg| ffmpeg -f mpeg -i - -qscale 6 -vcodec mpeg4 output.mp4

#合并视频先转ts再合并
ffmpeg -i 1.mp4 -vcodec copy -acodec copy -vbsf h264_mp4toannexb 1.ts
ffmpeg -i 2.mp4 -vcodec copy -acodec copy -vbsf h264_mp4toannexb 2.ts
ffmpeg -i "concat:1.ts|2.ts" -acodec copy -vcodec copy -absf aac_adtstoasc output.mp4



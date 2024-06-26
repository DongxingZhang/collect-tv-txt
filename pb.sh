#!/bin/bash

max_size=99999999

####功能函数START
get_stream_track() {
    track=$(${FFPROBE} -loglevel repeat+level+warning -i "$1" -show_streams -print_format csv | awk -F, '{print $1,$2,$3,$6}' | grep "$2" | awk 'NR==1{print $2}')
    echo ${track}
}

get_stream_track_decode() {
    track=$(${FFPROBE} -loglevel repeat+level+warning -i "$1" -show_streams -print_format csv | awk -F, '{print $1,$2,$3,$6}' | grep "$2" | awk 'NR==1{print $3}')
    echo ${track}
}

get_duration() {
    if [[ $1 =~ ^http ]] || [[ $1 =~ ^rtmp ]]; then
        echo ${max_size}
    else
        duration=$(${FFPROBE} -loglevel repeat+level+warning -i "$1" -show_entries format=duration -v quiet -of csv="p=0")
        echo ${duration}
    fi
}

get_duration2() {
    if [[ $1 =~ ^http ]] || [[ $1 =~ ^rtmp ]]; then
        echo ${max_size}
    else
        data=$(${FFPROBE} -hide_banner -show_format -show_streams "$1" 2>&1)
        if [ "$2" -lt 3600 ]; then
            Duration=$(echo $data | awk -F 'Duration: ' '{print $2}' | awk -F ',' '{print $1}' | awk -F '.' '{print $1}' | awk -F ':' '{print $2"\\\:"$3}')
        else
            Duration=$(echo $data | awk -F 'Duration: ' '{print $2}' | awk -F ',' '{print $1}' | awk -F '.' '{print $1}' | awk -F ':' '{print $1"\\\:"$2"\\\:"$3}')
        fi
        echo ${Duration}
    fi
}

get_file_size(){
    if [[ $1 =~ ^http ]] || [[ $1 =~ ^rtmp ]]; then
        echo ${max_size}
    else
        actualsize=$(wc -c <"$1")
        echo ${actualsize}
    fi
}

get_frames() {
    if [[ $1 =~ ^http ]] || [[ $1 =~ ^rtmp ]]; then
        echo ${max_size}
    else
        data=$(${FFPROBE} -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 "$1")
        if [ "${data}" = "" ]; then
            data=$(${FFPROBE} -v error -select_streams a:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 "$1" | head -n 1 | tr -d '\r' | tr -d '\n')
        fi
        echo $data
    fi
}

get_fontsize() {
    height=$1
    newfontsize=$(echo "scale=5;$height/900*$fontsize" | bc)
    newfontsize=$(echo "scale=0;$newfontsize/1" | bc)
    if [ ${newfontsize} -eq 0 ]; then
        newfontsize=50
    fi
    echo ${newfontsize}
}

get_size() {
    data=$(${FFPROBE} -hide_banner -show_format -show_streams "$1" 2>&1)
    for num in {2..10..1}
    do
        width=$(echo $data | awk -v var=$num -F 'width=' '{print $var}' | awk -F ' ' '{print $1}')
        height=$(echo $data | awk -v var=$num -F 'height=' '{print $var}' | awk -F ' ' '{print $1}')
        if [ "${width}" = "N/A" ] || [ "${height}" = "N/A" ]; then
            continue
        fi
        break
    done
    echo "${width}|${height}"

}

digit_half2full() {
    if [ $1 -lt 10 ] && [ $1 -ge 0 ]; then
        res=$(echo $1 | sed 's/0/０/g' | sed 's/1/１/g' | sed 's/2/２/g' | sed 's/3/３/g' | sed 's/4/４/g' | sed 's/5/５/g' | sed 's/6/６/g' | sed 's/7/７/g' | sed 's/8/８/g' | sed 's/9/９/g')
        echo $res
    else
        echo $1
    fi
}

find_substr_count() {
    count=$(echo "$1" | grep -o "$2" | wc -l)
    echo ${count}
}

get_dir() {
    DIR="$(dirname "$1")"
    echo $DIR
}

get_file() {
    FILE="$(basename "$1")"
    echo $FILE
}

check_even() {
    num=$1
    if [ $((num % 2)) -eq 0 ]; then
        echo "1"
    else
        echo "0"
    fi
}

check_video_path() {
    videopath=$1
    if [[ ${videopath} =~ ^http ]] || [[ ${videopath} =~ ^rtmp ]]; then
        echo ${videopath}
    else
        for ((i=0;i<${#folder_array[@]};i++)) do
            if [[ -e "${folder_array[i]}${videopath}" ]]; then
                echo "${folder_array[i]}${videopath}"
                break
            fi
        done;
    fi
}

check_srt_path() {
    dirname=$(dirname $1)
    filename=$(basename $1)
    ext=${filename##*.}
    name=${filename%.*}
    if [[ -f "${dirname}/srt/${name}.srt" ]]; then
        echo "${dirname}/srt/${name}.srt"
    elif [[ -f "${dirname}/srt/${name}.SRT" ]]; then
        echo "${dirname}/srt/${name}.SRT"
    else
        echo ""
    fi
}

kill_app() {
    while true; do
        pidlist=$(ps -ef | grep "$1" | grep "$2" | grep -v "ps -ef" | grep -v grep | awk '{print $2}')
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

#get_srt() {
#    fullpath=$1
#    dir=$(dirname "${fullpath}")
#    filename=$(basename "${fullpath}")
#    extension="${filename##*.}"
#    filenameprefix="${filename%.*}"
#    srt="${dir}/${filenameprefix}.srt"
#    if [[ -f "${srt}" ]]; then
#        echo "${srt}"
#    else
#        echo ""
#    fi
#}

####功能函数END

stream_play_main() {
    line=$1
    line=$(echo ${line} | tr -d '\r' | tr -d '\n')
    line=$(echo ${line} | tr ' ' '%')

    arr=(${line//|/ })
    video_type=${arr[0]:0:3}
    video_skip=${arr[0]:3}
    lighter=${arr[1]}
    audio=${arr[2]:0:1}
    adch=${arr[2]:1:1}
    subtitle=${arr[3]:0:1}
    subtrans=${arr[3]:1:1}
    param=${arr[4]}
    cur_file=${arr[5]}
    file_count=${arr[6]}
    play_time=${arr[7]}
    file_type=${arr[8]}
    videoname=${arr[9]}
    videopath=$(echo ${arr[10]} | tr '%' ' ')
    videopath0=${arr[11]}
    cur_times=${arr[12]}
    playtimes=${arr[13]}

    mode=$2
    period=$3
    echo ${mode}
    echo ${period}


    #取链接的地址
    if [[ ${videopath} =~ ^http ]] || [[ ${videopath} =~ ^rtmp ]]; then
        for i in 1 2 3 4 5 6
        do                
            pgrep get_live_link.py | xargs kill -s 9
            python3 get_live_link.py "${videopath}" "./log/${token}_route.txt"
            videopath1=$(cat "./log/${token}_route.txt")
            echo videopath1=${videopath1}
            if [ "${videopath1}" != "" ]; then
                break
            fi
        done
        if [ "${videopath1}" = "" ]; then
            return
        fi
        videopath=${videopath1}
        echo videopath=${videopath}
    fi
    echo -e ${yellow}视频类别（delogo）:${font} ${video_type}
    echo -e ${yellow}视频跳过:${font} ${video_skip}
    echo -e ${yellow}是否明亮（F为维持原亮度）:${font} ${lighter}
    echo -e ${yellow}音轨（F为不选择）:${font} ${audio}
    echo -e ${yellow}字幕轨（F为不选择）:${font} ${subtitle}
    echo -e ${yellow}LOGO（F武侠logo）:${font} ${param}
    echo -e ${yellow}视频路径:${font} ${videopath}
    echo -e ${yellow}当前集数:${font} ${cur_file}
    echo -e ${yellow}总集数:${font} ${file_count}
    echo -e ${yellow}播放标记:${font} ${play_time}
    echo -e ${yellow}播放类型:${font} ${file_type}
    echo -e ${yellow}电视剧名称:${font} ${videoname}
    echo -e ${yellow}播放模式（bg, fg, test）:${font} ${mode}
    rtmp="${rtmp_link}${rtmp_token}"
    echo ${rtmp}

    echo  ${videopath} >> ${playing_video}
 
    #增加所有声道支持 还未启用
    if [ "${auch}" = "L" ]; then
        audio_channel=" -af pan=stereo|c0=FL "
    elif [ "${auch}" = "R" ]; then
        audio_channel=" -af pan=stereo|c1=FR "
    else
        audio_channel=
    fi

    if [[ -d "${videopath}" ]]; then
        return 0
    fi

    # 文件超过8GB不要播放
    maxsize=800000000000000
    actualsize=$(get_file_size "${videopath}")
    echo 文件大小:$actualsize

    if [ $actualsize -lt 1000 ]; then
        rm -rf "${videopath}"
        return 0
    fi

    if [ $actualsize -ge $maxsize ]; then
        return 0
    fi

    video_track=$(get_stream_track "${videopath}" "video")
    video_track_decode=$(get_stream_track "${videopath}" "video")
    audio_track=$(get_stream_track "${videopath}" "audio")
    audio_track_decode=$(get_stream_track "${videopath}" "audio")
    sub_track=$(get_stream_track "${videopath}" "subtitle")
    sub_track_decode=$(get_stream_track "${videopath}" "subtitle")

    echo video_track=${video_track}
    echo video_track_decode=${video_track_decode}
    echo audio_track=${audio_track}
    echo audio_track_decode=${audio_track_decode}
    echo sub_track=${sub_track}
    echo sub_track_decode=${sub_track_decode}

    backgroundv="[2:v:0]"
    mapv="[0:v:0]"
    mapa="[0:a:0]"
    maps=""

    if [ "${subtitle}" = "E" ] || [ "${sub_track}" = "" ]; then
        maps=""
        subtitle=""
    else
        maps="0:s:${subtitle}"  
    fi
    
    if [ "${audio}" = "F" ]; then
        mapa="[0:a:0]"
    else
        mapa="[0:a:${audio}]"
    fi

    #分辨率
    if [ "${video_type}" = "FFF" ] || [ "${video_type}" = "EEE" ] || [ "${video_type}" = "DDD" ]; then
        bgvideo=$(get_seq "${bgvideodir}" "${curdir}/count/bgpicno")
        ssize=$(get_size "${bgvideo}") #计算分辨率
    else
        ssize=$(get_size "${videopath}") #计算分辨率
    fi

    sizearr=(${ssize//|/ })
    size_width=${sizearr[0]}
    size_height=${sizearr[1]}

    echo width=$size_width
    echo height=$size_height

    #使用歌曲封面
    if [ "${video_type}" = "FFF" ] || [ "${video_track}" = "" ]; then
        framecount=$(get_frames "${videopath}")
        framecount2=$(get_frames "${bgvideo}")
        division=$(echo "scale=0;${framecount}/${framecount2}+1" | bc)
        echo framecount=${framecount}
        echo framecount2=${framecount2}
        echo division=${division}
        mapv="[3:v:0]loop=loop=${division}:size=${framecount2}:start=0[mapvvv];[mapvvv]"
        backgroundv="[3:v:0]"
    elif [ "${video_type}" = "DDD" ] || [ "${video_type}" = "EEE" ]; then
        framecount=$(get_frames "${videopath}")
        framecount2=$(get_frames "${bgvideo}")
        division=$(echo "scale=0;${framecount}/${framecount2}+1" | bc)
        echo framecount=${framecount}
        echo framecount2=${framecount2}
        echo division=${division}
        mapv="[3:v:0]loop=loop=${division}:size=${framecount2}:start=0[mapvvv];[mapvvv]"
        if [ $(expr ${division} \> 0.99) -eq 1 ]; then
            mapv="[3:v:0]setpts=${division}*PTS[mapvvv];[0:v:0]format=yuva444p,colorchannelmixer=aa=0.9,scale=$size_width/4:$size_height/4:eval=frame[pic];[mapvvv][pic]overlay=$size_width*14/20:$size_height*14/20[mapv4];[mapv4]"
        else
            mapv="[3:v:0]trim=start=5:duration=${duration_audio}[mapvvv];[0:v:0]format=yuva444p,colorchannelmixer=aa=0.9,scale=$size_width/4:$size_height/4:eval=frame[pic];[mapvvv][pic]overlay=$size_width*14/20:$size_height*14/20[mapv4];[mapv4]"
        fi
        backgroundv="[3:v:0]"
    else
        mapv="[0:v:0]"
        backgroundv="[2:v:0]"
    fi

    echo ${mapv}, ${mapa}, ${maps}, ${backgroundv}

    ################################开始配置过滤器
    whratio=$(printf "%.2f" $(echo "scale=2;${size_width}/${size_height}" | bc))
    echo 长宽比:${whratio}

    #片名
    scale_flag=0 #强制缩放
    if [ ${size_height} -gt ${sheight} ] || [ ${scale_flag} -eq 1 ]; then
        newfontsize=$(get_fontsize "${sheight}")
    else
        newfontsize=$(get_fontsize "${size_height}")
    fi
    echo fontsize=${newfontsize}

    #计算时间显示字体大小
    halfnewfontsize=$(expr ${newfontsize} \* 45 / 100)
    halfnewfontsize=$(echo "scale=0;${halfnewfontsize}/1" | bc)

    #设置时间行距
    line_spacing=$(expr ${halfnewfontsize} / 4)
    line_spacing=$(echo "scale=0;${line_spacing}/1" | bc)
    
    #节目预告
    #echo $(get_next_video_name) >${news}
    #echo > ${news}
    #cat <( curl -s http://www.nmc.cn/publish/forecast/  ) | tr -s '\n' ' ' |  sed  's/<div class="col-xs-4">/\n/g' | sed -E 's/<[^>]+>//g' | awk -F ' ' 'NF==5{print $1,$2,$3}' | head -n 32 | tr -s '\n' ';' | sed 's/徐家汇/上海/g' | sed 's/长沙市/长沙/g' >  ${news}    
    #echo "下集预告 ${news}"

    #台标选择
    logo=
    if [ "${param}" = "F" ]; then
        #武侠logo
        logo=${logodir}/logo.png
    elif [ "${param}" = "0" ]; then
        #怀旧人文logo
        logo=${logodir}/logo2.png
    elif [ "${param}" = "1" ]; then
        #音乐logo
        logo=${logodir}/logo3.png
    elif [ "${param}" = "FF" ]; then
        #武侠logo
        logo=${logodir}/logow.png
    elif [ "${param}" = "00" ]; then
        #怀旧logo
        logo=${logodir}/logow2.png
    elif [ "${param}" = "11" ]; then
        #音乐logo
        logo=${logodir}/logow3.png
    else
        logo=${logodir}/logow4.png
    fi

    echo 台标=${logo}

    #缩放
    echo "缩放size_height=${size_height}"
    echo "缩放sheight=${sheight}"
    if [ ${size_height} -gt ${sheight} ] || [ ${scale_flag} -eq 1 ]; then
        scales="scale=trunc(oh*a/2)*2:${sheight}:eval=frame"  # 主视频
        scales2="scale=trunc(oh*a/2)*2:${sheight}:eval=frame" # 背景图片
    else
        scales="scale=trunc(oh*a/2)*2:${size_height}:eval=frame"
        scales2="scale=trunc(oh*a/2)*2:${size_height}:eval=frame"
    fi

    # 背景图    
    background="${backgroundv}${scales2}[scalebg];[scalebg]scale=ih*16/9:-1:eval=frame,crop=h=iw*9/16,gblur=sigma=50,eq=saturation=0.9[bgimg];"
    #ffmpeg -i input.mp4 -crf=20 -vf 'split[original][copy];[copy]scale=ih*16/9:-1,crop=h=iw*9/16,gblur=sigma=80,eq=saturation=0.9[background];[background][original]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2' output.mp4

    #遮挡logo
    delogos=$(cat ${delogofile} | grep "^${video_type}|")

    if [ "${delogos}" = "" ]; then
        delogo=""
    else
        delogos=$(echo ${delogos} | tr -d '\r' | tr -d '\n')
        delogosarr=(${delogos//|/ })
        delogo="${delogosarr[1]}[delogv];[delogv]"
    fi

    #跳过${video_skip}秒
    audio_format="volume=1.0,atrim=start=1"
    videoskips="trim=start=1[vs];[vs]"
    if [ "${video_skip}" != "" ]; then
        videoskips="trim=start=${video_skip}[vs];[vs]"
        audio_format="volume=1.1,atrim=start=${video_skip}"
    fi

    #字幕
    echo maps=${maps}，subtitle=${subtitle}，subtrack=$sub_track

    subs=""
    if [ "${maps}" != "" ] && [ "${subtitle}" != "" ]; then
        subs="subtitles=filename=${videopath}:si=${subtitle}:fontsdir=${curdir}/fonts:force_style='Fontname=华文仿宋,Fontsize=15,Alignment=2,MarginV=30'[vsub];[vsub]"
    else
        srt_file=$(check_srt_path "${videopath}")
        if [ "${srt_file}" != "" ]; then
            subs="subtitles=filename=${srt_file}:fontsdir=${curdir}/fonts:force_style='Fontname=华文仿宋,Fontsize=15,Alignment=2,MarginV=30'[vsub];[vsub]"
        fi
    fi

    #求视频的秒数的2/3
    duration_sec_org=$(get_duration "${videopath}")
    duration_sec=$(echo "scale=0;${duration_sec_org}*2/3" | bc)
    
    duration_sec_org_int=$(echo "scale=0;${duration_sec_org}/1" | bc)
    echo duration_sec_org_int=${duration_sec_org_int}

    #显示时长
    #播放百分比%{eif\:n\/nb_frames\:d}%%
    duration=$(get_duration2 "${videopath}" "${duration_sec_org_int}")
    right_pad=8
    if [ "${play_time}" = "rest" ]; then
        content=
    else
        if [ "${duration_sec_org_int}" -lt 3600 ]; then
            content="%{pts\:gmtime\:0\:%M\\\\\:%S}"
            right_pad=5
        else
            content="%{pts\:gmtime\:0\:%H\\\\\:%M\\\\\:%S}"
            right_pad=8
        fi
    fi
    #右上角
    #drawtext1="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:text='${content}':fontfile=${fonttimedir}:line_spacing=${line_spacing}:expansion=normal:x=w-line_h\*7:y=line_h/3\*5:shadowx=2:shadowy=2:${fontbg}[durv];[durv]"
    #左下角
    #drawtext1="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:text='${content}':fontfile=${fonttimedir}:line_spacing=${line_spacing}:expansion=normal:x=line_h\*8/2:y=h-line_h/3\*15:shadowx=2:shadowy=2:${fontbg}[durv];[durv]"
    #drawtext11="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:text='${duration}':fontfile=${fonttimedir}:line_spacing=${line_spacing}:expansion=normal:x=line_h\*8/2:y=h-line_h/3\*11:shadowx=2:shadowy=2:${fontbg}[durv2];[durv2]"
    #右下角
    #不显示时间
    content=
    duration=
    drawtext1="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:text='${content}':fontfile=${fonttimedir}:line_spacing=${line_spacing}:expansion=normal:x=w-line_h\*7-line_h\*${right_pad}/4:y=h-line_h/3\*15:shadowx=2:shadowy=2:${fontbg}[durv];[durv]"
    drawtext11="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:text='${duration}':fontfile=${fonttimedir}:line_spacing=${line_spacing}:expansion=normal:x=w-line_h\*7-line_h\*${right_pad}/4:y=h-line_h/3\*11:shadowx=2:shadowy=2:${fontbg}[durv2];[durv2]"

    #节目预告
    #从左往右drawtext2="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolor}:text='${news}':fontfile=${fontdir}:expansion=normal:x=(mod(5*n\,w+tw)-tw):y=h-line_h-10:shadowx=2:shadowy=2:${fontbg}"
    #从右到左
    drawtext2="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:textfile='${news}':fontfile=${fontforcastdir}:line_spacing=${line_spacing}:expansion=normal:x=w-mod(max(t-1\,0)*(w+tw\*5)/415\,(w+tw\*5)):y=h-line_h-5:shadowx=2:shadowy=2:${fontbg}[forcv];[forcv]"

    #显示时间
    drawtext22="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolor}:text='%{localtime\:%H\\\\\:%M\\\\\:%S}':fontfile=${fontdir}:line_spacing=${line_spacing}:expansion=normal:x=w-line_h\*7:y=line_h/3\*6:shadowx=2:shadowy=2:${fontbg}[currtime];[currtime]"    

    #显示标题
    echo 第${cur_file}集
    echo 共${file_count}集

#在右侧竖显剧名
#    if [ "${videoname}" = "精彩节目" ]; then
#        content2=""
#        cont_len=1
#    else
#        if [ "${file_count}" = "1" ]; then
#            cont_len=${#videoname}
#            content2=$(echo ${videoname} | sed 's#.#&\'"${enter}"'#g')
#            echo ${content2}
#        else            
#            splitstar="${enter}"
#            #splitstar="★"
#            cur_file2=$(digit_half2full ${cur_file})
#            if [ "${file_count}" = "${cur_file}" ]; then
#                vn=${videoname}${splitstar}大结局
#                cont_len=${#vn}
#                content2=$(echo ${videoname} | sed 's#.#&\'"${enter}"'#g')${splitstar}大${enter}结${enter}局
#            else
#                vn=${videoname}${splitstar}${cur_file2}
#                cont_len=${#vn}
#                content2=$(echo ${videoname} | sed 's#.#&\'"${enter}"'#g')${splitstar}${cur_file2}
#            fi
#            echo ${content2}
#            #cont_len=$(expr ${cont_len} + 1)
#        fi
#    fi
#    cont_len=$(expr ${cont_len} / 2)
#    drawtext3="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolorgold}:text='${content2}':fontfile=${fontdir}:line_spacing=${line_spacing}:expansion=normal:x=w-line_h\*3:y=h/2-line_h\*(${cont_len}+1):shadowx=2:shadowy=2:${fontbg}"

    epstart=8.5
    epstarty=6
    if [ "${videoname}" = "精彩节目" ]; then
        content2=""
    else
        if [ "${file_count}" = "1" ]; then
            content2=""            
        else
            if [ "${file_count}" = "${cur_file}" ]; then
                content2=大结局
                epstart=6.3
                epstarty=4
            else
                cur_file2=$(digit_half2full ${cur_file})
                content2="${cur_file2}"
            fi
        fi
    fi
    echo content2=${content2}
    drawtext3="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolorgold}:text='${content2}':fontfile=${fontdir}:line_spacing=${line_spacing}:expansion=normal:x=line_h\*${epstart}:y=line_h/3\*${epstarty}:shadowx=2:shadowy=2:${fontbg}"

    #增亮
    if [ "${lighter}" = "0" ]; then
        lights="eq=contrast=1[bg2]"
    else
        lights="hqdn3d,eq=contrast=1:brightness=0.2:saturation=1.5[bg2]"
    fi

    # 台标
    watermark="[1:v:0]scale=-1:${newfontsize}\*2:eval=frame[wm];" #[wm]

    # 混合台标
    logos="[wm]overlay=overlay_w/6:overlay_h/3[bg1];[bg1]"

    # 视频轨
    videos="${background}${watermark}${mapv}${delogo}${videoskips}${scales}[main];"

    # 视频补齐16:9
    videomakeup="[bgimg][main]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2[bg0];[bg0]"

    # 增加字幕和提示
    tips="${logos}${subs}${drawtext1}${drawtext11}${drawtext2}${drawtext22}${drawtext3}[bg];"

    # 音轨
    audios="${mapa}${audio_format}[bga];" #[bga]

    # 总选项
    video_format="${videos}${videomakeup}${tips}${audios}[bg]${lights}"

    #echo 滤镜:${video_format}

    ###########################################过滤器配置完成

    date1=$(TZ=Asia/Shanghai date +"%Y-%m-%d %H:%M:%S")

    echo videopath=${videopath}

    if [ "${mode:0:4}" != "test" ] && [ "${mode: -1}" != "a" ]; then
        kill_app "${rtmp}" "${FFMPEG}"
        echo ${FFMPEG} -re -loglevel "${logging}" -i "${videopath}" -i "${logo}" -i "${bgimg}" -i "${bgvideo}" -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg2]" -map "[bga]" -vsync 1 -async 1  -vcodec libx264 -g 60 -b:v 3000k -c:a aac -b:a 128k -ac 1 -ar 48000 -strict -2 -f flv -y "${rtmp}"
        nohup ${FFMPEG} -re -i "${videopath}" -i "${logo}" -i "${bgimg}" -i "${bgvideo}" -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg2]" -map "[bga]" -vsync 1 -async 1 -fflags discardcorrupt -err_detect aggressive -vcodec libx264 -g 60 -b:v 3000k -c:a aac -b:a 128k -ac 1 -ar 48000 -strict -2 -f flv -y "${rtmp}" &
        while true
        do
            sleep 20
            pidlist=$(ps -ef | grep "${rtmp}" | grep "${FFMPEG}" | grep -v "ps -ef" | grep -v grep | awk '{print $2}')
            if [ "${pidlist}" = "" ]; then
                break
            fi
        done              
        #ffmpeg  -timeout 30000000  -i http://39.134.65.164/PLTV/88888888/224/3221225569/1.m3u8 -vcodec libx264 -g 60 -b:v 3000k -c:a aac -b:a 128k -strict -2 -f flv -y  rtmp://www.tomandjerry.work/live/livestream
        echo finished playing $videopath
    fi

    date2=$(TZ=Asia/Shanghai date +"%Y-%m-%d %H:%M:%S")

    sys_date1=$(date -d "$date1" +%s)
    sys_date2=$(date -d "$date2" +%s)
    time_seconds=$(expr $sys_date2 - $sys_date1)

    echo mode=${mode}
    echo time_seconds=${time_seconds}
    echo play_time=${play_time}

    folder=${videopath0}

    if [ "${mode}" != "test" ] && [ ${time_seconds} -ge ${duration_sec} ]; then
        if [ "${play_time}" = "playing" ]; then
            video_played=$(cat "${playlist_done}" | grep "${period}|${folder}" | head -1)
            if [ "${video_played}" = "" ]; then
                echo "${period}|${folder}|${cur_file}|${file_count}|${cur_times}|${playtimes}" >>"${playlist_done}"
                cat ${playlist_done} | sort >./list/.pd.txt
                cp ./list/.pd.txt ${playlist_done}
                rm -rf ./list/.pd.txt
            else
                sed -i "s#${video_played}#${period}|${folder}|${cur_file}|${file_count}|${cur_times}|${playtimes}#" "${playlist_done}"
            fi
        fi
    else
        if [ "${play_time}" = "playing" ]; then
            video_played=$(cat "${playlist_done}" | grep "${period}|${folder}" | head -1)
            if [ "${video_played}" = "" ]; then
                echo "${period}|${folder}|${cur_file}|${cur_times}|${playtimes}"
            else
                echo sed -i "s#${video_played}#${period}|${folder}|${cur_file}|${file_count}|${cur_times}|${playtimes}#" "${playlist_done}"
            fi
        fi
    fi

}

ffmpeg_install() {
    # 安装FFMPEG
    read -p "你的机器内是否已经安装过FFmpeg4.x?安装FFmpeg才能正常推流,是否现在安装FFmpeg?(yes/no):" Choose
    if [ $Choose = "yes" ]; then
        apt-get install wget
        wget --no-check-certificate https://www.johnvansickle.com/ffmpeg/old-releases/ffmpeg-4.0.3-64bit-static.tar.xz
        tar -xJf ffmpeg-4.0.3-64bit-static.tar.xz
        cd ffmpeg-4.0.3-64bit-static
        mv ffmpeg /usr/bin && mv ${FFPROBE} /usr/bin && mv qt-faststart /usr/bin && mv ffmpeg-10bit /usr/bin
    fi
    if [ $Choose = "no" ]; then
        echo -e "${yellow} 你选择不安装FFmpeg,请确定你的机器内已经自行安装过FFmpeg,否则程序无法正常工作! ${font}"
        sleep 2
    fi
}

#判断当前时段
get_rest() {
    hours=$1
    ret="F|F|F"
    for line in $(cat ${config}); do
        line=$(echo ${line} | tr -d '\r' | tr -d '\n')
        # 判断是否要跳过
        flag=${line:0:1}
        if [ "${flag}" = "#" ]; then
            continue
        fi
        arr=(${line//|/ })
        start=${arr[0]}
        end=${arr[1]}
        index=${arr[2]}
        if [ ${start} -le ${end} ]; then
            if [ ${hours} -ge ${start} ] && [ ${hours} -le ${end} ]; then
                ret=${line}
                break
            fi
        else
            if [ ${hours} -ge ${start} ] || [ ${hours} -le ${end} ]; then
                ret=${line}
                break
            fi
        fi

    done
    echo ${ret}
}

#精确到分钟，获取当前时段
need_waiting() {
    hours=$(TZ=Asia/Shanghai date +%H)
    hours=$(expr ${hours} + 0)
    mins=$(TZ=Asia/Shanghai date +%M)
    mins=$(expr ${mins} + 0)
    ret=$(get_rest ${hours})

    if [ "${ret}" = "F|F|F" ]; then
        echo "F"
        return
    fi
    periodcount=$(cat ${config} | grep -v "^#" | sed /^$/d | wc -l)
    arr=(${ret//|/ })
    last_hour=${arr[1]}
    timed=${arr[2]}

    if [ "${hours}" = "${last_hour}" ]; then
        #判断当前分钟在40~59之间
        mins2end=$(expr 59 - ${mins})
        #判断下一个视频的长度是否大于mins2end分钟，如果两者都满足则播放下一个视频
        next_video=$(get_playing_video ${timed})
        arr_video=(${next_video//|/ })
        next_video_path=${arr_video[10]}
        dur=$(get_duration "${next_video_path}")
        dur=$(echo "scale=0;$dur/60+1" | bc)

        if [ ${mins2end} -le 20 ] && [ ${dur} -ge ${mins2end} ]; then
            nexthours=$(expr ${hours} + 1)
            if [ ${nexthours} -ge 24 ]; then
                nexthours=0
            fi
            retnext=$(get_rest ${nexthours})
            if [ "${retnext}" = "F|F|F" ]; then
                echo "F"
                return
            fi
            timed1=$(expr ${timed} + 1)
            if [ ${timed1} -ge ${periodcount} ]; then
                timed1=0
            fi
            echo "${timed1}"
            return
        fi
    fi
    echo ${timed}
}

#判断播放列表中每一行是否可播放
check_and_get_video_setting(){
    line=$1
    playlist_index=$2
    line=$(echo ${line} | tr -d '\r' | tr -d '\n')
    # 判断是否要跳过
    flag=${line:0:1}
    if [ "${flag}" = "#" ]; then
        echo ""
        return
    fi
    arr=(${line//|/ })
    video_index=${arr[0]}
    param=${arr[1]}
    videopath0=${arr[2]}
    playtimes=${arr[3]}
    #搜索时间段
    if [[ "${video_index}" != "${playlist_index}" ]]; then
        echo ""
        return
    fi
    #搜索电视库
    tv_setting_str=$(cat "${tvlist}" | grep "${videopath0}|" | head -1)
    if [ "${tv_setting_str}" = "" ]; then
        #如果不存在，则继续下一条
        echo ""
        return
    fi
    arrtvset=(${tv_setting_str//|/ })
    #天龙神剑|天龙神剑|TVA|0|1|F
    videoname=${arrtvset[1]}
    video_type=${arrtvset[2]}
    lighter=${arrtvset[3]}
    audio=${arrtvset[4]}
    subtitle=${arrtvset[5]}
    #这里路径可以只写目录名，然后自己搜索
    videopath=$(check_video_path ${videopath0})
    if [ "${videopath}" = "" ]; then
        echo ""
        return
    fi
    if [[ -d "${videopath}" ]]; then
        file_count=$(ls -l ${videopath} | grep "^-" | wc -l)
        if [ "${playtimes}" = "" ]; then
            playtimes=1
        fi
        video_played=$(cat "${playlist_done}" | grep "${playlist_index}|${videopath0}" | head -1)
        if [[ "${video_played}" = "" ]]; then
            cur_file=1
            cur_times=1
        else
            video_played_arr=(${video_played//|/ })
            if [[ "${video_played_arr[4]}" = "" ]]; then
                cur_times=1
            else
                cur_times=${video_played_arr[4]}
            fi
            if [[ "${video_played_arr[2]}" = "" ]]; then
                cur_file=1
            elif [[ "${video_played_arr[2]}" -ge "${file_count}" ]]; then
                if [[ "${cur_times}" -lt "${playtimes}" ]]; then
                    cur_file=1
                    cur_times=$(expr ${cur_times} + 1)
                else
                    echo ""
                    return
                fi
            else
                cur_file=$(expr ${video_played_arr[2]} + 1)
            fi
        fi
        ##查询到第cur_file个文件###
        cur=0
        for subdirfile in "${videopath}"/*; do
            cur=$(expr $cur + 1)
            if [[ "${cur}" = "${cur_file}" ]]; then
                echo "${video_type}|${lighter}|${audio}|${subtitle}|${param}|${cur_file}|${file_count}|playing|folder|${videoname}|${subdirfile}|${videopath0}|${cur_times}|${playtimes}"
                return
            fi
        done
    elif [[ -f "${videopath}" ]]; then
        if [ "${playtimes}" = "" ]; then
            playtimes=1
        fi
        file_count=1
        video_played=$(cat "${playlist_done}" | grep "${playlist_index}|${videopath0}" | head -1)
        if [[ "${video_played}" = "" ]]; then
            cur_file=1
            cur_times=1
        else
            video_played_arr=(${video_played//|/ })
            if [[ "${video_played_arr[4]}" = "" ]]; then
                cur_times=1
            else
                cur_times=${video_played_arr[4]}
            fi
            if [[ "${cur_times}" -lt "${playtimes}" ]]; then
                cur_file=1
                cur_times=$(expr ${cur_times} + 1)
            else
                echo ""
                return
            fi
        fi
        echo "${video_type}|${lighter}|${audio}|${subtitle}|${param}|${cur_file}|${file_count}|playing|file|${videoname}|${videopath}|${videopath0}|${cur_times}|${playtimes}"
        return
    elif [[ ${videopath} =~ ^http ]] || [[ ${videopath} =~ ^rtmp ]]; then
        if [ "${playtimes}" = "" ]; then
            playtimes=1
        fi
        file_count=1
        video_played=$(cat "${playlist_done}" | grep "${playlist_index}|${videopath0}" | head -1)
        if [[ "${video_played}" = "" ]]; then
            cur_file=1
            cur_times=1
        else
            video_played_arr=(${video_played//|/ })
            if [[ "${video_played_arr[4]}" = "" ]]; then
                cur_times=1
            else
                cur_times=${video_played_arr[4]}
            fi
            if [[ "${cur_times}" -lt "${playtimes}" ]]; then
                cur_file=1
                cur_times=$(expr ${cur_times} + 1)
            else
                echo ""
                return
            fi
        fi
        echo "${video_type}|${lighter}|${audio}|${subtitle}|${param}|${cur_file}|${file_count}|playing|file|${videoname}|${videopath}|${videopath0}|${cur_times}|${playtimes}"
        return
    fi
}

#找到最新可播放的视频文件
get_playing_video() {
    playlist_index=$1
    for line in $(cat ${playlist}); do
        cur_video_setting=$(check_and_get_video_setting "${line}" "${playlist_index}")
        if [ "${cur_video_setting}" = "" ]; then
            continue
        fi
        echo ${cur_video_setting}
        break
    done
}

#获取下一个播放电视剧名
get_next_video_name() {
    next_tv=$(cat ${memo})"　　"
    periodcount=$(cat ${config} | grep -v "^#" | sed /^$/d | wc -l)
    if [ ${periodcount} -le 1 ]; then
        return
    fi
    ret=$(get_rest $(TZ=Asia/Shanghai date +%H))
    if [ "${ret}" = "F|F|F" ]; then
        timec=0
    else
        arr=(${ret//|/ })
        timec=${arr[2]}
    fi
    timed=${timec}
    loop=1
    while true; do
        #if [ ${loop} -gt 3  ];then
        #    break
        #fi
        loop=$(expr ${loop} + 1)
        timed=$(expr ${timed} + 1)
        if [ ${timed} -ge ${periodcount} ]; then
            timed=0
        fi
        if [ "${timed}" = "${timec}" ]; then
            break
        fi
        next_video_path=$(get_playing_video ${timed})
        arr=(${next_video_path//|/ })
        cur_file=${arr[5]}
        file_count=${arr[6]}
        if [ "${cur_file}" = "${file_count}" ] && [ "${file_count}" -gt 1 ]; then
            cur_file="大结局"
        fi
        tvname=${arr[9]}
        period=$(cat ${config} | grep "|${timed}$")
        period=$(echo ${period} | tr -d '\r' | tr -d '\n')
        periodarr=(${period//|/ })
        if [ "${tvname}" = "精彩节目" ] || [ "${file_count}" -eq 1 ]; then
            next_tv=${next_tv}"${periodarr[0]}:00 ${tvname}　"
        else
            next_tv=${next_tv}"${periodarr[0]}:00 ${tvname}(${cur_file})　"
        fi
    done
    length=${#next_tv}
    echo ${next_tv::length-1}
}


get_seq() {
    waitingdir=$1
    videonofile=$2

    videono=0
    declare -a filenamelist
    for subdirfile in "${waitingdir}"/*; do
        filenamelist[$videono]="${subdirfile}"
        videono=$(expr $videono + 1)
    done
    video_lengh=${#filenamelist[@]}
    touch ${videonofile}
    next_video=$(cat ${videonofile})
    if [ "${next_video}" = "" ]; then
        next_video=0
    fi
    if [ ${next_video} -ge ${video_lengh} ]; then
        next_video=0
    fi
    echo "${filenamelist[$next_video]}"
    unset filenamelist
    next_video=$(expr $next_video + 1)
    echo "$next_video" >${videonofile}
}

#初始化ffmpeg路径
ffmpeg_init() {
    if [[ -e "/mnt/data/ffmpeg/ffmpeg" ]]; then
        FFMPEG=/mnt/data/ffmpeg/ffmpeg
    else
        FFMPEG=/usr/bin/ffmpeg
    fi

    if [[ -e "/mnt/data/ffmpeg/ffprobe" ]]; then
        FFPROBE=/mnt/data/ffmpeg/ffprobe
    else
        FFPROBE=/usr/bin/ffprobe
    fi
    echo $FFMPEG
    echo $FFPROBE

    #搜索路径定义
    folder_array[0]=""
    loop=1
    for line in $(cat ${pathlist}); do
        line=$(echo ${line} | tr -d '\r' | tr -d '\n')
        folder_array[${loop}]=${line}
        loop=$(expr ${loop} + 1)
    done

    for((i=0;i<${#folder_array[@]};i++)) do
        echo 增加路径：${folder_array[i]};
    done;
}

#开始播放
stream_start() {
    play_mode=$1
    while true; do
        period=$(need_waiting)
        echo period=${period}
        for line in $(cat ${playlist} | grep ^"${period}|"); do
            next=$(check_and_get_video_setting "${line}" "${period}")
            if [ "${next}" = "" ]; then
                continue
            fi
            echo "播放模式:${play_mode}" > "${ffmpeglog}"
            ffmpeg_init
            echo next=${next}
            stream_play_main "${next}" "${play_mode}" "${period}"
            next_period=$(need_waiting)
            if [ "${next_period}" != "${period}" ]; then
                break
            fi
            http_check=$(echo "${next}" | grep "|http" | head -1)
            rtmp_check=$(echo "${next}" | grep "|rtmp" | head -1)
            if [[ ${http_check} != "" ]] || [[ ${rtmp_check} != "" ]]; then
                continue
            else
                break
            fi
        done
    done
}

##########################################################
echo ==初始化开始==

# 颜色选择
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
font="\033[0m"

curdir=$(pwd)

# 定义推流地址和推流码
rtmp=

# 配置目录和文件
logodir=${curdir}/logo
news=${curdir}/log/news.txt
memo=${curdir}/log/memo.txt
tvlist=${curdir}/list/list.txt
delogofile=${curdir}/list/delogo.txt
rest_video_path=/mnt/share3/mvbrief
#背景为图片
bgimg=${curdir}/img/bg.jpg
bgvideodir=${curdir}/bg/
#背景为视频
bgvideo=${curdir}/img/bg.jpg
pathlist=${curdir}/list/path.txt

#street video dir
bgstreetdir=/mnt/share1/street/

# 可配置目录
subfile=${curdir}/sub/sub.srt
config=${curdir}/list/config.txt
playlist=${curdir}/list/playlist.txt
playlist_done=${curdir}/list/playlist_done.txt
playing_video=${curdir}/log/current

#配置字体
fontdir=${curdir}/fonts/font3.ttf
fonttimedir=${curdir}/fonts/font_time2.ttf
fontforcastdir=${curdir}/fonts/font.ttf
fontsize=50
fontcolor=#FDE6E0
fontcolor2=#B1121A
fontcolorgold=#D9D919
fontbg="box=1:boxcolor=black@0.01:boxborderw=3"
sheight=1080
#ffmpeg参数
logging="repeat+level+warning"
preset_decode_speed="fast"

enter=$(echo -e "\n''")
split=$(echo -e "\t''")

if [ ! -d ${curdir}/log ]; then
    echo create ${curdir}/log
    mkdir ${curdir}/log
fi

if [ ! -d ${curdir}/sub ]; then
    echo create ${curdir}/sub
    mkdir ${curdir}/sub
fi


echo 开始启动

mode=$1
rtmp_link=$2
rtmp_token=$3
token=$4
sheight=$5

rtmp=${rtmp_link}${rtmp_token}
subfile="${curdir}/sub/${token}_sub.srt"
config="${curdir}/list/${token}_config.txt"
playlist="${curdir}/list/${token}_list.txt"
playlist_done="${curdir}/list/${token}_list_done.txt"
ffmpeglog="${curdir}/log/${token}.log"
news="${curdir}/log/${token}_news.txt"
playing_video="${curdir}/log/${token}_current.txt"

echo mode=${mode}
echo rtmp_link=${rtmp_link}
echo rtmp_token=${rtmp_token}    
echo token=${token}
echo sheight=${sheight}
echo rtmp=${rtmp}
echo subfile=${subfile}
echo config=${config}
echo playlist=${playlist}
echo playlist_done=${playlist_done}
echo ffmpeglog=${ffmpeglog}
echo news=${news}
echo playing_video=${playing_video}

stream_start ${mode}

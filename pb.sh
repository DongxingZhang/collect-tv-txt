#!/bin/bash

# 颜色选择
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
font="\033[0m"

# 定义推流地址和推流码
#rtmp="rtmp://www.tomandjerry.work/live/livestream"
#rtmp="rtmp://127.0.0.1:1935/live/1"
rtmp2="rtmp://live-push.bilivideo.com/live-bvc/?streamname=live_97540856_1852534&key=a042d1eb6f69ca88b16f4fb9bf9a5435&schedule=rtmp&pflag=1"
rtmp="rtmp://qqgroup.6721.livepush.ilive.qq.com/trtc_1400526639/6721_99a2fefeadd58c8948f14058edd45a65?bizid=6721&txSecret=780c1d42dbb8012097c9439e2cbf7a07&txTime=64D26D51&sdkappid=1400526639&k=08c190c1941410beb7a399051a171215353431313731393233335f31363931323532393435&ck=ce8a&txPRI=1691252945"

# 配置目录和文件
curdir=`pwd`

logodir=${curdir}/logo

news=${curdir}/log/news.txt

subfile=${curdir}/sub/sub.srt

config=${curdir}/list/config.txt
delogofile=${curdir}/list/delogo.txt
playlist=${curdir}/list/playlist.txt
playlist_done=${curdir}/list/playlist_done.m3u

#配置字体
fontdir=${curdir}/fonts/font.ttf
fonttimedir=${curdir}/fonts/font_time.ttf
fontforcastdir=${curdir}/fonts/font.ttf
fontsize=70
fontcolor=#FDE6E0
fontbg="box=1:boxcolor=black@0.01:boxborderw=3"

#ffmpeg参数
logging="repeat+level+warning"
preset_decode_speed="ultrafast"

enter=`echo -e "\n''"`
split=`echo -e "\t''"`


if [ ! -d ${curdir}/log ];then
    echo create ${curdir}/log
    mkdir ${curdir}/log
fi

if [ ! -d ${curdir}/sub ];then
    echo create ${curdir}/sub
    mkdir ${curdir}/sub
fi


####功能函数START
get_stream_track(){
    track=`ffprobe -loglevel repeat+level+warning  -i "$1" -show_streams -print_format csv | awk -F, '{print $1,$2,$3,$6}' | grep "$2" | awk 'NR==1{print $2}'`
    echo ${track}
}

get_stream_track_decode(){
    track=`ffprobe -loglevel repeat+level+warning  -i "$1" -show_streams -print_format csv | awk -F, '{print $1,$2,$3,$6}' | grep "$2" | awk 'NR==1{print $3}'`
    echo ${track}
}

get_duration(){
    duration=`ffprobe -loglevel repeat+level+warning  -i "$1" -show_entries format=duration -v quiet -of csv="p=0"`
    echo ${duration}
}

get_duration2(){
    data=`ffprobe -hide_banner -show_format -show_streams "$1" 2>&1`
    Duration=`echo $data |awk -F 'Duration: ' '{print $2}' | awk -F ',' '{print $1}' | awk -F '.' '{print $1}' | awk -F ':' '{print $1"\:"$2"\:"$3}'`
    echo ${Duration}
}

get_fontsize(){
    data=`ffprobe -hide_banner -show_format -show_streams "$1" 2>&1`
    width=`echo $data |  awk -F 'width=' '{print $2}' | awk -F ' ' '{print $1}'`
    height=`echo $data |  awk -F 'height=' '{print $2}' | awk -F ' ' '{print $1}'`
    newfontsize=`echo "scale=5;sqrt($width*$width+$height*$height)/2203*$fontsize" | bc`
    newfontsize=`echo "scale=0;$newfontsize/1" | bc`
    echo ${newfontsize}
}

get_size(){
    data=`ffprobe -hide_banner -show_format -show_streams "$1" 2>&1`
    width=`echo $data |  awk -F 'width=' '{print $2}' | awk -F ' ' '{print $1}'`
    height=`echo $data |  awk -F 'height=' '{print $2}' | awk -F ' ' '{print $1}'`
    echo "${width}|${height}"
}


digit_half2full(){
    if [ $1 -lt 10 ] && [ $1 -ge 0 ]; then
        res=$(echo $1 | sed 's/0/０/g' | sed 's/1/１/g'  | sed 's/2/２/g'  | sed 's/3/３/g'  | sed 's/4/４/g'  | sed 's/5/５/g'  | sed 's/6/６/g'  | sed 's/7/７/g'  | sed 's/8/８/g' | sed 's/9/９/g')
        echo $res
    else
        echo $1
    fi
}

find_substr_count(){
    count=`echo "$1" | grep -o "$2" | wc -l`
    echo ${count}
}
####功能函数END

stream_play_main(){
    line=$1
    line=`echo ${line} | tr -d '\r' | tr -d '\n'`
    line=`echo ${line} | tr ' ' '%'`
    echo $line
    
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
    videoname=${arr[8]}
    videopath=`echo ${arr[9]} | tr '%' ' '`
    mode=$2
    period=$3
    echo ${mode}
    echo ${period}
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
    echo -e ${yellow}电视剧名称:${font} ${videoname}
    echo -e ${yellow}播放模式（bg, fg, test）:${font} ${mode}

    if [ "${auch}" = "L" ];then
        audio_channel=" -af pan=stereo|c0=FL "
    elif [ "${auch}" = "R" ];then
        audio_channel=" -af pan=stereo|c1=FR "
    else
        audio_channel=
    fi


    if [[ -d "${videopath}" ]];then
        return 0
    fi

    if [ "${mode:0:4}" != "test" ];then
        #ps -ef | grep "${rtmp}" | grep -v grep | awk '{print $2}' | xargs kill -9
        killall ffmpeg
    fi
   
    # 文件超过5GB不要播放
    maxsize=5000000000
    actualsize=$(wc -c <"$videopath")
    echo 文件大小:$actualsize
    if [ $actualsize -ge $maxsize ]; then
        return 0
    fi

    video_track=$(get_stream_track "${videopath}" "video")
    video_track_decode=$(get_stream_track "${videopath}" "video")
    audio_track=$(get_stream_track "${videopath}" "audio")
    audio_track_decode=$(get_stream_track "${videopath}" "audio")
    sub_track=$(get_stream_track "${videopath}" "subtitle")
    sub_track_decode=$(get_stream_track "${videopath}" "subtitle")
    
    if [ "$video_track" = "" ];then
        echo "${videopath} 没有视频轨道"
        echo "${videopath}" >> "${playlist_done}"
        return 
    fi
    
    if [ "$audio_track" = "" ];then
        echo "${videopath} 没有音频轨道"
        echo "${videopath}" >> "${playlist_done}"
        return 
    fi
    
    maps=
    if [ "$sub_track" != "" ];then
        maps="0:s:0"
    fi

    mapv="[0:v:0]"
    mapa="[0:a:0]"

    if [ "${audio}" != "F" ]; then
        mapa="[0:a:${audio}]"
    fi
    
    if [ "${subtitle}" != "F" ]; then
        maps="0:s:${subtitle}"
    fi

    if [ "${subtitle}" = "E" ]; then
        maps=""
    fi


    echo ${mapv}, ${mapa}, ${maps}

    #节目预告预报
    echo $(get_next_video_name) > ${news}
    #cat <( curl -s http://www.nmc.cn/publish/forecast/  ) | tr -s '\n' ' ' |  sed  's/<div class="col-xs-4">/\n/g' | sed -E 's/<[^>]+>//g' | awk -F ' ' 'NF==5{print $1,$2,$3}' | head -n 32 | tr -s '\n' ';' | sed 's/徐家汇/上海/g' | sed 's/长沙市/长沙/g' >>  ${news}

    #分辨率
    ssize=$(get_size "${videopath}")
    sizearr=(${ssize//|/ })
    size_width=${sizearr[0]}
    size_height=${sizearr[1]}

    echo size_width=$size_width
    echo size_height=$size_height

    #logo
    if [ "${param}" != "F" ]; then
        #怀旧logo
        logo=${logodir}/logow2.png
    else
        #武侠logo
        logo=${logodir}/logow.png
    fi

    echo logo=${logo} 

    delogos=`cat ${delogofile} | grep "^${video_type}|"`

    if [ "${delogos}" = "" ];then
        delogo=""
    else
        delogos=`echo ${delogos} | tr -d '\r' | tr -d '\n'`
        delogosarr=(${delogos//|/ })
        delogo="${delogosarr[1]},"
    fi
    
    #跳过${video_skip}秒 
    audio_format="volume=1.0,atrim=start=1"
    videos="trim=start=1[v1];[v1]"
    if [ "${video_skip}" != "" ]; then
        videos="trim=start=${video_skip}[v1];[v1]"
        audio_format="volume=1.0,atrim=start=${video_skip}"
    fi

    if [ "${maps}" != "" ];then  
        echo ffmpeg -i "${videopath}" -map ${maps} -y ${subfile}      
        ffmpeg -i "${videopath}" -map ${maps} -y ./sub/tmp.srt
        cat ./sub/tmp.srt | sed -E 's/<[^>]+>//g' > ./sub/tmp1.srt
        if [ "${subtrans}" = "" ];then
            cp ./sub/tmp1.srt ${subfile}
        else
            iconv -f utf8 -t gbk -c ./sub/tmp1.srt  > ${subfile}
        fi        
        rm ./sub/tmp1.srt
        mapv="${mapv}subtitles=filename=${subfile}:fontsdir=${curdir}/fonts:force_style='Fontname=华文仿宋,Fontsize=15,Alignment=0,MarginV=30'[v];[v]"
    fi

    if [ "${lighter}" != "F" ];then
        video_format="${mapv}${videos}${delogo}eq=contrast=1:brightness=0.15,curves=preset=lighter"
    else
        video_format="${mapv}${videos}${delogo}eq=contrast=1"
    fi

    if [ "${mode}" != "test" ] && [ "${mode: -1}" != "a" ];then
        newfontsize=$(get_fontsize "${videopath}")
    else        
        newfontsize=$(get_fontsize "${logodir}/bg.jpg")
    fi

    echo newfontsize=${newfontsize}
    #计算时间字体大小
    halfnewfontsize=$(expr ${newfontsize} \* 60 / 100)
    #设置行距
    line_spacing=$(expr ${halfnewfontsize} / 4)

    #显示时长
    #播放百分比%{eif\:n\/nb_frames\:d}%%
    duration=$(get_duration2 "${videopath}")
    content="%{pts\:gmtime\:0\:%H\\\\\:%M\\\\\:%S}${enter}${duration}"
    drawtext1="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:text='${content}':fontfile=${fonttimedir}:line_spacing=${line_spacing}:expansion=normal:x=w-line_h\*8:y=line_h\*3:shadowx=2:shadowy=2:${fontbg}"
    
    #天气预报
    #从左往右drawtext2="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolor}:text='${news}':fontfile=${fontdir}:expansion=normal:x=(mod(5*n\,w+tw)-tw):y=h-line_h-10:shadowx=2:shadowy=2:${fontbg}"
    #从右到左
    crop_width=$(expr ${size_width} / 4)
    crop_x=$(expr ${size_width} \* 3 / 4)
    drawtext2="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:textfile='${news}':fontfile=${fontforcastdir}:line_spacing=${line_spacing}:expansion=normal:x=w-mod(max(t-1\,0)*(w+tw\*5)/415\,(w+tw\*5)):y=h-line_h-5:shadowx=2:shadowy=2:${fontbg}"
    
    echo ${cur_file}
    echo ${file_count}
    
    if [ "${file_count}" = "1" ]; then
        cont_len=${#videoname}
        content2=`echo ${videoname} | sed 's#.#&\'"${enter}"'#g'`
        echo ${content2}
    else
        split="◇"
        #splitstar="☆"
        splitstar="★"
        cur_file2=$(digit_half2full ${cur_file})
        if [ "${file_count}" = "${cur_file}" ]; then
            vn=${videoname}${splitstar}终
            cont_len=${#vn}
            content2=`echo ${videoname} | sed 's#.#&\'"${enter}"'#g'`${splitstar}${enter}终
        else
            vn=${videoname}${splitstar}${cur_file2}
            cont_len=${#vn}
            content2=`echo ${videoname} | sed 's#.#&\'"${enter}"'#g'`${splitstar}${enter}${cur_file2}
        fi
        echo ${content2}
    fi
    cont_len=$(expr ${cont_len} / 2)

#    if [ "${play_time}" = "playing" ]; then
#        cur_file2=$(digit_half2full ${cur_file})
#        file_count2=$(digit_half2full ${file_count})
#        content2="第${enter}${cur_file2}${enter}集${enter}${enter}共${enter}${file_count2}${enter}集"
#    else
#        cur_file2=$(digit_half2full ${cur_file})
#        file_count2=$(digit_half2full ${file_count})
#        content2="第${enter}${cur_file2}${enter}集${enter}${enter}共${enter}${file_count2}${enter}集"
#        #rest_start2=$(digit_half2full ${rest_start})
#        #res_end2=$(expr $rest_end + 1)
#        #res_end2=$(digit_half2full ${res_end2})
#        #content2="${rest_start2}${enter}点${enter}到${enter}${res_end2}${enter}点${enter}休${enter}息${enter}第${enter}${cur_file2}${enter}集"
#    fi
    drawtext3="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolor}:text='${content2}':fontfile=${fontdir}:line_spacing=${line_spacing}:expansion=normal:x=w-line_h\*4:y=h/2-line_h\*${cont_len}:shadowx=2:shadowy=2:${fontbg}"
        
    watermark="[1:v]scale=-1:${newfontsize}\*2[wm];[bg][wm]overlay=overlay_w/3:overlay_h/2[bg1] "
    video_format="${video_format},${drawtext1},${drawtext2},${drawtext3}[bg];${mapa}${audio_format}[bga];${watermark};"

    echo ${video_format}
    echo ${enter}

    date1=$(TZ=Asia/Shanghai date +"%Y-%m-%d %H:%M:%S")

    
    if [ "${mode}" != "test" ] && [ "${mode: -1}" != "a" ];then
        duration0=$(get_duration "${videopath}")
        duration0int=${duration0%.*}
        duration0int=`expr ${duration0int} + 1`
        bgpic=${logodir}/bgqrcode.jpg
        #nohup ffmpeg -loglevel "${logging}" -r 8 -re -f image2 -loop 1  -i "${bgpic}" -i "/mnt/smb/videos/sleeping.mp4" -pix_fmt yuvj420p -t ${duration0int} -filter_complex "[0:v:0]eq=contrast=1[bg1];[1:a:0]volume=0.1[bga];"  -map "[bg1]" -map "[bga]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y ${rtmp2} &
        nohup ffmpeg -loglevel "${logging}" -r 8 -re -f image2 -loop 1  -i "${bgpic}" -i "$videopath" -pix_fmt yuvj420p -t ${duration0int} -filter_complex "[0:v:0]eq=contrast=1[bg1];[1:a:0]volume=0.1[bga];"  -map "[bg1]" -map "[bga]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y ${rtmp2} &
        echo ffmpeg -loglevel "${logging}" -re -i "$videopath" -i "${logo}"  -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg1]" -map "[bga]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y ${rtmp}
        ffmpeg -loglevel "${logging}" -re -i "$videopath" -i "${logo}"  -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg1]" -map "[bga]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y ${rtmp}
    else
        bgpic=${logodir}/bg.jpg
        logo=${logodir}/logow3.png
        duration0=$(get_duration "${videopath}")
        duration0int=${duration0%.*}
        duration0int=`expr ${duration0int} + 1`
        #分辨率
        bgssize=$(get_size "${bgpic}")
        bgsizearr=(${bgssize//|/ })
        bgsize_width=${bgsizearr[0]}
        bgsize_height=${sizearr[1]}
        scalestr="scale=${bgsize_width}*2/3:-1"
        watermark="[2:v]scale=-1:${newfontsize}\*2[wm];[bgv][wm]overlay=overlay_w/3:overlay_h/2[bg0];[bg0][fgv]overlay=150:150[bg1];"
        video_format="[0:v:0]eq=contrast=1:brightness=0.15,curves=preset=lighter,${drawtext1},${drawtext3}[bgv];[1:v:0]${scalestr}[fgv];[1:a:0]volume=1.0[bga];${watermark}"
        #去掉了 -s ${size_width}x${size_height}
        echo ffmpeg -loglevel "${logging}" -re -f image2 -loop 1  -i "${bgpic}" -i "$videopath" -i "${logo}" -s ${size_width}x${size_height} -pix_fmt yuvj420p -t ${duration0int} -filter_complex "${video_format}"  -map "[bg1]" -map "[bga]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y ${rtmp}
        ffmpeg -loglevel "${logging}" -re -f image2 -loop 1  -i "${bgpic}" -i "$videopath" -i "${logo}" -pix_fmt yuvj420p -t ${duration0int} -filter_complex "${video_format}"  -map "[bg1]" -map "[bga]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y ${rtmp}
    fi

    date2=$(TZ=Asia/Shanghai date +"%Y-%m-%d %H:%M:%S")

    sys_date1=$(date -d "$date1" +%s)
    sys_date2=$(date -d "$date2" +%s)
    time_seconds=`expr $sys_date2 - $sys_date1`

    if [ "${mode}" != "test" ] && [ ${time_seconds} -lt 120 ]; then
        echo "$(TZ=Asia/Shanghai date +"%Y-%m-%d %H:%M:%S") ffmpeg 命令失败！！需要调试"
        return
    fi

    echo mode=${mode}
    echo time_seconds=${time_seconds}
    echo play_time=${play_time}

    if [ "${mode}" != "test" ] && [ ${time_seconds} -ge 700 ]; then
        if [ "${play_time}" = "playing" ];then
            echo "${period}|${videopath}" >> "${playlist_done}"
            cat  ${playlist_done}  |  sort  >  ./list/.pd.txt
            cp  ./list/.pd.txt  ${playlist_done}
        fi
    else
        echo ""
    fi

}


ffmpeg_install(){
    # 安装FFMPEG
    read -p "你的机器内是否已经安装过FFmpeg4.x?安装FFmpeg才能正常推流,是否现在安装FFmpeg?(yes/no):" Choose
    if [ $Choose = "yes" ];then
        apt-get install wget
        wget --no-check-certificate https://www.johnvansickle.com/ffmpeg/old-releases/ffmpeg-4.0.3-64bit-static.tar.xz
        tar -xJf ffmpeg-4.0.3-64bit-static.tar.xz
        cd ffmpeg-4.0.3-64bit-static
        mv ffmpeg /usr/bin && mv ffprobe /usr/bin && mv qt-faststart /usr/bin && mv ffmpeg-10bit /usr/bin
    fi
    if [ $Choose = "no" ]
    then
        echo -e "${yellow} 你选择不安装FFmpeg,请确定你的机器内已经自行安装过FFmpeg,否则程序无法正常工作! ${font}"
        sleep 2
    fi
}


get_rest(){
    hours=$1
    ret="F|F|F"
    for line in $(cat ${config})
    do
        line=`echo ${line} | tr -d '\r' | tr -d '\n'`
        # 判断是否要跳过
        flag=${line:0:1}
        if [ "${flag}" = "#" ];then
            continue
        fi
        arr=(${line//|/ })
        start=${arr[0]}
        end=${arr[1]}
        index=${arr[2]}
        if [ ${start} -le ${end} ];then
            if [ ${hours} -ge ${start} ] && [ ${hours} -le ${end} ];then
                ret=${line}
                break
            fi
        else
            if [ ${hours} -ge ${start} ] || [ ${hours} -le ${end} ];then
                ret=${line}
                break
            fi
        fi
        
    done
    echo ${ret}
}


get_playing_video(){
    playlist_index=$1
    for line in $(cat ${playlist})
    do    
        line=`echo ${line} | tr -d '\r' | tr -d '\n'`
        # 判断是否要跳过   
        flag=${line:0:1}
        if [ "${flag}" = "#" ];then
            continue 
        fi       
        arr=(${line//|/ })
        video_index=${arr[0]}
        video_type=${arr[1]}
        lighter=${arr[2]} 
        audio=${arr[3]}
        subtitle=${arr[4]}
        param=${arr[5]}
        videopath=${arr[6]}
        videoname=${arr[7]}

        #搜索时间段        
        if [[ "${video_index}" != "${playlist_index}" ]];then
            continue
        fi

        if [[ -d "${videopath}" ]];then            
            found=0
            cur_file=0
            file_count=`ls -l ${videopath}  |grep "^-"|wc -l`
            for subdirfile in "${videopath}"/*; do
                cur_file=$(expr $cur_file + 1)
                if [[ -e "${playlist_done}" ]] && cat "${playlist_done}" | grep "${playlist_index}|${subdirfile}" > /dev/null; then
                    continue
                fi
                found=1
                echo "${video_type}|${lighter}|${audio}|${subtitle}|${param}|${cur_file}|${file_count}|playing|${videoname}|${subdirfile}"
                break
            done
            if [[ "${found}" = "1" ]];then
                break
            fi
        elif [[ -f "${videopath}" ]]; then
            if [[ -e "${playlist_done}" ]] && cat "${playlist_done}" | grep "${playlist_index}|${videopath}" > /dev/null; then
                continue
            fi
            echo "${video_type}|${lighter}|${audio}|${subtitle}|${param}|1|1|playing|${videoname}|${videopath}"
            break
        fi
    done
}


get_next_video_name(){
    next_tv=
    periodcount=`cat ${config} | grep -v "^#" | sed /^$/d | wc -l`
    ret=$(get_rest $(TZ=Asia/Shanghai date +%H))
    if [ "${ret}" = "F|F|F" ];then
        timec=4
    else
        arr=(${ret//|/ })
        timec=${arr[2]}
    fi
    timed=${timec}
    loop=1
    next_tv="接下来　　"
    while true
    do
        if [ ${loop} -gt 3  ];then
            break
        fi
        loop=$(expr ${loop} + 1)
        timed=$(expr ${timed} + 1)
        if [ ${timed} -ge ${periodcount} ];then
            timed=0
        fi
        if [ "${timed}" = "${timec}" ];then
            break
        fi
        next_video_path=$(get_playing_video ${timed})
        arr=(${next_video_path//|/ })
        cur_file=${arr[5]}
        tvname=${arr[8]}
        period=`cat ${config} | grep "|${timed}$"`
        period=`echo ${period} | tr -d '\r' | tr -d '\n'`
        periodarr=(${period//|/ })        
        next_tv=${next_tv}"${periodarr[0]}:00 ${tvname}(${cur_file})　"
    done
    length=${#next_tv}
    echo ${next_tv::length-1}
}


need_waiting(){
    hours=$(TZ=Asia/Shanghai date +%H)
    hours=$(expr ${hours} + 0)
    mins=$(TZ=Asia/Shanghai date +%M)
    mins=$(expr ${mins} + 0)
    ret=$(get_rest ${hours})
    periodcount=`cat ${config} | grep -v "^#" | sed /^$/d | wc -l`
    arr=(${ret//|/ })
    last_hour=${arr[1]}
    timed=${arr[2]}
    if [ "${timed}" = "F" ];then
        echo ${timed}
        return
    fi
    if [ "${hours}" = "${last_hour}" ];then
        mins2end=$(expr 59 - ${mins})
        if [ ${mins2end} -le 20 ];then
            #timed1=$(expr ${timed} + 1)
            #if [ ${timed1} -ge ${periodcount} ];then
            #    timed1=0
            #fi
            echo "F"
        else
            echo ${timed}
        fi
    else
        echo ${timed}
    fi
}


get_next(){
    next_video_path=$(get_playing_video $1)
    echo ${next_video_path}
}


get_rest_videos(){
    waitingdir=$1
    videonofile=$2
    title=$3
    next=$4

    if [ "${title}" =  "" ]; then
        title="休息一会儿"
    fi

    videono=0
    declare -a filenamelist
    for subdirfile in "${waitingdir}"/*; do
        filenamelist[$videono]="000|0|F|F|0|1|1|rest|${title}|${subdirfile}"
        videono=$(expr $videono + 1)
    done
    video_lengh=${#filenamelist[@]}
    touch ${videonofile}
    next_video=`cat ${videonofile}`
    if [ "${next_video}" =  "" ]; then
        next_video=0
    fi
    if [ ${next_video} -ge ${video_lengh} ]; then
        next_video=0
    fi
    echo "${filenamelist[$next_video]}"
    unset filenamelist
    if [ "${next}" != "next" ];then
        next_video=$(expr $next_video + 1)
        echo "$next_video" > ${videonofile}
    fi
}


stream_start(){    
    play_mode=$1

    if [[ $rtmp =~ "rtmp://" ]];then
        echo -e "${green} 推流地址输入正确,程序将进行下一步操作. ${font}"
    else  
        echo -e "${red} 你输入的地址不合法,请重新运行程序并输入! ${font}"
        exit 1
    fi 

    echo "推流地址和推流码:${rtmp}"
    echo "播放模式:${play_mode}"
    current=""
    while true
    do        
        period=$(need_waiting)
        if [ "${period}" = "F" ] || [  "${play_mode: -1}" = "a" ];then
            #next=$(get_rest_videos  "/mnt/smb/videos" "${curdir}/count/videono" "音乐播放中")
            sleep 2
            continue
        else
            next=$(get_next ${period})
        fi
        #如果连续两次的下一个出现问题，则播放歌曲
        if [ "${next}" = "${current}" ];then
            #next=$(get_rest_videos "/mnt/smb/videos" "${curdir}/count/videono" "出错了，等待修复。")
            sleep 2
            continue
        fi
        stream_play_main "${next}" "${play_mode}" "${period}" 
        current=${next}
    done
}


stream_append(){
    param=$1
    while true
    do
        clear
        echo "====视频列表===="
        videono=0
        for subdirfile in $(find /mnt/smb/电视剧 -maxdepth 1 | grep "${param}"  | awk -F ':' '{print $1}')
        do
            filename=`echo ${subdirfile} | awk -F "/" '{print $NF}'`
            if [[ -e "${playlist}" ]] && cat "${playlist}" | grep "${filename}" > /dev/null; then
                continue
            fi
            filenamelist[$videono]=${filename}
            videono=$(expr $videono + 1)
            echo "[${videono}]: ${filename}"
        done
        read -p "请输入视频序号:(1-${videono}),:" vindex
        if [ $vindex -ge 1 ] && [ $vindex -le ${videono}  ]; then
            vindex=$(expr $vindex - 1)
            echo '你选择了:'${filenamelist[$vindex]}
            read -p "输入(yes/no/y/n)确认:" yes
            if [ "$yes" = "y" ] || [ "$yes" = "yes" ]; then
                # 已经存在不要添加
                if [[ -e "${playlist}" ]] && cat "${playlist}" | grep "${filenamelist[$vindex]}" > /dev/null; then
                    echo "已经添加过/mnt/smb/电视剧/${filenamelist[$vindex]},不要再添加."
                else
                    echo 0,1:0点到6点
                    echo 2,3:6点到12点
                    echo 4,5:点到18点
                    echo 6,7:18点到24点
                    read -p "请输入视频序号:(0-7),:" timed
                    if [ $timed -lt 0 ] || [ $timed -gt 7  ]; then
                        continue
                    fi
                    echo 你选择了：$timed
                    echo "${timed}|000|F|F|F|0|/mnt/smb/电视剧/${filenamelist[$vindex]}|${filenamelist[$vindex]}" >> ${playlist}
                    echo "添加/mnt/smb/电视剧/${filenamelist[$vindex]}成功"  
                fi                
            fi
            read -p "还要继续添加吗(yes/no/y/n)?:" yes_addagain
            if [ "$yes_addagain" = "n" ] || [ "$yes_addagain" = "no" ]; then
                break
            fi
        elif [ "$vindex" = "q"  ]; then
            break
        fi
    done
    cat ${playlist}
}


# 开始菜单设置
echo -e "${yellow} FFmpeg无人值守直播工具(version 1.1) ${font}"
echo -e "${green} 1.安装FFmpeg (机器要安装FFmpeg才能正常推流) ${font}"
echo -e "${green} 2.开始无人值守循环推流 ${font}"
echo -e "${green} 3.开始播放的单个目录 ${font}"
echo -e "${green} 4.增加视频目录 ${font}"
echo -e "${green} 5.停止推流 ${font}"
start_menu(){

    if [ "$1" = ""  ]; then
        read -p "请输入选项:" num
        read -p "请输入模式:" mode
    else
        num=$1
        mode=$2       
    fi

    case "$num" in
        1)
        ffmpeg_install
        ;;
        2)
        stream_start "${mode}"
        ;;
        3)
        stream_append "${mode}"
        ;;
        4)
        stream_stop
        ;;
        *)
        echo -e "${red} 请输入正确的数字 (1-4) ${font}"
        ;;
    esac
	}

# 运行开始菜单
start_menu $1 $2


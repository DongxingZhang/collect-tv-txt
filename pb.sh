#!/bin/bash

# 颜色选择
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
font="\033[0m"

curdir=$(pwd)

# 定义推流地址和推流码
#rtmp="rtmp://www.tomandjerry.work/live/livestream"
#rtmp="rtmp://127.0.0.1:1935/live/1"
####http://101.206.209.7/live-bvc/927338/live_97540856_1852534/index.m3u8
#rtmp2="rtmp://live-push.bilivideo.com/live-bvc/?streamname=live_97540856_1852534&key=a042d1eb6f69ca88b16f4fb9bf9a5435&schedule=rtmp&pflag=1"
#rtmp_bak="rtmp://qqgroup.6721.livepush.ilive.qq.com/trtc_1400526639/6721_99a2fefeadd58c8948f14058edd45a65?bizid=6721&txSecret=f944652781e18a0ae34fbfa839681be7&txTime=64D6BAE2&sdkappid=1400526639&k=08c190c1941410beb7a399051a171215353431313731393233335f31363931353334393436&ck=469e&txPRI=1691534946"
rtmp="rtmp://qqgroup.6721.livepush.ilive.qq.com/trtc_1400526639/$(cat ${curdir}/rtmp_pass.txt)"

# 配置目录和文件
logodir=${curdir}/logo
news=${curdir}/log/news.txt
memo=${curdir}/log/memo.txt
tvlist=${curdir}/list/list.txt
delogofile=${curdir}/list/delogo.txt
rest_video_path=/mnt/share3/mvbrief
bgimg=${curdir}/img/bg.jpg
bgsongdir=${curdir}/bg/
bgsong=${curdir}/img/bg.jpg

# 可配置目录
subfile=${curdir}/sub/sub.srt
config=${curdir}/list/config.txt
playlist=${curdir}/list/playlist.txt
playlist_done=${curdir}/list/playlist_done.txt


#配置字体
fontdir=${curdir}/fonts/font3.ttf
fonttimedir=${curdir}/fonts/font_time2.ttf
fontforcastdir=${curdir}/fonts/font.ttf
fontsize=50
fontcolor=#FDE6E0
fontcolor2=#B1121A
fontcolorgold=#D9D919
fontbg="box=1:boxcolor=black@0.01:boxborderw=3"
sheight=720
#ffmpeg参数
logging="repeat+level+warning"
preset_decode_speed="ultrafast"

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

####功能函数START
get_stream_track() {
	track=$(ffprobe -loglevel repeat+level+warning -i "$1" -show_streams -print_format csv | awk -F, '{print $1,$2,$3,$6}' | grep "$2" | awk 'NR==1{print $2}')
	echo ${track}
}

get_stream_track_decode() {
	track=$(ffprobe -loglevel repeat+level+warning -i "$1" -show_streams -print_format csv | awk -F, '{print $1,$2,$3,$6}' | grep "$2" | awk 'NR==1{print $3}')
	echo ${track}
}

get_duration() {
	duration=$(ffprobe -loglevel repeat+level+warning -i "$1" -show_entries format=duration -v quiet -of csv="p=0")
	echo ${duration}
}

get_duration2() {
	data=$(ffprobe -hide_banner -show_format -show_streams "$1" 2>&1)
	Duration=$(echo $data | awk -F 'Duration: ' '{print $2}' | awk -F ',' '{print $1}' | awk -F '.' '{print $1}' | awk -F ':' '{print $1"\:"$2"\:"$3}')
	echo ${Duration}
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
	data=$(ffprobe -hide_banner -show_format -show_streams "$1" 2>&1)
	width=$(echo $data | awk -F 'width=' '{print $2}' | awk -F ' ' '{print $1}')
	height=$(echo $data | awk -F 'height=' '{print $2}' | awk -F ' ' '{print $1}')
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
	videoname=$1
	if [[ -d "${videoname}" ]]; then
		echo "${videoname}"
	elif [[ -f "${videoname}" ]]; then
		echo "${videoname}"
	elif [[ -d "/mnt/share1/movies/${videoname}" ]]; then
		echo "/mnt/share1/movies/${videoname}"
	elif [[ -d "/mnt/share2/movies/${videoname}" ]]; then
		echo "/mnt/share2/movies/${videoname}"
	elif [[ -d "/mnt/share3/movies/${videoname}" ]]; then
		echo "/mnt/share3/movies/${videoname}"
	elif [[ -f "/mnt/share1/movies/${videoname}" ]]; then
		echo "/mnt/share1/movies/${videoname}"
	elif [[ -f "/mnt/share1/videos/${videoname}" ]]; then
		echo "/mnt/share1/videos/${videoname}"
	elif [[ -f "/mnt/share1/tv/${videoname}" ]]; then
		echo "/mnt/share1/tv/${videoname}"
	elif [[ -f "/mnt/share2/tv/${videoname}" ]]; then
		echo "/mnt/share2/tv/${videoname}"
	elif [[ -f "/mnt/share3/tv/${videoname}" ]]; then
		echo "/mnt/share3/tv/${videoname}"
	else
		echo ""
	fi
}

kill_app() {
	rtmp=$1
	app=$2
	while true; do
		pidlist=$(ps -ef | grep "${rtmp}" | grep "${app}" | grep -v "ps -ef" | grep -v grep | awk '{print $2}')
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

get_srt() {
	fullpath=$1
	dir=$(dirname "${fullpath}")
	filename=$(basename "${fullpath}")
	extension="${filename##*.}"
	filenameprefix="${filename%.*}"
	srt="${dir}/${filenameprefix}.srt"
	if [[ -f "${srt}" ]]; then
		echo "${srt}"
	else
		echo ""
	fi
}

####功能函数END

stream_play_main() {
	line=$1
	line=$(echo ${line} | tr -d '\r' | tr -d '\n')
	line=$(echo ${line} | tr ' ' '%')
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
	file_type=${arr[8]}
	videoname=${arr[9]}
	videopath=$(echo ${arr[10]} | tr '%' ' ')
	videopath0=${arr[11]}
    cur_times=${arr[12]}
	playtimes=${arr[13]}

	mode=$2
	period=$3
	mvsource=$4
	echo ${mode}
	echo ${period}
	echo ${mvsource}

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
	rtmp="${rtmp_link}$(cat ${rtmp_token})"
	echo ${rtmp}

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
	maxsize=8000000000
	actualsize=$(wc -c < "${videopath}")
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

	if [ "$video_track" = "" ]; then
		echo "${videopath} 没有视频轨道" >>"${playlist_done}"
		return
	fi

	if [ "$audio_track" = "" ]; then
		echo "${videopath} 没有音频轨道" >>"${playlist_done}"
		return
	fi

	maps=
	if [ "$sub_track" != "" ]; then
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


	#分辨率
	if [ "${video_type}" = "FFF" ]; then
		bgsong=$(get_bg_picuture "${bgsongdir}" "${curdir}/count/bgpicno")
		ssize=$(get_size "${bgsong}") #计算分辨率
	else
		ssize=$(get_size "${videopath}") #计算分辨率
	fi
	sizearr=(${ssize//|/ })
	size_width=${sizearr[0]}
	size_height=${sizearr[1]}

	echo width=$size_width
	echo height=$size_height

	#使用歌曲封面
	if [ "${video_type}" = "FFF" ]; then
		mapv="[3:v:0][0:v:0]overlay=(W-w)/2:(H-h)/2[mapvv];[mapvv][3:v:0]overlay=0:0[mapvvv];[mapvvv]"
	fi

	echo ${mapv}, ${mapa}, ${maps}

	################################开始配置过滤器
	whratio=$(echo "scale=2;${size_width}/${size_height}" | bc)
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
	echo $(get_next_video_name) >${news}
	#cat <( curl -s http://www.nmc.cn/publish/forecast/  ) | tr -s '\n' ' ' |  sed  's/<div class="col-xs-4">/\n/g' | sed -E 's/<[^>]+>//g' | awk -F ' ' 'NF==5{print $1,$2,$3}' | head -n 32 | tr -s '\n' ';' | sed 's/徐家汇/上海/g' | sed 's/长沙市/长沙/g' >>  ${news}
	echo "下集预告 ${news}"

	#台标选择
	logo=
	if [ "${param}" = "F" ]; then
		#武侠logo
		logo=${logodir}/logo.png
	elif [ "${param}" = "0" ]; then
		#怀旧logo
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
		scales="scale=trunc(oh*a/2)*2:${sheight}" # 主视频
		scales2="scale=trunc(oh*a/2)*2:${sheight}" # 背景图片
	else
		scales="scale=trunc(oh*a/2)*2:${size_height}"
		scales2="scale=trunc(oh*a/2)*2:${size_height}"
	fi

	# 背景图
	background="[2:v:0]${scales2}[scalebg];[scalebg]scale=ih*16/9:-1,crop=h=iw*9/16,gblur=sigma=80,eq=saturation=0.9[bgimg];"    

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
	subs=""
	if [ "${maps}" != "" ]; then
		echo ffmpeg -i "${videopath}" -map ${maps} -y ${subfile}
		ffmpeg -i "${videopath}" -map ${maps} -y ./sub/tmp.srt
		cat ./sub/tmp.srt | sed -E 's/<[^>]+>//g' >./sub/tmp1.srt
		if [ "${subtrans}" = "" ]; then
			cp ./sub/tmp1.srt ${subfile}
		else
			iconv -f utf8 -t gbk -c ./sub/tmp1.srt >${subfile}
		fi
		rm ./sub/tmp1.srt
		subs="subtitles=filename=${subfile}:fontsdir=${curdir}/fonts:force_style='Fontname=华文仿宋,Fontsize=15,Alignment=2,MarginV=30'[vsub];[vsub]"
	fi

	#求视频的秒数的5/6
	duration_sec_org=$(get_duration "${videopath}")
	duration_sec=$(echo "scale=0;${duration_sec_org}*5/6" | bc)

	#显示时长
	#播放百分比%{eif\:n\/nb_frames\:d}%%
	duration=$(get_duration2 "${videopath}")
	if [ "${play_time}" = "rest" ]; then
		content=
	else
		content="%{pts\:gmtime\:0\:%H\\\\\:%M\\\\\:%S}${enter}${duration}"
	fi
	#右上角drawtext1="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:text='${content}':fontfile=${fonttimedir}:line_spacing=${line_spacing}:expansion=normal:x=w-line_h\*7:y=line_h/3\*5:shadowx=2:shadowy=2:${fontbg}[durv];[durv]"
	drawtext1="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:text='${content}':fontfile=${fonttimedir}:line_spacing=${line_spacing}:expansion=normal:x=line_h\*5/2:y=h-line_h/3\*15:shadowx=2:shadowy=2:${fontbg}[durv];[durv]"

	#节目预告
	#从左往右drawtext2="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolor}:text='${news}':fontfile=${fontdir}:expansion=normal:x=(mod(5*n\,w+tw)-tw):y=h-line_h-10:shadowx=2:shadowy=2:${fontbg}"
	#从右到左
	drawtext2="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:textfile='${news}':fontfile=${fontforcastdir}:line_spacing=${line_spacing}:expansion=normal:x=w-mod(max(t-1\,0)*(w+tw\*5)/415\,(w+tw\*5)):y=h-line_h-5:shadowx=2:shadowy=2:${fontbg}[forcv];[forcv]"

	#显示标题
	echo 第${cur_file}集
	echo 共${file_count}集

	if [ "${videoname}" = "精彩节目" ]; then
		content2=""
		cont_len=1
	else
		if [ "${file_count}" = "1" ]; then
			cont_len=${#videoname}
			content2=$(echo ${videoname} | sed 's#.#&\'"${enter}"'#g')
			echo ${content2}
		else
			splitstar="${enter}"
			#splitstar="★"
			cur_file2=$(digit_half2full ${cur_file})
			if [ "${file_count}" = "${cur_file}" ]; then
				vn=${videoname}${splitstar}大结局
				cont_len=${#vn}
				content2=$(echo ${videoname} | sed 's#.#&\'"${enter}"'#g')${splitstar}大${enter}结${enter}局
			else
				vn=${videoname}${splitstar}${cur_file2}
				cont_len=${#vn}
				content2=$(echo ${videoname} | sed 's#.#&\'"${enter}"'#g')${splitstar}${cur_file2}
			fi
			echo ${content2}
			#cont_len=$(expr ${cont_len} + 1)
		fi
	fi
    cont_len=$(expr ${cont_len} / 2)
	drawtext3="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolorgold}:text='${content2}':fontfile=${fontdir}:line_spacing=${line_spacing}:expansion=normal:x=w-line_h\*3:y=h/2-line_h\*${cont_len}:shadowx=2:shadowy=2:${fontbg}"
    
	#增亮
	if [ "${lighter}" != "F" ]; then
		#lights="eq=contrast=1:brightness=0.15,curves=preset=lighter[bg2]"
		lights="eq=contrast=1:brightness=0.20[bg2]"
  #lights="eq=sharp=10:luma=10:chroma=5[bg2]"
	else
		lights="eq=contrast=1[bg2]"
	fi

	# 台标
	watermark="[1:v:0]scale=-1:${newfontsize}\*2[wm];" #[wm]

	# 混合台标
    logos="[wm]overlay=overlay_w/6:overlay_h/3[bg1];[bg1]"

	# 视频轨
	videos="${background}${watermark}${mapv}${delogo}${videoskips}${scales}[main];"

	# 视频补齐16:9
	videomakeup="[bgimg][main]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2[bg0];[bg0]" 
	
	# 增加字幕和提示
    tips="${logos}${subs}${drawtext1}${drawtext2}${drawtext3}[bg];"

	# 音轨
	audios="${mapa}${audio_format}[bga];" #[bga]

    # 总选项
	video_format="${videos}${videomakeup}${tips}${audios}[bg]${lights}"

	echo 滤镜:${video_format}

	###########################################过滤器配置完成

	date1=$(TZ=Asia/Shanghai date +"%Y-%m-%d %H:%M:%S")

	if [ "${mode:0:4}" != "test" ] && [ "${mode: -1}" != "a" ]; then
		#bgpic=${logodir}/bgqrcode.jpg
		kill_app "${rtmp}" "ffmpeg -re"
		#nohup ffmpeg -loglevel "${logging}" -r 8 -re -f image2 -loop 1  -i "${bgpic}" -i "$videopath" -pix_fmt yuvj420p -t 1000000 -filter_complex "[0:v:0]eq=contrast=1[bg1];[1:a:0]volume=1[bga];"  -map "[bg2]" -map "[bga]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y "${rtmp2}" &
		echo ffmpeg -re -loglevel "${logging}" -i "$videopath" -i "${logo}" -i "${bgimg}" -i "${bgsong}" -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg2]" -map "[bga]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y "${rtmp}"
		ffmpeg -re -loglevel "${logging}" -i "$videopath" -i "${logo}" -i "${bgimg}" -i "${bgsong}" -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg2]" -map "[bga]" -vcodec libx264 -g 60 -b:v 3000k -c:a aac -b:a 128k -strict -2 -f flv -y "${rtmp}"
		#ffmpeg -r 25 -loglevel "${logging}" -i "$videopath" -i "${logo}" -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg2]" -map "[bga]" -vcodec libx264 -g 30 -b:v 2000k -c:a aac -b:a 128k -strict -2 -f flv -y "${rtmp}"
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
		mv ffmpeg /usr/bin && mv ffprobe /usr/bin && mv qt-faststart /usr/bin && mv ffmpeg-10bit /usr/bin
	fi
	if [ $Choose = "no" ]; then
		echo -e "${yellow} 你选择不安装FFmpeg,请确定你的机器内已经自行安装过FFmpeg,否则程序无法正常工作! ${font}"
		sleep 2
	fi
}

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

get_playing_video() {
	playlist_index=$1
	for line in $(cat ${playlist}); do
		line=$(echo ${line} | tr -d '\r' | tr -d '\n')
		# 判断是否要跳过
		flag=${line:0:1}
		if [ "${flag}" = "#" ]; then
			continue
		fi
		arr=(${line//|/ })
		video_index=${arr[0]}
		param=${arr[1]}
		videopath0=${arr[2]}
		playtimes=${arr[3]}
        #搜索电视库
		tv_setting_str=$(cat "${tvlist}" | grep "${videopath0}" | head -1)
		if [ "${tv_setting_str}" = "" ]; then
			#如果不存在，则继续下一条
			continue
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
			continue
		fi
		#搜索时间段
		if [[ "${video_index}" != "${playlist_index}" ]]; then
			continue
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
				if  [[ "${video_played_arr[4]}" = "" ]]; then
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
					    continue
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
				if  [[ "${video_played_arr[4]}" = "" ]]; then
                    cur_times=1
                else
                    cur_times=${video_played_arr[4]}
                fi
            
			    if [[ "${cur_times}" -lt "${playtimes}" ]]; then
                    cur_file=1
                    cur_times=$(expr ${cur_times} + 1)
                else
                    continue
                fi
			fi
			echo "${video_type}|${lighter}|${audio}|${subtitle}|${param}|${cur_file}|${file_count}|playing|file|${videoname}|${videopath}|${videopath0}|${cur_times}|${playtimes}"
			break
		fi
	done
}

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
		next_video=$(get_next ${timed})
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

get_next() {
	next_video_path=$(get_playing_video $1)
	echo ${next_video_path}
}


get_bg_picuture() {
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


stream_start() {
	play_mode=$1
	mvsource=$2

	echo "推流地址和推流码:"${mvsource}""
	echo "播放模式:${play_mode}"
	current=""
	while true; do
		period=$(need_waiting)
		next=$(get_next ${period})
		if [ "${next}" = "" ]; then
			sleep 2
			continue
		fi
		stream_play_main "${next}" "${play_mode}" "${period}" "${mvsource}"
		current=${next}
		echo =======================================================================================
		sleep 5
	done
}

#stream_append() {
#	param=$1
#	while true; do
#		clear
#		echo "====视频列表===="
#		videono=0
#		for subdirfile in $(find /mnt/smb/电视剧 -maxdepth 1 | grep "${param}" | awk -F ':' '{print $1}'); do
#			filename=$(echo ${subdirfile} | awk -F "/" '{print $NF}')
#			if [[ -e "${playlist}" ]] && cat "${playlist}" | grep "${filename}" >/dev/null; then
#				continue
#			fi
#			filenamelist[$videono]=${filename}
#			videono=$(expr $videono + 1)
#			echo "[${videono}]: ${filename}"
#		done
#		read -p "请输入视频序号:(1-${videono}),:" vindex
#		if [ $vindex -ge 1 ] && [ $vindex -le ${videono} ]; then
#			vindex=$(expr $vindex - 1)
#			echo '你选择了:'${filenamelist[$vindex]}
#			read -p "输入(yes/no/y/n)确认:" yes
#			if [ "$yes" = "y" ] || [ "$yes" = "yes" ]; then
#				# 已经存在不要添加
#				if [[ -e "${playlist}" ]] && cat "${playlist}" | grep "${filenamelist[$vindex]}" >/dev/null; then
#					echo "已经添加过/mnt/smb/电视剧/${filenamelist[$vindex]},不要再添加."
#				else
#					echo 0,1:0点到6点
#					echo 2,3:6点到12点
#					echo 4,5:点到18点
#					echo 6,7:18点到24点
#					read -p "请输入视频序号:(0-7),:" timed
#					if [ $timed -lt 0 ] || [ $timed -gt 7 ]; then
#						continue
#					fi
#					echo 你选择了：$timed
#					echo "${timed}|000|F|F|F|0|/mnt/smb/电视剧/${filenamelist[$vindex]}|${filenamelist[$vindex]}" >>${playlist}
#					echo "添加/mnt/smb/电视剧/${filenamelist[$vindex]}成功"
#				fi
#			fi
#			read -p "还要继续添加吗(yes/no/y/n)?:" yes_addagain
#			if [ "$yes_addagain" = "n" ] || [ "$yes_addagain" = "no" ]; then
#				break
#			fi
#		elif [ "$vindex" = "q" ]; then
#			break
#		fi
#	done
#	cat ${playlist}
#}

# 开始菜单设置
echo -e "${yellow} FFmpeg无人值守直播工具(version 1.1) ${font}"
echo -e "${green} 1.安装FFmpeg (机器要安装FFmpeg才能正常推流) ${font}"
echo -e "${green} 2.开始无人值守循环推流 ${font}"
echo -e "${green} 3.开始播放的单个目录 ${font}"
echo -e "${green} 4.增加视频目录 ${font}"
echo -e "${green} 5.停止推流 ${font}"
start_menu() {

	if [ "$1" = "" ]; then
		read -p "请输入选项:" num
		read -p "请输入模式:" mode
		read -p "请输入信号源:" mvsource
		read -p "字幕文件:" subfile
		read -p "时间段文件:" config
		read -p "电影列表文件:" playlist
		read -p "已播放文件:" playlist_done
		read -p "推流网站:" rtmp_link
		read -p "节目预告:" news
		read -p "分辨率:" sheight
		read -p "推流token" rtmp_token
	else
		num=$1
		mode=$2
		mvsource=$3
		if [ "$4" != "" ]; then
			subfile=$4
		fi
		if [ "$5" != "" ]; then
			config=$5
		fi
		if [ "$6" != "" ]; then
			playlist=$6
		fi
		if [ "$7" != "" ]; then
			playlist_done=$7
		fi
		if [ "$8" != "" ]; then
			rtmp_link=$8
		fi
		if [ "$9" != "" ]; then
			news=$9
		fi
		if [ "${10}" != "" ]; then
			sheight=${10}
		fi
		if [ "${11}" != "" ]; then
			rtmp_token=${11}
		fi

		if [[ ${rtmp_token} =~ ${rtmp_link} ]]; then
			rtmp="${rtmp_token}"
		else
			rtmp="${rtmp_link}$(cat ${rtmp_token})"
		fi

		rtmp="${rtmp_link}$(cat ${rtmp_token})"
		echo ${subfile}
		echo ${config}
		echo ${playlist}
		echo ${playlist_done}
		echo ${rtmp_link}
		echo ${news}
		echo ${sheight}
		echo ${rtmp_token}
		echo ${rtmp}
	fi

	case "$num" in
	1)
		ffmpeg_install
		;;
	2)
		stream_start "${mode}" "${mvsource}"
		;;
	3)
		stream_stop
		;;
	*)
		echo -e "${red} 请输入正确的数字 (1-4) ${font}"
		;;
	esac
}

# 运行开始菜单
start_menu $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11}

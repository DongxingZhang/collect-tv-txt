ls -alh /mnt/share1/tv /mnt/share2/tv /mnt/share3/tv

#ffmpeg.exe -f concat -safe 0 -i 2.txt -c copy -y o1.mp4

path=`pwd`
for subdirfile in "${path}"/*.{ts,mp4}; do
    dir=$(dirname "${subdirfile}")
    filename=$(basename "${subdirfile}")
    extension="${filename##*.}"
    filenameprefix="${filename%.*}"
    srt="${dir}/${filenameprefix}.srt"
    output=${filenameprefix// /}
    output=${output//(/}
    output=${output//)/}.mkv
    #echo "ffmpeg -i '${subdirfile}' -i '${srt}' -c:v copy -c:a copy -c:s mov_text -metadata:s:s:0 language=chi -y "${output}""
    #echo "ffmpeg -i '${subdirfile}' -i '${srt}' -map 0:v:0 -map 0:a:0 -c:v copy -c:a copy -c:s copy -map 1 -metadata:s:s:0 language=zh_CN  -y "${output}""
    #echo "ffmpeg -i '${subdirfile}' -i  -c copy '${output}'"
    #ffmpeg -i "${subdirfile}" -i "${srt}" -c copy -c:s srt -metadata:s:s:0 language=chi -y "EP${output}"
    echo ${output}
done

侠女传奇
仙鹤神针


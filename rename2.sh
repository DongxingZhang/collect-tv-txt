

    loop=1
    while true
    do
        if [ ${loop} -gt 100  ];then
            break
        fi
        loop=$(expr ${loop} + 1)
        if [ ${loop} -lt 10  ];then
            loop=`echo 0${loop}`
        fi

        fullpath=../下载6/血荐轩辕/srt/        
        echo mv "${fullpath}2004血荐轩辕${loop}.srt" "${fullpath}${loop}.srt" 
        mv "${fullpath}2004血荐轩辕${loop}.srt" "${fullpath}${loop}.srt" 
    done
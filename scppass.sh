#!/bin/bash
function auto_login_scp(){
        expect -c "
          set timeout -1;
            spawn scp -P 8022 -r  dx@192.168.1.3://mnt/smb/电视剧/$1 .
            log_file /tmp/hostBak_log
            expect {
                  *assword:* {
                      send mcqueen123abc\r;
                        expect {
                        *denied* {
                            exit: 2;
                            EOF
                        }
                        }
            }
            EOF {exit: 1;}
        }
        "
      return $?
}

auto_login_scp 义不容情
auto_login_scp 九王夺位
auto_login_scp 九阴真经1993
auto_login_scp 包青天三
auto_login_scp 包青天二
auto_login_scp 天蚕变之再与天比高
auto_login_scp 宰相刘罗锅
auto_login_scp 小侠龙旋风
auto_login_scp 少林与咏春
auto_login_scp 新上海滩
auto_login_scp 楚汉骄雄
auto_login_scp 河东狮吼
auto_login_scp 洪熙官
auto_login_scp 聊斋电视系列片
auto_login_scp 血溅太和殿
auto_login_scp 连城诀
auto_login_scp 银狐
auto_login_scp 青锋剑影
auto_login_scp 魔刀侠情






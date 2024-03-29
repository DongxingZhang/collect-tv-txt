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


auto_login_scp 魔刀侠情






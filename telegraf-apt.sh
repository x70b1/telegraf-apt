#!/bin/sh
# shellcheck disable=SC1091

case "$1" in
    --update)
        if [ "$(systemctl is-active telegraf.service)" = "active" ]; then
            kill -USR1 "$(pgrep -f -o "$0")" || true
        fi
        ;;
    *)
        trap exit INT
        trap "echo" USR1

        while true; do

            os_id=$(. /etc/os-release; echo "$ID" | sed 's/^[a-z]/\U&/g')

            echo "apt os_id=\"$os_id\""

            os_codename=$(. /etc/os-release; echo "$VERSION_CODENAME" | sed 's/^[a-z]/\U&/g')

            echo "apt os_codename=\"$os_codename\""

            os_release=$(. /etc/os-release; echo "$VERSION_ID")

            echo "apt os_release=\"$os_release\""

            if [ "$os_id" = "Debian" ]; then 

                release_ltsinfo=$(curl -sf https://wiki.debian.org/LTS | grep "Debian $os_release")

                if [ -n "$release_ltsinfo" ]; then
                    if echo "$release_ltsinfo" | grep -q "#98fb98"; then
                        release_support=0
                    elif echo "$release_ltsinfo" | grep -q "#FCED77"; then
                        release_support=1
                    else
                        release_support=2
                    fi

                    echo "apt os_support=$release_support"
                fi
            
            elif [ "$os_id" = "Ubuntu" ]; then 

                release_ltsinfo=$(curl -sf https://changelogs.ubuntu.com/meta-release | grep -A 2 "Version: $os_release" | grep "Supported" | cut -d ' ' -f 2)

                if [ -n "$release_ltsinfo" ]; then
                    if [ "$release_ltsinfo" -eq 1 ];then
                        release_support=0
                    else
                        release_support=2
                    fi

                    echo "apt os_support=$release_support"
                fi

            fi

            updates_regular=$(apt-get -qq -y --ignore-hold --allow-change-held-packages --allow-unauthenticated -s dist-upgrade | grep ^Inst | grep -c -v Security)
            updates_security=$(apt-get -qq -y --ignore-hold --allow-change-held-packages --allow-unauthenticated -s dist-upgrade | grep ^Inst | grep -c Security)
            updates_packages=$(apt-get -qq -y --ignore-hold --allow-change-held-packages --allow-unauthenticated -s dist-upgrade | grep ^Inst | cut -d ' ' -f 2 | paste -s -d " ")

            if [ "$updates_security" -gt 0 ] && [ "$updates_regular" -gt 0 ]; then
                updates_severity=3
            elif [ "$updates_security" -gt 0 ]; then
                updates_severity=2
            elif [ "$updates_regular" -gt 0 ]; then
                updates_severity=1
            else
                updates_severity=0
            fi

            echo "apt updates_regular=$updates_regular"
            echo "apt updates_security=$updates_security"
            echo "apt updates_packages=\"$updates_packages\""


            if [ -n "$release_support" ]; then
                echo "apt updates_severity=$(( release_support * 10 + updates_severity))"
            fi


            if sudo -l /usr/sbin/needrestart -b >> /dev/null; then
                needrestart_info=$(sudo needrestart -b)
                needrestart_kernel=$(echo "$needrestart_info" | grep -c "NEEDRESTART-KSTA: 3")
                needrestart_services=$(echo "$needrestart_info" | grep -c "NEEDRESTART-SVC")

                if [ "$needrestart_kernel" -eq 1 ] && [ "$needrestart_services" -gt 0 ]; then
                    needrestart_severity=3
                elif [ "$needrestart_kernel" -eq 1 ]; then
                    needrestart_severity=2
                elif [ "$needrestart_services" -gt 0 ]; then
                    needrestart_severity=1
                else
                    needrestart_severity=0
                fi

                echo "apt needrestart_services=$needrestart_services"
                echo "apt needrestart_severity=$needrestart_severity"
            fi


            pkill -P $$
            sleep infinity &
            wait
        done
        ;;
esac

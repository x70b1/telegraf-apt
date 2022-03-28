#!/bin/sh
 # shellcheck disable=SC1091

case "$1" in
    --update)
        kill -USR1 "$(pgrep -f -o "$0")"
        ;;
    *)
        trap exit INT
        trap "echo" USR1

        while true; do
            release_version=$(cat /etc/debian_version)
            release_codename=$(. /etc/os-release; echo "$VERSION_CODENAME" | sed 's/^[a-z]/\U&/g')

            release_ltsinfo=$(curl -sf https://wiki.debian.org/LTS | grep "Debian $(echo "$release_version" | cut -d '.' -f 1)")

            if echo "$release_ltsinfo" | grep -q "#98fb98"; then
                release_support=0
            elif echo "$release_ltsinfo" | grep -q "#FCED77"; then
                release_support=1
            else
                release_support=2
            fi


            updates_regular=$(apt-get -qq -y --ignore-hold --allow-change-held-packages --allow-unauthenticated -s dist-upgrade | grep ^Inst | grep -c -v Security)
            updates_security=$(apt-get -qq -y --ignore-hold --allow-change-held-packages --allow-unauthenticated -s dist-upgrade | grep ^Inst | grep -c Security)

            if [ "$updates_security" -gt 0 ] && [ "$updates_regular" -gt 0 ]; then
                updates_severity=3
            elif [ "$updates_security" -gt 0 ]; then
                updates_severity=2
            elif [ "$updates_regular" -gt 0 ]; then
                updates_severity=1
            else
                updates_severity=0
            fi


            echo "apt debian_release=\"$release_version\""
            echo "apt debian_codename=\"$release_codename\""
            echo "apt debian_support=$release_support"
            echo "apt updates_regular=$updates_regular"
            echo "apt updates_security=$updates_security"
            echo "apt updates_severity=$(( release_support * 10 + updates_severity))"


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

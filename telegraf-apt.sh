#!/bin/sh

apt_pid="/tmp/telegraf-apt.pid"
apt_ltsfile="/tmp/telegraf-apt.ltsinfo"

case "$1" in
    --update)
        if [ -f "$apt_pid" ]; then
            update_pid=$(cat "$apt_pid")

            if ps -p "$update_pid" > /dev/null; then
                kill -10 "$update_pid"
            fi
        fi
        ;;
    *)
        echo $$ > "$apt_pid"

        trap exit INT
        trap "echo" USR1

        while true; do
            release_version=$(cat /etc/debian_version)
            release_codename=$(lsb_release -s -c | sed 's/^[a-z]/\U&/g')

            if [ ! -f $apt_ltsfile ] || [ "$(find $apt_ltsfile -mtime +1 -print)" ]; then
                curl -sf -o $apt_ltsfile https://wiki.debian.org/LTS
            fi


            release_status=$(grep "$(echo "Debian $release_version" | cut -d '.' -f 1)" $apt_ltsfile)

            if echo "$release_status" | grep -q "#98fb98"; then
                release_support=0
            elif echo "$release_status" | grep -q "#FCED77"; then
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


            sleep infinity &
            wait
        done
        ;;
esac

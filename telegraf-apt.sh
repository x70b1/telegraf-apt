#!/bin/sh

release_string=$(cat /etc/debian_version)
release_status=$(curl -sf https://wiki.debian.org/LTS | grep "$(echo "Debian $release_string" | cut -d '.' -f 1)")
release_support=2

updates_regular=$(apt list -qq --upgradable 2> /dev/null | grep -c -v "security")
updates_security=$(apt list -qq --upgradable 2> /dev/null | grep -c "security")

if echo "$release_status" | grep -q "#98fb98"; then
    release_support=0
elif echo "$release_status" | grep -q "#FCED77"; then
    release_support=1
fi

if [ "$updates_security" -gt 0 ] && [ "$updates_regular" -gt 0 ]; then
    updates_severity=3
elif [ "$updates_security" -gt 0 ]; then
    updates_severity=2
elif [ "$updates_regular" -gt 0 ]; then
    updates_severity=1
else
    updates_severity=0
fi


echo "apt debian_release=\"$release_string\""
echo "apt debian_support=$release_support"
echo "apt updates_regular=$updates_regular"
echo "apt updates_security=$updates_security"
echo "apt updates_severity=$(( release_support * 10 + updates_severity))"

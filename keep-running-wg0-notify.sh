#!/bin/bash

#if [[ $(ps ax | grep -c '[w]g0-notify.sh') -eq 0 ]]
if pgrep -x "wg0-notify.sh" > /dev/null
then
    : #nothing
    #echo "at least one wiregard monitoring running"
else
    /usr/local/bin/wg0-notify.sh &
    #echo "wiregard monitoring is not running"
fi

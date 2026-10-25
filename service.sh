#!/system/bin/sh
#
# This script will be executed in service mode
#

sleep 10
if [ "`getprop init.svc.audioserver`" = "running" ]; then
    setprop ctl.restart audioserver
fi

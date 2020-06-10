#!/bin/bash
PLUGINDIR=$(dirname $0)
. $PLUGINDIR/utils.sh

if [[ $# -ne 1 ]]; then
    echo "Usage: ${0##*/} <service name>"
    exit $STATE_UNKNOWN
fi
service=$1

pidEstablishedConnections(){
    set +e
    netstat -alntp | grep ESTABL | grep " $1/" -c
    set -e
}

pidProtocolSockets(){
    netstat -nlp --inet | grep \"$1/\" | grep "^$2" -c
}

pidCpuPercentage() {
    set +e
    ps -p $1 -o %cpu| grep "%CPU" -A 1 | grep -v "%CPU"| sed "s/^ //g"
    set -e
}

pidtree() {
    set +e
    for _pid in "$@"; do
        echo "$_pid"
        pidtree `ps --ppid $_pid -o pid h`
    done
    set -e
}

status=$(systemctl is-enabled $service 2>/dev/null)
r=$?
if [[ -z "$status" ]]; then
    echo "ERROR: service $service doesn't exist"
    exit $STATE_CRITICAL
fi

if [[ $r -ne 0 ]]; then
    echo "ERROR: service $service is $status"
    exit $STATE_CRITICAL
fi


systemctl --quiet is-active $service
if [[ $? -ne 0 ]]; then
    echo "ERROR: service $service is not running"
    exit $STATE_CRITICAL
fi


set -e
showFile="$(mktemp)"
systemctl show $service > $showFile
startedTime="$(grep '^ActiveEnterTimestamp=' $showFile | cut -d'=' -f2)"
mainPID="$(grep '^MainPID=' $showFile | cut -d'=' -f2)"
description="$(grep '^Description=' $showFile | cut -d'=' -f2)"
#tasksCurrent="$(grep '^TasksCurrent=' $showFile | cut -d'=' -f2)"
#memoryCurrent="$(grep '^MemoryCurrent=' $showFile | cut -d'=' -f2)"
#memoryCurrent_mb="$(echo $memoryCurrent/1024/1024|bc)"
#procLines="$(pidtree $mainPID)"
#processCount="$(echo $procLines | wc -l)"
#processes="$(echo $procLines|xargs -I % echo -n " %"| sed 's/^ //g')"
#cpuPercentage="$(pidCpuPercentage $mainPID)"
#tcpListens="$(pidProtocolSockets $mainPID tcp)"
#udpListens="$(pidProtocolSockets $mainPID udp)"
#establishedConnections="$(pidEstablishedConnections $mainPID)"


set -e
#echo "OK: $description (PID $mainPID) running since $startedTime :: ${tasksCurrent} Threads, ${processCount} Procs, ${memoryCurrent_mb}MB Memory"
echo "OK: $description (PID $mainPID) running since $startedTime"
[ -f "$showFile" ] && unlink $showFile
exit $STATE_OK

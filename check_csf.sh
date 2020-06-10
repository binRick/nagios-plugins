#!/bin/bash

if [ -d /etc/csf ]; then
if [[ "$(/usr/sbin/csf -l | grep DROP -c)" -gt 0 ]]; then
if [[ "$(ps aux | grep ‘lfd’ | grep -v grep | wc -l)" -eq 0 ]]; then
echo "CSF OK :: note: LFD Stopped"
exit 0
fi
echo "CSF OK – Running"
exit 0
else

echo "CSF CRITICAL – NOT Running"
exit 2
fi
else
echo "CSF CRITICAL – NOT installed"
exit 2
fi

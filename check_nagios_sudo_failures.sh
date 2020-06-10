#!/bin/bash
set +e
LOG_FILE="/var/log/nagios/nagios.log"

function usage {
  echo "$(basename $0) usage: "
  echo "    -w warning_level Example: 80"
  echo "    -c critical_level Example: 90"
  echo "    -s seconds to search for failures in Example: 60"
  echo ""
  exit 1
}

while [[ $# -gt 1 ]]
do
    key="$1"
    case $key in
      -s)
      _SECS="$2"
      shift
      ;;
      -w)
      WARN="$2"
      shift
      ;;
      -c)
      CRIT="$2"
      shift
      ;;
      *)
      usage
      shift
      ;;
  esac
  shift
done

[ ! -z $_SECS ] && [ ! -z ${WARN} ] && [ ! -z ${CRIT} ] || usage

_AWK_CMD="command awk \"\\\$1>=$(echo $(date +%s)-$_SECS|bc)\""
_SED_CMD="command sed 's/^\[//g'"
_CMD="\
    command cat $LOG_FILE \
    | $_SED_CMD \
    | $_AWK_CMD \
    | command grep -c 'sudo:' ${LOG_FILE}"

MATCHES_QTY=$(eval $_CMD)
exit_code=$?


PERFDATA="MATCHES_QTY=$MATCHES_QTY;;;; LOG_FILE=$LOG_FILE;;;; _SECS=$_SECS;;;;"
if [[ "$_DEBUG_CMD" == "1" ]]; then
    PERFDATA="$PERFDATA _CMD=$_CMD;;;"
fi

if [[ ${MATCHES_QTY} -gt ${CRIT} ]]; then
  echo "CRITICAL - $MATCHES_QTY failed sudo events in the last $_SECS seconds |$PERFDATA"
  exit 2
elif [[ ${MATCHES_QTY} -gt ${WARN} ]]; then
  echo "WARNING - $MATCHES_QTY failed sudo events in the last $_SECS seconds |$PERFDATA"
  exit 1
else
  echo "OK - $MATCHES_QTY failed sudo events in the last $_SECS seconds |$PERFDATA"
  exit 0
fi

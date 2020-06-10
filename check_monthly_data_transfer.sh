#!/usr/bin/env bash
_DEBUG=0
while [[ -n "$1" ]]; do
  case $1 in
    --debug)
      _DEBUG=1
      shift
      ;;
    -d | --direction)
      _DIRECTION=$2
      shift
      ;;
    -w | --warning)
      _WARNING=$2
      shift
      ;;
    -c | --critical)
      _CRITICAL=$2
      shift
      ;;
    -u | --unit)
      _UNIT=$2
      shift
      ;;
    -i | --interface)
      _INTERFACE=$2
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exec "$0" --help
      exit 3
      ;;
  esac
  shift
done



if [[ -z "$_WARNING" ]] || [[ -z "$_CRITICAL" ]]; then
  echo "Error: --warning and --critical parameters are required"
  exit 3
fi


if [ -z "$_INTERFACE" ]; then
  echo "Error: --interface must be a network interface"
  exit 3
fi

if [ -z "$_DIRECTION" ]; then
  echo "Error: --direction must be \"in\" our \"out\""
  exit 3
fi

if [[ $_WARNING -ge $_CRITICAL ]]; then
  echo "Error: --warn ($_WARNING) can't be greater than --critical ($_CRITICAL)"
  exit 3
fi

if [ -z "$_UNIT" ]; then
  _UNIT="GB"
fi

now=$(date +%s)
_THIS_MONTH="$(date +%m| sed 's/^0//g')"

if [ "$_DIRECTION" == "in" ]; then
	_RXTX="rx"
	_RXTX_human="Received"
fi
if [ "$_DIRECTION" == "out" ]; then
	_RXTX="tx"
	_RXTX_human="Sent"
fi

evalCmd="vnstat -i ${_INTERFACE} --json m | jq \".interfaces[0].traffic.month\" | jq \".[]|select(.date.month==${_THIS_MONTH})\" | jq \".${_RXTX}\""



case "$_UNIT" in
  GB)
    _DIVIDER="1024*1024*1024"
  ;;
  MB)
    _DIVIDER="1024*1024"
  ;;
  TB)
    _DIVIDER="1024*1024*1024*1024"
  ;;
  *)
  echo "Error: --unit must be MB, GB, or TB"
  exit 3
  ;;
esac

evalOut="$(eval $evalCmd)"
evalCode="$?"
transferredUnits_cmd="echo \"$evalOut/($_DIVIDER)\"|bc"
transferredUnits_out="$(eval $transferredUnits_cmd)"
transferredUnits_code=$?

output="$transferredUnits_out $_UNIT $_RXTX_human this month"

if [ "$_DEBUG" == "1" ]; then
	echo _DIVIDER=$_DIVIDER
	echo evalCmd=$evalCmd
	echo evalOut=$evalOut
	echo evalCode=$evalCode
	echo transferredUnits_cmd=$transferredUnits_cmd
	echo transferredUnits_out=$transferredUnits_out
	echo transferredUnits_code=$transferredUnits_code
	echo output=$output
fi



if [[ $transferredUnits_out -ge $_WARNING ]]; then
  echo "WARNING: $output"
  exit 1
elif [[ $transferredUnits_out -ge $_CRITICAL ]]; then
  echo "CRITICAL: $output"
  exit 2
else
  echo "OK: $output"
  exit 0
fi

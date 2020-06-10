#!/bin/bash
 
get_nagios_state() {
# Usage:
#        get_nagios_state <current> <warn> <crit>
 
# Checks a value against warning/critical thresholds and returns the correct Nagios state code
 
  awk -v cur="$1" -v warn="$2" -v crit="$3" '
  BEGIN {
    state_ok=0;
    state_warning=1;
    state_critical=2;
    state_unknown=3;
    exit_state=state_unknown;
    
    if ( cur < warn )
      exit_state=state_ok;
    else if ( cur >= warn )
      exit_state=state_warning;
      if ( cur >= crit )
        exit_state=state_critical;
        
    exit exit_state;
  }'
  
  return $?
}
 
submit_passive_check() {
# Usage:
#        submit_passive_check <nagios_url> <user> <pass> <host> <service> <state> <output> [perfdata]
 
# Logs in as the Nagios user and submits a passive check via CGI
 
  NAGIOS_URL="$1"
  NAGIOS_USER="$2"
  NAGIOS_PASS="$3"
  CHECK_HOST="$4"
  CHECK_SERVICE="$5"
  CHECK_STATE="$6"
  CHECK_OUTPUT="$7"
  CHECK_PERFDATA="$8"
 
  CURL_OPTS="--silent --head"
 
  CURL_LOG=$(curl ${CURL_OPTS} --user "${NAGIOS_USER}:${NAGIOS_PASS}" \
       --data-urlencode "cmd_typ=30" \
       --data-urlencode "cmd_mod=2" \
       --data-urlencode "host=${CHECK_HOST}" \
       --data-urlencode "service=${CHECK_SERVICE}" \
       --data-urlencode "plugin_state=${CHECK_STATE}" \
       --data-urlencode "plugin_output=${CHECK_OUTPUT}" \
       --data-urlencode "performance_data=${CHECK_PERFDATA}" \
       "${NAGIOS_URL}/cgi-bin/cmd.cgi")
 
  echo "${CURL_LOG}" | grep -q "successfully submitted"
  RESULT=$?
  if [[ $RESULT -ne 0 ]]; then
    echo -e "ERROR: Error submitting passive check to Nagios CGI!\n\n${CURL_LOG}" >&2
    return 1
  fi
 
  return 0
}
 
# Example: Get current CPU load and report it back to a Nagios server
#   my_hostname=$(hostname -s | awk '{print tolower($0)}')
#   cpuload=$(cat /proc/loadavg | cut -d' ' -f1)
#   nagios_state=$(get_nagios_state ${cpuload} 0.50 0.75; echo $?)
#   submit_passive_check http://192.168.1.100/nagios passiveuser mypassword ${my_hostname} cpuload ${nagios_state} ${cpuload} "load=${cpuload};0.50;0.75"

#  pynag functions
[[ $- = *i*  ]] || return

execute_host_service(){
    _HOST="$1"
    _SVC="$2"
    shift; shift
    cmd="pynag execute '$_HOST' '$_SVC' $@"
    eval $cmd
}

pynag_list_cleaner(){
  egrep -v '^-------|^null$|^host_name$|^service_description'
}

list_hosts(){
  pynag list host_name where object_type=host 2>&1 \
    |sed 's/[[:space:]]//g'\
    |pynag_list_cleaner
}

list_host_services(){
  pynag list service_description where \
    host_name=$1 and \
    object_type=service \
      |pynag_list_cleaner
}

>&2 echo -e "pynag functions loaded: \n\
  list_hosts\n\
  list_host_services <HOST_NAME>\n\
  execute_host_service <HOST_NAME> \"<SERVICE_NAME>\" [OPTIONAL_PYNAG_ARGS]\n\
"

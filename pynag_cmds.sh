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

list_hosts(){
    pynag list host_name where object_type=host 2>&1 \
        |sed 's/[[:space:]]//g'\
        |egrep -v '^-------|^null$|^host_name$'
}

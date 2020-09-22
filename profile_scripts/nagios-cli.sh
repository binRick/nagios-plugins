#  nagios-cli profile
[[ $- = *i*  ]] || return

alias nagios-cli="/opt/nagios-cli/nagios-cli -c /opt/nagios-cli/nagios.cfg"
alias nag="nagios-cli -e \"host localhost; service\""

show_host_status(){
    cmd="nagios-cli -e 'host $1;status;'"
    eval $cmd
}
show_host_services_status(){
    cmd="nagios-cli -e 'host $1;service;'"
    eval $cmd
}

>&2 echo -e "nagios-cli functions loaded: show_host_status <HOST_NAME>, show_host_services_status <HOST_NAME>, "

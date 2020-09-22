#  bash aliases
[[ $- = *i*  ]] || return

alias vi="vim"
alias grep="grep --color -s"
alias grpe="grep"
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias gc="git clone"

>&2 echo -e "bash aliases loaded"

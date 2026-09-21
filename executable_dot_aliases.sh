# This file contains alises and usefull helper functions
# it is sourced from bashrc or zshrc
if [ -z ${BASH_SOURCE+x} ]; then SCRIPT_FILEPATH=${(%):-%N};
else SCRIPT_FILEPATH=${BASH_SOURCE[0]}; fi
SCRIPT_DIRPATH=`dirname $SCRIPT_FILEPATH`

# give direct acces to bin installed in ~/.local/bin
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# some more ls aliases
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias Pwd='pwd -P'
alias nosymb='cd `pwd -P`'
alias P='cd `pwd -P`'
alias CD='cd -P'
alias dl='dirs -v'
alias m='more'
alias n='nano'
## qView — filter Qt/XCB noise when running on Wayland session (QT_QPA_PLATFORM not set)
alias qv='$HOME/.local/bin/qView 2> >(grep -v "Ignoring XDG_SESSION_TYPE" >&2)'
alias gitf='gitfourchette .'
# rsync
alias rcp='rsync -avz --progress'

# copied from https://github.com/mcornella/dotfiles/blob/86a5c87fd10cf6f1752e2cc197e80ae6075eb5f3/aliases
# expand aliases after sudo
alias sudo='sudo '
# preserve environment (-E option) when login as root
alias sudoas='sudo -E -s'
# stdin to clipboard
alias xclip='xclip -selection c'
# directories
alias mkdir &>/dev/null && unalias mkdir # remove nocorrect (oh-my-zsh)
alias md='mkdir -p'
alias rd='rmdir'
[[ -d /C ]] && alias sistema='cd /C'
[[ -d /D ]] && alias dades='cd /D'
###### DOCKER ####################
alias docker_clean_images='docker rmi $(docker images -a --filter=dangling=true -q)'
alias docker_clean_ps='docker rm $(docker ps --filter=status=exited --filter=status=created -q)'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# if trash installed, forbid rm
which trash &> /dev/null && alias rm="echo Use 'trash', or the full path i.e. '/bin/rm'"

###### display csv nicely with col aligns
function csv_show {
    column -t -s, -n "$@" | less -F -S -X -K
}


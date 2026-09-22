## 
alias prout="echo 'toi meme'"
alias CD='cd -P'
alias gitf='gitfourchette .'
alias rcp='rsync -avz --progress'
###### DOCKER ####################
alias docker_clean_images='docker rmi $(docker images -a --filter=dangling=true -q)'
alias docker_clean_ps='docker rm $(docker ps --filter=status=exited --filter=status=created -q)'
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'


# nle_toolbox utilities
if [ -d "$HOME/nle_toolbox" ]; then
    export PATH="$HOME/nle_toolbox/bin:$PATH"
    [ -f "$HOME/nle_toolbox/bin/server_aliases.sh" ] && . "$HOME/nle_toolbox/bin/server_aliases.sh"
fi

## 
alias prout="echo 'toi meme'"
alias CD='cd -P'
# gitfourchette aliases
if command -v gitfourchette >/dev/null 2>&1; then
    alias gitf='gitfourchette $PWD'
fi
# rsync aliases
if command -v zellij >/dev/null 2>&1; then
	alias rcp='rsync -avz --progress'
fi
# zellij aliases
if command -v zellij >/dev/null 2>&1; then
	alias zel="zellij a -c $HOST"
fi


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

# yazi: cd to the last directory on exit
if command -v yazi >/dev/null 2>&1; then
    function y() {
        local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        command yazi "$@" --cwd-file="$tmp"
        IFS= read -r -d '' cwd < "$tmp"
        [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
        command rm -f -- "$tmp"
    }
fi

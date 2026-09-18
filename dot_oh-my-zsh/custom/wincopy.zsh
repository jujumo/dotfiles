function wincopy() {
    local data

    if [[ -n "$1" ]]; then
        if [[ ! -r "$1" ]]; then
            print -u2 "wincopy: cannot read '$1'"
            return 1
        fi
        data=$(<"$1")
    else
        data=$(cat)
    fi

    printf '\033]52;c;%s\033\\' "$(printf '%s' "$data" | base64 -w0)"
}
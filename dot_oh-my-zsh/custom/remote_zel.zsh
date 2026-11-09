# zel_<host> aliases: ssh into <host> and attach a persistent zellij session.
# One alias per literal Host name in ~/.ssh/config (patterns with * ? ! are
# skipped: list concrete names next to the pattern to get an alias for them).
# Bash/zsh compatible: also sourced from ~/.bashrc.
# Remote command: keep a single persistent session per server, named after the
# server itself, so zellij's header reads "Zellij (rock) > ..." and tells at a
# glance which machine the pane is on.
# - Prefer zellij, fall back to tmux, then to a plain login zsh: the servers
#   are not uniform (some have tmux but no zellij).
# - If that session exists and already has a client attached, use a plain
#   shell so a second simultaneous connection does not mirror the first.
#   zellij reports this via `action list-clients`, which queries a session
#   by name without attaching: header row only when nobody is attached, one
#   line per client.
# - Otherwise attach to it, creating it or resurrecting it after a crashed
#   connection.
# Single-quoted so $(...)/#{...} reach the remote shell untouched, and MUST NOT
# contain a single quote: the alias below wraps it in one more layer of them.
_remote_cmd='
S="$(hostname -s)"
Z="$(command -v zellij || echo "$HOME/.local/bin/zellij")"
if [ -x "$Z" ]; then
    if "$Z" list-sessions -s 2>/dev/null | grep -qxF "$S" &&
       [ "$("$Z" -s "$S" action list-clients 2>/dev/null | tail -n +2 | grep -c .)" != 0 ]; then
        exec zsh -l
    fi
    "$Z" attach -c "$S" || exec zsh -l
elif command -v tmux >/dev/null 2>&1; then
    if tmux has-session -t "$S" 2>/dev/null &&
       [ "$(tmux display-message -p -t "$S" "#{session_attached}" 2>/dev/null)" != 0 ]; then
        exec zsh -l
    fi
    tmux attach -t "$S" 2>/dev/null || tmux new -s "$S" 2>/dev/null || exec zsh -l
else
    exec zsh -l
fi'
if [ -r "$HOME/.ssh/config" ]; then
    for _host in $(awk 'tolower($1) == "host" {
            for (i = 2; i <= NF; i++) {
                if ($i ~ /^#/) break
                if ($i !~ /[*?!]/ && !seen[$i]++) print $i
            }
        }' "$HOME/.ssh/config"); do
        alias "zel_$_host"="ssh -t $_host '$_remote_cmd'"
    done
fi
unset _host _remote_cmd

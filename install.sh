#!/bin/sh
# Dotfiles bootstrap installer.
#
# One-liner:
#   sh -c "$(curl -fsLS https://raw.githubusercontent.com/jujumo/dotfiles/main/install.sh)"
#
# Installs base packages, Oh My Zsh, the jumo theme and chezmoi, then applies
# the dotfiles. Override the source repo with DOTFILES_REPO=... if needed.
set -e

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/jujumo/dotfiles.git}"

# UNATTENDED=1 guarantees no interactive prompt: any step that would otherwise
# ask for a password (e.g. changing the login shell without passwordless sudo)
# is skipped instead. Unset = best effort: try silently, prompt only if there is
# no other way. Mirrors Oh My Zsh's --unattended flag.
UNATTENDED="${UNATTENDED:-}"

# Where to fetch the SSH login keys to authorize. Empty by default, so no keys
# are authorized unless you opt in, e.g. with your GitHub account's public keys:
#   SSH_KEYS_URL=https://github.com/jujumo.keys
SSH_KEYS_URL="${SSH_KEYS_URL:-}"

# Run privileged commands with sudo unless we are already root.
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "==> Installing base packages (curl, git, openssh-client, zsh, nano, screen, tmux)"
$SUDO apt update
$SUDO apt install -y ca-certificates curl git openssh-client zsh nano screen tmux

echo "==> Installing Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  # --keep-zshrc: do not generate a .zshrc; chezmoi owns it.
  # The jumo theme is shipped by chezmoi (see dot_oh-my-zsh/custom/themes).
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

echo "==> Installing chezmoi"
# Look in ~/.local/bin first: that is where we install it, and it is typically
# not on PATH yet in the shell running this script, so relying on `command -v
# chezmoi` alone would re-download it on every run.
if [ -x "$HOME/.local/bin/chezmoi" ]; then
  CHEZMOI="$HOME/.local/bin/chezmoi"
elif command -v chezmoi >/dev/null 2>&1; then
  CHEZMOI="chezmoi"
else
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  CHEZMOI="$HOME/.local/bin/chezmoi"
fi

echo "==> Applying dotfiles with chezmoi"
# `chezmoi init` only clones when the source directory is not already a git
# repo, and it never pulls: on a re-run it would silently apply the stale local
# source state and ignore a changed DOTFILES_REPO. So init only the first time,
# and afterwards re-point the remote (in case DOTFILES_REPO changed) and let
# `chezmoi update` pull before applying.
SOURCE_DIR="$("$CHEZMOI" source-path 2>/dev/null || echo "$HOME/.local/share/chezmoi")"
if [ -d "$SOURCE_DIR/.git" ]; then
  current_url="$("$CHEZMOI" git -- remote get-url origin 2>/dev/null || true)"
  if [ "$current_url" != "$DOTFILES_REPO" ]; then
    "$CHEZMOI" git -- remote set-url origin "$DOTFILES_REPO" 2>/dev/null \
      || "$CHEZMOI" git -- remote add origin "$DOTFILES_REPO"
  fi
  "$CHEZMOI" update
else
  "$CHEZMOI" init --apply "$DOTFILES_REPO"
fi

# Authorize SSH login keys. Append-only and idempotent: each key is added just
# once and existing entries (e.g. provisioned by the host) are left untouched,
# so this never clobbers an existing authorized_keys like a chezmoi-managed file
# would. sshd's StrictModes requires 0700 on ~/.ssh and 0600 on the file.
if [ -n "$SSH_KEYS_URL" ]; then
  echo "==> Authorizing SSH login keys from $SSH_KEYS_URL"
  # Authorizing inbound keys implies wanting an SSH server to log into. The
  # default install (no SSH_KEYS_URL) stays client-only. The postinst generates
  # host keys; starting sshd is left to the host's init (or the test harness).
  $SUDO apt install -y openssh-server
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  AUTH="$HOME/.ssh/authorized_keys"
  touch "$AUTH"
  chmod 600 "$AUTH"
  curl -fsSL "$SSH_KEYS_URL" | while IFS= read -r key; do
    [ -n "$key" ] || continue
    grep -qxF "$key" "$AUTH" || printf '%s\n' "$key" >> "$AUTH"
  done
fi

# Change the login shell to zsh. chsh writes to /etc/passwd, so it needs to be
# root: as root it never prompts; via passwordless sudo it never prompts; with
# password-required sudo it would prompt, so we only try that when not UNATTENDED.
ZSH_PATH="$(command -v zsh || true)"
current_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
if [ -n "$ZSH_PATH" ] && [ "$current_shell" != "$ZSH_PATH" ]; then
  echo "==> Setting zsh as the default shell"
  if [ "$(id -u)" -eq 0 ]; then
    chsh -s "$ZSH_PATH" "$(id -un)"                  # root: never prompts
  elif sudo -n true 2>/dev/null; then
    sudo chsh -s "$ZSH_PATH" "$(id -un)"             # passwordless sudo: never prompts
  elif [ -n "$UNATTENDED" ]; then
    echo "    skipped (would need a password); run later: chsh -s $ZSH_PATH"
  else
    chsh -s "$ZSH_PATH" "$(id -un)" \
      || echo "    could not change shell; run later: chsh -s $ZSH_PATH"
  fi
fi

echo "==> Done. Start a new shell or run: exec zsh"

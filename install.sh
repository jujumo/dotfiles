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

echo "==> Installing base packages (curl, git, openssh-client, zsh, nano, screen)"
$SUDO apt update
$SUDO apt install -y ca-certificates curl git openssh-client zsh nano screen

echo "==> Installing Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  # --keep-zshrc: do not generate a .zshrc; chezmoi owns it.
  # The jumo theme is shipped by chezmoi (see dot_oh-my-zsh/custom/themes).
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

echo "==> Installing chezmoi"
if ! command -v chezmoi >/dev/null 2>&1; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi
CHEZMOI="$HOME/.local/bin/chezmoi"
command -v "$CHEZMOI" >/dev/null 2>&1 || CHEZMOI="chezmoi"

echo "==> Applying dotfiles with chezmoi"
"$CHEZMOI" init --apply "$DOTFILES_REPO"

# Authorize SSH login keys. Append-only and idempotent: each key is added just
# once and existing entries (e.g. provisioned by the host) are left untouched,
# so this never clobbers an existing authorized_keys like a chezmoi-managed file
# would. sshd's StrictModes requires 0700 on ~/.ssh and 0600 on the file.
if [ -n "$SSH_KEYS_URL" ]; then
  echo "==> Authorizing SSH login keys from $SSH_KEYS_URL"
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

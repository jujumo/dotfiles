#!/bin/sh
# Dotfiles bootstrap installer.
#
# One-liner:
#   sh -c "$(curl -fsLS https://raw.githubusercontent.com/jujumo/dotfiles/main/install.sh)"
#
# Installs base packages, Oh My Zsh, the jumo theme and chezmoi, then applies
# the dotfiles. Override the source repo with DOTFILES_REPO=... if needed.
set -e

DOTFILES_REPO="${DOTFILES_REPO:-git@github.com:jujumo/dotfiles.git}"

# Run privileged commands with sudo unless we are already root.
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "==> Installing base packages (zsh, nano, screen, git, curl)"
$SUDO apt update
$SUDO apt install -y zsh nano screen git curl

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

echo "==> Done. Start a new shell or run: exec zsh"

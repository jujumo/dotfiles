#!/bin/sh
# Dotfiles bootstrap installer.
#
# Usage, cloning straight into chezmoi's source directory:
#   sudo apt install -y git
#   git clone https://github.com/jujumo/dotfiles.git ~/.local/share/chezmoi
#   sh ~/.local/share/chezmoi/install.sh
#
# Installs base packages, Oh My Zsh, the jumo theme and chezmoi, then applies
# the dotfiles. The source repo is the origin of the clone this script runs
# from; override it with DOTFILES_REPO=... if needed.
#
# Best effort: installs what permissions and prerequisites allow, skips the
# rest. Without root or passwordless sudo, asks once whether to use sudo;
# NO_ROOT=1 answers "no" up front (system packages are then skipped).
# No `set -e`: best effort, a failing step is reported and the next one runs.

# Default to the origin of the clone this script lives in. The -f guard skips
# `sh -c "$(curl ...)"`, where $0 is "sh" and dirname would be the cwd.
DOTFILES_REPO="${DOTFILES_REPO:-}"
if [ -z "$DOTFILES_REPO" ] && [ -f "$0" ]; then
  DOTFILES_REPO="$(git -C "$(dirname "$0")" remote get-url origin 2>/dev/null)"
fi

# System information, available for optional installers.
OS="$(uname -s)"
ARCH="$(uname -m)"

# UNATTENDED=1 guarantees no interactive prompt: any step that would otherwise
# ask for a password (e.g. changing the login shell without passwordless sudo)
# is skipped instead. Unset = best effort: try silently, prompt only if there is
# no other way. Mirrors Oh My Zsh's --unattended flag.
UNATTENDED="${UNATTENDED:-}"

# Where to fetch the SSH login keys to authorize. Empty by default, so no keys
# are authorized unless you opt in, e.g. with your GitHub account's public keys:
#   SSH_KEYS_URL=https://github.com/jujumo.keys
SSH_KEYS_URL="${SSH_KEYS_URL:-}"

has() { command -v "$1" >/dev/null 2>&1; }

# Checks prerequisites of a step; prints what is missing otherwise.
need() {
  for cmd in "$@"; do
    has "$cmd" || { echo "    skipped (missing $cmd)"; return 1; }
  done
}

# Root decision. Not using sudo is an explicit choice (answer n or NO_ROOT=1):
# a failed sudo (e.g. mistyped password) aborts instead of silently skipping.
NO_ROOT="${NO_ROOT:-}"
SUDO="sudo"
CAN_ROOT=0
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
  CAN_ROOT=1
elif [ -n "$NO_ROOT" ] || ! has sudo; then
  :
elif sudo -n true 2>/dev/null; then
  CAN_ROOT=1
elif [ -z "$UNATTENDED" ] && ( : </dev/tty ) 2>/dev/null; then
  printf 'Use sudo for system packages? [Y/n] '
  read -r answer </dev/tty || answer=n
  case "$answer" in
    n|N|no) ;;
    *) sudo -v || { echo "sudo failed; re-run and answer n (or NO_ROOT=1) to install without root."; exit 1; }
       CAN_ROOT=1 ;;
  esac
fi

### Installing basic packages #################################################################
echo "==> Installing basic packages (ca-certificates curl wget git openssh-client zsh nano)"
if [ "$CAN_ROOT" = 1 ] && has apt; then
  $SUDO apt update || true
  for package in ca-certificates curl wget git openssh-client zsh nano; do
    $SUDO apt install -y "$package" || echo "    $package: skip"
  done
else
  echo "    skipped (no root or no apt)"
fi

### Installing extra packages #################################################################
echo "==> Installing extra packages (tree, btop, screen, micro, unzip, bzip2, build-essential, perl)"
if [ "$CAN_ROOT" = 1 ] && has apt; then
  for package in tree btop screen micro unzip bzip2 build-essential perl; do
    $SUDO apt install -y "$package" || echo "    $package: skip"
  done
else
  echo "    skipped (no root or no apt)"
fi

### Installing Oh My Zsh #################################################################
echo "==> Installing Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ] && need curl git zsh; then
  # --keep-zshrc: do not generate a .zshrc; chezmoi owns it.
  # The jumo theme is shipped by chezmoi (see dot_oh-my-zsh/custom/themes).
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc \
    || echo "    Oh My Zsh: failed"
fi

### Installing chezmoi #################################################################
echo "==> Installing chezmoi"
if need curl git; then
  # Look in ~/.local/bin first: that is where we install it, and it is typically
  # not on PATH yet in the shell running this script, so relying on `command -v
  # chezmoi` alone would re-download it on every run.
  if [ -x "$HOME/.local/bin/chezmoi" ]; then
    CHEZMOI="$HOME/.local/bin/chezmoi"
  elif command -v chezmoi >/dev/null 2>&1; then
    CHEZMOI="chezmoi"
  else
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
      || echo "    chezmoi: install failed"
    CHEZMOI="$HOME/.local/bin/chezmoi"
  fi

  echo "==> Applying dotfiles with chezmoi"
  # `chezmoi init` only clones when the source directory is not already a git
  # repo, and it never pulls. On subsequent runs, update the remote if needed
  # and pull/apply the latest dotfiles.
  SOURCE_DIR="$("$CHEZMOI" source-path 2>/dev/null || echo "$HOME/.local/share/chezmoi")"

  if [ -d "$SOURCE_DIR/.git" ]; then
    current_url="$("$CHEZMOI" git -- remote get-url origin 2>/dev/null || true)"

    if [ -n "$DOTFILES_REPO" ] && [ "$current_url" != "$DOTFILES_REPO" ]; then
      "$CHEZMOI" git -- remote set-url origin "$DOTFILES_REPO" 2>/dev/null \
        || "$CHEZMOI" git -- remote add origin "$DOTFILES_REPO"
    fi

    "$CHEZMOI" update || echo "    chezmoi: update failed"
  elif [ -z "$DOTFILES_REPO" ]; then
    echo "    skipped (no repo: clone it first, or set DOTFILES_REPO)"
  else
    "$CHEZMOI" init --apply "$DOTFILES_REPO" || echo "    chezmoi: init failed"
  fi
fi

# Authorize SSH login keys. Append-only and idempotent: each key is added just
# once and existing entries are left untouched.
if [ -n "$SSH_KEYS_URL" ] && need curl; then
  echo "==> Authorizing SSH login keys from $SSH_KEYS_URL"

  # Authorizing inbound keys implies wanting an SSH server to log into.
  if [ "$CAN_ROOT" = 1 ] && has apt; then
    $SUDO apt install -y openssh-server || echo "    openssh-server: skip"
  fi

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

# Change the login shell to zsh.
ZSH_PATH="$(command -v zsh || true)"
current_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"

if [ -n "$ZSH_PATH" ] && [ "$current_shell" != "$ZSH_PATH" ]; then
  echo "==> Setting zsh as the default shell"

  if [ "$(id -u)" -eq 0 ]; then
    chsh -s "$ZSH_PATH" "$(id -un)" || echo "    could not change shell"
  elif [ "$CAN_ROOT" = 1 ]; then
    sudo chsh -s "$ZSH_PATH" "$(id -un)" || echo "    could not change shell"
  elif [ -n "$UNATTENDED" ]; then
    echo "    skipped (would need a password); run later: chsh -s $ZSH_PATH"
  else
    chsh -s "$ZSH_PATH" "$(id -un)" \
      || echo "    could not change shell; run later: chsh -s $ZSH_PATH"
  fi
fi

### Installing AppMan #################################################################
echo "==> Installing AppMan (optional)"
if [ ! -x "$HOME/.local/bin/appman" ] && need curl; then
  AM_INSTALLER="$(mktemp "${TMPDIR:-/tmp}/AM-INSTALLER.XXXXXX")"

  {
    curl -fsSL -o "$AM_INSTALLER" \
      https://raw.githubusercontent.com/ivan-hc/AM/main/AM-INSTALLER
    chmod a+x "$AM_INSTALLER"
    "$AM_INSTALLER" -i appman
  } >/dev/null 2>&1 || true

  rm -f "$AM_INSTALLER"
fi

### Installing Zellij #################################################################
echo "==> Installing Zellij (optional)"
if [ ! -x "$HOME/.local/bin/zellij" ] && need curl tar; then
  (
    case "$ARCH" in
      x86_64)        ZELLIJ_ARCH="x86_64" ;;
      aarch64|arm64) ZELLIJ_ARCH="aarch64" ;;
      *)             exit 0 ;;
    esac

    case "$OS" in
      Linux) ZELLIJ_SYS="unknown-linux-musl" ;;
      *)     exit 0 ;;
    esac

    mkdir -p "$HOME/.local/bin"

    curl -fsSL \
      "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${ZELLIJ_ARCH}-${ZELLIJ_SYS}.tar.gz" |
      tar -xz -C "$HOME/.local/bin"

    chmod +x "$HOME/.local/bin/zellij"
  ) >/dev/null 2>&1 || true
fi

### Installing Yazi #################################################################
echo "==> Installing Yazi (optional)"
if [ ! -x "$HOME/.local/bin/yazi" ] && need curl; then
  (
    case "$ARCH" in
      x86_64)        YAZI_ARCH="x86_64" ;;
      aarch64|arm64) YAZI_ARCH="aarch64" ;;
      *)             exit 0 ;;
    esac
    [ "$OS" = "Linux" ] || exit 0

    YAZI_TMP="$(mktemp -d "${TMPDIR:-/tmp}/yazi.XXXXXX")"
    trap 'rm -rf "$YAZI_TMP"' EXIT
    mkdir -p "$HOME/.local/bin"

    curl -fsSL -o "$YAZI_TMP/yazi.zip" \
      "https://github.com/sxyazi/yazi/releases/latest/download/yazi-${YAZI_ARCH}-unknown-linux-musl.zip"
    # unzip may be missing (non-apt distros); python3 is a common fallback.
    if command -v unzip >/dev/null 2>&1; then
      unzip -q "$YAZI_TMP/yazi.zip" -d "$YAZI_TMP"
    else
      python3 -m zipfile -e "$YAZI_TMP/yazi.zip" "$YAZI_TMP"
    fi
    install -m 755 "$YAZI_TMP"/yazi-*/yazi "$YAZI_TMP"/yazi-*/ya "$HOME/.local/bin/"
  ) >/dev/null 2>&1 || echo "    yazi: skip"
fi

### Installing parallel #################################################################
echo "==> Installing GNU parallel (optional)"
# Perl script, so arch-independent; built from source into ~/.local (no root).
if [ ! -x "$HOME/.local/bin/parallel" ] && ! has parallel && need curl tar bzip2 make perl; then
  (
    PARALLEL_TMP="$(mktemp -d "${TMPDIR:-/tmp}/parallel.XXXXXX")"
    trap 'rm -rf "$PARALLEL_TMP"' EXIT

    curl -fsSL "https://ftpmirror.gnu.org/parallel/parallel-latest.tar.bz2" |
      tar -xj -C "$PARALLEL_TMP"
    cd "$PARALLEL_TMP"/parallel-*/ &&
      ./configure --prefix="$HOME/.local" &&
      make &&
      make install
  ) >/dev/null 2>&1 || echo "    parallel: skip"
fi

echo "==> Done. Start a new shell or run: exec zsh"
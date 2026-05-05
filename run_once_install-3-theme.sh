#!/bin/bash
set -e

THEME_DIR="$HOME/.oh-my-zsh/custom/themes"
mkdir -p "$THEME_DIR"
curl -fsSL https://raw.githubusercontent.com/jujumo/memento/main/coding/linux/jumo.zsh-theme \
    -o "$THEME_DIR/jumo.zsh-theme"


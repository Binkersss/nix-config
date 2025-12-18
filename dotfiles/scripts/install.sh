#!/usr/bin/env bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p ~/.config

ln -sf "$DOTFILES/nvim" ~/.config/nvim
ln -sf "$DOTFILES/tmux" ~/.config/tmux

echo "Dotfiles installed."


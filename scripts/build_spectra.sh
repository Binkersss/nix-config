#!/usr/bin/env bash
set -euo pipefail
FLAKE_TARGET=".#spectra"

# ---- helpers ----
pause() {
  read -rp "$1"
}

section() {
  echo
  echo "==> $1"
}

# ---- preflight ----
section "Git status"
git status
pause "Continue? (enter to continue, Ctrl+C to abort) "

section "Git diff"
git --no-pager diff
pause "Stage all changes? (enter to continue, Ctrl+C to abort) "

# ---- git commit ----
section "Staging changes"
git add -A

if [[ $# -gt 0 ]]; then
  USER_MSG="$*"
else
  read -rp "Commit message: " USER_MSG
fi

if [[ -z "$USER_MSG" ]]; then
  echo "Aborting: empty commit message"
  exit 1
fi

# Get current generation number before rebuild
CURRENT_GEN=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -1 | awk '{print $1}')
NEXT_GEN=$((CURRENT_GEN + 1))

# Format commit message
COMMIT_MSG="Generation ${NEXT_GEN}

${USER_MSG}"

section "Committing"
git commit -m "$COMMIT_MSG"

# ---- rebuild ----
section "Rebuilding NixOS (spectra)"
sudo nixos-rebuild switch --flake "$FLAKE_TARGET" |& nom

# --- validating nvim config ---

# Capture output and errors
output=$(nvim --headless \
  -c "lua vim.opt.termguicolors = false" \
  -c "lua print('Config loaded successfully')" \
  -c "checkhealth" \
  -c "quit" 2>&1)

exit_code=$?

echo "$output"

if [ $exit_code -eq 0 ]; then
    echo ""
    echo "✓ Neovim config validation passed"
    exit 0
else
    echo ""
    echo "✗ Neovim config validation failed"
    exit 1
fi
section "Done"

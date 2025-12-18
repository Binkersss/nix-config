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
  COMMIT_MSG="$*"
else
  read -rp "Commit message: " COMMIT_MSG
fi

if [[ -z "$COMMIT_MSG" ]]; then
  echo "Aborting: empty commit message"
  exit 1
fi

section "Committing"
git commit -m "$COMMIT_MSG"

# ---- rebuild ----
section "Rebuilding NixOS (spectra)"
sudo nixos-rebuild switch --flake "$FLAKE_TARGET"

section "Done"


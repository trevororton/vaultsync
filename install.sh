#!/bin/bash
#
# vaultsync installer.
#
#   curl -fsSL https://raw.githubusercontent.com/OWNER/vaultsync/main/install.sh | bash
#
# Installs vaultsync into ~/.local/bin, pulls in what it needs, and then hands
# you to `vaultsync setup`. Nothing runs in the background until you ask it to.

set -euo pipefail

REPO="${VAULTSYNC_REPO:-OWNER/vaultsync}"
BRANCH="${VAULTSYNC_BRANCH:-main}"
BIN_DIR="${VAULTSYNC_BIN_DIR:-$HOME/.local/bin}"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH/vaultsync"

bold=$(tput bold 2>/dev/null || true)
dim=$(tput dim 2>/dev/null || true)
red=$(tput setaf 1 2>/dev/null || true)
green=$(tput setaf 2 2>/dev/null || true)
yellow=$(tput setaf 3 2>/dev/null || true)
reset=$(tput sgr0 2>/dev/null || true)

say()  { printf '%s\n' "$*"; }
ok()   { printf '%sok%s   %s\n' "$green" "$reset" "$*"; }
warn() { printf '%s--%s   %s\n' "$yellow" "$reset" "$*"; }
die()  { printf '%serror%s %s\n' "$red" "$reset" "$*" >&2; exit 1; }

say "${bold}vaultsync installer${reset}"
say ""

# ---------------------------------------------------------------- platform

[ "$(uname -s)" = "Darwin" ] || die "vaultsync is macOS only: it uses launchd for \
background syncing and Apple's FSEvents to notice local edits."
ok "macOS $(sw_vers -productVersion 2>/dev/null || echo '')"

# ---------------------------------------------------------------- dependencies

NEED=()
have() { command -v "$1" >/dev/null 2>&1; }

have rclone  || NEED+=(rclone)
have fswatch || NEED+=(fswatch)

# The background agent needs an interpreter macOS will let read ~/Documents.
# Apple's bundled python3 is denied there, and the denial is silent.
BG_PYTHON=""
for candidate in /opt/homebrew/bin/python3 \
                 /opt/homebrew/opt/python@3.13/bin/python3.13 \
                 /opt/homebrew/opt/python@3.12/bin/python3.12 \
                 /usr/local/bin/python3; do
  [ -x "$candidate" ] && { BG_PYTHON="$candidate"; break; }
done
[ -n "$BG_PYTHON" ] || NEED+=(python@3.13)

if [ ${#NEED[@]} -gt 0 ]; then
  if have brew; then
    say "Installing: ${NEED[*]}"
    brew install "${NEED[@]}"
    ok "dependencies installed"
  else
    warn "Homebrew is not installed, and these are still needed: ${NEED[*]}"
    say ""
    say "  Easiest path — install Homebrew, then re-run this installer:"
    say "    ${dim}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${reset}"
    say ""
    say "  Or install them yourself:"
    say "    rclone      https://rclone.org/install/"
    say "    fswatch     optional; without it local edits wait for the poll"
    say "    python3     any non-Apple build, e.g. python.org"
    say ""
    say "  vaultsync will still be installed. Run ${bold}vaultsync doctor${reset} afterwards"
    say "  and it will tell you exactly what is still missing."
    say ""
  fi
else
  ok "rclone, fswatch and a background-safe Python are present"
fi

# ---------------------------------------------------------------- install

mkdir -p "$BIN_DIR"
TARGET="$BIN_DIR/vaultsync"

if [ -f "./vaultsync" ] && [ -z "${VAULTSYNC_FORCE_DOWNLOAD:-}" ]; then
  install -m 0755 ./vaultsync "$TARGET"      # running from a clone
  ok "installed from this directory to $TARGET"
else
  TMP="$(mktemp)"
  curl -fsSL "$RAW" -o "$TMP" || die "could not download $RAW"
  head -1 "$TMP" | grep -q python || die "downloaded file does not look like \
vaultsync; check that $REPO is correct and public"
  install -m 0755 "$TMP" "$TARGET"
  rm -f "$TMP"
  ok "installed to $TARGET"
fi

VERSION="$("$TARGET" version 2>/dev/null || echo 'vaultsync')"
ok "$VERSION"

# ---------------------------------------------------------------- PATH

case ":$PATH:" in
  *":$BIN_DIR:"*) ok "$BIN_DIR is on your PATH" ;;
  *)
    warn "$BIN_DIR is not on your PATH"
    SHELL_RC="$HOME/.zshrc"
    [ "$(basename "${SHELL:-/bin/zsh}")" = "bash" ] && SHELL_RC="$HOME/.bash_profile"
    say ""
    say "  Add it:"
    say "    ${dim}echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> $SHELL_RC${reset}"
    say "    ${dim}exec \$SHELL${reset}"
    say ""
    ;;
esac

# ---------------------------------------------------------------- next step

say ""
say "${bold}Next:${reset}"
say "    vaultsync setup      ${dim}# connect Google Drive, pick your vault${reset}"
say "    vaultsync doctor     ${dim}# check everything, including background access${reset}"
say ""
say "${dim}Nothing syncs until you run 'vaultsync add'.${reset}"

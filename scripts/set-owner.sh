#!/bin/bash
#
# Point this package at wherever you publish it.
#
#   ./scripts/set-owner.sh your-github-username
#
# Replaces the OWNER placeholder in the README, installer, Homebrew formula and
# the CLI's help link. Run this once before publishing.

set -euo pipefail

OWNER="${1:-}"
if [ -z "$OWNER" ]; then
  echo "usage: $0 <github-username-or-org> [repo-name]" >&2
  exit 1
fi
REPO="${2:-vaultsync}"

cd "$(dirname "$0")/.."

FILES=(README.md install.sh Formula/vaultsync.rb vaultsync)
for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  # BSD sed (macOS) needs the empty -i argument.
  sed -i '' "s|OWNER/vaultsync|$OWNER/$REPO|g" "$f"
  sed -i '' "s|OWNER/$REPO\.git|$OWNER/$REPO.git|g" "$f"
done

echo "Pointed at github.com/$OWNER/$REPO"
echo ""
echo "Remaining before a tagged release:"
echo "  - Formula/vaultsync.rb needs the tarball sha256 (see the comment in that file)"
echo "  - until then, 'brew install --HEAD $REPO' works with no further changes"
echo ""
echo "Check nothing was missed:"
echo "  grep -rn OWNER . --exclude-dir=.git || echo clean"

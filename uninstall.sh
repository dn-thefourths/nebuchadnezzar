#!/usr/bin/env bash
# Nebuchadnezzar Matrix splash — uninstaller
# Reverses install.sh: removes the copied script, strips the shell snippet
# block, and deletes the daily-frequency stamp. Terminal.app font changes are
# left untouched (see note at the end).
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${RED}!${NC} $*"; }

echo ""
echo "  ══════════════════════════════════"
echo "   Nebuchadnezzar — uninstall"
echo "  ══════════════════════════════════"
echo ""

MARKER="Nebuchadnezzar Matrix splash"

# ── Remove the splash script ──────────────────────────────────────────────

if [[ -f "$HOME/.config/matrix-splash.py" ]]; then
  rm -f "$HOME/.config/matrix-splash.py"
  success "Removed ~/.config/matrix-splash.py"
else
  info "Not present: ~/.config/matrix-splash.py — skipping"
fi

# ── Strip the snippet block from shell rc files ───────────────────────────
# The block runs from the marker line to its closing rule (the only other
# line that starts with "# ─"), so we drop everything between, inclusive.

strip_block() {
  local rc="$1"
  local tmp; tmp=$(mktemp)
  awk '
    state==0 && /Nebuchadnezzar Matrix splash/ { state=1; next }  # drop opening marker line
    state==1 && /^# ─/                          { state=2; next }  # drop closing rule line, stop
    state==1                                    { next }           # drop block body
    { print }
  ' "$rc" > "$tmp"
  cp "$rc" "$rc.nebu.bak"
  mv "$tmp" "$rc"
  success "Removed snippet from $rc (backup: $rc.nebu.bak)"
}

stripped=0
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [[ -f "$rc" ]] && grep -q "$MARKER" "$rc"; then
    strip_block "$rc"
    stripped=1
  fi
done
[[ "$stripped" -eq 1 ]] || info "No snippet block found in ~/.zshrc or ~/.bashrc"

# ── Remove the daily-frequency stamp ──────────────────────────────────────

STAMP="${XDG_CACHE_HOME:-$HOME/.cache}/nebuchadnezzar-last"
if [[ -f "$STAMP" ]]; then
  rm -f "$STAMP"
  success "Removed frequency stamp $STAMP"
fi

# ── Done ──────────────────────────────────────────────────────────────────

echo ""
warn "Terminal colours/title and any Terminal.app font change are not reverted."
warn "Open a new terminal for the removal to take effect."
echo ""
echo "  ══════════════════════════════════"
success "Uninstall complete."
echo "  ══════════════════════════════════"
echo ""

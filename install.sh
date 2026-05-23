#!/usr/bin/env bash
# Nebuchadnezzar Matrix splash — installer
# Tested on: macOS 14+ (zsh), Ubuntu 22+ (zsh)
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*"; exit 1; }

echo ""
echo "  ══════════════════════════════════"
echo "   Nebuchadnezzar Matrix Splash"
echo "  ══════════════════════════════════"
echo ""

# ── Pre-flight checks ──────────────────────────────────────────────────────

python3 --version &>/dev/null || error "python3 not found. Install it and re-run."
success "python3 found: $(python3 --version)"

if [[ "$(uname)" == "Darwin" ]]; then
  HAS_SAY=true
  success "macOS detected — Zarvox voice will be enabled"
else
  HAS_SAY=false
  info "Non-macOS — voice effect will be skipped"
fi

# ── Copy script ───────────────────────────────────────────────────────────

mkdir -p "$HOME/.config"
cp "$(dirname "$0")/matrix-splash.py" "$HOME/.config/matrix-splash.py"
chmod 644 "$HOME/.config/matrix-splash.py"
success "Copied matrix-splash.py → ~/.config/matrix-splash.py"

# ── Determine shell config file ───────────────────────────────────────────

if [[ -f "$HOME/.zshrc" ]]; then
  RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  RC="$HOME/.bashrc"
else
  RC="$HOME/.zshrc"
fi
info "Shell config: $RC"

# ── Ask about auto-launch ─────────────────────────────────────────────────

echo ""
echo "  After the splash, auto-launch a command?"
echo "  [1] claude   (Claude Code CLI)"
echo "  [2] Custom command"
echo "  [3] None — just show the splash and drop to prompt"
echo ""
read -rp "  Choice [1/2/3]: " choice

case "$choice" in
  1) LAUNCH_CMD="claude" ;;
  2) read -rp "  Enter command: " LAUNCH_CMD ;;
  *) LAUNCH_CMD="" ;;
esac

# ── Patch zshrc-snippet with voice and launch settings ───────────────────

SNIPPET=$(cat "$(dirname "$0")/zshrc-snippet.zsh")

# Set MATRIX_LAUNCH
SNIPPET="${SNIPPET/MATRIX_LAUNCH=\"\"/MATRIX_LAUNCH=\"${LAUNCH_CMD}\"}"

# Remove macOS say block if not on macOS
if [[ "$HAS_SAY" == "false" ]]; then
  # Strip the say block (3 lines)
  SNIPPET=$(echo "$SNIPPET" | grep -v 'macOS only\|uname\|say -v\|fi$' || true)
fi

# ── Append to shell config ────────────────────────────────────────────────

echo ""
MARKER="# ── Nebuchadnezzar Matrix splash ─"
if grep -q "$MARKER" "$RC" 2>/dev/null; then
  info "Snippet already present in $RC — skipping append"
else
  echo "" >> "$RC"
  echo "$SNIPPET" >> "$RC"
  success "Appended snippet to $RC"
fi

# ── Terminal font size (macOS only) ──────────────────────────────────────

if [[ "$HAS_SAY" == "true" ]]; then
  echo ""
  read -rp "  Patch Terminal.app font to 14pt minimum? [y/N]: " patch_font
  if [[ "$patch_font" =~ ^[Yy]$ ]]; then
    python3 - <<'PYEOF'
import plistlib, subprocess, shutil, tempfile, os

MIN = 14.0
tmp = tempfile.mktemp(suffix='.plist')
subprocess.run(['defaults', 'export', 'com.apple.Terminal', tmp], check=True)
with open(tmp, 'rb') as f:
    data = plistlib.load(f)
changed = 0
for profile in data.get('Window Settings', {}).values():
    if 'Font' not in profile:
        continue
    fp = plistlib.loads(profile['Font'])
    for obj in fp.get('$objects', []):
        if isinstance(obj, dict) and 'NSSize' in obj and obj['NSSize'] < MIN:
            obj['NSSize'] = MIN
            changed += 1
    profile['Font'] = plistlib.dumps(fp, fmt=plistlib.FMT_BINARY)
out = tempfile.mktemp(suffix='.plist')
with open(out, 'wb') as f:
    plistlib.dump(data, f, fmt=plistlib.FMT_BINARY)
subprocess.run(['defaults', 'import', 'com.apple.Terminal', out], check=True)
os.unlink(tmp); os.unlink(out)
print(f"  Patched {changed} profile(s) to {MIN}pt")
PYEOF
    success "Font size patched — restart Terminal to apply"
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────

echo ""
echo "  ══════════════════════════════════"
success "Done. Open a new terminal to see it."
echo "  ══════════════════════════════════"
echo ""

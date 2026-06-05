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
  IS_MACOS=true
  success "macOS detected"
else
  IS_MACOS=false
fi

# ── Copy script ───────────────────────────────────────────────────────────

mkdir -p "$HOME/.config"
cp "$(dirname "$0")/matrix-splash.py" "$HOME/.config/matrix-splash.py"
chmod 644 "$HOME/.config/matrix-splash.py"
success "Copied matrix-splash.py → ~/.config/matrix-splash.py"

# ── Determine shell config file ───────────────────────────────────────────

if [[ -f "$HOME/.zshrc" ]]; then
  RC="$HOME/.zshrc"; SHELL_KIND="zsh"
elif [[ -f "$HOME/.bashrc" ]]; then
  RC="$HOME/.bashrc"; SHELL_KIND="bash"
else
  RC="$HOME/.zshrc"; SHELL_KIND="zsh"
fi
info "Shell config: $RC ($SHELL_KIND)"

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

# ── Patch the shell snippet with the launch command ──────────────────────

if [[ "$SHELL_KIND" == "bash" ]]; then
  SNIPPET=$(cat "$(dirname "$0")/bashrc-snippet.bash")
else
  SNIPPET=$(cat "$(dirname "$0")/zshrc-snippet.zsh")
fi

# Set MATRIX_LAUNCH on the actual assignment line — anchored to line start so
# the commented example lines (which begin with "#") are left untouched.
# Pass the command via ENVIRON (not -v) so awk does not interpret backslash
# escapes in it (e.g. a path containing "\t").
SNIPPET=$(printf '%s\n' "$SNIPPET" | LAUNCH_CMD="$LAUNCH_CMD" awk '
  !done && /^MATRIX_LAUNCH=/ { print "MATRIX_LAUNCH=\"" ENVIRON["LAUNCH_CMD"] "\""; done=1; next }
  { print }
')

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

if [[ "$IS_MACOS" == "true" ]]; then
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

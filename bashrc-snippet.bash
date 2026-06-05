# ── Nebuchadnezzar Matrix splash ─────────────────────────────────────────────
#
# Set MATRIX_LAUNCH to any command you want auto-launched after the splash.
# Leave empty for a plain shell prompt.
#
#   MATRIX_LAUNCH="claude"   # launch Claude Code
#   MATRIX_LAUNCH="bash"     # just drop into bash
#   MATRIX_LAUNCH=""         # do nothing (default)
#
MATRIX_LAUNCH=""

_matrix_splash() {
  [[ $- == *i* ]] || return          # interactive shells only
  [[ -z "$VSCODE_PID" ]] || return   # skip VS Code integrated terminal

  # Terminal colours: Matrix green on black
  printf '\033]10;#00FF41\007'        # foreground
  printf '\033]11;#000000\007'        # background
  printf '\033]12;#00FF41\007'        # cursor
  printf '\033]0;NEBUCHADNEZZAR\007'  # tab title

  python3 ~/.config/matrix-splash.py 2>/dev/null || true

  [[ -n "$MATRIX_LAUNCH" ]] && exec "$MATRIX_LAUNCH"
}
_matrix_splash

# Green prompt
PS1='\[\e[0;32m\]\w\[\e[1;32m\] ❯\[\e[0m\] '
# ─────────────────────────────────────────────────────────────────────────────

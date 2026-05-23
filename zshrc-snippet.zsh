# ── Nebuchadnezzar Matrix splash ─────────────────────────────────────────────
#
# Set MATRIX_LAUNCH to any command you want auto-launched after the splash.
# Leave empty for a plain shell prompt.
#
#   MATRIX_LAUNCH="claude"   # launch Claude Code
#   MATRIX_LAUNCH="zsh"      # just drop into zsh
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

  # macOS only: Samantha voice fires after 5s — lands during the banner decode
  # Alternatives: Moira (Irish), Tessa (South African), Karen (Australian)
  if [[ "$(uname)" == "Darwin" ]]; then
    (sleep 5 && say -v Samantha "Welcome, Chosen One" 2>/dev/null) &
  fi

  python3 ~/.config/matrix-splash.py 2>/dev/null || true

  [[ -n "$MATRIX_LAUNCH" ]] && exec "$MATRIX_LAUNCH"
}
_matrix_splash

# Green prompt
autoload -U colors && colors
PROMPT='%F{green}%~%f %F{082}❯%f '
# ─────────────────────────────────────────────────────────────────────────────

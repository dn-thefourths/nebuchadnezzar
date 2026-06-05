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

# Optional extras — blank/unset uses the built-in defaults:
#   MATRIX_FREQUENCY="daily"          # "always" (default) or "daily" = once per calendar day
#   MATRIX_MESSAGE="Wake up, Neo"     # banner text (default: Welcome to the Nebuchadnezzar)
#   MATRIX_TICK="0.03"                # frame time in seconds; lower = faster (default 0.04)
MATRIX_FREQUENCY="${MATRIX_FREQUENCY:-always}"
MATRIX_MESSAGE="${MATRIX_MESSAGE:-}"
MATRIX_TICK="${MATRIX_TICK:-}"

_matrix_should_play() {
  [[ "${MATRIX_FREQUENCY:-always}" != "daily" ]] && return 0
  local stamp="${XDG_CACHE_HOME:-$HOME/.cache}/nebuchadnezzar-last"
  local today; today=$(date +%Y%m%d)
  [[ -f "$stamp" && "$(<"$stamp")" == "$today" ]] && return 1
  mkdir -p "${stamp%/*}" 2>/dev/null
  printf '%s' "$today" > "$stamp" 2>/dev/null
  return 0
}

_matrix_splash() {
  [[ $- == *i* ]] || return          # interactive shells only
  [[ -z "$VSCODE_PID" ]] || return   # skip VS Code integrated terminal

  # Terminal colours: Matrix green on black (applied every shell)
  printf '\033]10;#00FF41\007'        # foreground
  printf '\033]11;#000000\007'        # background
  printf '\033]12;#00FF41\007'        # cursor
  printf '\033]0;NEBUCHADNEZZAR\007'  # tab title

  if _matrix_should_play; then
    [[ -n "${MATRIX_MESSAGE:-}" ]] && export MATRIX_MESSAGE
    [[ -n "${MATRIX_TICK:-}" ]] && export MATRIX_TICK
    python3 ~/.config/matrix-splash.py 2>/dev/null || true
  fi

  [[ -n "$MATRIX_LAUNCH" ]] && exec "$MATRIX_LAUNCH"
}
_matrix_splash

# Green prompt
autoload -U colors && colors
PROMPT='%F{green}%~%f %F{082}❯%f '
# ─────────────────────────────────────────────────────────────────────────────

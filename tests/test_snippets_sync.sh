#!/usr/bin/env bash
# Guards against drift between the two shell snippets and verifies the
# structural anchors that install.sh and uninstall.sh depend on exist in BOTH
# snippets (the zsh snippet is otherwise untested — shellcheck can't parse zsh).
set -uo pipefail

z="$(dirname "$0")/../zshrc-snippet.zsh"
b="$(dirname "$0")/../bashrc-snippet.bash"
fail=0

# 1. The shared logic — from _matrix_should_play through the _matrix_splash
#    call — must stay byte-identical between the two snippets.
range='/_matrix_should_play()/,/^_matrix_splash$/p'
if diff <(sed -n "$range" "$z") <(sed -n "$range" "$b") >/dev/null; then
  echo "ok: shared snippet logic is in sync"
else
  echo "FAIL: zsh and bash snippets have drifted in the shared logic block"; fail=1
fi

# 2. Both snippets must carry the anchors install.sh / uninstall.sh rely on:
#    the marker line, the MATRIX_LAUNCH assignment, and a closing rule line.
for f in "$z" "$b"; do
  grep -q '^# ── Nebuchadnezzar Matrix splash ─' "$f" || { echo "FAIL: $f missing marker line"; fail=1; }
  grep -q '^MATRIX_LAUNCH='                       "$f" || { echo "FAIL: $f missing MATRIX_LAUNCH anchor"; fail=1; }
  grep -q '^# ─────'                              "$f" || { echo "FAIL: $f missing closing rule line"; fail=1; }
done

if [[ "$fail" -eq 0 ]]; then
  echo "snippet-sync tests passed"
else
  echo "snippet-sync tests FAILED"; exit 1
fi

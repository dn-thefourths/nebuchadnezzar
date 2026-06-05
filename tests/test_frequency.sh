#!/usr/bin/env bash
# Tests for the _matrix_should_play daily-throttle helper in bashrc-snippet.bash.
# Dependency-free: run directly with `bash tests/test_frequency.sh`.
set -uo pipefail

snippet="$(dirname "$0")/../bashrc-snippet.bash"
fn="$(mktemp)"
sed -n '/_matrix_should_play()/,/^}/p' "$snippet" > "$fn"
# shellcheck source=/dev/null
source "$fn"
rm -f "$fn"

XDG_CACHE_HOME="$(mktemp -d)"; export XDG_CACHE_HOME
trap 'rm -rf "$XDG_CACHE_HOME"' EXIT

fail=0
check() {  # check <actual-rc> <expected-rc> <label>
  if [[ "$1" == "$2" ]]; then
    echo "ok: $3"
  else
    echo "FAIL: $3 (got rc=$1, want rc=$2)"; fail=1
  fi
}

run() { if _matrix_should_play; then echo 0; else echo 1; fi; }

# MATRIX_FREQUENCY is read by the sourced helper (which shellcheck can't see),
# so export it to make that use explicit.
export MATRIX_FREQUENCY

# always mode: every call plays
MATRIX_FREQUENCY=always
check "$(run)" 0 "always plays #1"
check "$(run)" 0 "always plays #2"

# daily mode: first call plays, second is throttled
MATRIX_FREQUENCY=daily
check "$(run)" 0 "daily first play"
check "$(run)" 1 "daily second throttled"

# a stamp from a previous day lets it play again
echo "20000101" > "$XDG_CACHE_HOME/nebuchadnezzar-last"
check "$(run)" 0 "daily new day plays"

if [[ "$fail" -eq 0 ]]; then
  echo "frequency tests passed"
else
  echo "frequency tests FAILED"; exit 1
fi

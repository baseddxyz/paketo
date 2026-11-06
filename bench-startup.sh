#!/usr/bin/env bash
# Measure this config's startup time with Neovim's own `--startuptime`.
# Prints the number Neovim reports for `--- NVIM STARTED ---` per run, then
# the min, median, and max across runs. A missing marker fails the run loudly,
# so a startup error can't read as a fast run.
#
# Usage: ./bench-startup.sh [runs] [trace-file]
#   runs       number of startup runs (default: 7)
#   trace-file write the first run's full --startuptime log to this file
set -euo pipefail

runs="${1:-7}"
trace="${2:-}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Present the repo as the Neovim config directory so `plugin/` is sourced.
xdg="$(mktemp -d)"
ln -s "$root" "$xdg/nvim"
trap 'rm -rf "$xdg"' EXIT

times=()
for i in $(seq 1 "$runs"); do
  log="$(mktemp)"
  if [ -n "$trace" ] && [ "$i" -eq 1 ]; then
    rm -f "$trace"
    log="$trace"
  fi
  env XDG_CONFIG_HOME="$xdg" nvim --headless --startuptime "$log" +qa >/dev/null 2>&1
  t="$(awk '/NVIM STARTED/ {printf "%.1f", $1}' "$log")"
  if [ -z "$t" ]; then
    echo "run $i: no NVIM STARTED marker in $log" >&2
    exit 1
  fi
  [ "$log" = "$trace" ] || rm -f "$log"
  times+=("$t")
done

printf '%s\n' "${times[@]}" | sort -n |
  awk -v n="$runs" '{a[NR]=$1} END {printf "runs=%d min=%.1fms median=%.1fms max=%.1fms\n", NR, a[1], a[int((NR+1)/2)], a[n]}'

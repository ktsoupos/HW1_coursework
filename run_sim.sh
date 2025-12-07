#!/usr/bin/env bash
set -euo pipefail
workspace="$(cd "$(dirname "$0")" && pwd)"
# Usage: ./run_sim.sh [tb-path-or-pattern]
# If no argument is given, runs all testbenches under tb/ and tb/*/.

# Parse CLI args: optional testbench arg and flags
tb_arg=""
wave_opt="0"
no_run=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --wave|-w)
      wave_opt=1
      shift
      ;;
    --no-run|-n)
      no_run=1
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [tb-path-or-pattern] [--wave] [--no-run]"
      echo "Examples:" 
      echo "  $0                # run all testbenches"
      echo "  $0 alu/alu_tb.v   # run specific testbench"
      echo "  $0 --wave         # run all and open gtkwave"
      echo "  $0 --no-run      # compile only, don't run simulation"
      exit 0
      ;;
    *)
      if [[ -z "$tb_arg" ]]; then
        tb_arg="$1"
      else
        echo "Ignoring extra arg: $1" >&2
      fi
      shift
      ;;
  esac
done
# Build lists of source and tb files (may include subdirs)
SRCS=("$workspace/src"/*.v "$workspace/src"/*/*.v)
TB_GLOBS=()
if [[ -n "$tb_arg" ]]; then
  # Try multiple reasonable locations/patterns
  TB_GLOBS+=("$workspace/tb/$tb_arg")
  TB_GLOBS+=("$workspace/$tb_arg")
  TB_GLOBS+=("$tb_arg")
else
  TB_GLOBS+=("$workspace/tb"/*.v "$workspace/tb"/*/*.v)
fi

# Expand globs into actual files (bash nullglob not set globally here)
expand_files() {
  local arr=()
  for g in "$@"; do
    for f in $g; do
      if [[ -f "$f" ]]; then
        arr+=("$f")
      fi
    done
  done
  echo "${arr[@]}"
}

TB_FILES=( $(expand_files "${TB_GLOBS[@]}") )
SRC_FILES=( $(expand_files "${SRCS[@]}") )

if [[ ${#TB_FILES[@]} -eq 0 ]]; then
  echo "No testbench files found for: '${tb_arg:-<all>}'" >&2
  echo "Searched patterns: ${TB_GLOBS[*]}" >&2
  exit 1
fi

# Final file list
FILES=("${SRC_FILES[@]}" "${TB_FILES[@]}")

echo "Compiling with iverilog using ${#FILES[@]} files..."
iverilog -o "$workspace/sim/output.vvp" "${FILES[@]}"

if [[ $no_run -eq 0 ]]; then
  echo "Running simulation (vvp)..."
  vvp "$workspace/sim/output.vvp"
else
  echo "--no-run specified: compiled to $workspace/sim/output.vvp (did not run)"
fi

# dump.vcd is created by the testbench. Optionally open gtkwave with --wave
open_wave=0
if [[ "${wave_opt:-}" == "1" || "${wave_opt:-}" == "true" ]]; then
  open_wave=1
fi

if [[ $open_wave -eq 1 ]]; then
  if command -v gtkwave >/dev/null 2>&1; then
    echo "Opening waveform in gtkwave..."
    gtkwave "$workspace/dump.vcd" &
  else
    echo "gtkwave not found in PATH; install gtkwave or run it manually: gtkwave $workspace/dump.vcd" >&2
  fi
fi

# Verilog Project — HW1_coursework

Quick helper scripts and tasks to build and run the Verilog testbenches.

Usage

- Run all testbenches (builds and runs):

```bash
./run_sim.sh
```

- Run a specific testbench (pass file or pattern):

```bash
./run_sim.sh alu/alu_tb.v
./run_sim.sh tb/alu/alu_tb.v
./run_sim.sh "alu_tb.v"
```

- Open waveform automatically after simulation:

```bash
./run_sim.sh --wave
./run_sim.sh alu/alu_tb.v --wave
```

Makefile targets

- `make` or `make build` — compiles all sources
- `make run` — runs all testbenches using `run_sim.sh`
- `make run TB=alu/alu_tb.v` — run a specific testbench
- `make wave` — open `dump.vcd` with GTKWave

VS Code

- Use the `Compile Verilog` (Build) task to run the build+sim helper.
- Use the `Run Testbench` task to run a specific testbench (it will prompt for a value).

Notes

- `run_sim.sh` uses `bash` for glob expansion and accepts an optional testbench argument and `--wave` flag.
- The testbench writes `dump.vcd` in the repo root; `gtkwave` is used to view it.

Additional flags

- `--no-run` / `-n`: compile only (produces `sim/output.vvp`) and do not run the simulation. Useful for fast checks or CI compilation steps:

```bash
./run_sim.sh --no-run
make compile-only
```

CI-friendly targets

- `make ci` — compiles and runs the simulation non-interactively, writing output to `ci_simulation.log`. Suitable for CI pipelines. Example:

```bash
make ci
# HW_1_EX — Verilog Testbench Runner

This repository contains a small Verilog project (ALU) with helper scripts and tasks to compile and run testbenches and to view waveform output.

Quick start

- Build and run all testbenches:

```bash
./run_sim.sh
```

- Run a specific testbench (path or pattern accepted):

```bash
./run_sim.sh tb/alu/alu_tb.v
./run_sim.sh alu/alu_tb.v
```

- Run and open waveform in GTKWave:

```bash
./run_sim.sh --wave
./run_sim.sh tb/alu/alu_tb.v --wave
```

Script flags

- `--wave`, `-w`  : Open `dump.vcd` in GTKWave after the simulation (if `gtkwave` is available).
- `--no-run`, `-n`: Compile only; produce `sim/output.vvp` but do not execute the simulation.
- `--help`, `-h`  : Show usage information.

Makefile targets

- `make` / `make build`    : Compile all sources.
- `make run`               : Run testbenches via `run_sim.sh` (supports `make run TB=path`).
- `make compile-only`      : Compile only (invokes `run_sim.sh --no-run`).
- `make ci`                : CI-friendly target that compiles and runs the simulation non-interactively and writes `ci_simulation.log`.
- `make wave`              : Open `dump.vcd` with GTKWave.

VS Code tasks

The workspace includes tasks to invoke the helper script from the editor: use the `Compile Verilog` or `Run Testbench` tasks from the Run/Debug or Tasks menus.

Notes

- The testbench generates `dump.vcd` in the repository root.
- `run_sim.sh` uses `bash` for reliable glob expansion and supports running a subset of testbenches by path or pattern.
- `gtkwave` must be installed and available in `PATH` to use the `--wave` option.

Files of interest

- `run_sim.sh` — Build and run helper script.
- `Makefile`    — Targets for build, run, CI, and waveform viewing.
- `.vscode/tasks.json` — Editor tasks for building and running testbenches.
- `.gitignore`  — Recommended ignores for build artifacts and editor files.

License

This project is provided as-is for educational purposes.



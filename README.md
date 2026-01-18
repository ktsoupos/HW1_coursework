# HW1 - Digital Design Coursework

This project implements fundamental digital design components in Verilog as part of a hardware design course. It includes an Arithmetic Logic Unit (ALU), a calculator with encoder, a register file, and a simple neural network accelerator with FSM control. Each module is accompanied by testbenches for verification.

## Quick Start

Build and run all testbenches:
```bash
./run_sim.sh
```

Run a specific testbench:
```bash
./run_sim.sh tb/alu/alu_tb.v
```

Run and open waveform in GTKWave:
```bash
./run_sim.sh --wave
```

## Script Flags

- `--wave`, `-w`  : Open `dump.vcd` in GTKWave after simulation
- `--no-run`, `-n`: Compile only, do not run simulation
- `--help`, `-h`  : Show usage information

## Makefile Targets

- `make` / `make build`    : Compile all sources
- `make run`               : Run testbenches
- `make run TB=<path>`     : Run specific testbench
- `make wave`              : Open waveform in GTKWave
- `make ci`                : CI-friendly run with log output

## Requirements

- Icarus Verilog (`iverilog`)
- GTKWave (optional, for waveform viewing)

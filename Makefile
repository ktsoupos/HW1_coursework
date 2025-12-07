WORKDIR := $(shell pwd)
VVP := $(WORKDIR)/sim/output.vvp
SRCS := $(wildcard src/*.v) $(wildcard src/*/*.v)
TBS  := $(wildcard tb/*.v) $(wildcard tb/*/*.v)

.PHONY: all build run wave clean

all: build

build:
	iverilog -o $(VVP) $(SRCS) $(TBS)

# Usage: make run            -> runs all TBs (uses ./run_sim.sh)
#        make run TB=alu/alu_tb.v
run:
	@if [ -z "$(TB)" ]; then \
		./run_sim.sh; \
	else \
		./run_sim.sh "$(TB)"; \
	fi

# Compile-only target useful for CI or pre-checks
compile-only:
	./run_sim.sh --no-run

# CI-friendly target: compile and run non-interactively (no GUI)
.PHONY: ci
ci: build
	@echo "Running CI simulation..."
	vvp $(VVP) > ci_simulation.log 2>&1 || (echo "Simulation failed - see ci_simulation.log" && exit 1)
	@echo "CI simulation completed; log at ci_simulation.log"

wave:
	gtkwave dump.vcd &

clean:
	rm -f sim/output.vvp dump.vcd

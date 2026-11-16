VERILATOR ?= verilator
SEED ?= 1
N_RANDOM ?= 100
SOURCES := $(wildcard rtl/*.sv tb/*.sv tb/*.svh) sim/files.f
.PHONY: all build test waves regression clean
all: test
build: build/obj/Vtb_uart
build/obj/Vtb_uart: $(SOURCES)
	mkdir -p build
	$(VERILATOR) --binary --timing --assert --trace -j 2 --top-module tb_uart --Mdir build/obj -f sim/files.f

test: build
	./build/obj/Vtb_uart +verilator+seed+$(SEED) +N_RANDOM=$(N_RANDOM)
waves: build
	./build/obj/Vtb_uart +verilator+seed+$(SEED) +N_RANDOM=$(N_RANDOM) +WAVES
regression: build
	@set -e; for seed in 1 7 42 2026; do ./build/obj/Vtb_uart +verilator+seed+$$seed +N_RANDOM=$(N_RANDOM); done
clean:
	rm -rf build

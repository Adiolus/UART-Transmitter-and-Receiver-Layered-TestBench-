VERILATOR ?= verilator
SEED ?= 1
N_RANDOM ?= 100
SOURCES := $(wildcard rtl/*.sv tb/*.sv tb/*.svh)
COMPILE_FILES := rtl/uart_tx.sv rtl/uart_rx.sv rtl/uart.sv tb/uart_if.sv tb/uart_pkg.sv tb/tb_uart.sv
.PHONY: all build test waves regression clean
all: test
build: build/obj/Vtb_uart
build/obj/Vtb_uart: $(SOURCES) Makefile
	mkdir -p build
	$(VERILATOR) --binary --timing --assert --trace -j 2 --top-module tb_uart --Mdir build/obj +incdir+tb $(COMPILE_FILES)

test: build
	./build/obj/Vtb_uart +verilator+seed+$(SEED) +N_RANDOM=$(N_RANDOM)
waves: build
	./build/obj/Vtb_uart +verilator+seed+$(SEED) +N_RANDOM=$(N_RANDOM) +WAVES
regression: build
	@set -e; for seed in 1 7 42 2026; do ./build/obj/Vtb_uart +verilator+seed+$$seed +N_RANDOM=$(N_RANDOM); done
clean:
	rm -rf build

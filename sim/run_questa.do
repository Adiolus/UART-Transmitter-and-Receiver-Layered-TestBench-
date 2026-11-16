onerror {quit -code 1 -force}
if {![file isdirectory build]} {file mkdir build}
vlib build/work
vmap work build/work
vlog -sv -f sim/files.f
vsim -c -sv_seed 1 work.tb_uart +N_RANDOM=100
run -all
quit -code 0 -force

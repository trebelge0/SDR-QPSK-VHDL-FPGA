onerror {quit -code 1}
source "/home/trebelge/Job/Project/Exo1/SDR-QPSK-VHDL-FPGA/vunit_out/test_output/lib.tb_nco.all_300321251a1b9b03e34a3920dec37763b3e66e6c/modelsim/common.do"
set failed [vunit_load]
if {$failed} {quit -code 1}
set failed [vunit_run]
if {$failed} {quit -code 1}
quit -code 0

onerror {quit -code 1}
source "/home/trebelge/Job/Project/Exo1/SDR-QPSK-VHDL-FPGA/vunit_out/test_output/lib.tb_buffer.all_b37411af0de26238fd21b26f078634bb512faaab/modelsim/common.do"
set failed [vunit_load]
if {$failed} {quit -code 1}
set failed [vunit_run]
if {$failed} {quit -code 1}
quit -code 0

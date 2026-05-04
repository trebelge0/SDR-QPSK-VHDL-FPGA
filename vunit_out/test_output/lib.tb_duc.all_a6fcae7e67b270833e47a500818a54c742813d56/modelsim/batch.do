onerror {quit -code 1}
source "/home/trebelge/Job/Project/Exo1/SDR-QPSK-VHDL-FPGA/vunit_out/test_output/lib.tb_duc.all_a6fcae7e67b270833e47a500818a54c742813d56/modelsim/common.do"
set failed [vunit_load]
if {$failed} {quit -code 1}
set failed [vunit_run]
if {$failed} {quit -code 1}
quit -code 0

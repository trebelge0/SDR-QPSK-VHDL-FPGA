onerror {quit -code 1}
source "/home/trebelge/Job/Project/Exo1/SDR-QPSK-VHDL-FPGA/vunit_out/test_output/lib.tb_tx.all_de55b5529bb67cc86988c3e4218c738df2fc4e68/modelsim/common.do"
set failed [vunit_load]
if {$failed} {quit -code 1}
set failed [vunit_run]
if {$failed} {quit -code 1}
quit -code 0

onerror {quit -code 1}
source "/home/trebelge/Job/Project/Exo1/SDR-QPSK-VHDL-FPGA/vunit_out/test_output/lib.tb_upsample.all_2509d55958628167b3477c8371a0894f32bfcb98/modelsim/common.do"
set failed [vunit_load]
if {$failed} {quit -code 1}
set failed [vunit_run]
if {$failed} {quit -code 1}
quit -code 0

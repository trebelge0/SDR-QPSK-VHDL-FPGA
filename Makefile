
# Romain Englebert May 2026

all: compile test sim

compile:
	vcom -2008 rtl/tx/buffer.vhd
	vcom -2008 rtl/tx/encoder.vhd
	vcom -2008 rtl/tx/upsample.vhd
	vcom -2008 rtl/tx/fir.vhd
	vcom -2008 rtl/tx/sine_pkg.vhd
	vcom -2008 rtl/tx/nco.vhd
	vcom -2008 rtl/tx/mixer.vhd
	vcom -2008 rtl/tx/duc.vhd
	vcom -2008 rtl/tx/top_tx.vhd
	vcom -2008 rtl/tb/tb_tx.vhd
	

sim:
	vsim -do run.do

test:
	python3 run_vunit.py

# Romain Englebert May 2026

# --- Configuration ---
# iqfir or out
RUN_NAME ?= out

all: test compile sim

test:
	python3 run_vunit.py

compile:
	vcom -2008 src/buffer.vhd
	vcom -2008 src/encoder.vhd
	vcom -2008 src/upsample.vhd
	vcom -2008 src/fir.vhd
	vcom -2008 src/sine_pkg.vhd
	vcom -2008 src/nco.vhd
	vcom -2008 src/mixer.vhd
	vcom -2008 src/duc.vhd
	vcom -2008 src/top_tx.vhd
	vcom -2008 tb/tb_tx.vhd

sim: compile
	vsim -do "set log_filename $(RUN_NAME)_data; do run.do"

cleaner: sim
	python3 scripts/$(RUN_NAME)_cleaner.py

fft: cleaner
	python3 scripts/$(RUN_NAME)_fft.py

rrc:
	python3 scripts/rrc_fir_generator.py
# FPGA Transmitter Project (VHDL/DSP)

## Table of Contents
1. [Introduction](#introduction)
2. [System Architecture](#system-architecture)
3. [Demonstration](#demonstration)
4. [Tests](#test)
5. [How to Run](#how-to-run)

## Introduction
This project focuses on the design and implementation of a digital transmitter on an FPGA with QPSKodulation.

The primary objective is to apply fundamental concepts of DSP and digital communication using VHDL with AXI Stream interfaces, in an automated testing environment (VUnit, Makefile, TCP scripts, Python scripts).

## System Architecture
The design is structured around the following modules:
* **Symbol Generator:** Maps input data to the required symbols.
* **Upsampler:** Insert zero-padding between samples.
* **FIR Filter (RRC):** Performs pulse shaping to limit spectral occupancy and reduce Inter-Symbol Interference (ISI).
* **Mixer:** Quadrature (I/Q) modulation for RF transmission.
* **Timing Control:** Manages valid/ready signals using AXI Stream interfaces.
* **TCL script:** Setup Modelsim, waves and their format then run the testbench.
* **VUnit tests:** Unit test for each entity separately, and for the entire system.

## Demonstration
The results below validate the functionality of the transmission chain:

**Figure 1: Constellation Analysis**

*The constellation shows distinct clusters, confirming correct mapping and filtering.*

**Figure 2: Eye Diagram**

*The eye opening validates noise margin and optimal sampling timing.*

**Figure 3: Signals**



## How to Run

### Prerequisites
* ModelSim (Simulation)
* Python 3.x (Scripts)

### Steps
1. Run 'make' to compile VHDL files, execute all VUnit tests, and shows the global testbench with Modelsim.
2. Execute the testbench `tb_transmitter.vhd`.
3. Export `I` and `Q` output data to a `.csv` file.
4. Use the analysis script to visualize the constellation:
   `python analyze.py --file data.csv`
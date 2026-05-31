
# Romain Englebert May 2026

from vunit import VUnit

ui = VUnit.from_argv()

lib = ui.add_library("lib")
lib.add_source_files("src/*.vhd")
lib.add_source_files("tb/tb*.vhd")

ui.main()
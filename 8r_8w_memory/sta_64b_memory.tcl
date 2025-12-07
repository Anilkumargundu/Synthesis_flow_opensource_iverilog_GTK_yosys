#read the liberty file from the skywater130 digital library. This file will be different for different device, condtions, and temps
read_liberty /home/anilk/whyRD_eda_bundle/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# read module from verilog file. Yosys loads the cell library files (usually .lib files) so that ABC knows: 
read_verilog synth_64b_memory.v

# Make 'REM_MEMORY' from 'synth_memory_width_depth.v' the current active design, connect everything properly, resolve all submodules, and check that all modules in the hierarchy are found.
link_design b64_memory

#Read the timing constraints written in SDC (Synopsys Design Constraints) format and apply them to the design
read_sdc synth_64b_memory.sdc

#Description of the command
#report_checks : Report all timing constraint checks (setup/hold, input/output delays, clock edges, etc.).
#-path_delay max : Check worst-case (slow corner) delays to ensure setup time is not violated.
#-format full : Show EVERYTHING in the report — full details, not summary
report_checks -path_delay max -format full
report_checks -path_delay min -format full


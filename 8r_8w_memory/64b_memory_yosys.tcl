#read the liberty file from the skywater130 digital library. This file will be different for different device, condtions, and temps
read_liberty -lib /home/anilk/whyRD_eda_bundle/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# read module from verilog file
read_verilog 64b_memory.v

#elaborate design hierarchy. Here this shoul be module name in the .v file that written above
hierarchy -check -top b64_memory

# translate process to netlist
proc

#since I am generating SRAM, some internals are still defined as reg even after synthesis, so the tool have to tell yosys to replace them to DFFs.

# memory : Detects behavioral RAM (reg array) and converts it into Yosys $mem primitives
memory

# memory_dff : Converts $mem into DFFs ($dff, $dffe) because Sky130 has no real SRAM cells
memory_dff

#memory_map : Builds decoders, muxes, write enables from $memwr, $memrd (Creates real logic gates OpenSTA can understand)
memory_map

#remove unused cells and wires
clean

opt

share -aggressive

# mappring to internal cell library
techmap

# mapping the digital cells to sky130_fd_sc_hd__tt_025C_1v80.lib
dfflibmap -liberty /home/anilk/whyRD_eda_bundle/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

#mapping logic to sky130_fd_sc_hd__tt_025C_1v80.lib
abc -liberty /home/anilk/whyRD_eda_bundle/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

#remove unused cells and wires
clean

stat -liberty /home/anilk/whyRD_eda_bundle/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

#write the current design to a verilog file : preserves RTL names and removes unnecessary Yosys attributes
write_verilog -noattr synth_64b_memory.v
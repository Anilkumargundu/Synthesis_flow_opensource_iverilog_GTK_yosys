# gcd flow pipe cleaner
source "/home/anilk/OpenROAD/test/helpers.tcl"
source "/home/anilk/OpenROAD/test/flow_helpers.tcl"
source "/home/anilk/OpenROAD/test/sky130hd/sky130hd.vars"

#Please change this path according to your working directory. this path is used in the .tcl script of the floorplan , routing, cts to save file. 
set BASE_PATH "/home/anilk/VERILOG/MEMORY_CUTS/8r_8w_memory/64b_RTL_GDS"


#name of your design which is there in the synthesized verilog code after yosys (synthesizing)
set design "b64_memory"


#name of the top module in you design which is there in the synthesized verilog code after yosys (synthesizing)
set top_module "b64_memory"


#synthesized verilog file after yosys (synthesizing)
set synth_verilog "./synth_64b_memory.v"

#constraint file we write
set sdc_file "./synth_64b_memory.sdc"
#specifies die area and core area
set die_area {0 0 150 100}
set core_area {10.0 11.2 140 90}

source "openroad_64b_memory.tcl"
# source -echo "flow_global.tcl"
# source -echo "flow_global_placement.tcl"
# source -echo "flow_detailed_placement.tcl"

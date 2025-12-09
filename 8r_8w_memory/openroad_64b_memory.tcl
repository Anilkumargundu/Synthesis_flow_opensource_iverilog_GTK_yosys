## Assumes flow_helpers.tcl has been read before this script
# path of origial techfile /home/anilk/whyRD_eda_bundle/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
# path of origial techlef /home/anilk/whyRD_eda_bundle/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
# path of origial lib /home/anilk/whyRD_eda_bundle/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# path of origial ff lib /home/anilk/whyRD_eda_bundle/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ff_100C_1v95.lib
# path of origial ss lib /home/anilk/whyRD_eda_bundle/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_n40C_1v35.lib

# ---------------------------------------------------------
# Step 1: Read design files and link design
read_libraries                ;# Load the standard cell libraries
read_verilog $synth_verilog   ;# Read synthesized Verilog design
link_design $top_module       ;# Link design to create a full hierarchy
read_sdc $sdc_file            ;# Read SDC constraints (timing, clocks, etc.)

# ---------------------------------------------------------
# Step 2: Collect design metrics (optional)
#util::metric "IPP::ord_version" [ord::openroad_gif_describe]
# Note: stm:network_instance_count metric is invalid after tapcell insertion
#util::metric "IPP::instance_count" [sta::network_instance_count]

# ---------------------------------------------------------
# Step 3: Initialize floorplan
initialize_floorplan -site $site \
                     -die_area $die_area \
                     -core_area $core_area

write_def "$BASE_PATH/post_floorplan.def"
source $tracks_file

# ---------------------------------------------------------
# Step 4: Remove buffers inserted by synthesis
remove_buffers

# ---------------------------------------------------------
# Step 5: IO Placement (randomized)
place_pins -random -hor_layer $io_placer_hor_layer -ver_layers $io_placer_ver_layer

# ---------------------------------------------------------
# Step 6: Macro Placement & Performs global placement of all standard cells, spreading them across the core with the target density you set
if { [have_macros] } {
    global_placement -density $global_place_density
    macro_placement -halo $macro_place_halo -channel $macro_place_channel
}

write_def "$BASE_PATH/post_macro_placement.def"

# ---------------------------------------------------------
# Step 7: Tapcell insertion
eval tapcell $tapcell_args
write_def "$BASE_PATH/post_tapcell.def"

# Step 8: power distribution network insertion
#-----power distribution network insertion------------
#-----pdn_cfg file is again defined in the sky_var_bkp.vars-------- #-----------  these all subblocks you can get from flow.tcl

#addedby Anil
#set ::env(USE_POWER_PINS) 1
#set ::env(FP_PDN_CHECK_NODES) 0
#addedby Anil

source $pdn_cfg
pdngen

write_def "$BASE_PATH/post_pdn.def"

# Step 9: # Global placement : 
#-----------  these all subblocks you can get from flow.tcl

foreach layer_adjustment $global_routing_layer_adjustments {
  lassign $layer_adjustment layer adjustment
  set_global_routing_layer_adjustment $layer $adjustment
}
set_routing_layers -signal $global_routing_layers \
  -clock $global_routing_clock_layers
set_macro_extension 2

# Global placement skip IOs -pad_left $global_place_pad and -pad_right $global_place_pad Adds extra spacing (padding) on the left and right sides of every cell
global_placement -density $global_place_density \
  -pad_left $global_place_pad -pad_right $global_place_pad -skip_io


# IO Placement
place_pins -hor_layers $io_placer_hor_layer -ver_layers $io_placer_ver_layer -group_pins {clk rst we} \
  -group_pins {addr[0] addr[1] addr[2]} \
  -group_pins {wrdata[0] wrdata[1] wrdata[2] wrdata[3] wrdata[4] wrdata[5] wrdata[6] wrdata[7]} \
  -group_pins {rddata[0] rddata[1] rddata[2] rddata[3] rddata[4] rddata[5] rddata[6] rddata[7]} \
  -min_distance 5

# Global placement with placed IOs and routability-driven
global_placement -routability_driven -density $global_place_density \
  -pad_left $global_place_pad -pad_right $global_place_pad
global_connect
# checkpoint
set global_place_db [make_result_file ${design}_${platform}_global_place.db]
write_def "$BASE_PATH/global_place.def"
write_db "$BASE_PATH/global_place_db"


#addedbyme : Replacing some cells to fix slew violations, need to add before routing and after placement (better option)
replace_cell _255_ sky130_fd_sc_hd__nor4_2
replace_cell _256_ sky130_fd_sc_hd__nor4_2
replace_cell _257_ sky130_fd_sc_hd__nor4_2
#addedbyme

# Step 10: 
#-----------  these all subblocks you can get from flow.tcl
# Global placement Repair max slew/cap/fanout violations and normalize slews

source $layer_rc_file
set_wire_rc -signal -layer $wire_rc_layer
set_wire_rc -clock -layer $wire_rc_layer_clk
set_dont_use $dont_use

estimate_parasitics -placement

# edit by me
set_max_transition 0.25 [current_design]
set_max_capacitance 0.20 [current_design]
set_max_fanout 32 [current_design]
#edit by me

#edit the $slew_margin and $cap_margin in flow_helpers.tcl
repair_design -slew_margin $slew_margin -cap_margin $cap_margin
repair_design -slew_margin 0.05 -cap_margin 0.05

#editedbyAnil
repair_design
repair_design

#editedbyAnil

repair_tie_fanout -separation $tie_separation $tielo_port
repair_tie_fanout -separation $tie_separation $tiehi_port


# Step 9: setting placement pads to leave room for routing
#-----------  these all subblocks you can get from flow.tcl
set_placement_padding -global -left $detail_place_pad -right $detail_place_pad
detailed_placement


# post resize timing report (ideal clocks)
report_worst_slack -min -digits 3
report_worst_slack -max -digits 3
report_tns -digits 3
# Check slew repair
report_check_types -max_slew -max_capacitance -max_fanout -violators

utl::metric "RSZ::repair_design_buffer_count" [rsz::repair_design_buffer_count]
utl::metric "RSZ::max_slew_slack" [expr [sta::max_slew_check_slack_limit] * 100]
utl::metric "RSZ::max_fanout_slack" [expr [sta::max_fanout_check_slack_limit] * 100]
utl::metric "RSZ::max_capacitance_slack" [expr [sta::max_capacitance_check_slack_limit] * 100]


################################################################
# Clock Tree Synthesis

# Clone clock tree inverters next to register loads
# so cts does not try to buffer the inverted clocks.
repair_clock_inverters

clock_tree_synthesis -root_buf $cts_buffer -buf_list $cts_buffer \
  -sink_clustering_enable \
  -sink_clustering_max_diameter $cts_cluster_diameter

# CTS leaves a long wire from the pad to the clock tree root.
repair_clock_nets

# place clock buffers
detailed_placement

#Anil
#cts
#Anil

# checkpoint
set cts_db [make_result_file ${design}_${platform}_cts.db]
write_db "$BASE_PATH/cts_db"


################################################################
# Setup/hold timing repair

set_propagated_clock [all_clocks]

# Global routing is fast enough for the flow regressions.
# It is NOT FAST ENOUGH FOR PRODUCTION USE.
set repair_timing_use_grt_parasitics 0
if { $repair_timing_use_grt_parasitics } {
  # Global route for parasitics - no guide file requied
  global_route -congestion_iterations 100
  estimate_parasitics -global_routing
} else {
  estimate_parasitics -placement
}

repair_timing -skip_gate_cloning
#repair_timing

# Post timing repair.
report_worst_slack -min -digits 3
report_worst_slack -max -digits 3
report_tns -digits 3
report_check_types -max_slew -max_capacitance -max_fanout -violators -digits 3


##addedbyAnil

##addedbyAnil

utl::metric "RSZ::worst_slack_min" [sta::worst_slack -min]
utl::metric "RSZ::worst_slack_max" [sta::worst_slack -max]
utl::metric "RSZ::tns_max" [sta::total_negative_slack -max]
utl::metric "RSZ::hold_buffer_count" [rsz::hold_buffer_count]

################################################################
# Detailed Placement

detailed_placement

# Capture utilization before fillers make it 100%
utl::metric "DPL::utilization" [format %.1f [expr [rsz::utilization] * 100]]
utl::metric "DPL::design_area" [sta::format_area [rsz::design_area] 0]

# checkpoint
set dpl_db [make_result_file ${design}_${platform}_dpl.db]
write_db "$BASE_PATH/dpl_db"

set verilog_file [make_result_file ${design}_${platform}.v]
write_verilog "$BASE_PATH/verilog_file"



################################################################
# Global routing

pin_access

set route_guide [make_result_file ${design}_${platform}.route_guide]
global_route -guide_file $route_guide \
  -congestion_iterations 100 -verbose

set verilog_file [make_result_file ${design}_${platform}.v]
write_verilog -remove_cells $filler_cells "$BASE_PATH/verilog_file"

################################################################
# Repair antennas post-GRT

utl::set_metrics_stage "grt__{}"
repair_antennas -iterations 5

check_antennas
utl::clear_metrics_stage
utl::metric "GRT::ANT::errors" [ant::antenna_violation_count]

################################################################
# Detailed routing

# Run pin access again after inserting diodes and moving cells
pin_access

detailed_route -output_drc [make_result_file "${design}_${platform}_route_drc.rpt"] \
  -output_maze [make_result_file "${design}_${platform}_maze.log"] \
  -no_pin_access \
  -verbose 0

write_guides [make_result_file "${design}_${platform}_output_guide.mod"]
set drv_count [detailed_route_num_drvs]
utl::metric "DRT::drv" $drv_count

set routed_db [make_result_file ${design}_${platform}_route.db]
write_db "$BASE_PATH/routed_db"

set routed_def [make_result_file ${design}_${platform}_route.def]
write_def "$BASE_PATH/routed_def"

################################################################
# Repair antennas post-DRT

set repair_antennas_iters 0
utl::set_metrics_stage "drt__repair_antennas__pre_repair__{}"
while { [check_antennas] && $repair_antennas_iters < 5 } {
  utl::set_metrics_stage "drt__repair_antennas__iter_${repair_antennas_iters}__{}"

  repair_antennas

  detailed_route -output_drc [make_result_file "${design}_${platform}_ant_fix_drc.rpt"] \
    -output_maze [make_result_file "${design}_${platform}_ant_fix_maze.log"] \
    -verbose 0

  incr repair_antennas_iters
}

utl::set_metrics_stage "drt__{}"
check_antennas

utl::clear_metrics_stage
utl::metric "DRT::ANT::errors" [ant::antenna_violation_count]

if { ![design_is_routed] } {
  error "Design has unrouted nets."
}

set repair_antennas_db [make_result_file ${design}_${platform}_repaired_route.odb]
write_db "$BASE_PATH/repair_antennas_db"

################################################################
# Filler placement

filler_placement $filler_cells
check_placement -verbose

# gets pins
get_pins

# checkpoint
set fill_db [make_result_file ${design}_${platform}_fill.db]
write_db "$BASE_PATH/fill_db"

################################################################
# Extraction

if { $rcx_rules_file != "" } {
  define_process_corner -ext_model_index 0 X
  extract_parasitics -ext_model_file $rcx_rules_file

  set spef_file [make_result_file ${design}_${platform}.spef]
  write_spef "$BASE_PATH/spef_file"

  read_spef "$BASE_PATH/spef_file"
} else {
  # Use global routing based parasitics inlieu of rc extraction
  estimate_parasitics -global_routing
}

################################################################
# Final Report

report_checks -path_delay min_max -format full_clock_expanded \
  -fields {input_pin slew capacitance} -digits 3
report_worst_slack -min -digits 3
report_worst_slack -max -digits 3
report_tns -digits 3
report_check_types -max_slew -max_capacitance -max_fanout -violators -digits 3
report_clock_skew -digits 3
report_power -corner $power_corner

###added by me for extra checks
#resize_cell _294_/A2 2x
##added by me

report_floating_nets -verbose
report_design_area

utl::metric "DRT::worst_slack_min" [sta::worst_slack -min]
utl::metric "DRT::worst_slack_max" [sta::worst_slack -max]
utl::metric "DRT::tns_max" [sta::total_negative_slack -max]
utl::metric "DRT::clock_skew" [expr abs([sta::worst_clock_skew -setup])]

# slew/cap/fanout slack/limit
utl::metric "DRT::max_slew_slack" [expr [sta::max_slew_check_slack_limit] * 100]
utl::metric "DRT::max_fanout_slack" [expr [sta::max_fanout_check_slack_limit] * 100]
utl::metric "DRT::max_capacitance_slack" [expr [sta::max_capacitance_check_slack_limit] * 100]
# report clock period as a metric for updating limits
utl::metric "DRT::clock_period" [get_property [lindex [all_clocks] 0] period]

# not really useful without pad locations
#set_pdnsim_net_voltage -net $vdd_net_name -voltage $vdd_voltage
#analyze_power_grid -net $vdd_net_name
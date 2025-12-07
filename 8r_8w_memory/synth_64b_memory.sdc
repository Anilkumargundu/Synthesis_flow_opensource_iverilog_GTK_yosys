#current_design bisr (this can be explicitlye defined or not our wish)
#define the primary clock  source in the design, here the units are in ns as defined in the .lib file of skywater
create_clock -name CLK -period 10 [get_ports clk]

#add 0.05 ns (50 ps) uncertainty to CLK
set_clock_uncertainty 0.08 [get_clocks CLK]

#specifies the slew (rise/fall transition time) of the incoming clock signal at the source before STA starts propagating it through the design
set_clock_transition -rise 0.08 [get_clocks CLK]
set_clock_transition -fall 0.08 [get_clocks CLK]


#set input delay wrt clock
set_input_delay 0.08 -clock CLK [get_ports wrdata]

#set output delay wrt clock
set_output_delay 0.08 -clock CLK [get_ports rddata]
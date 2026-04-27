
#---------------------------------------------------------
# Specify a CLK_PER ns clock period with 50% duty cycle and 50ps
# skew. Increasing clock skew makes the tools work harder meet setup
# and hold time requirements.
#---------------------------------------------------------
set CLK_PER  5.0
set CLK_SKEW 0.05
create_clock -name $CLK_NAME -period $CLK_PER -waveform "0 [expr $CLK_PER / 2.0]" $CLK_NAME
set_clock_uncertainty $CLK_SKEW $CLK_NAME

#---------------------------------------------------------
# ASSUME combinational inputs change IP_DELAY after clock edge. Real
# analysis would be conservative based on the path to the inputs.
#---------------------------------------------------------
set ip_delay 0.100
set_input_delay $ip_delay -clock $CLK_NAME [remove_from_collection [all_inputs] $CLK_NAME]

#---------------------------------------------------------
# ASSUME outputs need to be ready at module outputs OP_DELAY before the
# clock edge so that they will satisfy timing requirements at the end of
# their path in another module.
#---------------------------------------------------------
set op_delay 0.400
set_output_delay $op_delay -clock $CLK_NAME [all_outputs]
#
#---------------------------------------------------------	
# ASSUME modules inputs are driven by D-flip-flops. DC uses this to
# know how much the delay will change if loading the input.
#---------------------------------------------------------
set dr_cell_name DFFR_X1
set dr_cell_pin  Q
set_driving_cell -lib_cell $dr_cell_name -pin $dr_cell_pin [remove_from_collection [all_inputs] $CLK_NAME]
#
#---------------------------------------------------------
# ASSUME the worst case load for each output is 1 D-flip-flop (D-inputs)
# and an additional amount of capacitance from wiring
#---------------------------------------------------------
set port_load_cell  NangateOpenCellLibrary/DFFR_X1/D 
set wire_load_est   0.000
set fanout          300
set port_load [expr $wire_load_est + $fanout * [load_of $port_load_cell]]
set_load $port_load [all_outputs]
#
#---------------------------------------------------------
# set the GOALS for the compile. If you want to minimize area, set
# the goal for maximum area to be 0
#---------------------------------------------------------
set_max_area 0

set_ungroup [get_designs *] false
set_fix_multiple_port_nets -all -buffer_constants [get_designs]
replace_synthetic -ungroup
#set_fix_hold [get_clocks clk]

#---------------------------------------------------------
# Check whether the design is capable of being compiled, and issue
# warnings are errors in case of any problems.
# "dc_shell> man check_design" for more information.
#---------------------------------------------------------
check_design

link

#---------------------------------------------------------
# Write the delay constraints as a Synopsys Delay Constraint
# (.sdc) file. This is used as in input in the PnR stage. 
#--------------------------------------------------------
write_sdc $PNR_DIR/constraints_$NETLIST_NAME.sdc


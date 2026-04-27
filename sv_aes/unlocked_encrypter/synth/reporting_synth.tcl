set_fix_multiple_port_nets -all -buffer_constants
#set_app_var verilogout_no_tri true
#set_app_var verilogout_show_unconnected_pins true

# run timing checks before reporting
check_timing

# write out reports so that you can read them after synthesis
report_timing -delay_type max > $RPT_DIR/timing_max_$NETLIST_NAME.rpt
report_timing -delay_type min > $RPT_DIR/timing_min_$NETLIST_NAME.rpt
report_cell                   > $RPT_DIR/cell_report_$NETLIST_NAME.rpt
# [generate additional reports here, e.g. for power]
report_power > $RPT_DIR/power_$NETLIST_NAME.rpt

change_names -rules verilog -hierarchy

# write out the post-synthesis netlist
#write_file -hierarchy -f verilog -o $RPT_DIR/$NETLIST_NAME.v

# write out the post-synthesis netlist in the pnr directory
write_file -hierarchy -f verilog -o $PNR_DIR/$NETLIST_NAME.v

# write out to rtl directory
write_file -hierarchy -f verilog -o ../rtl/$NETLIST_NAME.v
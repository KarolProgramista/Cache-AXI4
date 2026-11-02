# Target standard Artix-7 or Zynq device
create_project -in_memory -part xc7a35tcpg236-1

# Read RTL sources
read_verilog -sv [glob rtl/*.sv]
read_xdc constraints.xdc

# Run Synthesis on the top RTL module
synth_design -top cache -part xc7a35tcpg236-1

# Create output directory and export reports
file mkdir reports
report_utilization -file reports/utilization.rpt
report_timing_summary -file reports/timing.rpt

# Export netlist for gate-level simulation
file mkdir netlist
write_verilog -force netlist/cache_synth_netlist.v

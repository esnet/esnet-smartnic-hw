report_timing_summary -max_paths 10 -report_unconstrained -file report_timing_summary_route_opt.rpt

report_utilization -file report_utilization_route_opt.rpt
report_utilization -hierarchical -file report_utilization_hier_route_opt.rpt

puts "Wrote route_opt reports."

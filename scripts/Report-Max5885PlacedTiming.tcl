set root_dir [file normalize [file join [file dirname [info script]] ..]]
set dcp [file join $root_dir build vivado_ltc2208 base_add_overlay.runs impl_1 system_wrapper_placed.dcp]
set report [file join $root_dir build max5885_placed_timing.rpt]

open_checkpoint $dcp
report_timing_summary -delay_type max -max_paths 10 -file $report
report_timing -delay_type max -max_paths 5 -path_type full -file $report -append
close_design
exit

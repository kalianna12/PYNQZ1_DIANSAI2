set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ..]]
set project_name base_add_overlay
set design_name system
set part_name xc7z020clg400-1
set board_part www.digilentinc.com:pynq-z1:part0:1.0

set build_dir [file join $root_dir build vivado]
set pynq_dir [file join $root_dir pynq]
set board_repo_dir [file join $root_dir board_files]
set external_board_repo_dir [file normalize "G:/FIREFOX下载/pynq-z1"]

set rtl_src [list \
    [file join $root_dir rtl src led_ctrl_axi.v] \
    [file join $root_dir rtl src sine_lut_1024.v] \
    [file join $root_dir rtl src ad9767_signal_axi.v] \
    [file join $root_dir rtl src max5885_signal_axi.v] \
]
set sine_mem [file join $root_dir rtl src sine_lut_1024x14.mem]
set board_io_xdc [file join $root_dir constraints lemon_pynqz1_board_io.xdc]
set max5885_xdc [file join $root_dir constraints lemon_pynqz1_max5885.xdc]

file mkdir $build_dir
file mkdir $pynq_dir

set board_repo_paths [list]
if {[file exists $external_board_repo_dir]} {
    lappend board_repo_paths $external_board_repo_dir
}
if {[file exists $board_repo_dir]} {
    lappend board_repo_paths $board_repo_dir
}
if {[llength $board_repo_paths] != 0} {
    set_param board.repoPaths $board_repo_paths
}

create_project -force $project_name $build_dir -part $part_name
if {[llength [get_board_parts -quiet $board_part]] != 0} {
    set_property board_part $board_part [current_project]
} else {
    puts "WARNING: board_part not found, using part only: $board_part"
}

add_files -norecurse $rtl_src
if {[file exists $sine_mem]} {
    add_files -fileset sources_1 -norecurse $sine_mem
}
add_files -fileset constrs_1 -norecurse $board_io_xdc
add_files -fileset constrs_1 -norecurse $max5885_xdc
update_ip_catalog

create_bd_design $design_name

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
set_property -dict [list \
    CONFIG.PCW_EN_CLK0_PORT {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {125.000000} \
] [get_bd_cells processing_system7_0]

apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR"} \
    [get_bd_cells processing_system7_0]

create_bd_cell -type module -reference led_ctrl_axi led_ctrl_0
create_bd_cell -type module -reference max5885_signal_axi max5885_ctrl_0

create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 dac_clk_wiz_0
set_property -dict [list \
    CONFIG.PRIM_IN_FREQ {125.000} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.NUM_OUT_CLKS {1} \
    CONFIG.USE_RESET {false} \
] [get_bd_cells dac_clk_wiz_0]

foreach axi_target {
    led_ctrl_0/S_AXI
    max5885_ctrl_0/S_AXI
} {
    set axi_pin [get_bd_intf_pins -quiet $axi_target]
    if {[llength $axi_pin] == 0} {
        puts "ERROR: Could not find AXI-Lite interface $axi_target"
        exit 1
    }
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto"} \
        $axi_pin
}

foreach led_pin_name {
    leds_4bits_tri_o
    rgb_leds_6bits_tri_o
    btns_4bits_tri_i
} {
    make_bd_pins_external [get_bd_pins led_ctrl_0/$led_pin_name]
}

foreach ext_pair {
    {leds_4bits_tri_o_0 leds_4bits_tri_o}
    {rgb_leds_6bits_tri_o_0 rgb_leds_6bits_tri_o}
    {btns_4bits_tri_i_0 btns_4bits_tri_i}
} {
    set old_name [lindex $ext_pair 0]
    set new_name [lindex $ext_pair 1]
    set bd_port [get_bd_ports -quiet $old_name]
    if {[llength $bd_port] != 0} {
        set_property name $new_name $bd_port
    }
}

foreach max5885_pin_name {
    dac_a_data
    dac_a_clk
    dac_b_data
    dac_b_clk
} {
    make_bd_pins_external [get_bd_pins max5885_ctrl_0/$max5885_pin_name]
    set generated_port [get_bd_ports -quiet "${max5885_pin_name}_0"]
    if {[llength $generated_port] != 0} {
        set_property name $max5885_pin_name $generated_port
    }
}

set fclk0_pin [get_bd_pins -quiet processing_system7_0/FCLK_CLK0]
if {[llength $fclk0_pin] == 0} {
    puts "ERROR: Could not find processing_system7_0/FCLK_CLK0"
    exit 1
}

foreach clk_target {
    led_ctrl_0/S_AXI_ACLK
    max5885_ctrl_0/S_AXI_ACLK
} {
    set clk_pin [get_bd_pins -quiet $clk_target]
    if {[llength $clk_pin] != 0 && [llength [get_bd_nets -quiet -of_objects $clk_pin]] == 0} {
        connect_bd_net $fclk0_pin $clk_pin
    }
}

connect_bd_net $fclk0_pin [get_bd_pins dac_clk_wiz_0/clk_in1]
connect_bd_net [get_bd_pins dac_clk_wiz_0/clk_out1] [get_bd_pins max5885_ctrl_0/dac_clk]

set resetn_pin [get_bd_pins -quiet -hier -filter {NAME == peripheral_aresetn && DIR == O}]
if {[llength $resetn_pin] == 0} {
    puts "ERROR: Could not find processor system reset peripheral_aresetn"
    exit 1
}
set resetn_pin [lindex $resetn_pin 0]

foreach rst_target {
    led_ctrl_0/S_AXI_ARESETN
    max5885_ctrl_0/S_AXI_ARESETN
    max5885_ctrl_0/dac_resetn
} {
    set rst_pin [get_bd_pins -quiet $rst_target]
    if {[llength $rst_pin] != 0 && [llength [get_bd_nets -quiet -of_objects $rst_pin]] == 0} {
        connect_bd_net $resetn_pin $rst_pin
    }
}

assign_bd_address
validate_bd_design
save_bd_design

set bd_file [get_files "$build_dir/$project_name.srcs/sources_1/bd/$design_name/$design_name.bd"]
generate_target all $bd_file

set wrapper_file [make_wrapper -files $bd_file -top]
add_files -norecurse $wrapper_file
update_compile_order -fileset sources_1
set_property top ${design_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

# Use a short implementation pass while closing the 200 MHz architecture.
# Once WNS is near zero, the final build can switch these back to Explore.
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE Default [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Default [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Default [get_runs impl_1]

launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: synth_1 did not finish"
    exit 1
}

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: impl_1 did not finish"
    exit 1
}

open_run impl_1
set wns [get_property SLACK [get_timing_paths -delay_type max -max_paths 1]]
if {$wns < 0} {
    puts "ERROR: Negative WNS after implementation: $wns ns"
    exit 1
}

set bit_file [file join $build_dir "$project_name.runs" impl_1 "${design_name}_wrapper.bit"]
set hwh_file [file join $build_dir "$project_name.gen" sources_1 bd $design_name hw_handoff "${design_name}.hwh"]
set hwh_file_alt [file join $build_dir "$project_name.srcs" sources_1 bd $design_name hw_handoff "${design_name}.hwh"]

if {[file exists $bit_file]} {
    file copy -force $bit_file [file join $pynq_dir base_add.bit]
    puts "Copied bitstream to [file join $pynq_dir base_add.bit]"
} else {
    puts "ERROR: Bitstream not found: $bit_file"
    exit 1
}

if {[file exists $hwh_file]} {
    file copy -force $hwh_file [file join $pynq_dir base_add.hwh]
    puts "Copied handoff to [file join $pynq_dir base_add.hwh]"
} elseif {[file exists $hwh_file_alt]} {
    file copy -force $hwh_file_alt [file join $pynq_dir base_add.hwh]
    puts "Copied handoff to [file join $pynq_dir base_add.hwh]"
} else {
    puts "ERROR: HWH not found"
    exit 1
}

exit

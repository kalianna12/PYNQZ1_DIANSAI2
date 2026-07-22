vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv "+incdir+../../../../ltc2208_max5885.gen/sources_1/ip/vio_0/hdl/verilog" "+incdir+../../../../ltc2208_max5885.gen/sources_1/ip/vio_0/hdl" \
"F:/Xilix/Vivado/Vivado/2023.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"F:/Xilix/Vivado/Vivado/2023.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93  \
"F:/Xilix/Vivado/Vivado/2023.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../ltc2208_max5885.gen/sources_1/ip/vio_0/hdl/verilog" "+incdir+../../../../ltc2208_max5885.gen/sources_1/ip/vio_0/hdl" \
"../../../../ltc2208_max5885.gen/sources_1/ip/vio_0/sim/vio_0.v" \

vlog -work xil_defaultlib \
"glbl.v"


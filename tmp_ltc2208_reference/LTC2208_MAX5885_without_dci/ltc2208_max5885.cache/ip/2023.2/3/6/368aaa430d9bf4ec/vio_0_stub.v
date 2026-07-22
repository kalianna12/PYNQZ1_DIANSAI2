// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
// Date        : Wed Mar 26 17:17:52 2025
// Host        : AYJT running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ vio_0_stub.v
// Design      : vio_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "vio,Vivado 2023.2" *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix(clk, probe_out0, probe_out1, probe_out2, 
  probe_out3, probe_out4, probe_out5, probe_out6, probe_out7, probe_out8, probe_out9)
/* synthesis syn_black_box black_box_pad_pin="probe_out0[47:0],probe_out1[31:0],probe_out2[15:0],probe_out3[3:0],probe_out4[47:0],probe_out5[47:0],probe_out6[47:0],probe_out7[31:0],probe_out8[0:0],probe_out9[0:0]" */
/* synthesis syn_force_seq_prim="clk" */;
  input clk /* synthesis syn_isclock = 1 */;
  output [47:0]probe_out0;
  output [31:0]probe_out1;
  output [15:0]probe_out2;
  output [3:0]probe_out3;
  output [47:0]probe_out4;
  output [47:0]probe_out5;
  output [47:0]probe_out6;
  output [31:0]probe_out7;
  output [0:0]probe_out8;
  output [0:0]probe_out9;
endmodule

`timescale 1 ns / 1 ps

// MAX5885 physical wrapper.
//
// The waveform core runs entirely in the 200 MHz DAC domain.  MAX5885 needs
// two 16-bit buses; the retained 14-bit fixed-point waveform format is aligned
// to the DAC MSBs, leaving the two LSBs zero.  This preserves numerical scaling
// from the proven C-problem control path while avoiding any combinational logic
// between its final register and the FPGA IO cells.
module max5885_signal_axi #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 7
) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 S_AXI_ACLK CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET S_AXI_ARESETN, FREQ_HZ 125000000" *)
    input wire S_AXI_ACLK,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 S_AXI_ARESETN RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input wire S_AXI_ARESETN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire [2:0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,
    output wire [1:0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire S_AXI_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire [2:0] S_AXI_ARPROT,
    input wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input wire S_AXI_RREADY,

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 dac_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 200000000" *)
    input wire dac_clk,
    input wire dac_resetn,

    output wire [15:0] dac_a_data,
    output wire dac_a_clk,
    output wire [15:0] dac_b_data,
    output wire dac_b_clk
);
    wire [13:0] dac_a_code14;
    wire [13:0] dac_b_code14;
    wire unused_a_wrt;
    wire unused_b_wrt;
    (* ASYNC_REG = "TRUE" *) reg [1:0] dac_reset_sync;
    wire dac_resetn_sync = dac_reset_sync[1];

    // The PS reset is asynchronous to the 200 MHz clock.  Assert immediately
    // and release only after two DAC-clock edges before entering the core.
    always @(posedge dac_clk or negedge dac_resetn) begin
        if (!dac_resetn)
            dac_reset_sync <= 2'b00;
        else
            dac_reset_sync <= {dac_reset_sync[0], 1'b1};
    end

    max5885_wave_core #(
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) u_wave_core (
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWPROT(S_AXI_AWPROT),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARPROT(S_AXI_ARPROT),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY),
        .dac_clk(dac_clk),
        .dac_resetn(dac_resetn_sync),
        .dac_a_data(dac_a_code14),
        .dac_a_clk(dac_a_clk),
        .dac_a_wrt(unused_a_wrt),
        .dac_b_data(dac_b_code14),
        .dac_b_clk(dac_b_clk),
        .dac_b_wrt(unused_b_wrt)
    );

    // The data register is clocked on the opposite edge from the forwarded
    // clock.  IOB placement prevents extra fabric routing at the DAC boundary.
    (* IOB = "TRUE" *) reg [15:0] dac_a_data_iob;
    (* IOB = "TRUE" *) reg [15:0] dac_b_data_iob;
    assign dac_a_data = dac_a_data_iob;
    assign dac_b_data = dac_b_data_iob;
    always @(negedge dac_clk) begin
        dac_a_data_iob <= {dac_a_code14, 2'b00};
        dac_b_data_iob <= {dac_b_code14, 2'b00};
    end
endmodule

`timescale 1 ns / 1 ps

// Shared 200 MSPS waveform core for the MAX5885 wrapper.  The AXI contract is
// deliberately kept compatible with the former AD9767 helper while the
// physical wrapper expands its samples to the MAX5885 16-bit interface.
module max5885_wave_core #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 7
) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 S_AXI_ACLK CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET S_AXI_ARESETN" *)
    input wire S_AXI_ACLK,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 S_AXI_ARESETN RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input wire S_AXI_ARESETN,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire [2:0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output reg S_AXI_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output reg S_AXI_WREADY,
    output reg [1:0] S_AXI_BRESP,
    output reg S_AXI_BVALID,
    input wire S_AXI_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire [2:0] S_AXI_ARPROT,
    input wire S_AXI_ARVALID,
    output reg S_AXI_ARREADY,
    output reg [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg [1:0] S_AXI_RRESP,
    output reg S_AXI_RVALID,
    input wire S_AXI_RREADY,

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 dac_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET dac_resetn, FREQ_HZ 200000000" *)
    input wire dac_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 dac_resetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input wire dac_resetn,

    output wire [13:0] dac_a_data,
    output wire        dac_a_clk,
    output wire        dac_a_wrt,
    output wire [13:0] dac_b_data,
    output wire        dac_b_clk,
    output wire        dac_b_wrt
);
    localparam integer ADDR_LSB = 2;
    localparam integer REG_INDEX_BITS = 5;

    localparam [31:0] VERSION_VALUE = 32'h4D353802;          // "M58" revision 2
    localparam [31:0] SAMPLE_RATE_HZ = 32'd200000000;
    localparam [31:0] DEFAULT_CARRIER_FWORD = 32'd644245094; // 30 MHz @ 200 MSPS
    localparam [31:0] DEFAULT_MOD_FWORD = 32'd42949673;      // 2 MHz @ 200 MSPS
    localparam [31:0] DEFAULT_SQUARE_FWORD = 32'd21474836;   // 1 MHz @ 200 MSPS

    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;

    reg [31:0] ctrl_reg;
    reg [31:0] carrier_fword_reg;
    reg [31:0] mod_fword_reg;
    reg [31:0] square_fword_reg;
    reg [31:0] sd_phase_reg;
    reg [31:0] sm_phase_reg;
    reg [31:0] delay_carrier_phase_reg;
    reg [31:0] delay_mod_phase_reg;
    reg [15:0] sd_gain_q14_reg;
    reg [15:0] sm_gain_q14_reg;
    reg [15:0] am_depth_q14_reg;
    reg [13:0] dc_offset_reg;
    reg [2:0]  out_a_sel_reg;
    reg [2:0]  out_b_sel_reg;
    reg [15:0] dac_a_gain_q14_reg;
    reg [15:0] dac_b_gain_q14_reg;
    reg [31:0] sample_counter;

    reg [31:0] phase_acc;
    reg [31:0] mod_phase_acc;
    reg [31:0] square_phase_acc;

    wire write_enable = S_AXI_AWREADY && S_AXI_AWVALID &&
                        S_AXI_WREADY && S_AXI_WVALID;
    wire read_enable = S_AXI_ARREADY && S_AXI_ARVALID && !S_AXI_RVALID;
    wire [REG_INDEX_BITS-1:0] write_index =
        axi_awaddr[ADDR_LSB + REG_INDEX_BITS - 1:ADDR_LSB];
    wire [REG_INDEX_BITS-1:0] read_index =
        axi_araddr[ADDR_LSB + REG_INDEX_BITS - 1:ADDR_LSB];

    wire enable = ctrl_reg[0];
    wire am_enable = ctrl_reg[1];
    wire phase_reset_req = write_enable && write_index == 5'h00 && S_AXI_WDATA[2];

    reg config_toggle_axi;
    reg config_toggle_d1;
    reg config_toggle_d2;
    reg config_seen_dac;
    wire config_update_dac = config_toggle_d2 ^ config_seen_dac;

    reg [31:0] ctrl_dac;
    reg [31:0] carrier_fword_dac;
    reg [31:0] mod_fword_dac;
    reg [31:0] square_fword_dac;
    reg [31:0] sd_phase_dac;
    reg [31:0] sm_phase_dac;
    reg [31:0] delay_carrier_phase_dac;
    reg [31:0] delay_mod_phase_dac;
    reg [15:0] sd_gain_q14_dac;
    reg [15:0] sm_gain_q14_dac;
    reg [15:0] am_depth_q14_dac;
    reg [13:0] dc_offset_dac;
    reg [2:0] out_a_sel_dac;
    reg [2:0] out_b_sel_dac;
    reg [15:0] dac_a_gain_q14_dac;
    reg [15:0] dac_b_gain_q14_dac;

    wire enable_dac = ctrl_dac[0];
    wire am_enable_dac = ctrl_dac[1];

    reg [9:0] carrier_addr_base_d1;
    reg [9:0] mod_addr_base_d1;
    reg [9:0] sd_phase_addr_d1;
    reg [9:0] sm_phase_addr_d1;
    reg [9:0] delay_carrier_addr_d1;
    reg [9:0] delay_mod_addr_d1;
    reg [9:0] sd_carrier_addr_d2;
    reg [9:0] sm_carrier_addr_d2;
    reg [9:0] sd_mod_addr_d2;
    reg [9:0] sm_mod_addr_d2;

    wire [13:0] sd_carrier_u14;
    wire [13:0] sm_carrier_u14;
    wire [13:0] sd_mod_u14;
    wire [13:0] sm_mod_u14;

    sine_lut_1024 u_sd_carrier_lut (
        .clk(dac_clk),
        .addr(sd_carrier_addr_d2),
        .dout(sd_carrier_u14)
    );

    sine_lut_1024 u_sm_carrier_lut (
        .clk(dac_clk),
        .addr(sm_carrier_addr_d2),
        .dout(sm_carrier_u14)
    );

    sine_lut_1024 u_sd_mod_lut (
        .clk(dac_clk),
        .addr(sd_mod_addr_d2),
        .dout(sd_mod_u14)
    );

    sine_lut_1024 u_sm_mod_lut (
        .clk(dac_clk),
        .addr(sm_mod_addr_d2),
        .dout(sm_mod_u14)
    );

    wire signed [14:0] sd_carrier_s15_w = {1'b0, sd_carrier_u14} - 15'sd8192;
    wire signed [14:0] sm_carrier_s15_w = {1'b0, sm_carrier_u14} - 15'sd8192;
    wire signed [14:0] sd_mod_s15_w = {1'b0, sd_mod_u14} - 15'sd8192;
    wire signed [14:0] sm_mod_s15_w = {1'b0, sm_mod_u14} - 15'sd8192;

    reg signed [14:0] sd_carrier_s15_d1;
    reg signed [14:0] sm_carrier_s15_d1;
    reg signed [14:0] sd_mod_s15_d1;
    reg signed [14:0] sm_mod_s15_d1;
    reg [15:0] sd_gain_q14_pipe_d1;
    reg [15:0] sm_gain_q14_pipe_d1;
    reg [15:0] am_depth_q14_pipe_d1;
    reg signed [47:0] sd_amp_prod_d2;
    reg signed [47:0] sm_amp_prod_d2;
    reg signed [47:0] sd_env_prod_d2;
    reg signed [47:0] sm_env_prod_d2;
    reg signed [17:0] sd_amp_s18_d3;
    reg signed [17:0] sm_amp_s18_d3;
    reg signed [17:0] sd_env_s18_d3;
    reg signed [17:0] sm_env_s18_d3;
    reg signed [35:0] sd_sig_prod_d4;
    reg signed [35:0] sm_sig_prod_d4;
    reg signed [31:0] sd_sig_s32_d5;
    reg signed [31:0] sm_sig_s32_d5;
    reg signed [31:0] sout_sig_s32_d6;
    reg signed [31:0] sd_offset_s32_d6;
    reg signed [31:0] sm_offset_s32_d6;
    reg signed [31:0] sout_offset_s32_d7;
    reg [13:0] sd_code;
    reg [13:0] sm_code;
    reg [13:0] sout_code;
    reg [13:0] mod_square_code;
    reg [13:0] mod_sine_code;
    reg [13:0] dac_a_selected_d1;
    reg [13:0] dac_b_selected_d1;
    reg signed [14:0] dac_a_centered_d1;
    reg signed [14:0] dac_b_centered_d1;
    reg signed [30:0] dac_a_trim_prod_d2;
    reg signed [30:0] dac_b_trim_prod_d2;
    reg signed [31:0] dac_a_offset_s32_d3;
    reg signed [31:0] dac_b_offset_s32_d3;
    reg [13:0] dac_a_trimmed_d4;
    reg [13:0] dac_b_trimmed_d4;

    function [13:0] clamp_to_dac;
        input signed [31:0] value;
        begin
            if (value < 32'sd0)
                clamp_to_dac = 14'd0;
            else if (value > 32'sd16383)
                clamp_to_dac = 14'd16383;
            else
                clamp_to_dac = value[13:0];
        end
    endfunction

    function [13:0] select_output;
        input [2:0] sel;
        begin
            case (sel)
            3'd0: select_output = sd_code;
            3'd1: select_output = sm_code;
            3'd2: select_output = sout_code;
            3'd3: select_output = dc_offset_dac;
            3'd4: select_output = mod_square_code;
            3'd5: select_output = mod_sine_code;
            default: select_output = dc_offset_dac;
            endcase
        end
    endfunction

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            axi_awaddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else if (!S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID) begin
            S_AXI_AWREADY <= 1'b1;
            axi_awaddr <= S_AXI_AWADDR;
        end else begin
            S_AXI_AWREADY <= 1'b0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_WREADY <= 1'b0;
        end else if (!S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWVALID) begin
            S_AXI_WREADY <= 1'b1;
        end else begin
            S_AXI_WREADY <= 1'b0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_BVALID <= 1'b0;
            S_AXI_BRESP <= 2'b00;
        end else if (write_enable && !S_AXI_BVALID) begin
            S_AXI_BVALID <= 1'b1;
            S_AXI_BRESP <= 2'b00;
        end else if (S_AXI_BVALID && S_AXI_BREADY) begin
            S_AXI_BVALID <= 1'b0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
            axi_araddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else if (!S_AXI_ARREADY && S_AXI_ARVALID) begin
            S_AXI_ARREADY <= 1'b1;
            axi_araddr <= S_AXI_ARADDR;
        end else begin
            S_AXI_ARREADY <= 1'b0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_RVALID <= 1'b0;
            S_AXI_RRESP <= 2'b00;
            S_AXI_RDATA <= 32'h00000000;
        end else if (read_enable) begin
            S_AXI_RVALID <= 1'b1;
            S_AXI_RRESP <= 2'b00;
            case (read_index)
            5'h00: S_AXI_RDATA <= ctrl_reg;
            5'h01: S_AXI_RDATA <= {
                12'd0, out_b_sel_reg, out_a_sel_reg,
                am_enable, enable, 12'd0
            };
            5'h02: S_AXI_RDATA <= carrier_fword_reg;
            5'h03: S_AXI_RDATA <= mod_fword_reg;
            5'h04: S_AXI_RDATA <= sd_phase_reg;
            5'h05: S_AXI_RDATA <= sm_phase_reg;
            5'h06: S_AXI_RDATA <= delay_carrier_phase_reg;
            5'h07: S_AXI_RDATA <= delay_mod_phase_reg;
            5'h08: S_AXI_RDATA <= {16'd0, sd_gain_q14_reg};
            5'h09: S_AXI_RDATA <= {16'd0, sm_gain_q14_reg};
            5'h0A: S_AXI_RDATA <= {16'd0, am_depth_q14_reg};
            5'h0B: S_AXI_RDATA <= {18'd0, dc_offset_reg};
            5'h0C: S_AXI_RDATA <= {29'd0, out_a_sel_reg};
            5'h0D: S_AXI_RDATA <= {29'd0, out_b_sel_reg};
            5'h0E: S_AXI_RDATA <= VERSION_VALUE;
            5'h0F: S_AXI_RDATA <= SAMPLE_RATE_HZ;
            5'h10: S_AXI_RDATA <= sample_counter;
            5'h11: S_AXI_RDATA <= {sd_code, sm_code, 4'd0};
            5'h12: S_AXI_RDATA <= {sout_code, dac_a_data, 4'd0};
            5'h13: S_AXI_RDATA <= square_fword_reg;
            5'h14: S_AXI_RDATA <= {16'd0, dac_a_gain_q14_reg};
            5'h15: S_AXI_RDATA <= {16'd0, dac_b_gain_q14_reg};
            default: S_AXI_RDATA <= 32'h00000000;
            endcase
        end else if (S_AXI_RVALID && S_AXI_RREADY) begin
            S_AXI_RVALID <= 1'b0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            ctrl_reg <= 32'h00000001;
            carrier_fword_reg <= DEFAULT_CARRIER_FWORD;
            mod_fword_reg <= DEFAULT_MOD_FWORD;
            square_fword_reg <= DEFAULT_SQUARE_FWORD;
            sd_phase_reg <= 32'd0;
            sm_phase_reg <= 32'd0;
            delay_carrier_phase_reg <= 32'd0;
            delay_mod_phase_reg <= 32'd0;
            sd_gain_q14_reg <= 16'd8192;
            sm_gain_q14_reg <= 16'd8192;
            am_depth_q14_reg <= 16'd0;
            dc_offset_reg <= 14'd8192;
            out_a_sel_reg <= 3'd0;
            out_b_sel_reg <= 3'd1;
            dac_a_gain_q14_reg <= 16'd16384;
            dac_b_gain_q14_reg <= 16'd16384;
            config_toggle_axi <= 1'b0;
        end else if (write_enable) begin
            case (write_index)
            5'h00: begin
                ctrl_reg <= S_AXI_WDATA;
                config_toggle_axi <= ~config_toggle_axi;
            end
            5'h02: carrier_fword_reg <= S_AXI_WDATA;
            5'h03: mod_fword_reg <= S_AXI_WDATA;
            5'h13: square_fword_reg <= S_AXI_WDATA;
            5'h04: sd_phase_reg <= S_AXI_WDATA;
            5'h05: sm_phase_reg <= S_AXI_WDATA;
            5'h06: delay_carrier_phase_reg <= S_AXI_WDATA;
            5'h07: delay_mod_phase_reg <= S_AXI_WDATA;
            5'h08: sd_gain_q14_reg <= S_AXI_WDATA[15:0];
            5'h09: sm_gain_q14_reg <= S_AXI_WDATA[15:0];
            5'h0A: am_depth_q14_reg <= S_AXI_WDATA[15:0];
            5'h0B: dc_offset_reg <= S_AXI_WDATA[13:0];
            5'h0C: out_a_sel_reg <= S_AXI_WDATA[2:0];
            5'h0D: out_b_sel_reg <= S_AXI_WDATA[2:0];
            5'h14: dac_a_gain_q14_reg <= S_AXI_WDATA[15:0];
            5'h15: dac_b_gain_q14_reg <= S_AXI_WDATA[15:0];
            default: begin
            end
            endcase
        end
    end

    always @(posedge dac_clk) begin
        if (!dac_resetn) begin
            config_toggle_d1 <= 1'b0;
            config_toggle_d2 <= 1'b0;
            config_seen_dac <= 1'b0;
            ctrl_dac <= 32'h00000001;
            carrier_fword_dac <= DEFAULT_CARRIER_FWORD;
            mod_fword_dac <= DEFAULT_MOD_FWORD;
            square_fword_dac <= DEFAULT_SQUARE_FWORD;
            sd_phase_dac <= 32'd0;
            sm_phase_dac <= 32'd0;
            delay_carrier_phase_dac <= 32'd0;
            delay_mod_phase_dac <= 32'd0;
            sd_gain_q14_dac <= 16'd8192;
            sm_gain_q14_dac <= 16'd8192;
            am_depth_q14_dac <= 16'd0;
            dc_offset_dac <= 14'd8192;
            out_a_sel_dac <= 3'd0;
            out_b_sel_dac <= 3'd1;
            dac_a_gain_q14_dac <= 16'd16384;
            dac_b_gain_q14_dac <= 16'd16384;
        end else begin
            config_toggle_d1 <= config_toggle_axi;
            config_toggle_d2 <= config_toggle_d1;
            if (config_update_dac) begin
                config_seen_dac <= config_toggle_d2;
                ctrl_dac <= ctrl_reg;
                carrier_fword_dac <= carrier_fword_reg;
                mod_fword_dac <= mod_fword_reg;
                square_fword_dac <= square_fword_reg;
                sd_phase_dac <= sd_phase_reg;
                sm_phase_dac <= sm_phase_reg;
                delay_carrier_phase_dac <= delay_carrier_phase_reg;
                delay_mod_phase_dac <= delay_mod_phase_reg;
                sd_gain_q14_dac <= sd_gain_q14_reg;
                sm_gain_q14_dac <= sm_gain_q14_reg;
                am_depth_q14_dac <= am_depth_q14_reg;
                dc_offset_dac <= dc_offset_reg;
                out_a_sel_dac <= out_a_sel_reg;
                out_b_sel_dac <= out_b_sel_reg;
                dac_a_gain_q14_dac <= dac_a_gain_q14_reg;
                dac_b_gain_q14_dac <= dac_b_gain_q14_reg;
            end
        end
    end

    always @(posedge dac_clk) begin
        if (!dac_resetn || config_update_dac) begin
            phase_acc <= 32'd0;
            mod_phase_acc <= 32'd0;
            square_phase_acc <= 32'd0;
            sample_counter <= 32'd0;
            carrier_addr_base_d1 <= 10'd0;
            mod_addr_base_d1 <= 10'd0;
            sd_phase_addr_d1 <= 10'd0;
            sm_phase_addr_d1 <= 10'd0;
            delay_carrier_addr_d1 <= 10'd0;
            delay_mod_addr_d1 <= 10'd0;
            sd_carrier_addr_d2 <= 10'd0;
            sm_carrier_addr_d2 <= 10'd0;
            sd_mod_addr_d2 <= 10'd0;
            sm_mod_addr_d2 <= 10'd0;
        end else if (enable_dac) begin
            phase_acc <= phase_acc + carrier_fword_dac;
            mod_phase_acc <= mod_phase_acc + mod_fword_dac;
            square_phase_acc <= square_phase_acc + square_fword_dac;
            sample_counter <= sample_counter + 1'b1;
            carrier_addr_base_d1 <= phase_acc[31:22];
            mod_addr_base_d1 <= mod_phase_acc[31:22];
            sd_phase_addr_d1 <= sd_phase_dac[31:22];
            sm_phase_addr_d1 <= sm_phase_dac[31:22];
            delay_carrier_addr_d1 <= delay_carrier_phase_dac[31:22];
            delay_mod_addr_d1 <= delay_mod_phase_dac[31:22];
            sd_carrier_addr_d2 <= carrier_addr_base_d1 + sd_phase_addr_d1;
            sm_carrier_addr_d2 <= carrier_addr_base_d1 + sd_phase_addr_d1 +
                                  sm_phase_addr_d1 - delay_carrier_addr_d1;
            sd_mod_addr_d2 <= mod_addr_base_d1;
            sm_mod_addr_d2 <= mod_addr_base_d1 - delay_mod_addr_d1;
        end
    end

    always @(posedge dac_clk) begin
        if (!dac_resetn) begin
            sd_carrier_s15_d1 <= 15'sd0;
            sm_carrier_s15_d1 <= 15'sd0;
            sd_mod_s15_d1 <= 15'sd0;
            sm_mod_s15_d1 <= 15'sd0;
            sd_gain_q14_pipe_d1 <= 16'd8192;
            sm_gain_q14_pipe_d1 <= 16'd8192;
            am_depth_q14_pipe_d1 <= 16'd0;
            sd_amp_prod_d2 <= 48'sd0;
            sm_amp_prod_d2 <= 48'sd0;
            sd_env_prod_d2 <= 48'sd0;
            sm_env_prod_d2 <= 48'sd0;
            sd_amp_s18_d3 <= 18'sd0;
            sm_amp_s18_d3 <= 18'sd0;
            sd_env_s18_d3 <= 18'sd16384;
            sm_env_s18_d3 <= 18'sd16384;
            sd_sig_prod_d4 <= 36'sd0;
            sm_sig_prod_d4 <= 36'sd0;
            sd_sig_s32_d5 <= 32'sd0;
            sm_sig_s32_d5 <= 32'sd0;
            sout_sig_s32_d6 <= 32'sd0;
            sd_offset_s32_d6 <= 32'sd8192;
            sm_offset_s32_d6 <= 32'sd8192;
            sout_offset_s32_d7 <= 32'sd8192;
            sd_code <= 14'd8192;
            sm_code <= 14'd8192;
            sout_code <= 14'd8192;
            mod_square_code <= 14'd8192;
            mod_sine_code <= 14'd8192;
            dac_a_centered_d1 <= 15'sd0;
            dac_b_centered_d1 <= 15'sd0;
            dac_a_trim_prod_d2 <= 31'sd0;
            dac_b_trim_prod_d2 <= 31'sd0;
            dac_a_offset_s32_d3 <= 32'sd8192;
            dac_b_offset_s32_d3 <= 32'sd8192;
            dac_a_trimmed_d4 <= 14'd8192;
            dac_b_trimmed_d4 <= 14'd8192;
        end else begin
            sd_carrier_s15_d1 <= sd_carrier_s15_w;
            sm_carrier_s15_d1 <= sm_carrier_s15_w;
            sd_mod_s15_d1 <= sd_mod_s15_w;
            sm_mod_s15_d1 <= sm_mod_s15_w;
            // Explicit DSP input pipeline: config registers can be placed
            // independently from the DSP48 columns at 200 MHz.
            sd_gain_q14_pipe_d1 <= sd_gain_q14_dac;
            sm_gain_q14_pipe_d1 <= sm_gain_q14_dac;
            am_depth_q14_pipe_d1 <= am_depth_q14_dac;

            sd_amp_prod_d2 <= sd_carrier_s15_d1 * $signed({1'b0, sd_gain_q14_pipe_d1});
            sm_amp_prod_d2 <= sm_carrier_s15_d1 * $signed({1'b0, sm_gain_q14_pipe_d1});
            sd_env_prod_d2 <= sd_mod_s15_d1 * $signed({1'b0, am_depth_q14_pipe_d1});
            sm_env_prod_d2 <= sm_mod_s15_d1 * $signed({1'b0, am_depth_q14_pipe_d1});

            sd_amp_s18_d3 <= $signed(sd_amp_prod_d2[31:14]);
            sm_amp_s18_d3 <= $signed(sm_amp_prod_d2[31:14]);
            sd_env_s18_d3 <= am_enable_dac ?
                (18'sd16384 + $signed(sd_env_prod_d2[30:13])) :
                18'sd16384;
            sm_env_s18_d3 <= am_enable_dac ?
                (18'sd16384 + $signed(sm_env_prod_d2[30:13])) :
                18'sd16384;

            sd_sig_prod_d4 <= sd_amp_s18_d3 * sd_env_s18_d3;
            sm_sig_prod_d4 <= sm_amp_s18_d3 * sm_env_s18_d3;

            sd_sig_s32_d5 <= sd_sig_prod_d4 >>> 14;
            sm_sig_s32_d5 <= sm_sig_prod_d4 >>> 14;
            sout_sig_s32_d6 <= sd_sig_s32_d5 + sm_sig_s32_d5;

            // Keep the 32-bit offset add and saturation comparator in
            // separate stages.  At 200 MHz this removes the long carry chain
            // from the final DAC-code register path.
            sd_offset_s32_d6 <= sd_sig_s32_d5 + $signed({18'd0, dc_offset_dac});
            sm_offset_s32_d6 <= sm_sig_s32_d5 + $signed({18'd0, dc_offset_dac});
            sout_offset_s32_d7 <= sout_sig_s32_d6 + $signed({18'd0, dc_offset_dac});

            sd_code <= clamp_to_dac(sd_offset_s32_d6);
            sm_code <= clamp_to_dac(sm_offset_s32_d6);
            sout_code <= clamp_to_dac(sout_offset_s32_d7);
            mod_square_code <= square_phase_acc[31] ? 14'd16383 : 14'd0;
            mod_sine_code <= sd_mod_u14;
            dac_a_centered_d1 <= $signed({1'b0, dac_a_selected_d1}) - 15'sd8192;
            dac_b_centered_d1 <= $signed({1'b0, dac_b_selected_d1}) - 15'sd8192;
            dac_a_trim_prod_d2 <= dac_a_centered_d1 * $signed({1'b0, dac_a_gain_q14_dac});
            dac_b_trim_prod_d2 <= dac_b_centered_d1 * $signed({1'b0, dac_b_gain_q14_dac});
            dac_a_offset_s32_d3 <= (dac_a_trim_prod_d2 >>> 14) + $signed({18'd0, dc_offset_dac});
            dac_b_offset_s32_d3 <= (dac_b_trim_prod_d2 >>> 14) + $signed({18'd0, dc_offset_dac});
            dac_a_trimmed_d4 <= clamp_to_dac(dac_a_offset_s32_d3);
            dac_b_trimmed_d4 <= clamp_to_dac(dac_b_offset_s32_d3);
        end
    end

    // Select one full cycle ahead of the final falling-edge IOB register in
    // the MAX5885 wrapper.  This keeps selection and DC paths out of the
    // half-cycle timing budget.
    always @(posedge dac_clk) begin
        if (!dac_resetn) begin
            dac_a_selected_d1 <= 14'd8192;
            dac_b_selected_d1 <= 14'd8192;
        end else begin
            dac_a_selected_d1 <= select_output(out_a_sel_dac);
            dac_b_selected_d1 <= select_output(out_b_sel_dac);
        end
    end
    assign dac_a_data = dac_a_trimmed_d4;
    assign dac_b_data = dac_b_trimmed_d4;

    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .INIT(1'b0),
        .SRTYPE("SYNC")
    ) u_oddr_dac_a_clk (
        .Q(dac_a_clk),
        .C(dac_clk),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );

    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .INIT(1'b0),
        .SRTYPE("SYNC")
    ) u_oddr_dac_a_wrt (
        .Q(dac_a_wrt),
        .C(dac_clk),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );

    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .INIT(1'b0),
        .SRTYPE("SYNC")
    ) u_oddr_dac_b_clk (
        .Q(dac_b_clk),
        .C(dac_clk),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );

    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .INIT(1'b0),
        .SRTYPE("SYNC")
    ) u_oddr_dac_b_wrt (
        .Q(dac_b_wrt),
        .C(dac_clk),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );
endmodule

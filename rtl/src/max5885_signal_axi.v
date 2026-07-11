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

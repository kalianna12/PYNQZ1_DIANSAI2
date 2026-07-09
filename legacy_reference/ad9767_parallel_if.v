`timescale 1ns / 1ps

module ad9767_parallel_if #(
    parameter integer CLK_FREQ_HZ       = 125_000_000,
    parameter integer UPDATE_RATE_HZ    = 25_000_000,
    parameter integer DDS_LATENCY_CLKS  = 3,
    parameter integer DATA_SETUP_CLKS   = 2,
    parameter integer PULSE_HIGH_CLKS   = 2
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [13:0] sample_data,

    output reg  [13:0] dac_data,
    output wire        dac_clk,
    output wire        dac_wrt,
    output reg         sample_tick
);

    localparam integer UPDATE_DIV = CLK_FREQ_HZ / UPDATE_RATE_HZ;

    reg [31:0] update_cnt = 32'd0;

    // Launch data on the falling edge, then let AD9767 sample it on the next
    // forwarded clock edge. This matches the verified PYNQ-Z2 AD9767 example
    // and avoids changing dac_data on the same edge used by CLK/WRT.
    always @(negedge clk) begin
        if (rst)
            dac_data <= 14'd0;
        else
            dac_data <= sample_data;
    end

    always @(posedge clk) begin
        if (rst) begin
            sample_tick <= 1'b0;
            update_cnt  <= 32'd0;
        end else begin
            sample_tick <= 1'b0;

            if (update_cnt == UPDATE_DIV - 1)
                update_cnt <= 32'd0;
            else
                update_cnt <= update_cnt + 1'b1;

            if (update_cnt == 32'd0)
                sample_tick <= 1'b1;
        end
    end

    // Forward the DAC sampling clock continuously. CLK and WRT intentionally
    // stay in phase for the common AD9767 module wiring.
    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .INIT(1'b0),
        .SRTYPE("SYNC")
    ) u_oddr_dac_clk (
        .Q(dac_clk),
        .C(clk),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(rst),
        .S(1'b0)
    );

    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .INIT(1'b0),
        .SRTYPE("SYNC")
    ) u_oddr_dac_wrt (
        .Q(dac_wrt),
        .C(clk),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(rst),
        .S(1'b0)
    );

endmodule

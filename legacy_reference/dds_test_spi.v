`timescale 1ns / 1ps

// Minimal ESP32-P4 <-> PYNQDDS SPI echo test top.
//
// Use this module as Vivado top with the existing pynq_dds_system.xdc.
// It does not parse D3/D4/D5 and does not drive AD9767 playback. Every
// completed 128-byte ESP SPI frame is sampled, summarized, and returned in
// the next SPI transaction.
module dds_test_spi (
    input  wire        clk_125m,
    input  wire        rst_btn,

    output wire        led0,
    output wire        led1,
    output wire        led2,
    output wire        led3,

    input  wire        adc_spi_mosi,
    output wire        adc_spi_miso,
    input  wire        adc_spi_sclk,
    input  wire        adc_spi_cs_n,

    input  wire        esp_spi_sclk,
    input  wire        esp_spi_mosi,
    output wire        esp_spi_miso,
    input  wire        esp_spi_cs_n,

    output wire [13:0] dac_data,
    output wire        dac_clk,
    output wire        dac_wrt
);

    // Keep unused original-system outputs quiet.
    assign adc_spi_miso = 1'b0;
    assign dac_data = 14'd8192;
    assign dac_clk = clk_125m;
    assign dac_wrt = clk_125m;

    reg [7:0] por_cnt = 8'd0;
    wire rst = (por_cnt < 8'd255) | rst_btn;

    always @(posedge clk_125m) begin
        if (por_cnt < 8'd255)
            por_cnt <= por_cnt + 1'b1;
    end

    wire [1023:0] esp_rx_frame;
    wire [1023:0] esp_tx_frame;
    wire esp_done;
    wire esp_active;
    wire esp_cs_fall;

    spi_slave_128b u_esp_spi_slave (
        .clk(clk_125m),
        .rst(rst),
        .tx_frame(esp_tx_frame),
        .mosi(esp_spi_mosi),
        .miso(esp_spi_miso),
        .sclk(esp_spi_sclk),
        .cs_n(esp_spi_cs_n),
        .rx_frame(esp_rx_frame),
        .done(esp_done),
        .active(esp_active),
        .cs_fall(esp_cs_fall)
    );

    reg [31:0] rx_count = 32'd0;
    reg [7:0]  rx_b0 = 8'd0;
    reg [7:0]  rx_b1 = 8'd0;
    reg [7:0]  rx_b2 = 8'd0;
    reg [7:0]  rx_b3 = 8'd0;
    reg [7:0]  rx_b4 = 8'd0;
    reg [7:0]  rx_b5 = 8'd0;
    reg [7:0]  rx_b6 = 8'd0;
    reg [7:0]  rx_b7 = 8'd0;
    reg [7:0]  rx_checksum = 8'd0;
    reg [7:0]  calc_checksum = 8'd0;
    reg        rx_magic_ok = 1'b0;
    reg        rx_checksum_ok = 1'b0;
    reg        rx_valid = 1'b0;
    reg        done_toggle = 1'b0;
    reg [26:0] comm_alive = 27'd0;

    integer i;
    reg [7:0] chk;

    always @(posedge clk_125m) begin
        if (rst) begin
            rx_count <= 32'd0;
            rx_b0 <= 8'd0;
            rx_b1 <= 8'd0;
            rx_b2 <= 8'd0;
            rx_b3 <= 8'd0;
            rx_b4 <= 8'd0;
            rx_b5 <= 8'd0;
            rx_b6 <= 8'd0;
            rx_b7 <= 8'd0;
            rx_checksum <= 8'd0;
            calc_checksum <= 8'd0;
            rx_magic_ok <= 1'b0;
            rx_checksum_ok <= 1'b0;
            rx_valid <= 1'b0;
            done_toggle <= 1'b0;
            comm_alive <= 27'd0;
        end else begin
            if (comm_alive != 27'd0)
                comm_alive <= comm_alive - 27'd1;

            if (esp_done) begin
                chk = 8'd0;
                for (i = 0; i < 116; i = i + 1)
                    chk = chk ^ esp_rx_frame[i*8 +: 8];

                rx_count <= rx_count + 32'd1;
                rx_b0 <= esp_rx_frame[0*8 +: 8];
                rx_b1 <= esp_rx_frame[1*8 +: 8];
                rx_b2 <= esp_rx_frame[2*8 +: 8];
                rx_b3 <= esp_rx_frame[3*8 +: 8];
                rx_b4 <= esp_rx_frame[4*8 +: 8];
                rx_b5 <= esp_rx_frame[5*8 +: 8];
                rx_b6 <= esp_rx_frame[6*8 +: 8];
                rx_b7 <= esp_rx_frame[7*8 +: 8];
                rx_checksum <= esp_rx_frame[116*8 +: 8];
                calc_checksum <= chk;
                rx_magic_ok <= (esp_rx_frame[0*8 +: 8] == 8'hA5) &&
                               (esp_rx_frame[1*8 +: 8] == 8'h5A) &&
                               (esp_rx_frame[3*8 +: 8] == 8'd112);
                rx_checksum_ok <= (esp_rx_frame[116*8 +: 8] == chk);
                rx_valid <= (esp_rx_frame[0*8 +: 8] == 8'hA5) &&
                            (esp_rx_frame[1*8 +: 8] == 8'h5A) &&
                            (esp_rx_frame[3*8 +: 8] == 8'd112) &&
                            (esp_rx_frame[116*8 +: 8] == chk);
                done_toggle <= ~done_toggle;
                comm_alive <= 27'd125_000_000; // LED0 on about 1 second after any full frame.
            end
        end
    end

    function [1023:0] build_echo_frame;
        input [31:0] count;
        input [7:0] b0;
        input [7:0] b1;
        input [7:0] b2;
        input [7:0] b3;
        input [7:0] b4;
        input [7:0] b5;
        input [7:0] b6;
        input [7:0] b7;
        input [7:0] rx_chk;
        input [7:0] calc_chk;
        input magic_ok;
        input checksum_ok;
        input valid;
        input active_now;
        integer bi;
        reg [7:0] out_chk;
        begin
            build_echo_frame = 1024'd0;
            build_echo_frame[0*8 +: 8] = 8'hA5;
            build_echo_frame[1*8 +: 8] = 8'h5A;
            build_echo_frame[2*8 +: 8] = 8'hE1;
            build_echo_frame[3*8 +: 8] = 8'd112;

            build_echo_frame[4*8 +: 8] = count[7:0];
            build_echo_frame[5*8 +: 8] = count[15:8];
            build_echo_frame[6*8 +: 8] = count[23:16];
            build_echo_frame[7*8 +: 8] = count[31:24];

            build_echo_frame[8*8 +: 8]  = b0;
            build_echo_frame[9*8 +: 8]  = b1;
            build_echo_frame[10*8 +: 8] = b2;
            build_echo_frame[11*8 +: 8] = b3;
            build_echo_frame[12*8 +: 8] = b4;
            build_echo_frame[13*8 +: 8] = b5;
            build_echo_frame[14*8 +: 8] = b6;
            build_echo_frame[15*8 +: 8] = b7;

            build_echo_frame[16*8 +: 8] = rx_chk;
            build_echo_frame[17*8 +: 8] = calc_chk;
            build_echo_frame[18*8 +: 8] = {4'd0, active_now, valid, checksum_ok, magic_ok};
            build_echo_frame[19*8 +: 8] = 8'hE1;
            build_echo_frame[20*8 +: 8] = 8'h3C;
            build_echo_frame[21*8 +: 8] = 8'hC3;

            out_chk = 8'd0;
            for (bi = 0; bi < 116; bi = bi + 1)
                out_chk = out_chk ^ build_echo_frame[bi*8 +: 8];
            build_echo_frame[116*8 +: 8] = out_chk;
        end
    endfunction

    assign esp_tx_frame = build_echo_frame(
        rx_count,
        rx_b0, rx_b1, rx_b2, rx_b3, rx_b4, rx_b5, rx_b6, rx_b7,
        rx_checksum, calc_checksum,
        rx_magic_ok, rx_checksum_ok, rx_valid, esp_active
    );

    // led0: recent full ESP frame received
    // led1: ESP CS active
    // led2: last frame had A5 5A / len 112 / checksum OK
    // led3: toggles on every completed 128-byte frame
    assign led0 = (comm_alive != 27'd0);
    assign led1 = esp_active;
    assign led2 = rx_valid;
    assign led3 = done_toggle;

endmodule

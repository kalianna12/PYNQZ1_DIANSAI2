`timescale 1ns / 1ps

module tb_pynq_dds_system_fast;
    reg clk = 1'b0;
    reg rst_btn = 1'b1;
    reg adc_spi_mosi = 1'b0;
    reg adc_spi_sclk = 1'b0;
    reg adc_spi_cs_n = 1'b1;
    wire adc_spi_miso;
    reg esp_spi_mosi = 1'b0;
    reg esp_spi_sclk = 1'b0;
    reg esp_spi_cs_n = 1'b1;
    wire esp_spi_miso;
    wire [13:0] dac_data;
    wire dac_clk;
    wire dac_wrt;
    wire led0, led1, led2, led3;

    integer i;

    always #4 clk = ~clk; // 125 MHz

    pynq_dds_system_top #(
        .SIM_FAST(1),
        .SIM_SAMPLE_COUNT(32'd16),
        .SIM_ARB_STEP_PERIOD_CLKS(32'd8)
    ) dut (
        .clk_125m(clk),
        .rst_btn(rst_btn),
        .led0(led0),
        .led1(led1),
        .led2(led2),
        .led3(led3),
        .adc_spi_mosi(adc_spi_mosi),
        .adc_spi_miso(adc_spi_miso),
        .adc_spi_sclk(adc_spi_sclk),
        .adc_spi_cs_n(adc_spi_cs_n),
        .esp_spi_sclk(esp_spi_sclk),
        .esp_spi_mosi(esp_spi_mosi),
        .esp_spi_miso(esp_spi_miso),
        .esp_spi_cs_n(esp_spi_cs_n),
        .dac_data(dac_data),
        .dac_clk(dac_clk),
        .dac_wrt(dac_wrt)
    );

    task put_u32;
        inout [1023:0] frame;
        input integer off;
        input [31:0] value;
        begin
            frame[(off + 0) * 8 +: 8] = value[7:0];
            frame[(off + 1) * 8 +: 8] = value[15:8];
            frame[(off + 2) * 8 +: 8] = value[23:16];
            frame[(off + 3) * 8 +: 8] = value[31:24];
        end
    endtask

    task finish_frame;
        inout [1023:0] frame;
        integer bi;
        reg [7:0] chk;
        begin
            chk = 8'd0;
            for (bi = 0; bi < 116; bi = bi + 1)
                chk = chk ^ frame[bi * 8 +: 8];
            frame[116 * 8 +: 8] = chk;
        end
    endtask

    task esp_spi_send_frame;
        input [1023:0] frame;
        integer bi;
        integer bit_idx;
        reg [7:0] b;
        begin
            esp_spi_cs_n = 1'b0;
            repeat (8) @(posedge clk);
            for (bi = 0; bi < 128; bi = bi + 1) begin
                b = frame[bi * 8 +: 8];
                for (bit_idx = 7; bit_idx >= 0; bit_idx = bit_idx - 1) begin
                    esp_spi_mosi = b[bit_idx];
                    repeat (4) @(posedge clk);
                    esp_spi_sclk = 1'b1;
                    repeat (4) @(posedge clk);
                    esp_spi_sclk = 1'b0;
                end
            end
            repeat (8) @(posedge clk);
            esp_spi_cs_n = 1'b1;
            repeat (16) @(posedge clk);
        end
    endtask

    task make_d3;
        output [1023:0] frame;
        input [31:0] seq;
        begin
            frame = 1024'd0;
            frame[0*8 +: 8] = 8'hA5;
            frame[1*8 +: 8] = 8'h5A;
            frame[2*8 +: 8] = 8'hD3;
            frame[3*8 +: 8] = 8'd112;
            put_u32(frame, 4, seq);
            put_u32(frame, 8, 32'd16);
            put_u32(frame, 12, 32'd100000);
            finish_frame(frame);
        end
    endtask

    task make_d4;
        output [1023:0] frame;
        input [31:0] seq;
        input [31:0] start_index;
        input [31:0] count;
        integer si;
        reg signed [15:0] sample;
        begin
            frame = 1024'd0;
            frame[0*8 +: 8] = 8'hA5;
            frame[1*8 +: 8] = 8'h5A;
            frame[2*8 +: 8] = 8'hD4;
            frame[3*8 +: 8] = 8'd112;
            put_u32(frame, 4, seq);
            put_u32(frame, 8, start_index / 32'd30);
            put_u32(frame, 12, start_index);
            put_u32(frame, 16, count);
            for (si = 0; si < 30; si = si + 1) begin
                sample = (si < count) ? $signed(16'sd256 * si) : 16'sd0;
                frame[(20 + si * 2) * 8 +: 8] = sample[7:0];
                frame[(21 + si * 2) * 8 +: 8] = sample[15:8];
            end
            finish_frame(frame);
        end
    endtask

    task make_d5;
        output [1023:0] frame;
        input [31:0] seq;
        begin
            frame = 1024'd0;
            frame[0*8 +: 8] = 8'hA5;
            frame[1*8 +: 8] = 8'h5A;
            frame[2*8 +: 8] = 8'hD5;
            frame[3*8 +: 8] = 8'd112;
            put_u32(frame, 4, seq);
            finish_frame(frame);
        end
    endtask

    reg [1023:0] tx;

    initial begin
        repeat (40) @(posedge clk);
        rst_btn = 1'b0;
        repeat (300) @(posedge clk);

        // Layer A: direct RAM write, no SPI. Tests arb playback and DAC output.
        for (i = 0; i < 16; i = i + 1)
            dut.wave_ram[i] = $signed(16'sd512 * i);
        dut.arb_sample_count = 32'd16;
        dut.arb_step_period_clks = 32'd8;
        dut.arb_mode = 1'b1;
        dut.arb_playing = 1'b1;
        repeat (300) @(posedge clk);
        dut.arb_playing = 1'b0;
        dut.arb_mode = 1'b0;

        // Layer B: one D3, one D4 carrying 16 samples, then D5.
        make_d3(tx, 32'h1001);
        esp_spi_send_frame(tx);
        make_d4(tx, 32'h1001, 32'd0, 32'd16);
        esp_spi_send_frame(tx);
        make_d5(tx, 32'h1001);
        esp_spi_send_frame(tx);
        repeat (500) @(posedge clk);

        // Layer C hook: instantiate with SIM_FAST=0 in a separate long sim and
        // call make_d4 repeatedly for 35 chunks to cover all 1024 samples.
        $finish;
    end
endmodule

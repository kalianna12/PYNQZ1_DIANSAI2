`timescale 1ns / 1ps

module pynq_dds_system_top #(
    // Simulation-only acceleration knobs.
    // Hardware/default arbitrary-wave behavior:
    //   SIM_FAST=0, 4096 samples, 100 kSPS playback.
    parameter integer SIM_FAST = 0,
    parameter [31:0] SIM_SAMPLE_COUNT = 32'd1024,
    parameter [31:0] SIM_ARB_STEP_PERIOD_CLKS = 32'd1000
) (
    input  wire        clk_125m,
    input  wire        rst_btn,

    // Debug LEDs
    // led0: arbitrary-wave mode
    // led1: ESP SPI active, arbitrary-wave receiving, or D4 RAM writing
    // led2: arbitrary-wave playing
    // led3: toggles on accepted ESP SPI command, or lights when all samples received
    output wire        led0,
    output wire        led1,
    output wire        led2,
    output wire        led3,

    // SPI-B Slave from PYNQADC (PmodB P7-P10)
    input  wire        adc_spi_mosi,
    output wire        adc_spi_miso,
    input  wire        adc_spi_sclk,
    input  wire        adc_spi_cs_n,

    // Second SPI slave from ESP32-P4, used only for arbitrary-wave D3/D4/D5
    input  wire        esp_spi_sclk,
    input  wire        esp_spi_mosi,
    output wire        esp_spi_miso,
    input  wire        esp_spi_cs_n,

    // AD9767 DAC interface
    output wire [13:0] dac_data,
    output wire        dac_clk,
    output wire        dac_wrt
);

    // ============================================================
    // Power-on reset
    // ============================================================
    localparam [31:0] ARB_CLK_HZ = 32'd125000000;
    localparam [31:0] DEFAULT_ARB_SAMPLE_RATE_HZ = 32'd100000;
    localparam [31:0] ARB_RAM_DEPTH = 32'd4096;
    localparam integer ARB_ADDR_BITS = 12;

    reg [7:0] por_cnt = 8'd0;
    wire por_rst = (por_cnt < 8'd255) | rst_btn;

    always @(posedge clk_125m) begin
        if (por_cnt < 8'd255)
            por_cnt <= por_cnt + 1'b1;
    end

    // Forward declarations for signals used by status LEDs before the SPI and
    // command parser blocks below.
    wire [1023:0] adc_spi_rx_frame;
    wire [1023:0] adc_spi_tx_frame;
    wire adc_spi_done;
    wire adc_spi_active;
    wire adc_spi_cs_fall;

    wire [1023:0] esp_spi_rx_frame;
    wire [1023:0] esp_spi_tx_frame;
    wire esp_spi_done;
    wire esp_spi_active;
    wire esp_spi_cs_fall;

    localparam [31:0] DEFAULT_ARB_SAMPLE_COUNT =
        (SIM_FAST != 0 && SIM_SAMPLE_COUNT != 32'd0 && SIM_SAMPLE_COUNT < ARB_RAM_DEPTH) ?
        SIM_SAMPLE_COUNT : ARB_RAM_DEPTH;
    localparam [31:0] DEFAULT_ARB_STEP_PERIOD_CLKS =
        (SIM_FAST != 0 && SIM_ARB_STEP_PERIOD_CLKS != 32'd0) ?
        SIM_ARB_STEP_PERIOD_CLKS : 32'd1250;

    reg  dds_cmd_accepted = 1'b0;
    reg  esp_cmd_accepted = 1'b0;
    reg  spi_frame_err    = 1'b0;
    reg        arb_mode         = 1'b0;
    reg        arb_receiving    = 1'b0;
    reg        arb_playing      = 1'b0;
    reg        output_owner_arb = 1'b0;
    reg        esp_arb_output_enable = 1'b0;
    reg [31:0] arb_stuck_watchdog = 32'd0;
    reg [31:0] arb_last_progress = 32'd0;
    reg [31:0] arb_sample_count = DEFAULT_ARB_SAMPLE_COUNT;
    reg [31:0] arb_sample_rate_hz = DEFAULT_ARB_SAMPLE_RATE_HZ;
    reg [31:0] arb_write_count  = 32'd0;
    reg [ARB_ADDR_BITS-1:0]  arb_play_index   = {ARB_ADDR_BITS{1'b0}};
    reg signed [15:0] arb_play_sample = 16'sd0;
    reg [13:0] arb_dac_code = 14'd8192;
    reg        arb_start_play_pulse = 1'b0;
    reg        arb_start_pending = 1'b0;
    reg [31:0] arb_step_period_clks = DEFAULT_ARB_STEP_PERIOD_CLKS; // default: 125MHz / 100kHz
    reg [31:0] arb_step_cnt = 32'd0;
    reg [ARB_ADDR_BITS-1:0]  arb_read_addr   = {ARB_ADDR_BITS{1'b0}};
    wire signed [15:0] wave_ram_read_data;

    wire arb_all_samples_received =
        (arb_sample_count != 32'd0) && (arb_write_count >= arb_sample_count);

    // ============================================================
    // Serialized D4 chunk writer
    // ============================================================
    // Do not write up to 30 wave_ram addresses in one clock. A true BRAM
    // only has one or two ports, so a 30-write-port style can make Vivado
    // infer huge LUT/FF logic and slow synthesis badly.
    //
    // D4 is first captured into this small 30-sample register buffer, then
    // wave_ram is written one sample per clk_125m cycle. SPI-B transactions
    // are much slower than 30 clk_125m cycles, so this does not reduce the
    // external transfer rate.
    reg        d4_write_pending = 1'b0;
    reg [ARB_ADDR_BITS-1:0]  d4_write_base    = {ARB_ADDR_BITS{1'b0}};
    reg [5:0]  d4_write_count   = 6'd0;
    reg [5:0]  d4_write_pos     = 6'd0;
    reg signed [15:0] d4_sample_buf [0:29];

    wire [ARB_ADDR_BITS-1:0] d4_write_addr = d4_write_base + d4_write_pos[4:0];
    wire wave_ram_write_en = d4_write_pending;

    arb_wave_ram #(
        .ADDR_BITS(ARB_ADDR_BITS),
        .DEPTH(4096)
    ) u_arb_wave_ram (
        .clk(clk_125m),
        .we(wave_ram_write_en),
        .waddr(d4_write_addr),
        .wdata(d4_sample_buf[d4_write_pos]),
        .raddr(arb_read_addr),
        .rdata(wave_ram_read_data)
    );

    // ============================================================
    // LEDs
    // ============================================================
    localparam [23:0] LED_BLINK_TICKS = 24'd10_000_000; // ~100ms at 100MHz

    reg [26:0] heartbeat_cnt = 27'd0;
    reg        cs_fall_toggle = 1'b0;
    reg        cmd_ok_toggle = 1'b0;
    reg        esp_cmd_ok_toggle = 1'b0;
    reg [23:0] frame_err_blink = 24'd0;
    reg [23:0] esp_done_blink = 24'd0;

    always @(posedge clk_125m) begin
        if (por_rst) begin
            heartbeat_cnt <= 27'd0;
            cs_fall_toggle <= 1'b0;
            cmd_ok_toggle <= 1'b0;
            esp_cmd_ok_toggle <= 1'b0;
            frame_err_blink <= 24'd0;
            esp_done_blink <= 24'd0;
        end else begin
            heartbeat_cnt <= heartbeat_cnt + 27'd1;

            if (esp_spi_done)
                esp_done_blink <= LED_BLINK_TICKS;
            else if (esp_done_blink != 24'd0)
                esp_done_blink <= esp_done_blink - 24'd1;

            if (adc_spi_cs_fall || esp_spi_cs_fall)
                cs_fall_toggle <= ~cs_fall_toggle;

            if (dds_cmd_accepted)
                cmd_ok_toggle <= ~cmd_ok_toggle;

            if (esp_cmd_accepted)
                esp_cmd_ok_toggle <= ~esp_cmd_ok_toggle;

            if (spi_frame_err)
                frame_err_blink <= LED_BLINK_TICKS;
            else if (frame_err_blink != 24'd0)
                frame_err_blink <= frame_err_blink - 24'd1;
        end
    end

    // ============================================================
    // SPI-B Slave from PYNQADC, D1/NOP only
    // ============================================================
    spi_slave_128b u_adc_spi_slave (
        .clk(clk_125m),
        .rst(por_rst),
        .tx_frame(adc_spi_tx_frame),
        .mosi(adc_spi_mosi),
        .miso(adc_spi_miso),
        .sclk(adc_spi_sclk),
        .cs_n(adc_spi_cs_n),
        .rx_frame(adc_spi_rx_frame),
        .done(adc_spi_done),
        .active(adc_spi_active),
        .cs_fall(adc_spi_cs_fall)
    );

    // ============================================================
    // Second SPI Slave from ESP32-P4, arbitrary-wave D3/D4/D5 only
    // ============================================================
    spi_slave_128b u_esp_spi_slave (
        .clk(clk_125m),
        .rst(por_rst),
        .tx_frame(esp_spi_tx_frame),
        .mosi(esp_spi_mosi),
        .miso(esp_spi_miso),
        .sclk(esp_spi_sclk),
        .cs_n(esp_spi_cs_n),
        .rx_frame(esp_spi_rx_frame),
        .done(esp_spi_done),
        .active(esp_spi_active),
        .cs_fall(esp_spi_cs_fall)
    );

    // ============================================================
    // DDS Command registers & SPI frame parser
    // ============================================================
    reg [31:0] dds_cmd_seq    = 32'd0;
    reg [31:0] dds_cmd        = 32'd0;
    reg [31:0] dds_cmd_freq   = 32'd0;
    reg [31:0] dds_cmd_ampl   = 32'd1000;
    reg [31:0] dds_cmd_phase  = 32'd0;
    reg [31:0] dds_start_freq = 32'd0;
    reg [31:0] dds_stop_freq  = 32'd0;
    reg [31:0] dds_step_freq  = 32'd0;
    reg [31:0] dds_mode       = 32'd0;
    reg [31:0] dds_flags      = 32'd1; // bit0=ready
    reg [31:0] esp_d2_seq     = 32'd0;
    reg [31:0] esp_d2_cmd     = 32'd0;
    reg [31:0] esp_d2_freq    = 32'd0;
    reg [31:0] esp_d2_flags   = 32'd1;
    reg [31:0] last_cmd_seq     = 32'hFFFFFFFF;
    reg [31:0] dds_fword        = 32'd172; // ~1Hz default
    reg        dds_phase_reset  = 1'b0;
    reg [31:0] last_valid_freq_hz = 32'd1000;
    reg [31:0] last_valid_fword = 32'd171799;
    reg [31:0] basic_dds_watchdog = 32'd0;
    reg [31:0] basic_dds_recover_count = 32'd0;
    reg        basic_dds_recovered = 1'b0;
    reg        basic_freq_zero_reject = 1'b0;
    reg [23:0] basic_event_blink = 24'd0;
    // Keepalive policy:
    // - normal STOP never mutes DDS
    // - ADC SET_FREQ/SET_SINGLE always takes DAC output back to basic DDS
    // - ESP arbitrary-wave output is allowed only after a fresh D3 begins it
    localparam integer ENABLE_DDS_STOP_MUTE = 0;
    localparam integer ENABLE_ESP_ARB_DAC_OUTPUT = 1;
    localparam [31:0] ARB_STUCK_TIMEOUT_CLKS = 32'd500000000; // 5s at 100MHz
    localparam [31:0] BASIC_DDS_WATCHDOG_CLKS = 32'd1000000; // 10ms at 100MHz

    wire active_path_is_arb =
        (ENABLE_ESP_ARB_DAC_OUTPUT != 0) &&
        esp_arb_output_enable &&
        output_owner_arb &&
        arb_playing;

    always @(posedge clk_125m) begin
        if (por_rst) begin
            basic_event_blink <= 24'd0;
        end else begin
            if (basic_freq_zero_reject || basic_dds_recovered)
                basic_event_blink <= LED_BLINK_TICKS;
            else if (basic_event_blink != 24'd0)
                basic_event_blink <= basic_event_blink - 24'd1;
        end
    end

    assign led0 = (dds_fword != 32'd0);
    assign led1 = adc_spi_active;
    assign led2 = active_path_is_arb;
    assign led3 = (basic_event_blink != 24'd0) | por_rst;

    // DDS command enum
    localparam [31:0] DDS_CMD_NOP          = 32'd0;
    localparam [31:0] DDS_CMD_SET_FREQ     = 32'd1;
    localparam [31:0] DDS_CMD_START_SWEEP  = 32'd2;
    localparam [31:0] DDS_CMD_STOP         = 32'd3;
    localparam [31:0] DDS_CMD_SET_SINGLE   = 32'd4;
    localparam [31:0] DDS_CMD_RECON_WAVE   = 32'd20;
    localparam [31:0] DDS_CMD_OUTPUT_RECON = 32'd21;

    integer pi;
    integer wi;
    reg [7:0] pchk;

    wire [7:0] adc_rx_frame_type = adc_spi_rx_frame[2*8 +: 8];
    wire [31:0] adc_rx_cmd_seq = {
        adc_spi_rx_frame[7*8 +: 8], adc_spi_rx_frame[6*8 +: 8],
        adc_spi_rx_frame[5*8 +: 8], adc_spi_rx_frame[4*8 +: 8]};
    wire [31:0] adc_rx_cmd = {
        adc_spi_rx_frame[11*8 +: 8], adc_spi_rx_frame[10*8 +: 8],
        adc_spi_rx_frame[9*8 +: 8],  adc_spi_rx_frame[8*8 +: 8]};
    wire [31:0] adc_rx_cmd_freq = {
        adc_spi_rx_frame[15*8 +: 8], adc_spi_rx_frame[14*8 +: 8],
        adc_spi_rx_frame[13*8 +: 8], adc_spi_rx_frame[12*8 +: 8]};
    wire [31:0] adc_rx_cmd_ampl = {
        adc_spi_rx_frame[19*8 +: 8], adc_spi_rx_frame[18*8 +: 8],
        adc_spi_rx_frame[17*8 +: 8], adc_spi_rx_frame[16*8 +: 8]};
    wire [31:0] adc_rx_cmd_phase = {
        adc_spi_rx_frame[23*8 +: 8], adc_spi_rx_frame[22*8 +: 8],
        adc_spi_rx_frame[21*8 +: 8], adc_spi_rx_frame[20*8 +: 8]};
    wire [31:0] adc_rx_start_freq = {
        adc_spi_rx_frame[27*8 +: 8], adc_spi_rx_frame[26*8 +: 8],
        adc_spi_rx_frame[25*8 +: 8], adc_spi_rx_frame[24*8 +: 8]};
    wire [31:0] adc_rx_stop_freq = {
        adc_spi_rx_frame[31*8 +: 8], adc_spi_rx_frame[30*8 +: 8],
        adc_spi_rx_frame[29*8 +: 8], adc_spi_rx_frame[28*8 +: 8]};
    wire [31:0] adc_rx_step_freq = {
        adc_spi_rx_frame[35*8 +: 8], adc_spi_rx_frame[34*8 +: 8],
        adc_spi_rx_frame[33*8 +: 8], adc_spi_rx_frame[32*8 +: 8]};
    wire [31:0] adc_rx_mode = {
        adc_spi_rx_frame[39*8 +: 8], adc_spi_rx_frame[38*8 +: 8],
        adc_spi_rx_frame[37*8 +: 8], adc_spi_rx_frame[36*8 +: 8]};

    wire [7:0] esp_rx_frame_type = esp_spi_rx_frame[2*8 +: 8];
    wire [31:0] esp_rx_cmd_seq = {
        esp_spi_rx_frame[7*8 +: 8], esp_spi_rx_frame[6*8 +: 8],
        esp_spi_rx_frame[5*8 +: 8], esp_spi_rx_frame[4*8 +: 8]};
    wire [31:0] esp_rx_cmd = {
        esp_spi_rx_frame[11*8 +: 8], esp_spi_rx_frame[10*8 +: 8],
        esp_spi_rx_frame[9*8 +: 8],  esp_spi_rx_frame[8*8 +: 8]};
    wire [31:0] esp_rx_cmd_freq = {
        esp_spi_rx_frame[15*8 +: 8], esp_spi_rx_frame[14*8 +: 8],
        esp_spi_rx_frame[13*8 +: 8], esp_spi_rx_frame[12*8 +: 8]};
    wire [31:0] esp_rx_cmd_ampl = {
        esp_spi_rx_frame[19*8 +: 8], esp_spi_rx_frame[18*8 +: 8],
        esp_spi_rx_frame[17*8 +: 8], esp_spi_rx_frame[16*8 +: 8]};

    // Effective D4 sample count after clipping to 30 samples, current
    // arbitrary-wave sample_count, and the physical arbitrary-wave RAM size.
    wire [31:0] d4_room_to_sample_count =
        (esp_rx_cmd_freq < arb_sample_count) ? (arb_sample_count - esp_rx_cmd_freq) : 32'd0;

    wire [31:0] d4_room_to_ram_end =
        (esp_rx_cmd_freq < ARB_RAM_DEPTH) ? (ARB_RAM_DEPTH - esp_rx_cmd_freq) : 32'd0;

    wire [31:0] d4_room =
        (d4_room_to_sample_count < d4_room_to_ram_end) ?
        d4_room_to_sample_count : d4_room_to_ram_end;

    wire [31:0] d4_count_limit =
        (esp_rx_cmd_ampl < 32'd30) ? esp_rx_cmd_ampl : 32'd30;

    wire [31:0] d4_effective_count =
        (d4_count_limit < d4_room) ? d4_count_limit : d4_room;

    function [13:0] arb_sample_to_dac;
        input signed [15:0] s;
        reg signed [17:0] sample_ext;
        reg signed [17:0] code;
        begin
            // The reconstructed ADC waveform already arrives as a centered
            // signed sample. Do not attenuate it here; small IFFT outputs
            // otherwise collapse into a near-DC DAC code.
            sample_ext = {{2{s[15]}}, s};
            code = 18'sd8192 + sample_ext;
            if (code < 18'sd0)
                arb_sample_to_dac = 14'd0;
            else if (code > 18'sd16383)
                arb_sample_to_dac = 14'd16383;
            else
                arb_sample_to_dac = code[13:0];
        end
    endfunction

    function [31:0] freq_hz_to_fword;
        input [31:0] freq_hz;
        reg [63:0] product_q20;
        begin
            // round(freq_hz * 2^32 / 25_000_000)
            // 2^32 / 25 MHz = 171.79869184 = 180143985 / 2^20.
            product_q20 = ({32'd0, freq_hz} * 64'd180143985) + 64'd524288;
            freq_hz_to_fword = product_q20 >> 20;
        end
    endfunction

    function [31:0] sample_rate_hz_to_step_clks;
        input [31:0] sample_rate_hz;
        begin
            // Keep this as a small lookup table, not a variable divider.
            // ARB clock is 125 MHz, so step = 125000000 / sample_rate_hz.
            if (sample_rate_hz == 32'd100000)
                sample_rate_hz_to_step_clks = 32'd1250;
            else if (sample_rate_hz == 32'd200000)
                sample_rate_hz_to_step_clks = 32'd625;
            else if (sample_rate_hz == 32'd500000)
                sample_rate_hz_to_step_clks = 32'd250;
            else
                sample_rate_hz_to_step_clks = DEFAULT_ARB_STEP_PERIOD_CLKS;
        end
    endfunction

    always @(posedge clk_125m) begin
        if (por_rst) begin
            dds_cmd_seq    <= 32'd0;
            dds_cmd        <= 32'd0;
            dds_cmd_freq   <= 32'd0;
            dds_cmd_ampl   <= 32'd1000;
            dds_cmd_phase  <= 32'd0;
            dds_start_freq <= 32'd0;
            dds_stop_freq  <= 32'd0;
            dds_step_freq  <= 32'd0;
            dds_mode       <= 32'd0;
            dds_flags      <= 32'd1;
            esp_d2_seq     <= 32'd0;
            esp_d2_cmd     <= 32'd0;
            esp_d2_freq    <= 32'd0;
            esp_d2_flags   <= 32'd1;
            dds_cmd_accepted <= 1'b0;
            esp_cmd_accepted <= 1'b0;
            spi_frame_err  <= 1'b0;
            last_cmd_seq   <= 32'hFFFFFFFF;
            dds_fword      <= freq_hz_to_fword(32'd1000);
            dds_phase_reset <= 1'b0;
            last_valid_freq_hz <= 32'd1000;
            last_valid_fword <= freq_hz_to_fword(32'd1000);
            basic_dds_watchdog <= 32'd0;
            basic_dds_recover_count <= 32'd0;
            basic_dds_recovered <= 1'b0;
            basic_freq_zero_reject <= 1'b0;
            arb_mode <= 1'b0;
            arb_receiving <= 1'b0;
            arb_playing <= 1'b0;
            output_owner_arb <= 1'b0;
            esp_arb_output_enable <= 1'b0;
            arb_stuck_watchdog <= 32'd0;
            arb_last_progress <= 32'd0;
            arb_sample_count <= DEFAULT_ARB_SAMPLE_COUNT;
            arb_sample_rate_hz <= DEFAULT_ARB_SAMPLE_RATE_HZ;
            arb_write_count <= 32'd0;
            arb_start_play_pulse <= 1'b0;
            arb_start_pending <= 1'b0;
            arb_step_period_clks <= DEFAULT_ARB_STEP_PERIOD_CLKS;
            d4_write_pending <= 1'b0;
            d4_write_base <= {ARB_ADDR_BITS{1'b0}};
            d4_write_count <= 6'd0;
            d4_write_pos <= 6'd0;
        end else begin
            dds_cmd_accepted <= 1'b0;
            esp_cmd_accepted <= 1'b0;
            spi_frame_err <= 1'b0;
            dds_phase_reset <= 1'b0;
            basic_dds_recovered <= 1'b0;
            basic_freq_zero_reject <= 1'b0;
            arb_start_play_pulse <= 1'b0;

            if (!active_path_is_arb && last_valid_fword != 32'd0) begin
                if (dds_fword == 32'd0) begin
                    if (basic_dds_watchdog >= BASIC_DDS_WATCHDOG_CLKS) begin
                        dds_fword <= last_valid_fword;
                        dds_phase_reset <= 1'b1;
                        basic_dds_recover_count <= basic_dds_recover_count + 32'd1;
                        basic_dds_recovered <= 1'b1;
                        basic_dds_watchdog <= 32'd0;
                        dds_flags <= 32'h00000023;
                        dds_cmd_freq <= last_valid_freq_hz;
                    end else begin
                        basic_dds_watchdog <= basic_dds_watchdog + 32'd1;
                    end
                end else begin
                    basic_dds_watchdog <= 32'd0;
                end
            end else begin
                basic_dds_watchdog <= 32'd0;
            end

            if (arb_receiving || arb_start_pending || d4_write_pending) begin
                if (d4_write_pending) begin
                    arb_stuck_watchdog <= 32'd0;
                    arb_last_progress <= {26'd0, d4_write_pos};
                end else if (arb_write_count != arb_last_progress) begin
                    arb_stuck_watchdog <= 32'd0;
                    arb_last_progress <= arb_write_count;
                end else if (arb_stuck_watchdog < ARB_STUCK_TIMEOUT_CLKS) begin
                    arb_stuck_watchdog <= arb_stuck_watchdog + 32'd1;
                end
            end else begin
                arb_stuck_watchdog <= 32'd0;
                arb_last_progress <= arb_write_count;
            end

            if (arb_stuck_watchdog >= ARB_STUCK_TIMEOUT_CLKS) begin
                arb_mode <= 1'b0;
                arb_receiving <= 1'b0;
                arb_playing <= 1'b0;
                output_owner_arb <= 1'b0;
                esp_arb_output_enable <= 1'b0;
                arb_start_pending <= 1'b0;
                d4_write_pending <= 1'b0;
                d4_write_pos <= 6'd0;
                arb_write_count <= 32'd0;
                arb_stuck_watchdog <= 32'd0;
                esp_d2_flags <= 32'hBAD0DEAD;
            end else if (d4_write_pending) begin
                if ((d4_write_pos + 6'd1) >= d4_write_count) begin
                    d4_write_pending <= 1'b0;
                    d4_write_pos <= 6'd0;
                    if (arb_start_pending && arb_all_samples_received) begin
                        arb_start_pending <= 1'b0;
                        arb_receiving <= 1'b0;
                        arb_playing <= 1'b1;
                        arb_mode <= 1'b1;
                        if (ENABLE_ESP_ARB_DAC_OUTPUT != 0 && esp_arb_output_enable)
                            output_owner_arb <= 1'b1;
                        arb_start_play_pulse <= 1'b1;
                        esp_d2_flags <= 32'h0000000B; // ready + done + playing
                    end
                end else begin
                    d4_write_pos <= d4_write_pos + 6'd1;
                end
            end else if (arb_start_pending && arb_all_samples_received) begin
                arb_start_pending <= 1'b0;
                arb_receiving <= 1'b0;
                arb_playing <= 1'b1;
                arb_mode <= 1'b1;
                if (ENABLE_ESP_ARB_DAC_OUTPUT != 0 && esp_arb_output_enable)
                    output_owner_arb <= 1'b1;
                arb_start_play_pulse <= 1'b1;
                esp_d2_flags <= 32'h0000000B; // ready + done + playing
            end

            if (adc_spi_done) begin
                // PYNQADC owns only the fixed-DDS/sweep control path.
                pchk = 8'd0;
                for (pi = 0; pi < 116; pi = pi + 1)
                    pchk = pchk ^ adc_spi_rx_frame[pi*8 +: 8];

                if (adc_spi_rx_frame[0*8 +: 8]  == 8'hA5 &&
                    adc_spi_rx_frame[1*8 +: 8]  == 8'h5A &&
                    adc_rx_frame_type == 8'hD1 &&
                    adc_spi_rx_frame[3*8 +: 8]  == 8'd112 &&
                    adc_spi_rx_frame[116*8 +: 8] == pchk) begin

                    dds_cmd_seq    <= adc_rx_cmd_seq;
                    dds_cmd_freq   <= adc_rx_cmd_freq;
                    dds_flags      <= 32'd3; // ready + done/accepted

                    if (basic_dds_recovered)
                        dds_flags <= 32'h00000023;

                    dds_cmd        <= adc_rx_cmd;
                    dds_cmd_ampl   <= adc_rx_cmd_ampl;
                    dds_cmd_phase  <= adc_rx_cmd_phase;
                    dds_start_freq <= adc_rx_start_freq;
                    dds_stop_freq  <= adc_rx_stop_freq;
                    dds_step_freq  <= adc_rx_step_freq;
                    dds_mode       <= adc_rx_mode;

                    if (adc_rx_cmd_seq != last_cmd_seq && adc_rx_cmd != DDS_CMD_NOP) begin
                        last_cmd_seq <= adc_rx_cmd_seq;
                        dds_cmd_accepted <= 1'b1;

                        if (adc_rx_cmd == DDS_CMD_SET_FREQ || adc_rx_cmd == DDS_CMD_SET_SINGLE) begin
                            if (adc_rx_cmd_freq != 32'd0) begin
                                dds_fword <= freq_hz_to_fword(adc_rx_cmd_freq);
                                last_valid_fword <= freq_hz_to_fword(adc_rx_cmd_freq);
                                last_valid_freq_hz <= adc_rx_cmd_freq;
                                dds_cmd_freq <= adc_rx_cmd_freq;
                                dds_flags <= 32'd3;
                                basic_freq_zero_reject <= 1'b0;
                            end else begin
                                dds_fword <= last_valid_fword;
                                dds_cmd_freq <= last_valid_freq_hz;
                                dds_flags <= 32'h00000013;
                                basic_freq_zero_reject <= 1'b1;
                            end
                            basic_dds_watchdog <= 32'd0;
                            dds_phase_reset <= 1'b1;
                            output_owner_arb <= 1'b0;
                            esp_arb_output_enable <= 1'b0;
                            arb_playing <= 1'b0;
                            arb_mode <= 1'b0;
                            arb_receiving <= 1'b0;
                            arb_start_pending <= 1'b0;
                            d4_write_pending <= 1'b0;
                            d4_write_pos <= 6'd0;
                        end else if (adc_rx_cmd == DDS_CMD_STOP) begin
                            // Disabled for keepalive debug: STOP is ACKed but
                            // must not mute DDS, clear RAM state, or change DAC owner.
                        end
                    end
                end else begin
                    spi_frame_err <= 1'b1;
                end
            end

            if (esp_spi_done) begin
                // ESP32-P4 owns the arbitrary-wave RAM and start path.
                pchk = 8'd0;
                for (pi = 0; pi < 116; pi = pi + 1)
                    pchk = pchk ^ esp_spi_rx_frame[pi*8 +: 8];

                if (esp_spi_rx_frame[0*8 +: 8]  == 8'hA5 &&
                    esp_spi_rx_frame[1*8 +: 8]  == 8'h5A &&
                    (esp_rx_frame_type == 8'hD3 ||
                     esp_rx_frame_type == 8'hD4 ||
                     esp_rx_frame_type == 8'hD5) &&
                    esp_spi_rx_frame[3*8 +: 8]  == 8'd112 &&
                    esp_spi_rx_frame[116*8 +: 8] == pchk) begin

                    esp_d2_seq     <= esp_rx_cmd_seq;
                    esp_d2_flags   <= 32'd3; // ready + done/accepted
                    dds_cmd_accepted <= 1'b1;
                    esp_cmd_accepted <= 1'b1;

                    if (esp_rx_frame_type == 8'hD3) begin
                        esp_d2_cmd <= 32'h000000D3;
                        esp_d2_freq <= esp_rx_cmd_freq; // sample_rate_hz
                        esp_arb_output_enable <= (ENABLE_ESP_ARB_DAC_OUTPUT != 0);
                        arb_stuck_watchdog <= 32'd0;
                        arb_last_progress <= 32'd0;
                        arb_receiving <= 1'b1;
                        arb_start_pending <= 1'b0;
                        arb_sample_count <= (SIM_FAST != 0) ? DEFAULT_ARB_SAMPLE_COUNT :
                                            ((esp_rx_cmd == 32'd0 || esp_rx_cmd > ARB_RAM_DEPTH) ? ARB_RAM_DEPTH : esp_rx_cmd);
                        arb_sample_rate_hz <= (esp_rx_cmd_freq == 32'd0) ? DEFAULT_ARB_SAMPLE_RATE_HZ : esp_rx_cmd_freq;
                        arb_step_period_clks <= sample_rate_hz_to_step_clks(
                            (esp_rx_cmd_freq == 32'd0) ? DEFAULT_ARB_SAMPLE_RATE_HZ : esp_rx_cmd_freq);
                        arb_write_count <= 32'd0;
                    end else if (esp_rx_frame_type == 8'hD4) begin
                        esp_d2_cmd <= 32'h000000D4;
                        esp_d2_freq <= esp_rx_cmd_freq; // start index

                        if (arb_receiving && d4_effective_count != 32'd0) begin
                            // Capture this 30-sample chunk into small registers.
                            // The actual wave_ram write is serialized above.
                            for (wi = 0; wi < 30; wi = wi + 1) begin
                                d4_sample_buf[wi] <=
                                    {esp_spi_rx_frame[(21 + wi*2)*8 +: 8],
                                     esp_spi_rx_frame[(20 + wi*2)*8 +: 8]};
                            end

                            d4_write_base <= esp_rx_cmd_freq[ARB_ADDR_BITS-1:0];
                            d4_write_count <= d4_effective_count[5:0];
                            d4_write_pos <= 6'd0;
                            d4_write_pending <= 1'b1;

                            arb_write_count <= esp_rx_cmd_freq + d4_effective_count;
                        end
                    end else if (esp_rx_frame_type == 8'hD5) begin
                        esp_d2_cmd <= 32'h000000D5;
                        esp_d2_freq <= arb_sample_rate_hz;
                        if (!arb_all_samples_received || d4_write_pending) begin
                            arb_start_pending <= 1'b1;
                        end else begin
                            arb_receiving <= 1'b0;
                            arb_playing <= 1'b1;
                            arb_mode <= 1'b1;
                            if (ENABLE_ESP_ARB_DAC_OUTPUT != 0 && esp_arb_output_enable)
                                output_owner_arb <= 1'b1;
                            arb_start_play_pulse <= 1'b1;
                            esp_d2_flags <= 32'h0000000B; // ready + done + playing
                        end
                    end
                end else begin
                    // Debug invalid ESP frames by echoing the first received
                    // bytes in the next D2 ACK:
                    // seq  = rx[3:0], cmd = rx[7:4],
                    // freq = {rx_checksum, calc_checksum, rx_len, rx_type}.
                    esp_d2_seq <= {
                        esp_spi_rx_frame[3*8 +: 8],
                        esp_spi_rx_frame[2*8 +: 8],
                        esp_spi_rx_frame[1*8 +: 8],
                        esp_spi_rx_frame[0*8 +: 8]};
                    esp_d2_cmd <= {
                        esp_spi_rx_frame[7*8 +: 8],
                        esp_spi_rx_frame[6*8 +: 8],
                        esp_spi_rx_frame[5*8 +: 8],
                        esp_spi_rx_frame[4*8 +: 8]};
                    esp_d2_freq <= {
                        esp_spi_rx_frame[116*8 +: 8],
                        pchk,
                        esp_spi_rx_frame[3*8 +: 8],
                        esp_rx_frame_type};
                    esp_d2_flags <= 32'hBAD00001;
                    spi_frame_err <= 1'b1;
                end
            end
        end
    end

    // ============================================================
    // 0xD2 ACK frame builders. ADC and ESP keep independent ACK state so
    // arbitrary-wave traffic cannot disturb basic sweep command polling.
    // ============================================================
    function [1023:0] build_d2_frame;
        input [31:0] seq;
        input [31:0] cmd;
        input [31:0] freq;
        input [31:0] flags;
        integer bi;
        reg [7:0] bchk;
        begin
            build_d2_frame = 1024'd0;
            build_d2_frame[0*8 +: 8] = 8'hA5;
            build_d2_frame[1*8 +: 8] = 8'h5A;
            build_d2_frame[2*8 +: 8] = 8'hD2;
            build_d2_frame[3*8 +: 8] = 8'd112;

            build_d2_frame[4*8 +: 8] = seq[7:0];
            build_d2_frame[5*8 +: 8] = seq[15:8];
            build_d2_frame[6*8 +: 8] = seq[23:16];
            build_d2_frame[7*8 +: 8] = seq[31:24];

            build_d2_frame[8*8 +: 8]  = cmd[7:0];
            build_d2_frame[9*8 +: 8]  = cmd[15:8];
            build_d2_frame[10*8 +: 8] = cmd[23:16];
            build_d2_frame[11*8 +: 8] = cmd[31:24];

            build_d2_frame[12*8 +: 8] = freq[7:0];
            build_d2_frame[13*8 +: 8] = freq[15:8];
            build_d2_frame[14*8 +: 8] = freq[23:16];
            build_d2_frame[15*8 +: 8] = freq[31:24];

            build_d2_frame[16*8 +: 8] = flags[7:0];
            build_d2_frame[17*8 +: 8] = flags[15:8];
            build_d2_frame[18*8 +: 8] = flags[23:16];
            build_d2_frame[19*8 +: 8] = flags[31:24];

            bchk = 8'd0;
            for (bi = 0; bi < 116; bi = bi + 1)
                bchk = bchk ^ build_d2_frame[bi*8 +: 8];
            build_d2_frame[116*8 +: 8] = bchk;
        end
    endfunction

    assign adc_spi_tx_frame = build_d2_frame(dds_cmd_seq, dds_cmd, dds_cmd_freq, dds_flags);
    assign esp_spi_tx_frame = build_d2_frame(esp_d2_seq, esp_d2_cmd, esp_d2_freq, esp_d2_flags);

    // ============================================================
    // Frequency word calculator uses rounded fixed-point conversion above:
    // FWORD = freq_hz * 2^32 / 25_000_000.
    // ============================================================

    // ============================================================
    // DDS Core + AD9767 interface (verified)
    // ============================================================
    wire [13:0] dac_code;
    wire sample_tick;

    dds_core #(
        .FWORD(32'd172),
        .SWEEP_FWORD_MIN(32'd171799),
        .SWEEP_FWORD_MAX(32'd17179869),
        .SWEEP_FWORD_STEP(32'd171799),
        .SWEEP_HOLD_TICKS(32'd250000)
    ) u_dds_core (
        .clk(clk_125m),
        .rst(por_rst),
        .dds_en(1'b1),
        .sample_tick(sample_tick),
        .wave_sel(3'b001),   // sine wave
        .t_group(1'b0),
        .fword(dds_fword),
        .phase_offset(dds_cmd_phase),
        .phase_reset(dds_phase_reset),
        .dac_code(dac_code)
    );

    wire [ARB_ADDR_BITS-1:0] arb_last_index =
        (arb_sample_count >= ARB_RAM_DEPTH) ? {ARB_ADDR_BITS{1'b1}} :
        (arb_sample_count[ARB_ADDR_BITS-1:0] == {ARB_ADDR_BITS{1'b0}} ?
         {ARB_ADDR_BITS{1'b0}} : (arb_sample_count[ARB_ADDR_BITS-1:0] - {{(ARB_ADDR_BITS-1){1'b0}}, 1'b1}));

    always @(posedge clk_125m) begin
        if (por_rst) begin
            arb_play_index <= {ARB_ADDR_BITS{1'b0}};
            arb_read_addr <= {ARB_ADDR_BITS{1'b0}};
            arb_play_sample <= 16'sd0;
            arb_dac_code <= 14'd8192;
            arb_step_cnt <= 32'd0;
        end else if (arb_start_play_pulse) begin
            arb_read_addr <= {ARB_ADDR_BITS{1'b0}};
            arb_play_index <= {ARB_ADDR_BITS{1'b0}};
            arb_play_sample <= 16'sd0;
            arb_dac_code <= 14'd8192;
            arb_step_cnt <= 32'd0;
        end else if (arb_playing) begin
            if (arb_step_cnt >= (arb_step_period_clks - 32'd1)) begin
                arb_step_cnt <= 32'd0;
                arb_play_sample <= wave_ram_read_data;
                arb_dac_code <= arb_sample_to_dac(wave_ram_read_data);
                if (arb_play_index >= arb_last_index) begin
                    arb_play_index <= {ARB_ADDR_BITS{1'b0}};
                    arb_read_addr <= {ARB_ADDR_BITS{1'b0}};
                end else begin
                    arb_play_index <= arb_play_index + {{(ARB_ADDR_BITS-1){1'b0}}, 1'b1};
                    arb_read_addr <= arb_play_index + {{(ARB_ADDR_BITS-1){1'b0}}, 1'b1};
                end
            end else begin
                arb_step_cnt <= arb_step_cnt + 32'd1;
            end
        end
    end

    wire [13:0] active_dac_code = active_path_is_arb ? arb_dac_code : dac_code;

    ad9767_parallel_if #(
        .CLK_FREQ_HZ(125_000_000),
        .UPDATE_RATE_HZ(25_000_000),
        .DDS_LATENCY_CLKS(3),
        .DATA_SETUP_CLKS(2),
        .PULSE_HIGH_CLKS(2)
    ) u_ad9767_if (
        .clk(clk_125m),
        .rst(por_rst),
        .sample_data(active_dac_code),
        .dac_data(dac_data),
        .dac_clk(dac_clk),
        .dac_wrt(dac_wrt),
        .sample_tick(sample_tick)
    );

endmodule

module arb_wave_ram #(
    parameter integer ADDR_BITS = 12,
    parameter integer DEPTH = 4096
) (
    input  wire                      clk,
    input  wire                      we,
    input  wire [ADDR_BITS-1:0]      waddr,
    input  wire signed [15:0]        wdata,
    input  wire [ADDR_BITS-1:0]      raddr,
    output reg  signed [15:0]        rdata
);

    (* ram_style = "block" *) reg signed [15:0] ram [0:DEPTH-1];

    always @(posedge clk) begin
        if (we)
            ram[waddr] <= wdata;
        rdata <= ram[raddr];
    end

endmodule

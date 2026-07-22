`timescale 1 ns / 1 ps

// LTC2208 dual-channel capture front end.
// The ADC domain runs at 130 MHz. Two 32-bit samples are packed into one
// 64-bit AXI stream beat so the 125 MHz DMA side has sustainable bandwidth.
module ltc2208_capture_axi #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 7,
    // Verified default capture limit. The stream itself is not BRAM-buffered;
    // a later DMA BTT validation can raise this without changing the sampler.
    parameter integer MAX_SAMPLE_N = 262144
) (
    input  wire S_AXI_ACLK,
    input  wire S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire [2:0] S_AXI_AWPROT,
    input  wire S_AXI_AWVALID,
    output reg  S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire S_AXI_WVALID,
    output reg  S_AXI_WREADY,
    output reg  [1:0] S_AXI_BRESP,
    output reg  S_AXI_BVALID,
    input  wire S_AXI_BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire [2:0] S_AXI_ARPROT,
    input  wire S_AXI_ARVALID,
    output reg  S_AXI_ARREADY,
    output reg  [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg  [1:0] S_AXI_RRESP,
    output reg  S_AXI_RVALID,
    input  wire S_AXI_RREADY,

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ADC_CLK_130 CLK" *)
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 130000000" *)
    input  wire adc_clk_130,
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ADC_CAPTURE_CLK_130 CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXIS_SAMPLE, FREQ_HZ 130000000" *)
    input  wire adc_capture_clk_130,
    input  wire adc_clock_locked,
    input  wire [15:0] ltc_a_data,
    input  wire [15:0] ltc_b_data,
    output wire ltc_a_clk,
    output wire ltc_b_clk,

    output wire [63:0] M_AXIS_SAMPLE_TDATA,
    output wire M_AXIS_SAMPLE_TVALID,
    input  wire M_AXIS_SAMPLE_TREADY,
    output wire M_AXIS_SAMPLE_TLAST,
    output wire [7:0] M_AXIS_SAMPLE_TKEEP
);
    localparam [31:0] VERSION_VALUE = 32'h22081300;
    localparam [5:0] REG_CTRL = 6'h00;
    localparam [5:0] REG_STATUS = 6'h01;
    localparam [5:0] REG_SAMPLE_COUNT = 6'h02;
    localparam [5:0] REG_ADC_HALF = 6'h03;
    localparam [5:0] REG_SAMPLE_DELAY = 6'h04;
    localparam [5:0] REG_DECIMATION = 6'h05;
    localparam [5:0] REG_CHANNEL_MASK = 6'h06;
    localparam [5:0] REG_CAPTURE_MODE = 6'h07;
    localparam [5:0] REG_TRIGGER_MODE = 6'h08;
    localparam [5:0] REG_PRE_DELAY = 6'h09;
    localparam [5:0] REG_BUFFER_SELECT = 6'h0A;
    localparam [5:0] REG_LATEST_A = 6'h0B;
    localparam [5:0] REG_LATEST_B = 6'h0C;
    localparam [5:0] REG_SAMPLE_COUNTER = 6'h0D;
    localparam [5:0] REG_FIFO_LEVEL = 6'h0E;
    localparam [5:0] REG_ERROR_FLAGS = 6'h0F;
    localparam [5:0] REG_VERSION = 6'h11;
    localparam [5:0] REG_SAVED_COUNTER = 6'h12;
    localparam [5:0] REG_LAST_SAMPLE_WORD = 6'h13;
    localparam [5:0] REG_DEBUG_STATE = 6'h14;
    localparam [5:0] REG_AXIS_SENT_COUNT = 6'h15;
    localparam [5:0] REG_AXIS_STALL_COUNT = 6'h16;
    localparam [5:0] REG_TLAST_COUNT = 6'h17;
    localparam [5:0] REG_FIFO_BACKPRESSURE = 6'h18;
    localparam [5:0] REG_DROPPED_SAMPLE_COUNT = 6'h19;
    localparam [5:0] REG_CAPTURE_DONE = 6'h1A;
    localparam [5:0] REG_CORE_DONE = 6'h1B;

    reg enable_cfg, start_toggle_cfg, clear_toggle_cfg, soft_reset_cfg;
    reg [31:0] sample_count_cfg, pre_delay_cfg;
    reg [15:0] decimation_cfg;
    reg [1:0] channel_mask_cfg, capture_mode_cfg, trigger_mode_cfg;
    wire write_fire = S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WREADY && S_AXI_WVALID;
    wire read_fire = S_AXI_ARREADY && S_AXI_ARVALID && !S_AXI_RVALID;
    wire [5:0] write_index = {1'b0, S_AXI_AWADDR[6:2]};
    wire [5:0] read_index = {1'b0, S_AXI_ARADDR[6:2]};

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0; S_AXI_WREADY <= 1'b0; S_AXI_BVALID <= 1'b0; S_AXI_BRESP <= 2'b00;
        end else begin
            S_AXI_AWREADY <= !S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID;
            S_AXI_WREADY <= !S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWVALID;
            if (write_fire) S_AXI_BVALID <= 1'b1;
            else if (S_AXI_BVALID && S_AXI_BREADY) S_AXI_BVALID <= 1'b0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            enable_cfg <= 1'b0; start_toggle_cfg <= 1'b0; clear_toggle_cfg <= 1'b0; soft_reset_cfg <= 1'b0;
            sample_count_cfg <= 32'd32768; decimation_cfg <= 16'd1; channel_mask_cfg <= 2'b11;
            capture_mode_cfg <= 2'd1; trigger_mode_cfg <= 2'd0; pre_delay_cfg <= 32'd0;
        end else if (write_fire) begin
            case (write_index)
                REG_CTRL: begin
                    enable_cfg <= S_AXI_WDATA[0];
                    if (S_AXI_WDATA[1]) start_toggle_cfg <= ~start_toggle_cfg;
                    if (S_AXI_WDATA[2]) clear_toggle_cfg <= ~clear_toggle_cfg;
                    soft_reset_cfg <= S_AXI_WDATA[6];
                end
                REG_SAMPLE_COUNT: sample_count_cfg <= S_AXI_WDATA;
                REG_DECIMATION: decimation_cfg <= S_AXI_WDATA[15:0];
                REG_CHANNEL_MASK: channel_mask_cfg <= S_AXI_WDATA[1:0];
                REG_CAPTURE_MODE: capture_mode_cfg <= S_AXI_WDATA[1:0];
                REG_TRIGGER_MODE: trigger_mode_cfg <= S_AXI_WDATA[1:0];
                REG_PRE_DELAY: pre_delay_cfg <= S_AXI_WDATA;
                default: begin end
            endcase
        end
    end

    (* IOB = "TRUE" *) reg [15:0] a_iob;
    (* IOB = "TRUE" *) reg [15:0] b_iob;
    always @(posedge adc_capture_clk_130) begin
        a_iob <= ltc_a_data;
        b_iob <= ltc_b_data;
    end

`ifndef SYNTHESIS
    assign ltc_a_clk = (enable_cfg && adc_clock_locked) ? adc_clk_130 : 1'b0;
    assign ltc_b_clk = (enable_cfg && adc_clock_locked) ? adc_clk_130 : 1'b0;
`else
    ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE"), .INIT(1'b0), .SRTYPE("SYNC")) ltc_a_clk_oddr (
        .Q(ltc_a_clk), .C(adc_clk_130), .CE(1'b1), .D1(1'b1), .D2(1'b0),
        .R(!S_AXI_ARESETN || !enable_cfg || !adc_clock_locked), .S(1'b0));
    ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE"), .INIT(1'b0), .SRTYPE("SYNC")) ltc_b_clk_oddr (
        .Q(ltc_b_clk), .C(adc_clk_130), .CE(1'b1), .D1(1'b1), .D2(1'b0),
        .R(!S_AXI_ARESETN || !enable_cfg || !adc_clock_locked), .S(1'b0));
`endif

    (* ASYNC_REG = "TRUE" *) reg [1:0] start_sync, clear_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] enable_sync, reset_sync;
    reg start_seen, clear_seen;
    reg busy_130, done_130, error_130, have_first;
    reg [31:0] count_130, saved_130, dropped_130, axis_sent_130, axis_stall_130, tlast_130;
    reg [15:0] decim_count_130, decimation_run;
    reg [31:0] target_run;
    reg [1:0] mask_run, mode_run;
    reg [31:0] first_word, latest_a_130, latest_b_130, last_word_130;
    reg [63:0] axis_data_130;
    reg axis_valid_130, axis_last_130;
    reg [7:0] axis_keep_130;
    wire can_emit = !axis_valid_130 || M_AXIS_SAMPLE_TREADY;
    wire [31:0] current_word = {
        mask_run[1] ? b_iob : 16'd0,
        mask_run[0] ? a_iob : 16'd0
    };
    wire [31:0] fake_word = {16'hFFFF - count_130[15:0], count_130[15:0]};
    wire [31:0] sample_word = (mode_run == 2'd2) ? fake_word : current_word;
    wire [31:0] target_clamped = (sample_count_cfg == 0) ? 32'd1 :
                                 (sample_count_cfg > MAX_SAMPLE_N) ? MAX_SAMPLE_N : sample_count_cfg;
    wire [15:0] decim_clamped = (decimation_cfg == 0) ? 16'd1 : decimation_cfg;

    always @(posedge adc_capture_clk_130 or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            start_sync <= 2'b00; clear_sync <= 2'b00; enable_sync <= 2'b00; reset_sync <= 2'b00;
            start_seen <= 1'b0; clear_seen <= 1'b0; busy_130 <= 1'b0; done_130 <= 1'b0; error_130 <= 1'b0;
            have_first <= 1'b0; count_130 <= 0; saved_130 <= 0; dropped_130 <= 0; axis_sent_130 <= 0;
            axis_stall_130 <= 0; tlast_130 <= 0; decim_count_130 <= 0; target_run <= 1; decimation_run <= 1;
            mask_run <= 2'b11; mode_run <= 2'd1; first_word <= 0; latest_a_130 <= 0; latest_b_130 <= 0;
            last_word_130 <= 0; axis_data_130 <= 0; axis_valid_130 <= 1'b0; axis_last_130 <= 1'b0; axis_keep_130 <= 8'hFF;
        end else begin
            start_sync <= {start_sync[0], start_toggle_cfg}; clear_sync <= {clear_sync[0], clear_toggle_cfg};
            enable_sync <= {enable_sync[0], enable_cfg}; reset_sync <= {reset_sync[0], soft_reset_cfg};
            if (axis_valid_130 && M_AXIS_SAMPLE_TREADY) begin
                axis_valid_130 <= 1'b0;
                axis_sent_130 <= axis_sent_130 + 1'b1;
                if (axis_last_130) tlast_130 <= tlast_130 + 1'b1;
            end else if (axis_valid_130 && !M_AXIS_SAMPLE_TREADY) begin
                axis_stall_130 <= axis_stall_130 + 1'b1;
            end
            if (clear_sync[1] != clear_seen || reset_sync[1]) begin
                clear_seen <= clear_sync[1]; busy_130 <= 1'b0; done_130 <= 1'b0; error_130 <= 1'b0;
                have_first <= 1'b0; count_130 <= 0; saved_130 <= 0; dropped_130 <= 0; axis_sent_130 <= 0;
                axis_stall_130 <= 0; tlast_130 <= 0; axis_valid_130 <= 1'b0;
            end else if (start_sync[1] != start_seen) begin
                start_seen <= start_sync[1]; have_first <= 1'b0; count_130 <= 0; saved_130 <= 0; dropped_130 <= 0;
                axis_sent_130 <= 0; axis_stall_130 <= 0; tlast_130 <= 0; axis_valid_130 <= 1'b0; done_130 <= 1'b0; error_130 <= 1'b0;
                target_run <= target_clamped; decimation_run <= decim_clamped;
                mask_run <= (channel_mask_cfg == 0) ? 2'b11 : channel_mask_cfg; mode_run <= capture_mode_cfg; decim_count_130 <= 0;
                busy_130 <= enable_sync[1] && (capture_mode_cfg == 2'd1 || capture_mode_cfg == 2'd2) && adc_clock_locked;
            end else if (busy_130) begin
                if (decim_count_130 + 1 < decimation_run) begin
                    decim_count_130 <= decim_count_130 + 1'b1;
                end else begin
                    decim_count_130 <= 0;
                    latest_a_130 <= a_iob; latest_b_130 <= b_iob; saved_130 <= saved_130 + 1'b1;
                    if (!have_first) begin
                        first_word <= sample_word; have_first <= 1'b1; count_130 <= count_130 + 1'b1;
                        if (count_130 + 1 >= target_run) begin
                            if (can_emit) begin
                                axis_data_130 <= {32'd0, sample_word}; axis_keep_130 <= 8'h0F; axis_last_130 <= 1'b1; axis_valid_130 <= 1'b1;
                            end else begin
                                dropped_130 <= dropped_130 + 1'b1; error_130 <= 1'b1;
                            end
                            busy_130 <= 1'b0; done_130 <= 1'b1; have_first <= 1'b0; last_word_130 <= sample_word;
                        end
                    end else begin
                        count_130 <= count_130 + 1'b1; have_first <= 1'b0; last_word_130 <= sample_word;
                        if (can_emit) begin
                            axis_data_130 <= {sample_word, first_word}; axis_keep_130 <= 8'hFF;
                            axis_last_130 <= (count_130 + 1 >= target_run); axis_valid_130 <= 1'b1;
                        end else begin
                            dropped_130 <= dropped_130 + 2; error_130 <= 1'b1;
                        end
                        if (count_130 + 1 >= target_run) begin busy_130 <= 1'b0; done_130 <= 1'b1; end
                    end
                end
            end
        end
    end

    (* ASYNC_REG = "TRUE" *) reg [1:0] busy_sync, done_sync, error_sync;
    reg [31:0] count_meta, count_ps, saved_meta, saved_ps, drop_meta, drop_ps, sent_meta, sent_ps, stall_meta, stall_ps, last_meta, last_ps;
    reg [15:0] a_meta, a_ps, b_meta, b_ps;
    always @(posedge S_AXI_ACLK) begin
        busy_sync <= {busy_sync[0], busy_130}; done_sync <= {done_sync[0], done_130}; error_sync <= {error_sync[0], error_130};
        count_meta <= count_130; count_ps <= count_meta; saved_meta <= saved_130; saved_ps <= saved_meta;
        drop_meta <= dropped_130; drop_ps <= drop_meta; sent_meta <= axis_sent_130; sent_ps <= sent_meta;
        stall_meta <= axis_stall_130; stall_ps <= stall_meta; last_meta <= last_word_130; last_ps <= last_meta;
        a_meta <= latest_a_130[15:0]; a_ps <= a_meta; b_meta <= latest_b_130[15:0]; b_ps <= b_meta;
    end

    wire [31:0] status_word = {24'd0, error_sync[1], 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, done_sync[1], busy_sync[1]};
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin S_AXI_ARREADY <= 1'b0; S_AXI_RVALID <= 1'b0; S_AXI_RRESP <= 2'b00; S_AXI_RDATA <= 0; end
        else begin
            S_AXI_ARREADY <= !S_AXI_ARREADY && S_AXI_ARVALID;
            if (read_fire) begin
                S_AXI_RVALID <= 1'b1; S_AXI_RRESP <= 2'b00;
                case (read_index)
                    REG_CTRL: S_AXI_RDATA <= {25'd0, soft_reset_cfg, 3'd0, 1'b0, 1'b0, enable_cfg};
                    REG_STATUS: S_AXI_RDATA <= status_word;
                    REG_SAMPLE_COUNT: S_AXI_RDATA <= sample_count_cfg;
                    REG_ADC_HALF: S_AXI_RDATA <= 16'd1;
                    REG_SAMPLE_DELAY: S_AXI_RDATA <= 0;
                    REG_DECIMATION: S_AXI_RDATA <= decimation_cfg;
                    REG_CHANNEL_MASK: S_AXI_RDATA <= channel_mask_cfg;
                    REG_CAPTURE_MODE: S_AXI_RDATA <= capture_mode_cfg;
                    REG_TRIGGER_MODE: S_AXI_RDATA <= trigger_mode_cfg;
                    REG_PRE_DELAY: S_AXI_RDATA <= pre_delay_cfg;
                    REG_LATEST_A: S_AXI_RDATA <= {16'd0, a_ps};
                    REG_LATEST_B: S_AXI_RDATA <= {16'd0, b_ps};
                    REG_SAMPLE_COUNTER: S_AXI_RDATA <= count_ps;
                    REG_ERROR_FLAGS: S_AXI_RDATA <= {31'd0, error_sync[1]};
                    REG_VERSION: S_AXI_RDATA <= VERSION_VALUE;
                    REG_SAVED_COUNTER: S_AXI_RDATA <= saved_ps;
                    REG_LAST_SAMPLE_WORD: S_AXI_RDATA <= last_ps;
                    REG_DEBUG_STATE: S_AXI_RDATA <= {29'd0, busy_sync[1] ? 3'd3 : (done_sync[1] ? 3'd4 : 3'd0)};
                    REG_AXIS_SENT_COUNT: S_AXI_RDATA <= sent_ps;
                    REG_AXIS_STALL_COUNT: S_AXI_RDATA <= stall_ps;
                    REG_TLAST_COUNT: S_AXI_RDATA <= tlast_130;
                    REG_FIFO_BACKPRESSURE: S_AXI_RDATA <= {31'd0, (stall_ps != 0)};
                    REG_DROPPED_SAMPLE_COUNT: S_AXI_RDATA <= drop_ps;
                    REG_CAPTURE_DONE: S_AXI_RDATA <= {31'd0, done_sync[1]};
                    REG_CORE_DONE: S_AXI_RDATA <= {31'd0, done_sync[1]};
                    default: S_AXI_RDATA <= 0;
                endcase
            end else if (S_AXI_RVALID && S_AXI_RREADY) S_AXI_RVALID <= 1'b0;
        end
    end

    assign M_AXIS_SAMPLE_TDATA = axis_data_130;
    assign M_AXIS_SAMPLE_TVALID = axis_valid_130;
    assign M_AXIS_SAMPLE_TLAST = axis_last_130;
    assign M_AXIS_SAMPLE_TKEEP = axis_keep_130;
endmodule

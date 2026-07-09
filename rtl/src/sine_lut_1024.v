`timescale 1 ns / 1 ps

module sine_lut_1024 (
    input  wire        clk,
    input  wire [9:0]  addr,
    output reg  [13:0] dout
);
    (* rom_style = "block" *) reg [13:0] rom [0:1023];

    initial begin
        $readmemh("sine_lut_1024x14.mem", rom);
    end

    always @(posedge clk) begin
        dout <= rom[addr];
    end
endmodule

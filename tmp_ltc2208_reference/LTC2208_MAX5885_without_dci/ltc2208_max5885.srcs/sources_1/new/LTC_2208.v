module LTC_2208 (
    input                    sys_rst_n    ,
    input                    adc_dci      ,
    input      signed [15:0] adc_dai      ,
    output reg signed [15:0] adc_data
);

always @(posedge adc_dci)begin
    if (!sys_rst_n) begin
        adc_data<=0;
    end
    else begin
        adc_data <= adc_dai;
    end
end

endmodule
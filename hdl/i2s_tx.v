module i2s_tx #(
    parameter PDATA_WIDTH = 32
) (
    input wire arstn_in,

    input wire lrck_in,
    input wire sclk_in,

    output wire sdata_out,

    input wire [PDATA_WIDTH - 1 : 0] pldata_in,
    input wire [PDATA_WIDTH - 1 : 0] prdata_in
);

    // LRCK delayed by 1 SCLK cyle
    reg lrck_d1_int;
    // LRCK delayed by 2 SCLK cycles
    reg lrck_d2_int;

    always @(posedge sclk_in, negedge arstn_in)
        begin
            if (arstn_in == 1'b0)
                begin
                    lrck_d1_int <= 1'b0;
                    lrck_d2_int <= 1'b0;
                end
            else
                begin
                    lrck_d1_int <= lrck_in;
                    lrck_d2_int <= lrck_d1_int;
                end
        end

    // LRCK pulse
    wire lrck_p_int;

    assign lrck_p_int = lrck_d1_int ^ lrck_d2_int;

    // Select channel
    reg [PDATA_WIDTH - 1 : 0] pdata_int;

    always @(lrck_d1_int, pldata_in, prdata_in)
        begin
            if (lrck_d1_int)
                pdata_int = prdata_in;
            else
                pdata_int = pldata_in;
        end

    // PISO (Parallel-In, Serial-Out)
    reg [PDATA_WIDTH - 1 : 0] piso_int;

    always @(negedge sclk_in, negedge arstn_in)
        begin
            if (arstn_in == 1'b0)
                piso_int <= { PDATA_WIDTH { 1'b0 } };
            else
                begin
                    if (lrck_p_int)
                        piso_int <= pdata_int;
                    else
                        piso_int <= { piso_int[PDATA_WIDTH - 2 : 0], 1'b0 };
                end
        end

    // Serial data
    assign sdata_out = piso_int[PDATA_WIDTH - 1 : PDATA_WIDTH - 1];

endmodule

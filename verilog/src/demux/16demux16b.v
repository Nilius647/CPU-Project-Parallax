module _16demux16b (
    input  [15:0] y,
    input  [3:0]  sel,
    output reg [255:0] out
);
    always @(*) begin
        for (integer index = 0; index < 16; index = index + 1) begin
            if (index == sel)
                out[index*16 +: 16]  = y;
            else
                out[index*16 +: 16]  = 16'h0000;
        end
    end
endmodule
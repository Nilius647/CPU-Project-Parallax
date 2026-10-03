module _2demux16b (
    input [15:0] y,
    input sel,
    output reg [15:0] a, b
);  
    always @(*) begin
        case (sel)
            2'b00: begin a = y; b = 16'h0000; end
            2'b01: begin b = y; a = 16'h0000; end
            default: begin a = 16'h0000; b = 16'h0000; end
        endcase
    end
endmodule
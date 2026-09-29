module _2mux16b (
    input [15:0] a, b,
    input [0:0] sel,
    output reg [15:0] y
);  
    always @(*) begin
        case (sel)
            2'b00: y = a;
            2'b01: y = b;
            default: y = 16'h0000;
        endcase
    end
endmodule
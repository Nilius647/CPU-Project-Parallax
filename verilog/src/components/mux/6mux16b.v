module _6mux16b (
    input [15:0] a, b, c, d, e, f,
    input [2:0] sel,
    output reg [15:0] y
);  
    always @(*) begin
        case (sel)
            3'b000: y = a;
            3'b001: y = b;
            3'b010: y = c;
            3'b011: y = d;
            3'b100: y = e;
            3'b101: y = f;
            default: y = 16'h0000;
        endcase
    end
endmodule
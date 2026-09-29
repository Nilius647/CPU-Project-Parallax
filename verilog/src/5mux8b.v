module _5mux8b (
    input [7:0] a, b, c, d, e,
    input [2:0] sel,
    output reg [7:0] y
);  
    always @(*) begin
        case (sel)
            3'b000: y = a;
            3'b001: y = b;
            3'b010: y = c;
            3'b011: y = d;
            3'b100: y = e;
            default: y = 8'h00;
        endcase
    end
endmodule
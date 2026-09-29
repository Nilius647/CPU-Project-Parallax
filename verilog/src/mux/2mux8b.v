module _2mux8b (
    input [7:0] a, b,
    input [0:0] sel,
    output reg [7:0] y
);  
    always @(*) begin
        case (sel)
            2'b00: y = a;
            2'b01: y = b;
            default: y = 8'h00;
        endcase
    end
endmodule
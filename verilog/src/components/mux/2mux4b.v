module _2mux4b (
    input [3:0] a, b,
    input sel,
    output reg [3:0] y
);  
    always @(*) begin
        case (sel)
            2'b00: y = a;
            2'b01: y = b;
            default: y = 4'h0;
        endcase
    end
endmodule
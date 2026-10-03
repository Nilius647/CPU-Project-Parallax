module _16mux16b (
    input [15:0] a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p,
    input [3:0] sel,
    output reg [15:0] y
);  
    always @(*) begin
        case (sel)
            4'b0000: y = a;
            4'b0001: y = b;
            4'b0010: y = c;
            4'b0011: y = d;
            4'b0100: y = e;
            4'b0101: y = f;
            4'b0110: y = g;
            4'b0111: y = h;
            4'b1000: y = i;
            4'b1001: y = j;
            4'b1010: y = k;
            4'b1011: y = l;
            4'b1100: y = m;
            4'b1101: y = n;
            4'b1110: y = o;
            4'b1111: y = p;
            default: y = 16'h0000;
        endcase
    end
endmodule
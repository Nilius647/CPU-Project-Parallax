module ALU (
    input wire enable_flags,
    input wire [3:0] operation,
    input wire [15:0] a, b,
    output reg [7:0] flags,
    output reg [15:0] out
);
    reg [16:0] temp_add;
    reg [31:0] temp_mul;
    reg [7:0] internal;
    always @(*) begin
        case (operation)
            4'b0000: temp_add = a + b;
            4'b0001: temp_add = a - b;
            4'b0010: out = ~a;
            4'b0011: out = a & b;
            4'b0100: out = a | b;
            4'b0101: out = a ^ b;
            4'b0110: out = a ~& b;
            4'b0111: out = a ~| b;
            4'b1000: out = a ~^ b;
            4'b1001: out = ~a | b;
            4'b1010: out = a & ~b;
            4'b1011: out = a * 2;
            4'b1100: out = a / 2;
            4'b1101: out = a + 1;
            4'b1110: out = a - 1;
            4'b1111: temp_mul = a * b;
        endcase
        if (operation == 4'b0000 || operation == 4'b0001) begin
            internal[0] = temp_add[16] == 1 ? 1 : 0;
            out = temp_add;
        end else if (operation == 4'b1111) begin
            internal[7] = temp_mul[31:16] > 0 ? 1 : 0;
            out = temp_mul;
        end else begin
            internal[0] = 0;
            internal[7] = 0;
        end
        if (enable_flags) begin
            internal[1] = a > b ? 1 : 0;
            internal[2] = a == b ? 1 : 0;
            internal[3] = a < b ? 1 : 0;
            internal[4] = out == 16'b0000 ? 1 : 0;
            internal[5] = ~internal[0];
            internal[6] = ~internal[4];
        end
        flags = internal;
    end
endmodule
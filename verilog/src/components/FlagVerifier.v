module FlagVerifier (
    input wire clk,
    input wire rst,
    input wire [7:0] flags,
    input wire [3:0] condition,
    output reg condition_true
);
    reg [7:0] internal;
    always @(posedge clk) begin
        if (rst)
            internal <= 8'h00;
        else if (|flags)
            internal <= flags;
    end
    always @(*) begin
        condition_true = 0;
        if (condition <= 4'b0111) begin
            if (internal[condition] == 1)
                condition_true = 1;
        end
    end
endmodule
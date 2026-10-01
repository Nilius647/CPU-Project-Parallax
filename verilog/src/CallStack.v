module CallStack (
    input wire clk,
    input wire rst,
    input wire call,
    input wire return,
    input wire [7:0] address_in,
    output reg [7:0] address_out
);
    reg [7:0] stack [0:15];
    reg [3:0] counter = 0;
    always @(posedge clk) begin
        if (rst)
            counter <= 0;
        else if (call) begin
            stack[counter] <= address_in;
            counter <= counter + 1;
        end else if (return)
            counter <= counter - 1;
    end 
    always @(*) begin
        if (return)
            address_out = stack [counter - 1];
        else
            address_out = 16'h0000;
    end
endmodule
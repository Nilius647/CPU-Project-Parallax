module CallStack (
    input wire clk,
    input wire rst,
    input wire call,
    input wire ret,
    input wire [15:0] address_in,
    output reg [15:0] address_out
);
    reg [15:0] stack [0:15];
    reg [3:0] counter = 0;
    wire [3:0] top;
    assign top = counter - 4'd1;
    always @(posedge clk) begin
        if (rst)
            counter <= 0;
        else if (call) begin
            stack[counter] <= address_in;
            counter <= counter + 1;
        end else if (ret)
            counter <= counter - 1;
    end 
    always @(*) begin
        if (ret) begin
                address_out = stack[top];
        end else begin
            address_out = 16'h0000;
        end
    end
endmodule
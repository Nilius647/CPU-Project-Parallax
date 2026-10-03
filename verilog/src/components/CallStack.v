module CallStack (
    input wire clk,
    input wire rst,
    input wire call,
    input wire ret,
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
        end else if (ret)
            counter <= counter - 1;
    end 
    always @(*) begin
        if (ret) begin
            if(counter != 0)
                address_out = stack[counter - 1];
            else
                address_out = 0;
        end else begin
            address_out = 8'h00;
        end
    end
endmodule
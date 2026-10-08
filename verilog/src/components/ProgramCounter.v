module ProgramCounter (
    input wire clk,
    input wire rst,
    input wire halt,
    input wire [15:0] address,
    output reg [15:0] address_out,
    output reg [15:0] next_address
);
    always @(posedge clk) begin
        if(rst) begin
            address_out <= 0;
            next_address <= 0;
        end else if (halt) begin
            
        end else begin
            address_out <= address;
            next_address <= (address + 1);
        end
    end
endmodule
module RAM (
    input wire clk,
    input wire write,
    input wire [15:0] address,
    input wire [15:0] data_in,
    output reg [15:0] data_out
);
    reg [15:0] ram [0:1023];
    always @(posedge clk) begin
        if (write)
            ram[address[9:0]] <= data_in;
    end 
    always @(*)
        data_out = ram[address[9:0]];
endmodule
module RAM (
    input wire clk,
    input wire write,
    input wire [15:0] address,
    input wire [15:0] data_in,
    output reg [15:0] data_out
);
    reg [15:0] ram [0:1023];
    initial begin
        for (integer i = 0; i < 1024; i = i + 1)
            ram[1] = 0;
    end
    always @(posedge clk) begin
        if (write)
            ram[address[9:0]] <= data_in;
    end 
    always @(*)
        data_out = ram[address[9:0]];
endmodule
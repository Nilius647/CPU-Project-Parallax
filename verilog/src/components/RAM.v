module RAM #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16,
    parameter RAM_SIZE = 8192,
    parameter ADDR_USED = $clog2(RAM_SIZE)
)(
    input wire clk,
    input wire write,
    input wire [ADDR_WIDTH-1:0] address,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    reg [DATA_WIDTH-1:0] ram [0:RAM_SIZE-1];
    initial begin
        // synopsys translate_off
        for (integer i = 0; i < RAM_SIZE; i = i + 1)
            ram[i] = 0;
        // synopsys translate_on
    end
    always @(posedge clk) begin
        data_out <= ram[address[ADDR_USED-1:0]];
        if (write)
            ram[address[ADDR_USED-1:0]] <= data_in;
    end 
endmodule
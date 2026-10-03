module DRSWregister (
    input wire clk,
    input wire rst,
    input wire write,
    input wire [3:0] addr1, addr2, write_addr,
    input wire [15:0] data,
    output reg [15:0] out1, out2
);
    reg [255:0] internal;
    always @(posedge clk) begin
        if (rst)
            internal <= 0;
        else if (write && write_addr != 0)
            internal[write_addr*16 +: 16] <= data;
    end
    always @(*) begin
        if (addr1 != 0)
            out1 = internal[addr1*16 +: 16];
        else 
            out1 = 0;
        if (addr2 != 0)
            out2 = internal[addr2*16 +: 16];
        else 
            out2 = 0;
    end
endmodule
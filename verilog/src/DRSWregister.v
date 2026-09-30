module DRSWregister (
    input wire clk,
    input wire enable,
    input wire write,
    input wire [7:0] addr1, addr2, write_addr,
    input wire [15:0] data,
    output reg [15:0] out1, out2
);
    reg [255:0] internal;
    always @(posedge clk) begin
        if (enable && write && write_addr != 2'b00)
            internal[write_addr*16 +: 16] <= data;
    end
    always @(*) begin
        if (addr1 != 8'h00)
            out1 = internal[addr1*16 +: 16];
        else 
            out1 = 16'h0000;
        if (addr2 != 8'h00)
            out2 = internal[addr2*16 +: 16];
        else 
            out2 = 16'h0000;
    end
endmodule
module tb_RAM;
    localparam DATA_WIDTH = 16;
    localparam RAM_SIZE = 8192;
    localparam ADDR_WIDTH = 16;
    reg clk;
    reg write;
    reg [ADDR_WIDTH-1:0] address;
    reg [DATA_WIDTH-1:0] data_in;
    wire [DATA_WIDTH-1:0] data_out;
    RAM uut (.clk(clk), .write(write), .address(address), .data_in(data_in), .data_out(data_out));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_RAM);
        write = 1;
        address = 16'h0000;
        data_in = 16'hAAAA;
        @(posedge clk);
        #1;
        write = 0;
        @(posedge clk);
        #1;
        if (data_out !== 16'hAAAA)
            $display("Error: RAM failed!");
        write = 1;
        address = RAM_SIZE;
        data_in = 16'hBBBB;
        @(posedge clk);
        #1;
        write = 0;
        address = 16'h0000;
        @(posedge clk);
        #1;
        if (data_out !== 16'hBBBB)
            $display("Error: wrapping failed!");
        $display("Test finished");
        $finish;
    end
endmodule

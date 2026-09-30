module tb_DRSWregister;
    reg clk;
    reg enable;
    reg write;
    reg [7:0] addr1, addr2, write_addr;
    reg [15:0] data;
    wire [15:0] out1, out2;
    DRSWregister uut (.clk(clk), .enable(enable), .write(write), .addr1(addr1), .addr2(addr2), .write_addr(write_addr), .data(data), .out1(out1), .out2(out2));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_DRSWregister);
        enable = 1;
        write = 1;
        write_addr = 8'h01;
        data = 16'hAAAA;
        @(posedge clk);
        #1;
        write_addr = 8'h02;
        data = 16'hBBBB;
        @(posedge clk);
        #1;
        addr1 = 8'h01;
        addr2 = 8'h02;
        #10;
        if (out1 != 16'hAAAA)
            $display("Error: output 1 doesn't match input data!");
        if (out2 != 16'hBBBB)
            $display("Error: output 2 doesn't match input data!");
        #10;
        write_addr = 8'h00;
        data = 16'hCCCC;
        @(posedge clk);
        #1;
        addr1 = 8'h00;
        #10;
        if (out1 != 16'h0000)
            $display("Error: zero register displays data!");
        $finish;
    end
endmodule
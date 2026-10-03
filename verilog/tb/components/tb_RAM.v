module tb_RAM;
    reg clk;
    reg write;
    reg [15:0] address;
    reg [15:0] data_in;
    wire [15:0] data_out;
    RAM uut (.clk(clk), .write(write), .address(address), .data_in(data_in), .data_out(data_out));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_RAM);
        data_in = 16'hAAAA;
        write = 1;
        address = 16'h0000;
        @(posedge clk);
        #10;
        if (data_out != 16'hAAAA)
            $display("Error: RAM failed!");
        address = 16'h0400;
        data_in = 16'hBBBB;
        @(posedge clk);
        #1;
        address = 16'h0000;
        #10;
        if (data_out != 16'hBBBB)
            $display("Error: wrapping failed!");
        $display("Test finished");
        $finish;
    end
endmodule
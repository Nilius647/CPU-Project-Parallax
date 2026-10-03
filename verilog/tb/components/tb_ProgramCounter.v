module tb_ProgramCunter;
    reg clk;
    reg rst;
    reg halt;
    reg [7:0] address;
    wire [7:0] address_out;
    wire [7:0] next_address;
    ProgramCounter uut (.clk(clk), .rst(rst), .halt(halt), .address(address), .address_out(address_out), .next_address(next_address));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_ProgramCunter);
        rst = 0;
        halt = 0;
        address = 8'h10;
        @(posedge clk);
        #10;
        if (address_out != 8'h10)
            $display("Error: address out failed!");
        if (next_address != 8'h11)
            $display("Error: next address failed!");
        halt = 1;
        @(posedge clk);
        #1;
        @(posedge clk);
        #10;
        if (address_out != 8'h10)
            $display("Error: address out failed!");
        rst = 1;
        @(posedge clk);
        #10;
        if (address_out != 8'h00)
            $display("Error: reset failed!");
        if (next_address != 8'h00)
            $display("Error: reset failed!");
        $display("Test finished");
        $finish;
    end
endmodule
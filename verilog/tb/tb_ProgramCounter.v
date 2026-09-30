module tb_ProgramCunter;
    reg clk;
    reg rst;
    reg [15:0] address;
    wire [15:0] address_out;
    wire [15:0] next_address;
    ProgramCounter uut (.clk(clk), .rst(rst), .address(address), .address_out(address_out), .next_address(next_address));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_ProgramCunter);
        address = 16'h0010;
        @(posedge clk);
        #10;
        if (address_out != 16'h0010)
            $display("Error: address out failed!");
        if (next_address != 16'h0011)
            $display("Error: next address failed!");
        rst = 1;
        @(posedge clk);
        #10;
        if (address_out != 16'h0000)
            $display("Error: reset failed!");
        if (next_address != 16'h0000)
            $display("Error: reset failed!");
        $finish;
    end
endmodule
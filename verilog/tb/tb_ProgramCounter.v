module tb_ProgramCunter;
    reg clk;
    reg rst;
    reg [7:0] address;
    wire [7:0] address_out;
    wire [7:0] next_address;
    ProgramCounter uut (.clk(clk), .rst(rst), .address(address), .address_out(address_out), .next_address(next_address));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_ProgramCunter);
        address = 8'h10;
        @(posedge clk);
        #10;
        if (address_out != 8'h10)
            $display("Error: address out failed!");
        if (next_address != 8'h11)
            $display("Error: next address failed!");
        rst = 1;
        @(posedge clk);
        #10;
        if (address_out != 8'h00)
            $display("Error: reset failed!");
        if (next_address != 8'h00)
            $display("Error: reset failed!");
        $finish;
    end
endmodule
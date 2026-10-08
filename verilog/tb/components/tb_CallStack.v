module tb_CallStack;
    reg clk;
    reg rst;
    reg call;
    reg ret;
    reg [15:0] address_in;
    wire [15:0] address_out;
    CallStack uut (.clk(clk), .rst(rst), .call(call), .ret(ret), .address_in(address_in), .address_out(address_out));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_CallStack);
        address_in = 16'hBBBB;
        call = 1;
        @(posedge clk);
        #5;
        call = 0;
        if (address_out != 16'h0000)
            $display("Error: call failed!");
        ret = 1;
        #5;
        if (address_out != 16'hBBBB)
            $display("Error: return failed!");
        address_in = 16'hEEEE;
        call = 1;
        @(posedge clk);
        #1;
        address_in = 16'hFFFF;
        @(posedge clk);
        #1;
        call = 0;
        ret = 1;
        #1;
        if (address_out != 16'hFFFF)
            $display("Error: return 1 failed!");
        @(posedge clk);
        #10;
        if (address_out != 16'hEEEE)
            $display("Error: return 2 failed!");
        address_in = 16'h0001;
        call = 1;
        @(posedge clk);
        #1;
        rst = 1;
        @(posedge clk);
        #10;
        if (address_out != 16'h0000)
            $display("Error: reset failed!");
        rst = 0;
        call = 0;
        ret = 0;
        // 16 nested calls: the last level must be returnable too
        for (integer n = 1; n <= 16; n = n + 1) begin
            address_in = n;
            call = 1;
            @(posedge clk);
            #1;
        end
        call = 0;
        for (integer n = 16; n >= 1; n = n - 1) begin
            ret = 1;
            #1;
            if (address_out !== n)
                $display("Error: nested return %0d failed!", n);
            @(posedge clk);
            #1;
        end
        ret = 0;
        $display("Test finished");
        $finish;
    end
endmodule
module tb_CallStack;
    reg clk;
    reg rst;
    reg call;
    reg return;
    reg [7:0] address_in;
    wire [7:0] address_out;
    CallStack uut (.clk(clk), .rst(rst), .call(call), .return(return), .address_in(address_in), .address_out(address_out));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_CallStack);
        address_in = 8'hBB;
        call = 1;
        @(posedge clk);
        #10;
        call = 0;
        if (address_out != 8'h00)
            $display("Error: call failed!");
        return = 1;
        #10;
        if (address_out != 8'hBB)
            $display("Error: return failed!");
        address_in = 8'hEE;
        call = 1;
        @(posedge clk);
        #1;
        address_in = 8'hFF;
        @(posedge clk);
        #1;
        call = 0;
        return = 1;
        #1;
        if (address_out != 8'hFF)
            $display("Error: return 1 failed!");
        @(posedge clk);
        #10;
        if (address_out != 8'hEE)
            $display("Error: return 2 failed!");
        address_in = 8'h01;
        call = 1;
        @(posedge clk);
        #1;
        rst = 1;
        @(posedge clk);
        #10;
        if (address_out != 8'h01)
            $display("Error: reset failed!");
        $finish;
    end
endmodule
module tb_FlagVerifier;
    reg clk;
    reg rst;
    reg [7:0] flags;
    reg [3:0] condition;
    wire condition_true;
    FlagVerifier uut (.clk(clk), .rst(rst), .flags(flags), .condition(condition), .condition_true(condition_true));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_FlagVerifier);
        rst = 0;
        flags =  8'b00101100;
        condition = 4'b0010;
        @(posedge clk);
        #10;
        if (!condition_true)
            $display("Error: true flag is displayed as false!");
        condition = 4'b0111;
        #10;
        if (condition_true)
            $display("Error: false flag is displayed as true!");
        condition = 4'b1111;
        #10;
        if (condition_true)
            $display("Error: empty flag is displyed as true!");
        condition = 4'b0010;
        flags = 0;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        if (!condition_true)
            $display("Error: flags weren't saved!");
        flags = 8'b00010000;
        @(posedge clk);
        #1;
        if (condition_true)
            $display("Error: flags summed!");
        condition = 4'b0100;
        #10;
        if (!condition_true)
            $display("Error: flags were resetted!");
        rst = 1;
        @(posedge clk);
        #1;
        rst = 0;
        if (condition_true)
            $display("Error: flag verifier didn't reset!");
        $display("Test finished");
        $finish;
    end
endmodule
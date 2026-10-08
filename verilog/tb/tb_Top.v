module tb_Top;
    reg clk;
    reg rst_btn;
    reg [3:0] sw;
    reg [3:0] btn;
    wire [15:0] led;
    // active-high reset button, program in sim/build/leds (run from the verilog folder)
    Top #(.IM_INIT_FILE("sim/build/leds/rom.txt"), .RST_BTN_ACTIVE_LOW(0)) uut (.clk(clk), .rst_btn(rst_btn), .sw(sw), .btn(btn), .led(led));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_Top);
        rst_btn = 0;
        sw = 0;
        btn = 0;
        // the power-up reset lasts 256 cycles, the program is 3 instructions plus the wait cycles
        repeat (300) @(posedge clk);
        #1;
        if (led !== 16'hFF00)
            $display("Error: LEDs should show 0x00FF inverted (0xFF00), they show 0x%h!", led);
        // the reset button clears the output port, the program then runs again
        rst_btn = 1;
        repeat (4) @(posedge clk);
        #1;
        if (led !== 16'hFFFF)
            $display("Error: LEDs should be all off during reset, they show 0x%h!", led);
        rst_btn = 0;
        repeat (20) @(posedge clk);
        #1;
        if (led !== 16'hFF00)
            $display("Error: the program did not run again after the reset!");
        // switches and buttons reach input port 0: switches in the low nibble, buttons in the high one
        sw = 4'b0101;
        btn = 4'b1001;
        repeat (4) @(posedge clk);
        #1;
        if (uut.in_bus[15:0] !== 16'h0095)
            $display("Error: input port 0 should be 0x0095, it is 0x%h!", uut.in_bus[15:0]);
        $display("Test finished");
        $finish;
    end
endmodule

module tb_4mux16b;
    reg [15:0] a, b, c, d;
    reg [1:0] sel;
    wire [15:0] y;
    integer index;
    _4mux16b uut (.a(a), .b(b), .c(c), .d(d),
        .sel(sel),
        .y(y)
    );
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_4mux16b);
        a = 16'h0000;
        b = 16'h0001;
        c = 16'h0002;
        d = 16'h0003;
        for(index = 0; index < 4; index = index + 1) begin
            sel = index;
            #10;
            $display("Time=%0t | Selected channel=%d | Output MUX=%h", $time, sel, y);
            if (y !== (sel)) begin
                $display("Error: MUX output does not match the selected channel!");
            end
        end
        $display("Test finished");
        $finish;
    end
endmodule
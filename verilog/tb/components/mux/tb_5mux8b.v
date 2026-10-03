module tb_5mux8b;
    reg [7:0] a, b, c, d, e;
    reg [2:0] sel;
    wire [7:0] y;
    integer index;
    _5mux8b uut (.a(a), .b(b), .c(c), .d(d), .e(e),
        .sel(sel),
        .y(y)
    );
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_5mux8b);
        a = 8'h00;
        b = 8'h01;
        c = 8'h02;
        d = 8'h03;
        e = 8'h04;
        for(index = 0; index < 5; index = index + 1) begin
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
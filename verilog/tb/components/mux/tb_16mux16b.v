module tb_16mux16b;
    reg [15:0] a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p;
    reg [3:0] sel;
    wire [15:0] y;
    integer index;
    _16mux16b uut (.a(a), .b(b), .c(c), .d(d), .e(e), .f(f), .g(g), .h(h),
        .i(i), .j(j), .k(k), .l(l), .m(m), .n(n), .o(o), .p(p),
        .sel(sel),
        .y(y)
    );
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_16mux16b);
        a = 16'h0000;
        b = 16'h0001;
        c = 16'h0002;
        d = 16'h0003;
        e = 16'h0004;
        f = 16'h0005;
        g = 16'h0006;
        h = 16'h0007;
        i = 16'h0008;
        j = 16'h0009;
        k = 16'h000A;
        l = 16'h000B;
        m = 16'h000C;
        n = 16'h000D;
        o = 16'h000E;
        p = 16'h000F;
        for(index = 0; index < 16; index = index + 1) begin
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
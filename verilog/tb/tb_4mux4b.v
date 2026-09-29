module tb_4mux4b;
    reg [3:0] a, b, c, d;
    reg [1:0] sel;
    wire [3:0] y;
    integer index;
    _4mux4b uut (.a(a), .b(b), .c(c), .d(d),
        .sel(sel),
        .y(y)
    );
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_4mux4b);
        a = 4'h0;
        b = 4'h1;
        c = 4'h2;
        d = 4'h3;
        for(index = 0; index < 4; index = index + 1) begin
            sel = index;
            #10;
            $display("Time=%0t | Selected channel=%d | Output MUX=%h", $time, sel, y);
            if (y !== (sel)) begin
                $display("Error: MUX output does not match the selected channel!");
            end
        end
        $finish;
    end
endmodule
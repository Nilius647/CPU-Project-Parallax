module tb_2mux4b;
    reg [3:0] a, b;
    reg [0:0] sel;
    wire [3:0] y;
    integer index;
    _2mux4b uut (.a(a), .b(b),
        .sel(sel),
        .y(y)
    );
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_2mux4b);
        a = 4'h0;
        b = 4'h1;
        for(index = 0; index < 2; index = index + 1) begin
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
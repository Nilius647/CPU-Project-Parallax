module tb_2mux16b;
    reg [15:0] a, b;
    reg [0:0] sel;
    wire [15:0] y;
    integer index;
    _2mux16b uut (.a(a), .b(b),
        .sel(sel),
        .y(y)
    );
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_2mux16b);
        a = 16'h0000;
        b = 16'h0001;
        for(index = 0; index < 2; index = index + 1) begin
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
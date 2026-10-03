module tb_2mux8b;
    reg [7:0] a, b;
    reg [0:0] sel;
    wire [7:0] y;
    integer index;
    _2mux8b uut (.a(a), .b(b),
        .sel(sel),
        .y(y)
    );
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_2mux8b);
        a = 8'h00;
        b = 8'h01;
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
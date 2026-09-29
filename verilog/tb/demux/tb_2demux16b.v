module tb_2demux16b;
    reg [15:0] y;
    reg [0:0] sel;
    wire [15:0] a, b;
    integer index;
    _2demux16b uut (.a(a), .b(b),
        .sel(sel),
        .y(y)
    );
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_2demux16b);
        y = 16'h0001;
        for(index = 0; index < 2; index = index + 1) begin
            sel = index;
            #10;
            $display("Time=%0t | Selected channel=%d | Output DEMUX=%h", $time, sel, y);
            if (sel == 0) begin
                if (a != y) begin
                    $display("Error: DEMUX output does not match the selected channel!");
                end
            end else if (sel == 1) begin
                if (b != y) begin
                    $display("Error: DEMUX output does not match the selected channel!");
                end
            end
        end
        $finish;
    end
endmodule
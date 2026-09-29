module tb_16demux16b;
    reg [15:0] y;
    reg [3:0] sel;
    wire [255:0] out;
    integer i;
    integer j;
    _16demux16b uut (.y(y), .sel(sel), .out(out));
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_16demux16b);
        y = 16'h0001;
        for (i = 0; i < 16; i = i + 1) begin
            sel = i;
            #10;
            for (j = 0; j < 16; j = j + 1) begin
                $display("Time=%0t | Selected channel=%d | Output DEMUX=%h", $time, i, y);
                if (j == i) begin
                    if(out[j*16 +: 16] !== y)
                        $display("Error: selected output does not match!");
                end else begin
                    if(out[j*16 +: 16] !== 16'h0000)
                        $display("Error: unselected output not zero!");
                end
            end
        end
        $finish;
    end
endmodule
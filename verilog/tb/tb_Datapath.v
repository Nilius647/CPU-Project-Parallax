module tb_Datapath;
    reg clk;
    reg rst;
    reg write;
    reg [15:0] write_address;
    reg [27:0] instruction;
    reg [255:0] in;
    wire [255:0] out;
    Datapath uut (.clk(clk), .rst(rst), .write(write), .write_address(write_address), .instruction(instruction), .in(in), .out(out));
    reg [15:0] low [0:255];
    reg [15:0] high [0:255];
    reg [27:0] instructions [0:255];
    reg [8*100-1:0] dir_in;
    reg [8*100-1:0] rom_low_path;
    reg [8*100-1:0] rom_high_path;
    integer k = 0;
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_Datapath);
        in = 0;
        if (!$value$plusargs("rom=%s", dir_in)) begin
            $display("Error: +rom argument missing!");
            $finish;
        end
        $sformat(rom_low_path, "%0s/rom_low.txt", dir_in);
        $sformat(rom_high_path, "%0s/rom_high.txt", dir_in);
        $readmemb(rom_low_path, low);
        $readmemb(rom_high_path, high);
        for (integer i = 0; i < 256; i = i + 1)
            instructions[i] = {high[i][11:0], low[i]};
        for (integer j = 0; j < 256; j = j + 1) begin
            uut.IM.instr_mem[j] = instructions[j];
        end
        rst = 1;
        @(posedge clk);
        #1;
        rst = 0;
        in[0*16 +: 16] = 16'h1234;
        in[1*16 +: 16] = 16'h5678;
        while (uut.cu_halt != 1 && k < 10000) begin
            @(posedge clk);
            #10;
            k = k + 1;
        end
        if ($test$plusargs("ports")) begin
            if (out[0*16 +: 16] != 16'h00FF || out[1*16 +: 16] != 16'h00FF)
                $display("Error: output failed!");
            if (uut.REG.internal[13*16 +: 16] != 16'h5678 || uut.REG.internal[14*16 +: 16] != 16'h1234)
                $display("Error: input failed!");
        end
        if (uut.REG.internal[15*16 +: 16] == 16'hDEAD)
            $display("Error: test failed!");
        else if (uut.REG.internal[15*16 +: 16] == 16'hBEEF)
            $display("Test succesful!");
        else
            $display("Error: test didn't finish!");
        $display("Test finished");
        $finish;
    end
endmodule
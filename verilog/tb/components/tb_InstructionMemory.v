module tb_InstructionMemory;
    localparam IM_SIZE = 8192;
    localparam ADDR_WIDTH = 16;
    localparam DATA_WIDTH = 28;
    reg clk;
    reg write;
    reg [ADDR_WIDTH-1:0] write_address;
    reg [DATA_WIDTH-1:0] data_in;
    reg [ADDR_WIDTH-1:0] address;
    wire [7:0] opcode_out;
    wire [3:0] nibble1_out;
    wire [3:0] nibble2_out;
    wire [3:0] nibble3_out;
    wire [3:0] nibble4_out;
    wire [3:0] nibble5_out;
    InstructionMemory uut (.clk(clk), .write(write), .write_address(write_address), .data_in(data_in), .address(address), .opcode_out(opcode_out),
        .nibble1_out(nibble1_out), .nibble2_out(nibble2_out), .nibble3_out(nibble3_out), .nibble4_out(nibble4_out), .nibble5_out(nibble5_out));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_InstructionMemory);
        // write one instruction through the write port
        write = 1;
        write_address = 0;
        data_in = 28'b0000000100010010001100000000;
        address = 0;
        @(posedge clk);
        #1;
        // read it back: the read is synchronous, the value is valid after the next edge
        write = 0;
        @(posedge clk);
        #1;
        if (opcode_out !== 8'b00000001)
            $display("Error: opcode out failed!");
        if (nibble1_out !== 4'b0001)
            $display("Error: nibble 1 out failed!");
        if (nibble2_out !== 4'b0010)
            $display("Error: nibble 2 failed!");
        if (nibble3_out !== 4'b0011)
            $display("Error: nibble 3 failed!");
        if (nibble4_out !== 4'b0000)
            $display("Error: nibble 4 failed!");
        if (nibble5_out !== 4'b0000)
            $display("Error: nibble 5 failed!");
        // an address beyond the installed memory reads as an all-zero instruction, it does not wrap
        address = IM_SIZE;
        @(posedge clk);
        #1;
        if (opcode_out !== 8'b00000000 || nibble1_out !== 4'b0000 || nibble2_out !== 4'b0000 ||
            nibble3_out !== 4'b0000 || nibble4_out !== 4'b0000 || nibble5_out !== 4'b0000)
            $display("Error: address beyond the memory is not read as zero!");
        // a write beyond the installed memory is ignored: it must not land on cell 0
        write = 1;
        write_address = IM_SIZE;
        data_in = 28'b1111111111111111111111111111;
        address = 0;
        @(posedge clk);
        #1;
        write = 0;
        @(posedge clk);
        #1;
        if (opcode_out !== 8'b00000001)
            $display("Error: write beyond the memory changed cell 0!");
        $display("Test finished");
        $finish;
    end
endmodule

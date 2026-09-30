module tb_InstructionMemory;
    reg [7:0] address;
    wire [7:0] opcode_out;
    wire [3:0] nibble1_out;
    wire [3:0] nibble2_out;
    wire [3:0] nibble3_out;
    wire [3:0] nibble4_out;
    wire [3:0] nibble5_out;
    InstructionMemory uut (.address(address), .opcode_out(opcode_out), 
        .nibble1_out(nibble1_out), .nibble2_out(nibble2_out), .nibble3_out(nibble3_out), .nibble4_out(nibble4_out), .nibble5_out(nibble5_out));
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_InstructionMemory);
        address = 0;
        uut.instr_mem[0] = 28'b0000000100010010001100000000;
        #10;
        if (opcode_out != 8'b00000001)
            $display("Error: opcode out failed!");
        if (nibble1_out != 4'b0001)
            $display("Error: nibble 1 out failed!");
        if (nibble2_out != 4'b0010)
            $display("Error: nibble 2 failed!");
        if (nibble3_out != 4'b0011)
            $display("Error: nibble 3 failed!");
        if (nibble4_out != 4'b0000)
            $display("Error: nibble 4 failed!");
        if (nibble5_out != 4'b0000)
            $display("Error: nibble 5 failed!");
        $finish;
    end
endmodule
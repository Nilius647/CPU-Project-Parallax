module InstructionMemory (
    input wire [7:0] address,
    output reg [7:0] opcode_out,
    output reg [3:0] nibble1_out,
    output reg [3:0] nibble2_out,
    output reg [3:0] nibble3_out,
    output reg [3:0] nibble4_out,
    output reg [3:0] nibble5_out
);
    reg [27:0] instr_mem [0:255];
    reg [27:0] temp;
    initial begin
        for (integer i = 0; i < 256; i = i + 1)
            instr_mem[i] = 0;
    end
    always @(*) begin
        temp = instr_mem[address];
        opcode_out = temp [27:20];
        nibble1_out = temp [19:16];
        nibble2_out = temp [15:12];
        nibble3_out = temp [11:8];
        nibble4_out = temp [7:4];
        nibble5_out = temp [3:0];
    end
endmodule
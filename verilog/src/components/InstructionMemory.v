module InstructionMemory #(
    parameter DATA_WIDTH = 28,
    parameter ADDR_WIDTH = 16,
    parameter IM_SIZE = 8192,
    parameter INIT_FILE = ""
)(
    input wire clk,
    input wire write,
    input wire [ADDR_WIDTH-1:0] write_address,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [ADDR_WIDTH-1:0] address,
    output reg [7:0] opcode_out,
    output reg [3:0] nibble1_out,
    output reg [3:0] nibble2_out,
    output reg [3:0] nibble3_out,
    output reg [3:0] nibble4_out,
    output reg [3:0] nibble5_out
);
    reg [DATA_WIDTH-1:0] instr_mem [0:IM_SIZE-1];
    reg [DATA_WIDTH-1:0] temp;
    initial begin
        // synopsys translate_off
        for (integer i = 0; i < IM_SIZE; i = i + 1)
            instr_mem[i] = 0;
        // synopsys translate_on
        if (INIT_FILE != "")
            $readmemb(INIT_FILE, instr_mem);
    end
    always @(posedge clk) begin
        if (write) begin
            if (write_address < IM_SIZE)
                instr_mem[write_address] <= data_in;
        end else begin
            if (address < IM_SIZE) begin
                temp = instr_mem[address];
                opcode_out <= temp [27:20];
                nibble1_out <= temp [19:16];
                nibble2_out <= temp [15:12];
                nibble3_out <= temp [11:8];
                nibble4_out <= temp [7:4];
                nibble5_out <= temp [3:0];
            end else begin
                temp = 0;
                opcode_out <= 0;
                nibble1_out <= 0;
                nibble2_out <= 0;
                nibble3_out <= 0;
                nibble4_out <= 0;
                nibble5_out <= 0;
            end
        end
    end
endmodule

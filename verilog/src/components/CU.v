module CU (
    input wire [7:0] opcode,
    output reg [3:0] ALU_op,
    output reg store_reg, store_mem, call, ret, ports, flags, stop_clock, needs_wait,
    output reg [2:0] PAM,
    output reg [1:0] RDM, RWM,
    output reg BAM, IMM, MRPO, MRPI, RMIA, RMOA, MAM
);
    always @(*) begin
        ALU_op = 0;
        store_reg = 0;
        store_mem = 0;
        call = 0;
        ret = 0;
        ports = 0;
        flags = 0;
        stop_clock = 0;
        needs_wait = 0;
        PAM = 0;
        RDM = 0;
        RWM = 0;
        BAM = 0;
        IMM = 0;
        MRPO = 0;
        MRPI = 0;
        RMIA = 0;
        RMOA = 0;
        MAM = 0;
        case (opcode)
            8'b00000000: begin ALU_op = 4'b0000; store_reg = 1; flags = 1; end
            8'b00000001: begin ALU_op = 4'b0001; store_reg = 1; flags = 1; end
            8'b00000010: begin ALU_op = 4'b0010; store_reg = 1; flags = 1; end
            8'b00000011: begin ALU_op = 4'b0011; store_reg = 1; flags = 1; end
            8'b00000100: begin ALU_op = 4'b0100; store_reg = 1; flags = 1; end
            8'b00000101: begin ALU_op = 4'b0101; store_reg = 1; flags = 1; end
            8'b00000110: begin ALU_op = 4'b0110; store_reg = 1; flags = 1; end
            8'b00000111: begin ALU_op = 4'b0111; store_reg = 1; flags = 1; end
            8'b00001000: begin ALU_op = 4'b1000; store_reg = 1; flags = 1; end
            8'b00001001: begin ALU_op = 4'b1001; store_reg = 1; flags = 1; end
            8'b00001010: begin ALU_op = 4'b1010; store_reg = 1; flags = 1; end
            8'b00001011: begin ALU_op = 4'b1011; store_reg = 1; flags = 1; end
            8'b00001100: begin ALU_op = 4'b1100; store_reg = 1; flags = 1; end
            8'b00001101: begin ALU_op = 4'b1101; store_reg = 1; flags = 1; end
            8'b00001110: begin ALU_op = 4'b1110; store_reg = 1; flags = 1; end
            8'b00001111: begin ALU_op = 4'b1111; store_reg = 1; flags = 1; end
            8'b00010000: begin end
            8'b00010001: begin stop_clock = 1; end
            8'b00010010: begin RDM = 1; RWM = 1; store_reg = 1; end
            8'b00010011: begin RWM = 1; BAM = 1; store_reg = 1; flags = 1; end
            8'b00010100: begin PAM = 1; end
            8'b00010101: begin PAM = 3'b010; end
            8'b00010110: begin PAM = 3'b011; end
            8'b00010111: begin store_mem = 1; end
            8'b00011000: begin RDM = 2'b10; RWM = 1; store_reg = 1; needs_wait = 1; end
            8'b00011001: begin MAM = 1; store_mem = 1; end
            8'b00011010: begin RDM = 2'b10; RWM = 1; MAM = 1; store_reg = 1; needs_wait = 1; end
            8'b00011011: begin RMOA = 1; ports = 1; needs_wait = 1; end
            8'b00011100: begin IMM = 1; RMIA = 1; store_mem = 1; end
            8'b00011101: begin MRPO = 1; ports = 1; end
            8'b00011110: begin RDM = 2'b11; RWM = 2'b10; MRPI = 1; store_reg = 1; end
            8'b00011111: begin PAM = 3'b001; call = 1; end
            8'b00100000: begin PAM = 3'b100; ret = 1; end
            default: begin end
        endcase
    end
endmodule
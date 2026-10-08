module tb_CU;
    reg [7:0] opcode;
    wire [3:0] ALU_op;
    wire store_reg, store_mem, call, ret, ports, flags, stop_clock, needs_wait;
    wire [2:0] PAM;
    wire [1:0] RDM, RWM;
    wire BAM, IMM, MRPO, MRPI, RMIA, RMOA, MAM;
    CU uut (.opcode(opcode), .ALU_op(ALU_op), 
        .store_reg(store_reg), .store_mem(store_mem), .call(call), .ret(ret), .ports(ports), .flags(flags), .stop_clock(stop_clock), .needs_wait(needs_wait),
        .PAM(PAM), .RDM(RDM), .RWM(RWM), .BAM(BAM), .IMM(IMM), .MRPO(MRPO), .MRPI(MRPI), .RMIA(RMIA), .RMOA(RMOA), .MAM(MAM));
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_CU);
        opcode = 0;
        #10;
        for (integer index = 4'b0000; index < 4'b1111 + 1; index = index + 1) begin
            if ((ALU_op != index) || (store_reg != 1) || (flags != 1))
                $display("Error: ALU operation failed!");
            opcode = opcode + 1;
            #10;
        end
        opcode = opcode + 1;
        #10;
        if (stop_clock != 1)
            $display("Error: HLT failed!");
        opcode = opcode + 1;
        #10;
        if (RDM != 1 || RWM != 1 || store_reg != 1)
            $display("Error: LDI failed!");
        opcode = opcode + 1;
        #10;
        if (RWM != 1 || BAM != 1 || store_reg != 1 || flags != 1)
            $display("Error: ADI failed!");
        opcode = opcode + 1;
        #10;
        if (PAM != 1)
            $display("Error: JMP failed!");
        opcode = opcode + 1;
        #10;
        if (PAM != 3'b010)
            $display("Error: BRH failed!");
        opcode = opcode + 1;
        #10;
        if (PAM != 3'b011)
            $display("Error: JMR failed!");
        opcode = opcode + 1;
        #10;
        if (store_mem != 1)
            $display("Error: STR failed!");
        opcode = opcode + 1;
        #10;
        if (RDM != 2'b10 || RWM != 1 || store_reg != 1 || needs_wait != 1)
            $display("Error: LOD failed!");
        opcode = opcode + 1;
        #10;
        if (MAM != 1 || store_mem != 1)
            $display("Error: STP failed!");
        opcode = opcode + 1;
        #10;
        if (RDM != 2'b10 || RWM != 1 || MAM != 1 || store_reg != 1 || needs_wait != 1)
            $display("Error: LDP failed!");
        opcode = opcode + 1;
        #10;
        if (RMOA != 1 || ports != 1 || needs_wait != 1)
            $display("Error: PSM failed!");
        opcode = opcode + 1;
        #10;
        if (IMM != 1 || RMIA != 1 || store_mem != 1)
            $display("Error: PLM failed!");
        opcode = opcode + 1;
        #10;
        if (MRPO != 1 || ports != 1)
            $display("Error: PSR failed!");
        opcode = opcode + 1;
        #10;
        if (RDM != 2'b11 || RWM != 2'b10 || MRPI != 1 || store_reg != 1)
            $display("Error: PLR failed!");
        opcode = opcode + 1;
        #10;
        if (PAM != 3'b001 || call != 1)
            $display("Error: CAL failed!");
        opcode = opcode + 1;
        #10;
        if (PAM != 3'b100 || ret != 1)
            $display("Error: RET failed!");
        $display("Test finished");
        $finish;
    end
endmodule
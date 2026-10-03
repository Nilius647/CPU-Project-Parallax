module Datapath (
    input wire clk,
    input wire rst,
    input wire [255:0] in,
    output reg [255:0] out
); 
    wire [7:0] pam_pc;
    wire [7:0] next_address;
    wire [7:0] pc_im;
    wire [7:0] opcode;
    wire [7:0] cs_pam;
    wire [3:0] nibble1;
    wire [3:0] nibble2;
    wire [3:0] nibble3;
    wire [3:0] nibble4;
    wire [3:0] nibble5;
    wire [3:0] ALU_op;
    wire [15:0] immediate;
    wire [7:0] pc_address;
    wire cu_call;
    wire cu_return;
    wire cu_halt;
    wire cu_flags;
    wire cu_reg;
    wire cu_mem;
    wire cu_ports;
    wire [1:0] cu_rdm;
    wire [1:0] cu_rwm;
    wire [2:0] cu_pam1;
    reg [2:0] cu_pam2;
    wire cu_bam;
    wire cu_imm;
    wire cu_mrpo;
    wire cu_mrpi;
    wire cu_rmia;
    wire cu_rmoa;
    wire cu_mam;
    wire [15:0] reg_data;
    wire [3:0] reg_write;
    wire [15:0] reg_out1;
    wire [15:0] reg_out2;
    wire [15:0] alu_b;
    wire [15:0] alu_out;
    wire [7:0] alu_flags;
    wire [15:0] ram_in;
    wire [15:0] ram_out;
    wire [15:0] ram_address;
    wire [15:0] port_ram;
    wire [15:0] port_reg;
    wire [3:0] port_in_addr;
    wire [3:0] port_out_addr;
    reg [15:0] port_in_data;
    wire [15:0] port_out_data;
    wire flag_true;
    assign immediate = {nibble2, nibble3, nibble4, nibble5};
    assign pc_address = {nibble2, nibble3};
    _4mux16b RDM (.a(alu_out), .b(immediate), .c(ram_out), .d(port_reg), .sel(cu_rdm), .y(reg_data));
    _4mux4b RWM (.a(nibble3), .b(nibble1), .c(nibble2), .d(4'h0), .sel(cu_rwm), .y(reg_write));
    _5mux8b PAM (.a(next_address), .b(pc_address), .c(pc_address), .d(reg_out1[7:0]), .e(cs_pam), .sel(cu_pam2), .y(pam_pc));
    _2mux16b BAM (.a(reg_out2), .b(immediate), .sel(cu_bam), .y(alu_b));
    _2mux16b IMM (.a(reg_out1), .b(port_ram), .sel(cu_imm), .y(ram_in));
    _2mux16b MRPO (.a(ram_out), .b(reg_out2), .sel(cu_mrpo), .y(port_out_data));
    _2demux16b MRPI (.a(port_ram), .b(port_reg), .sel(cu_mrpi), .y(port_in_data));
    _2mux4b RMIA (.a(nibble3), .b(nibble1), .sel(cu_rmia), .y(port_in_addr));
    _2mux4b RMOA (.a(nibble3), .b(nibble1), .sel(cu_rmoa), .y(port_out_addr));
    _2mux16b MAM (.a(immediate), .b(reg_out2), .sel(cu_mam), .y(ram_address));
    ProgramCounter PC (.clk(clk), .rst(rst), .halt(cu_halt), .address(pam_pc), .address_out(pc_im), .next_address(next_address));
    InstructionMemory IM (.address(pc_im), 
        .nibble1_out(nibble1), .nibble2_out(nibble2), .nibble3_out(nibble3), .nibble4_out(nibble4), .nibble5_out(nibble5), .opcode_out(opcode));
    CU CU (.opcode(opcode), .ALU_op(ALU_op), 
        .store_reg(cu_reg), .store_mem(cu_mem), .call(cu_call), .ret(cu_return), .ports(cu_ports), .flags(cu_flags), .stop_clock(cu_halt), 
        .PAM(cu_pam1), .RDM(cu_rdm), .RWM(cu_rwm), .BAM(cu_bam), .IMM(cu_imm), .MRPO(cu_mrpo), .MRPI(cu_mrpi), .RMIA(cu_rmia), .RMOA(cu_rmoa), .MAM(cu_mam));
    CallStack CS (.clk(clk), .rst(rst), .call(cu_call), .ret(cu_return), .address_in(next_address), .address_out(cs_pam));
    DRSWregister REG (.clk(clk), .rst(rst), .write(cu_reg), 
        .addr1(nibble1), .addr2(nibble2), .write_addr(reg_write), .data(reg_data), .out1(reg_out1), .out2(reg_out2));
    RAM RAM (.clk(clk), .write(cu_mem), .address(ram_address), .data_in(ram_in), .data_out(ram_out));
    ALU ALU (.enable_flags(cu_flags), .operation(ALU_op), .a(reg_out1), .b(alu_b), .flags(alu_flags), .out(alu_out));
    FlagVerifier FV (.clk(clk), .rst(rst), .flags(alu_flags), .condition(nibble1), .condition_true(flag_true));
    always @(posedge clk) begin
        if (rst)
            out <= 0;
        else begin
            if (cu_ports)
                out[port_out_addr*16 +: 16] <= port_out_data;
        end
    end
    always @(*) begin
        port_in_data = in[port_in_addr*16 +: 16];
        if (cu_pam1 == 3'b010) begin
            if(flag_true)
                cu_pam2 = 3'b010;
            else
                cu_pam2 = 3'b000;
        end else begin
            cu_pam2 = cu_pam1;
        end
    end
endmodule
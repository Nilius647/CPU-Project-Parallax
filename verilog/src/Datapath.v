module Datapath #(
    parameter IM_INIT_FILE = ""
)(
    input wire clk,
    input wire rst,
    input wire write,
    input wire [15:0] write_address,
    input wire [27:0] instruction,
    input wire [255:0] in,
    output reg [255:0] out
); 
    wire [15:0] pam_pc;
    wire [15:0] next_address;
    wire [15:0] pc_im;
    wire [7:0] opcode;
    wire [15:0] cs_pam;
    wire [3:0] nibble1;
    wire [3:0] nibble2;
    wire [3:0] nibble3;
    wire [3:0] nibble4;
    wire [3:0] nibble5;
    wire [3:0] ALU_op;
    wire [15:0] imm_pc_addr;
    wire cu_call;
    wire cu_return;
    wire cu_halt;
    wire cu_flags;
    wire cu_reg1;
    reg cu_reg2;
    wire cu_mem;
    wire cu_ports1;
    reg cu_ports2;
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
    wire pc_halt;
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
    wire [15:0] im_address;
    wire flag_true;
    reg wait_done;
    wire stall;
    wire needs_wait;
    assign stall = needs_wait & ~wait_done;
    assign pc_halt = cu_halt | stall;
    assign imm_pc_addr = {nibble2, nibble3, nibble4, nibble5};
    assign im_address = rst ? 16'h0000 : pam_pc;
    _4mux16b RDM (.a(alu_out), .b(imm_pc_addr), .c(ram_out), .d(port_reg), .sel(cu_rdm), .y(reg_data));
    _4mux4b RWM (.a(nibble3), .b(nibble1), .c(nibble2), .d(4'h0), .sel(cu_rwm), .y(reg_write));
    _6mux16b PAM (.a(next_address), .b(imm_pc_addr), .c(imm_pc_addr), .d(reg_out1), .e(cs_pam), .f(pc_im), .sel(cu_pam2), .y(pam_pc));
    _2mux16b BAM (.a(reg_out2), .b(imm_pc_addr), .sel(cu_bam), .y(alu_b));
    _2mux16b IMM (.a(reg_out1), .b(port_ram), .sel(cu_imm), .y(ram_in));
    _2mux16b MRPO (.a(ram_out), .b(reg_out2), .sel(cu_mrpo), .y(port_out_data));
    _2demux16b MRPI (.a(port_ram), .b(port_reg), .sel(cu_mrpi), .y(port_in_data));
    _2mux4b RMIA (.a(nibble3), .b(nibble1), .sel(cu_rmia), .y(port_in_addr));
    _2mux4b RMOA (.a(nibble3), .b(nibble1), .sel(cu_rmoa), .y(port_out_addr));
    _2mux16b MAM (.a(imm_pc_addr), .b(reg_out2), .sel(cu_mam), .y(ram_address));
    ProgramCounter PC (.clk(clk), .rst(rst), .halt(pc_halt), .address(pam_pc), .address_out(pc_im), .next_address(next_address));
    InstructionMemory #(.INIT_FILE(IM_INIT_FILE)) IM (.clk(clk), .write(write), .write_address(write_address), .data_in(instruction), .address(im_address), 
        .nibble1_out(nibble1), .nibble2_out(nibble2), .nibble3_out(nibble3), .nibble4_out(nibble4), .nibble5_out(nibble5), .opcode_out(opcode));
    CU CU (.opcode(opcode), .ALU_op(ALU_op), 
        .store_reg(cu_reg1), .store_mem(cu_mem), .call(cu_call), .ret(cu_return), .ports(cu_ports1), .flags(cu_flags), .stop_clock(cu_halt), .needs_wait(needs_wait), 
        .PAM(cu_pam1), .RDM(cu_rdm), .RWM(cu_rwm), .BAM(cu_bam), .IMM(cu_imm), .MRPO(cu_mrpo), .MRPI(cu_mrpi), .RMIA(cu_rmia), .RMOA(cu_rmoa), .MAM(cu_mam));
    CallStack CS (.clk(clk), .rst(rst), .call(cu_call), .ret(cu_return), .address_in(next_address), .address_out(cs_pam));
    DRSWregister REG (.clk(clk), .rst(rst), .write(cu_reg2), 
        .addr1(nibble1), .addr2(nibble2), .write_addr(reg_write), .data(reg_data), .out1(reg_out1), .out2(reg_out2));
    RAM RAM (.clk(clk), .write(cu_mem), .address(ram_address), .data_in(ram_in), .data_out(ram_out));
    ALUnit ALU (.enable_flags(cu_flags), .operation(ALU_op), .a(reg_out1), .b(alu_b), .flags(alu_flags), .out(alu_out));
    FlagVerifier FV (.clk(clk), .rst(rst), .flags(alu_flags), .condition(nibble1), .condition_true(flag_true));
    always @(posedge clk) begin
        if (rst) begin
            out <= 0;
            wait_done <= 0;
        end else begin
            wait_done <= stall;
            if (cu_ports2)
                out[port_out_addr*16 +: 16] <= port_out_data;
        end
    end
    always @(*) begin
        port_in_data = in[port_in_addr*16 +: 16];
        cu_reg2 = cu_reg1 & ~stall;
        cu_ports2 = cu_ports1 & ~stall;
        if (cu_pam1 == 3'b010) begin
            if(flag_true)
                cu_pam2 = 3'b010;
            else
                cu_pam2 = 3'b000;
        end else if (cu_halt || stall) begin
            cu_pam2 = 3'b101;
        end else begin
            cu_pam2 = cu_pam1;
        end
    end
endmodule
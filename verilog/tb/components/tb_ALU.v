module tb_ALU;
    reg enable_flags;
    reg [3:0] operation;
    reg [15:0] a, b;
    wire [7:0] flags;
    wire [15:0] out;
    ALU uut (.enable_flags(enable_flags), .operation(operation), .a(a), .b(b), .flags(flags), .out(out));
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_ALU);
        enable_flags = 1;
        a = 16'b0110110100011100;
        b = 16'b1011011011010010;
        operation = 4'b0000;
        #10;
        if (out != a + b)
            $display("Error: addition failed!");
        if (flags[0] != 1 || flags[5] != 0)
            $display("Error: carry out flag failed!");
        if (flags[1] != 0)
            $display("Error: a > b flag failed!");
        if (flags[3] != 1)
            $display("Error: a < b flag failed!");
        operation = 4'b0001;
        #10;
        if (out != a - b)
            $display("Error: subtraction failed!");
        operation = 4'b0010;
        #10;
        if (out != ~a)
            $display("Error: bitwise NOT failed!");
        operation = 4'b0011;
        #10;
        if (out != (a & b))
            $display("Error: bitwise AND failed!");
        operation = 4'b0100;
        #10;
        if (out != (a | b))
            $display("Error: bitwise OR failed!");
        operation = 4'b0101;
        #10;
        if (out != (a ^ b))
            $display("Error: bitwise XOR failed!");
        operation = 4'b110;
        #10;
        if (out != (a ~& b))
            $display("Error: bitwise NAND failed!");
        operation = 4'b0111;
        #10;
        if (out != (a ~| b))
            $display("Error: bitwise NOR failed!");
        operation = 4'b1000;
        #10;
        if (out != (a ~^ b))
            $display("Error: bitwise XNOR failed!");
        operation = 4'b1001;
        #10;
        if (out != (~a | b))
            $display("Error: bitwise IMPLY failed!");
        operation = 4'b1010;
        #10;
        if (out != (a & ~b))
            $display("Error: bitwise NIMPLY failed!");
        operation = 4'b1011;
        #10;
        if (out != a * 2)
            $display("Error: shift left failed!");
        operation = 4'b1100;
        #10;
        if (out != a / 2)
            $display("Error: shift right failed!");
        operation = 4'b1101;
        #10;
        if (out != a + 1)
            $display("Error: increment failed!");
        operation = 4'b1110;
        #10;
        if (out != a - 1)
            $display("Error: decrement failed!");
        operation = 4'b1111;
        #10;
        if (out != a * b)
            $display("Error: multiplication failed!");
        if (flags[7] != 1)
            $display("Error: overflow flag failed!");
        a = 16'b1110110100011100;
        b = 16'b1110110100011100;
        operation = 4'b0001;
        #10;
        if (flags[4] != 1 || flags[6] != 0)
            $display("Error: zero flag failed!");
        if (flags[2] != 1)
            $display("Error: a = b flag failed!");
        enable_flags = 0;
        operation = 4'b0000;
        #10;
        if (out != a + b)
            $display("Error: addition without flags failed!");
        if (flags != 0)
            $display("Error: flags are showed with flags disabled!");
        operation = 4'b1111;
        #10;
        if (flags != 0)
            $display("Error: flags are showed with flags disabled!");
        $display("Test finished");
        $finish;
    end
endmodule
module Top #(
    parameter IM_INIT_FILE = "",
    parameter RST_BTN_ACTIVE_LOW = 1
)(
    input wire clk,
    input wire rst_btn,
    input wire [3:0] sw,
    input wire [3:0] btn,
    output wire [15:0] led
);
    reg [7:0] por_cnt = 8'd0;
    wire por_active;
    assign por_active = ~&por_cnt;
    always @(posedge clk) begin
        if (por_active)
            por_cnt <= por_cnt + 1'b1;
    end
    wire rst_pressed;
    assign rst_pressed = RST_BTN_ACTIVE_LOW ? ~rst_btn : rst_btn;
    reg [1:0] rst_sync = 2'b00;
    reg rst = 1'b1;
    always @(posedge clk) begin
        rst_sync <= {rst_sync[0], rst_pressed};
        rst <= por_active | rst_sync[1];
    end
    reg [7:0] sync1 = 8'd0;
    reg [7:0] sync2 = 8'd0;
    always @(posedge clk) begin
        sync1 <= {btn, sw};
        sync2 <= sync1;
    end
    wire [255:0] in_bus;
    wire [255:0] out_bus;
    assign in_bus = {248'b0, sync2};
    Datapath #(
        .IM_INIT_FILE(IM_INIT_FILE)
    ) datapath (.clk(clk), .rst(rst), .write(1'b0), .write_address(16'b0), .instruction(28'b0), .in(in_bus), .out(out_bus));
    assign led = ~out_bus[15:0];
endmodule
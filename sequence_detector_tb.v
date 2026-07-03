`timescale 1ns/1ps

module sequence_detector_tb;

reg clk;
reg rst;
reg x;
wire y;

sequence_detector uut (
    .clk(clk),
    .rst(rst),
    .x(x),
    .y(y)
);
wire [1:0] state=uut.state;
always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    x = 0;

    #10 rst = 0;

    #12 x = 1;
    #10 x = 1;
    #10 x = 0;
    #10 x = 1;
    #10 x = 1;
    #10 x = 0;

    #20;
    $finish;
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
end

endmodule
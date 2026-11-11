`timescale 1ns/1ps

module sequence_detector_tb;

reg clk;
reg rst;
reg x;
wire y;

integer errors;
integer i;
integer detects;

sequence_detector uut (
    .clk(clk),
    .rst(rst),
    .x(x),
    .y(y)
);

// Apply x on the falling edge so it is stable at the rising edge
always #5 clk = ~clk;

task apply_bit;
    input bit_val;
    input exp_y;
    input [8*64-1:0] tag;
    begin
        @(negedge clk);
        x = bit_val;
        @(posedge clk);
        #1;
        if (y !== exp_y) begin
            $display("FAIL %0s: x=%0b y=%0b expected %0b at t=%0t", tag, bit_val, y, exp_y, $time);
            errors = errors + 1;
        end
        if (y)
            detects = detects + 1;
    end
endtask

initial begin
    errors = 0;
    detects = 0;
    clk = 0;
    rst = 1;
    x = 0;

    @(posedge clk);
    #1;
    if (y !== 1'b0) begin
        $display("FAIL y not 0 in reset");
        errors = errors + 1;
    end

    @(negedge clk);
    rst = 0;

    // 110 110: overlapping detections. Moore output is 1 in S3,
    // one clock after the completing 0.
    // bits: 1 1 0 1 1 0
    // y:    0 0 1 0 0 1
    apply_bit(1, 0, "first 1");
    apply_bit(1, 0, "second 1");
    apply_bit(0, 1, "first 110");
    apply_bit(1, 0, "overlap 1 after detect");
    apply_bit(1, 0, "overlap second 1");
    apply_bit(0, 1, "second overlapping 110");

    if (detects !== 2) begin
        $display("FAIL expected 2 detections in 110110, got %0d", detects);
        errors = errors + 1;
    end

    // 111 should not produce a detection: from S2 a 1 stays in S2 (y=0)
    rst = 1;
    @(negedge clk);
    rst = 0;
    detects = 0;
    apply_bit(1, 0, "111 bit0");
    apply_bit(1, 0, "111 bit1");
    apply_bit(1, 0, "111 bit2 - not 110");
    if (detects !== 0) begin
        $display("FAIL 111 should not detect 110");
        errors = errors + 1;
    end
    // completing with 0 after 11 should detect
    apply_bit(0, 1, "110 after 111 prefix");

    // 100: 1 then 0 returns to S0, no detect; trailing 0 stays in S0
    rst = 1;
    @(negedge clk);
    rst = 0;
    detects = 0;
    apply_bit(1, 0, "100 bit0");
    apply_bit(0, 0, "100 bit1");
    apply_bit(0, 0, "100 bit2");
    if (detects !== 0) begin
        $display("FAIL 100 should not detect");
        errors = errors + 1;
    end

    // Reset in the middle of 11, then a lone 0 must not detect
    rst = 1;
    @(negedge clk);
    rst = 0;
    apply_bit(1, 0, "pre-reset 1");
    apply_bit(1, 0, "pre-reset 1");
    @(negedge clk);
    rst = 1;
    x = 0;
    @(posedge clk);
    #1;
    if (y !== 1'b0) begin
        $display("FAIL y not cleared during reset");
        errors = errors + 1;
    end
    @(negedge clk);
    rst = 0;
    apply_bit(0, 0, "0 after mid-sequence reset");

    if (errors == 0)
        $display("RESULT: ALL TESTS PASSED");
    else
        $display("RESULT: FAILED, %0d error(s)", errors);
    $finish;
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, sequence_detector_tb);
end

endmodule

module sequence_detector (
    input clk,
    input rst,
    input x,
    output reg y
);
reg [1:0] state, next_state;
parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;
always @(posedge clk or posedge rst) begin
    if (rst)
        state <= S0;
    else
        state <= next_state;
end
always @(*) begin
    case (state)
        S0: begin
            if (x)
                next_state = S1;
            else
                next_state = S0;
        end
        S1: begin
            if (x)
                next_state = S2;
            else
                next_state = S0;
        end
        S2: begin
            if (x)
                next_state = S2;
            else
                next_state = S3;
        end
        S3: begin
            if (x)
                next_state = S1;
            else
                next_state = S0;
        end
        default: next_state = S0;
    endcase
end
always @(*) begin
    case (state)
        S0: y = 0;
        S1: y = 0;
        S2: y = 0;
        S3: y = 1;
        default: y = 0;
    endcase
end
endmodule
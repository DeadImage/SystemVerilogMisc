/*

    Input expected to be a value of a cycle counter.
    This value should be transmitted to the output, with an additional MSB.
    Once the counter reaches its max value and then falls down to 0, MSB of the output has to switch its value to the opposite.

    Example: CLK0; input = 0b1111, output = 0b01110
             CLK1; input = 0b0000, output = 0b01111
             CLK2; input = 0b0001, output = 1b10000

*/

module bit_expand_counter # (
    parameter INPUT_WIDTH = 9
)
(
    input  wire                   clk,
    input  wire                   resetn,
    input  wire [INPUT_WIDTH-1:0] input_value,
    output wire [INPUT_WIDTH:0]   output_value
);

reg [INPUT_WIDTH:0] output_value_reg;
assign output_value = output_value_reg;

always @ (posedge clk or negedge resetn) begin
    if (~resetn)
        output_value_reg <= {INPUT_WIDTH+1{1'b0}};
    else begin
        output_value_reg[INPUT_WIDTH-1:0] <= input_value;
        if (output_value_reg[INPUT_WIDTH-1] == 1'b1 && input_value[INPUT_WIDTH-1] == 1'b0)
            output_value_reg[INPUT_WIDTH] <= ~output_value_reg[INPUT_WIDTH];
        else
            output_value_reg[INPUT_WIDTH] <= output_value_reg[INPUT_WIDTH];
    end
end

endmodule

module priority_encoder # (
    // Width of input
    parameter INPUT_WIDTH = 4,
    // Bit width of encoding
    parameter ENC_WIDTH = $clog2(INPUT_WIDTH),
    // Least-significant-bit priority
    parameter LSB_HIGH_PRIORITY = 0
)
(
    input logic [INPUT_WIDTH-1:0] input_unencoded,
    output logic [INPUT_WIDTH-1:0] output_unencoded,
    output logic [ENC_WIDTH-1:0] output_encoded,
    output logic output_valid
);

integer i;

always_comb begin
    if (LSB_HIGH_PRIORITY) begin
        i = 0;
        while (input_unencoded[i] == 0 && i < INPUT_WIDTH)
            i = i + 1;
    end else begin
        i = INPUT_WIDTH - 1;
        while (input_unencoded[i] == 0 && i >= 0)
            i = i - 1;
    end
    output_encoded = i;
end

assign output_valid = |input_unencoded;
assign output_unencoded = 1 << output_encoded;

endmodule

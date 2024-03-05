module test_timing_checks # (
    parameter AXIS_DATA_WIDTH = 512,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH / 8
)
(
    input wire                         clk_tx,
    input wire                         clk_rx,
    input wire                         aresetn,

    // AXI-Stream TX
	input  wire                        tx_axis_tvalid,
	input  wire                        tx_axis_tready,

	// AXI-Stream RX
	input  wire [AXIS_DATA_WIDTH-1:0]  rx_s_axis_tdata,
	input  wire [AXIS_KEEP_WIDTH-1:0]  rx_s_axis_tkeep,
	input  wire                        rx_s_axis_tvalid,
	output wire                        rx_s_axis_tready,
	input  wire                        rx_s_axis_tlast,

	output wire [AXIS_DATA_WIDTH-1:0]  rx_m_axis_tdata,
	output wire [AXIS_KEEP_WIDTH-1:0]  rx_m_axis_tkeep,
	output wire                        rx_m_axis_tvalid,
	input  wire                        rx_m_axis_tready,
	output wire                        rx_m_axis_tlast
);

// bit sync imitation
wire req_tx, ack_rx;
reg [4:0] req_sync, ack_sync;

always_ff @ (posedge clk_rx or negedge aresetn) begin
    if (~aresetn) begin
        req_sync <= 5'b00000;
    end else begin
        req_sync[0] <= req_tx;
        for (int i = 1; i < 5; i = i + 1)
            req_sync[i] <= req_sync[i-1];
    end
end

always_ff @ (posedge clk_tx or negedge aresetn) begin
    if (~aresetn) begin
        ack_sync <= 5'b00000;
    end else begin
        ack_sync[0] <= ack_rx;
        for (int i = 1; i < 5; i = i + 1) begin
            ack_sync[i] <= ack_sync[i-1];
        end
    end
end

tx_timing_checker tx_timing_checker_inst (
    .clk            (clk_tx),
    .aresetn        (aresetn),
	.axis_tvalid    (tx_axis_tvalid),
	.axis_tready    (tx_axis_tready),
	.tx_started_req (req_tx),
	.tx_started_ack (ack_sync[4])
);

rx_timing_checker # (
    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH)
) rx_timing_checker_inst (
    .clk            (clk_rx),
    .aresetn        (aresetn),
	.s_axis_tdata   (rx_s_axis_tdata),
	.s_axis_tkeep   (rx_s_axis_tkeep),
	.s_axis_tvalid  (rx_s_axis_tvalid),
	.s_axis_tready  (rx_s_axis_tready),
	.s_axis_tlast   (rx_s_axis_tlast),
	.m_axis_tdata   (rx_m_axis_tdata),
	.m_axis_tkeep   (rx_m_axis_tkeep),
	.m_axis_tvalid  (rx_m_axis_tvalid),
	.m_axis_tready  (rx_m_axis_tready),
	.m_axis_tlast   (rx_m_axis_tlast),
	.tx_started_req (req_sync[4]),
	.tx_started_ack (ack_rx)
);

initial begin
    $dumpfile("waves.vcd");
    $dumpvars;
end

endmodule

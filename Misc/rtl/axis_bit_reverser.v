/*

Performs bit-wise reversion of the data supplied through AXI-Stream interface

*/
module axis_bit_reverser # (
    // Data Bus width in AXI-Stream
    parameter AXIS_DATA_WIDTH = 512,
    // TKEEP width in AXI-Stream
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH / 8
)
(
    input wire                         clk,
    input wire                         rst,
    // AXI-Stream input
	input  wire [AXIS_DATA_WIDTH-1:0]  s_axis_tdata,
	input  wire [AXIS_KEEP_WIDTH-1:0]  s_axis_tkeep,
	input  wire                        s_axis_tvalid,
	output wire                        s_axis_tready,
	input  wire                        s_axis_tlast,
	// AXI-Stream output
	output wire [AXIS_DATA_WIDTH-1:0]  m_axis_tdata,
	output wire [AXIS_KEEP_WIDTH-1:0]  m_axis_tkeep,
	output wire                        m_axis_tvalid,
	input  wire                        m_axis_tready,
	output wire                        m_axis_tlast
);

// M Regfile
reg [AXIS_DATA_WIDTH-1:0] m_axis_tdata_reg;
reg [AXIS_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
reg                       m_axis_tvalid_reg;
reg                       m_axis_tlast_reg;

wire [AXIS_DATA_WIDTH-1:0] m_axis_tdata_next;
wire [AXIS_KEEP_WIDTH-1:0] m_axis_tkeep_next;

assign m_axis_tdata =  m_axis_tdata_reg;
assign m_axis_tkeep =  m_axis_tkeep_reg;
assign m_axis_tvalid = m_axis_tvalid_reg;
assign m_axis_tlast =  m_axis_tlast_reg;

// S Regfile
reg s_axis_tready_reg;

assign s_axis_tready = s_axis_tready_reg;

// Data bit reversal
genvar n;

generate
    for (n = 0; n < AXIS_DATA_WIDTH; n = n + 1) begin
        assign m_axis_tdata_next[n] = s_axis_tdata[AXIS_DATA_WIDTH - n - 1];
    end
endgenerate

// Keep bit reversal
genvar m;

generate
    for (m = 0; m < AXIS_KEEP_WIDTH; m = m + 1) begin
        assign m_axis_tkeep_next[m] = s_axis_tkeep[AXIS_KEEP_WIDTH - m - 1];
    end
endgenerate

// Beat-ready-to-be-transferred
wire s_axis_beat_ready = s_axis_tready & s_axis_tvalid;
wire m_axis_beat_ready = m_axis_tready & m_axis_tvalid;

// Slave logic
always @ (posedge clk or posedge rst) begin
    if (rst) begin
        s_axis_tready_reg <= 1'b0;
    end else begin
        s_axis_tready_reg <= s_axis_beat_ready ? m_axis_beat_ready : !m_axis_tvalid | m_axis_tready;
    end
end

// Master logic
always @ (posedge clk or posedge rst) begin
    if (rst) begin
        m_axis_tvalid_reg <= 1'b0;
    end else begin
        if (s_axis_beat_ready) begin
            m_axis_tdata_reg <= m_axis_tdata_next;
            m_axis_tkeep_reg <= m_axis_tkeep_next;
            m_axis_tlast_reg <= s_axis_tlast;
            m_axis_tvalid_reg <= 1'b1;
        end else begin
            m_axis_tdata_reg <= m_axis_tdata_reg;
            m_axis_tkeep_reg <= m_axis_tkeep_reg;
            m_axis_tlast_reg <= m_axis_tlast_reg;
            m_axis_tvalid_reg <= m_axis_beat_ready ? 1'b0 : m_axis_tvalid_reg;
        end
    end
end

endmodule

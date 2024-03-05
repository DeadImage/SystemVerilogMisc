module rx_timing_checker # (
    parameter AXIS_DATA_WIDTH = 512,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH / 8
)
(
    input wire                         clk,
    input wire                         aresetn,
    // AXI-Stream input
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)
	input  wire [AXIS_DATA_WIDTH-1:0]  s_axis_tdata,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TKEEP" *)
	input  wire [AXIS_KEEP_WIDTH-1:0]  s_axis_tkeep,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)
	input  wire                        s_axis_tvalid,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *)
	output wire                        s_axis_tready,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TLAST" *)
	input  wire                        s_axis_tlast,
	// AXI-Stream output
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
	output wire [AXIS_DATA_WIDTH-1:0]  m_axis_tdata,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TKEEP" *)
	output wire [AXIS_KEEP_WIDTH-1:0]  m_axis_tkeep,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
	output wire                        m_axis_tvalid,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *)
	input  wire                        m_axis_tready,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TLAST" *)
	output wire                        m_axis_tlast,
	// Async tx_started signal
	input  wire                        tx_started_req,
	output wire                        tx_started_ack
);

// AXIS Regfile
reg [AXIS_DATA_WIDTH-1:0] m_axis_tdata_reg;
reg [AXIS_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
reg                       m_axis_tvalid_reg;
reg                       m_axis_tlast_reg;
reg                       s_axis_tready_reg;

wire [AXIS_DATA_WIDTH-1:0] m_axis_tdata_next;

assign m_axis_tdata =  m_axis_tdata_reg;
assign m_axis_tkeep =  m_axis_tkeep_reg;
assign m_axis_tvalid = m_axis_tvalid_reg;
assign m_axis_tlast =  m_axis_tlast_reg;
assign s_axis_tready = s_axis_tready_reg;

// Beat-ready-to-be-transferred
wire s_axis_beat_ready = s_axis_tready & s_axis_tvalid;
wire m_axis_beat_ready = m_axis_tready & m_axis_tvalid;

// FSM
localparam ST_IDLE = 2'b00, ST_REQ = 2'b01, ST_ACK = 2'b10;
reg [1:0] state;

always @ (posedge clk or negedge aresetn) begin
    if (~aresetn) begin
        state <= ST_IDLE;
    end else begin
        case (state)
            ST_IDLE: begin
                state <= tx_started_req ? ST_REQ : ST_IDLE;
            end
            ST_REQ: begin
                state <= s_axis_beat_ready ? ST_ACK : ST_REQ;
            end
            ST_ACK: begin
                state <= !tx_started_req ? ST_IDLE : ST_ACK;
            end
        endcase
    end
end

// Counter
reg [47:0] counter;

// Signal Regfile
reg tx_started_ack_reg;
assign tx_started_ack = tx_started_ack_reg;

// AXIS behavior
reg sent;

assign m_axis_tdata_next = {counter, s_axis_tdata[0 +: 464]};

always @ (posedge clk or negedge aresetn) begin
     if (~aresetn) begin
        m_axis_tvalid_reg <= 1'b0;
        s_axis_tready_reg <= 1'b0;
        sent <= 1'b0;
    end else begin
        if (s_axis_beat_ready) begin
            m_axis_tdata_reg <= m_axis_tdata_next;
            m_axis_tkeep_reg <= s_axis_tkeep;
            m_axis_tlast_reg <= s_axis_tlast;
        end
        case (state)
            ST_IDLE: begin
                m_axis_tvalid_reg <= 1'b0;
                s_axis_tready_reg <= 1'b0;
                sent <= 1'b0;
            end
            ST_REQ: begin
                m_axis_tvalid_reg <= s_axis_beat_ready ? 1'b1 : 1'b0;
                s_axis_tready_reg <= s_axis_beat_ready ? 1'b0 : 1'b1;
                sent <= 1'b0;
            end
            ST_ACK: begin
                m_axis_tvalid_reg <= m_axis_beat_ready | sent ? 1'b0 : 1'b1;
                s_axis_tready_reg <= 1'b0;
                sent <= m_axis_beat_ready | sent ? 1'b1 : 1'b0;
            end
        endcase
    end
end

// Signal and counter behavior
always @ (posedge clk or negedge aresetn) begin
    if (~aresetn) begin
        counter <= 0;
        tx_started_ack_reg <= 1'b0;
        sent <= 1'b0;
    end else begin
        case (state)
            ST_IDLE: begin
                counter <= 0;
                tx_started_ack_reg <= 1'b0;
            end
            ST_REQ: begin
                counter <= counter + 1;
                tx_started_ack_reg <= 1'b0;
            end
            ST_ACK: begin
                counter <= counter;
                tx_started_ack_reg <= 1'b1;
            end
        endcase
    end
end

endmodule

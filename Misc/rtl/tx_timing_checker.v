module tx_timing_checker
(
    input wire                         clk,
    input wire                         aresetn,
    // AXI-Stream
	input  wire                        axis_tvalid,
	input  wire                        axis_tready,
	// Async tx_started signal
	output wire                        tx_started_req,
	input  wire                        tx_started_ack
);

// Beat-ready-to-be-transferred
wire axis_beat_ready = axis_tready & axis_tvalid;

// FSM
localparam ST_IDLE = 2'b00, ST_REQ = 2'b01, ST_ACK = 2'b10;
reg [1:0] state;

// Regfile
reg tx_started_req_reg;
assign tx_started_req = tx_started_req_reg;

always @ (posedge clk or negedge aresetn) begin
    if (~aresetn) begin
        state <= ST_IDLE;
    end else begin
        case (state)
            ST_IDLE: begin
                state <= axis_beat_ready ? ST_REQ : ST_IDLE;
            end
            ST_REQ: begin
                state <= tx_started_ack ? ST_ACK : ST_REQ;
            end
            ST_ACK: begin
                state <= !tx_started_ack ? ST_IDLE : ST_ACK;
            end
        endcase
    end
end

// Signal logic
always @ (posedge clk or negedge aresetn) begin
    if (~aresetn) begin
        tx_started_req_reg <= 1'b0;
    end else begin
        case (state)
            ST_IDLE: begin
                tx_started_req_reg <= 1'b0;
            end
            ST_REQ: begin
                tx_started_req_reg <= 1'b1;
            end
            ST_ACK: begin
                tx_started_req_reg <= 1'b0;
            end
        endcase
    end
end

endmodule

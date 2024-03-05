module axi_many_to_one_interconnect # (
	// Slave count
	parameter C_S_COUNT = 4,
	// Address width
	parameter C_ADDR_WIDTH = 32,
	// Data width
	parameter C_DATA_WIDTH = 32,
	// Strobe width
	parameter C_STRB_WIDTH = C_DATA_WIDTH / 8,
	// ID width
	parameter C_ID_WIDTH = 4,
	// User width
	parameter C_USER_WIDTH = 1,
	// Usage of Transaction IDs to control multitransactional behaviour
	parameter C_ID_MT_USE = 1
)
(
	// Clock and Resetn
	input logic clk,
	input logic resetn,

	/*
		Slave Interfaces
	*/
	input  logic [C_S_COUNT*C_ID_WIDTH-1:0]     s_axi_awid,
    input  logic [C_S_COUNT*C_ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  logic [C_S_COUNT*8-1:0]              s_axi_awlen,
    input  logic [C_S_COUNT*3-1:0]              s_axi_awsize,
    input  logic [C_S_COUNT*2-1:0]              s_axi_awburst,
    input  logic [C_S_COUNT-1:0]                s_axi_awlock,
    input  logic [C_S_COUNT*4-1:0]              s_axi_awcache,
    input  logic [C_S_COUNT*3-1:0]              s_axi_awprot,
    input  logic [C_S_COUNT*4-1:0]              s_axi_awqos,
    input  logic [C_S_COUNT*C_USER_WIDTH-1:0]   s_axi_awuser,
    input  logic [C_S_COUNT-1:0]                s_axi_awvalid,
    output logic [C_S_COUNT-1:0]                s_axi_awready,
    input  logic [C_S_COUNT*C_DATA_WIDTH-1:0]   s_axi_wdata,
    input  logic [C_S_COUNT*C_STRB_WIDTH-1:0]   s_axi_wstrb,
    input  logic [C_S_COUNT-1:0]                s_axi_wlast,
    input  logic [C_S_COUNT*C_USER_WIDTH-1:0]   s_axi_wuser,
    input  logic [C_S_COUNT-1:0]                s_axi_wvalid,
    output logic [C_S_COUNT-1:0]                s_axi_wready,
    output logic [C_S_COUNT*C_ID_WIDTH-1:0]     s_axi_bid,
    output logic [C_S_COUNT*2-1:0]              s_axi_bresp,
    output logic [C_S_COUNT*C_USER_WIDTH-1:0]   s_axi_buser,
    output logic [C_S_COUNT-1:0]                s_axi_bvalid,
    input  logic [C_S_COUNT-1:0]                s_axi_bready,
    input  logic [C_S_COUNT*C_ID_WIDTH-1:0]     s_axi_arid,
    input  logic [C_S_COUNT*C_ADDR_WIDTH-1:0]   s_axi_araddr,
    input  logic [C_S_COUNT*8-1:0]              s_axi_arlen,
    input  logic [C_S_COUNT*3-1:0]              s_axi_arsize,
    input  logic [C_S_COUNT*2-1:0]              s_axi_arburst,
    input  logic [C_S_COUNT-1:0]                s_axi_arlock,
    input  logic [C_S_COUNT*4-1:0]              s_axi_arcache,
    input  logic [C_S_COUNT*3-1:0]              s_axi_arprot,
    input  logic [C_S_COUNT*4-1:0]              s_axi_arqos,
    input  logic [C_S_COUNT*C_USER_WIDTH-1:0]   s_axi_aruser,
    input  logic [C_S_COUNT-1:0]                s_axi_arvalid,
    output logic [C_S_COUNT-1:0]                s_axi_arready,
    output logic [C_S_COUNT*C_ID_WIDTH-1:0]     s_axi_rid,
    output logic [C_S_COUNT*C_DATA_WIDTH-1:0]   s_axi_rdata,
    output logic [C_S_COUNT*2-1:0]              s_axi_rresp,
    output logic [C_S_COUNT-1:0]                s_axi_rlast,
    output logic [C_S_COUNT*C_USER_WIDTH-1:0]   s_axi_ruser,
    output logic [C_S_COUNT-1:0]                s_axi_rvalid,
    input  logic [C_S_COUNT-1:0]                s_axi_rready,

    /*
		Master Interface
	*/
	output logic [C_ID_WIDTH-1:0]   m_axi_awid,
    output logic [C_ADDR_WIDTH-1:0] m_axi_awaddr,
    output logic [7:0]              m_axi_awlen,
    output logic [2:0]              m_axi_awsize,
    output logic [1:0]              m_axi_awburst,
    output logic                    m_axi_awlock,
    output logic [3:0]              m_axi_awcache,
    output logic [2:0]              m_axi_awprot,
    output logic [3:0]              m_axi_awqos,
    output logic [3:0]              m_axi_awregion,
    output logic [C_USER_WIDTH-1:0] m_axi_awuser,
    output logic                    m_axi_awvalid,
    input  logic                    m_axi_awready,
    output logic [C_DATA_WIDTH-1:0] m_axi_wdata,
    output logic [C_STRB_WIDTH-1:0] m_axi_wstrb,
    output logic                    m_axi_wlast,
    output logic [C_USER_WIDTH-1:0] m_axi_wuser,
    output logic                    m_axi_wvalid,
    input  logic                    m_axi_wready,
    input  logic [C_ID_WIDTH-1:0]   m_axi_bid,
    input  logic [1:0]              m_axi_bresp,
    input  logic [C_USER_WIDTH-1:0] m_axi_buser,
    input  logic                    m_axi_bvalid,
    output logic                    m_axi_bready,
    output logic [C_ID_WIDTH-1:0]   m_axi_arid,
    output logic [C_ADDR_WIDTH-1:0] m_axi_araddr,
    output logic [7:0]              m_axi_arlen,
    output logic [2:0]              m_axi_arsize,
    output logic [1:0]              m_axi_arburst,
    output logic                    m_axi_arlock,
    output logic [3:0]              m_axi_arcache,
    output logic [2:0]              m_axi_arprot,
    output logic [3:0]              m_axi_arqos,
    output logic [3:0]              m_axi_arregion,
    output logic [C_USER_WIDTH-1:0] m_axi_aruser,
    output logic                    m_axi_arvalid,
    input  logic                    m_axi_arready,
    input  logic [C_ID_WIDTH-1:0]   m_axi_rid,
    input  logic [C_DATA_WIDTH-1:0] m_axi_rdata,
    input  logic [1:0]              m_axi_rresp,
    input  logic                    m_axi_rlast,
    input  logic [C_USER_WIDTH-1:0] m_axi_ruser,
    input  logic                    m_axi_rvalid,
    output logic                    m_axi_rready
);

parameter C_S_COUNT_LOG = $clog2(C_S_COUNT);

/*
	Arbitration Logic
*/
logic [C_S_COUNT-1:0] request;
logic [C_S_COUNT-1:0] acknowledge;
logic [C_S_COUNT-1:0] grant;
logic grant_valid;
logic [$clog2(C_S_COUNT)-1:0] grant_encoded;

logic read_finish_flag, read_finish_flag_next;
logic write_finish_flag, write_finish_flag_next;

// request and acknowledge generation
genvar n;

generate
	for (n = 0; n < C_S_COUNT; n = n + 1) begin
		assign request[n] = s_axi_awvalid[n] | s_axi_arvalid[n];
	end
endgenerate

generate
	for (n = 0; n < C_S_COUNT; n = n + 1) begin
		assign acknowledge[n] = grant[n] && read_finish_flag && write_finish_flag;
	end
endgenerate

// Slave select
logic [C_S_COUNT_LOG-1:0] slave_select;

assign slave_select = grant_encoded;

// Arbiter instance
arbiter # (
	.PORTS(C_S_COUNT),
	.ARB_TYPE_ROUND_ROBIN(1),
	.ARB_BLOCK(1),
	.ARB_BLOCK_ACK(1),
	.ARB_LSB_HIGH_PRIORITY(1)
) arbiter_inst (
	.clk(clk),
	.resetn(resetn),
	.request(request),
	.acknowledge(acknowledge),
	.grant(grant),
	.grant_valid(grant_valid),
	.grant_encoded(grant_encoded)
);

/*
	State Machine Logic
*/
enum logic [1:0] {ST_IDLE, ST_TRANSACTION, ST_FINISH} curr_state, next_state;

always_comb begin
	next_state = curr_state;
	case (curr_state)
		ST_IDLE: begin
			if (grant_valid) begin
				next_state = ST_TRANSACTION;
			end
		end
		ST_TRANSACTION: begin
			if (read_finish_flag && write_finish_flag) begin
				next_state = ST_FINISH;
			end
		end
		ST_FINISH: begin
			next_state = ST_IDLE;
		end
	endcase
end

always_ff @ (posedge clk or negedge resetn) begin
	if (~resetn) begin
		curr_state <= ST_IDLE;
	end else begin
		curr_state <= next_state;
	end
end

/*
	Internal Signals
*/
logic [C_ID_WIDTH-1:0]   axi_awid_reg, axi_awid_next, axi_awid_selected;
logic [C_ADDR_WIDTH-1:0] axi_awaddr_reg, axi_awaddr_next, axi_awaddr_selected;
logic [7:0]              axi_awlen_reg, axi_awlen_next, axi_awlen_selected;
logic [2:0]              axi_awsize_reg, axi_awsize_next, axi_awsize_selected;
logic [1:0]              axi_awburst_reg, axi_awburst_next, axi_awburst_selected;
logic                    axi_awlock_reg, axi_awlock_next, axi_awlock_selected;
logic [3:0]              axi_awcache_reg, axi_awcache_next, axi_awcache_selected;
logic [2:0]              axi_awprot_reg, axi_awprot_next, axi_awprot_selected;
logic [3:0]              axi_awqos_reg, axi_awqos_next, axi_awqos_selected;
logic [3:0]              axi_awregion_reg, axi_awregion_next;
logic [C_USER_WIDTH-1:0] axi_awuser_reg, axi_awuser_next, axi_awuser_selected;
logic                    axi_awvalid_reg, axi_awvalid_next, axi_awvalid_selected;
logic                    axi_awready_reg, axi_awready_next;
logic [C_DATA_WIDTH-1:0] axi_wdata_reg, axi_wdata_next, axi_wdata_selected;
logic [C_STRB_WIDTH-1:0] axi_wstrb_reg, axi_wstrb_next, axi_wstrb_selected;
logic                    axi_wlast_reg, axi_wlast_next, axi_wlast_selected;
logic [C_USER_WIDTH-1:0] axi_wuser_reg, axi_wuser_next, axi_wuser_selected;
logic                    axi_wvalid_reg, axi_wvalid_next, axi_wvalid_selected;
logic                    axi_wready_reg, axi_wready_next;
logic [C_ID_WIDTH-1:0]   axi_bid_reg, axi_bid_next;
logic [1:0]              axi_bresp_reg, axi_bresp_next;
logic [C_USER_WIDTH-1:0] axi_buser_reg, axi_buser_next;
logic                    axi_bvalid_reg, axi_bvalid_next;
logic                    axi_bready_reg, axi_bready_next, axi_bready_selected;
logic [C_ID_WIDTH-1:0]   axi_arid_reg, axi_arid_next, axi_arid_selected;
logic [C_ADDR_WIDTH-1:0] axi_araddr_reg, axi_araddr_next, axi_araddr_selected;
logic [7:0]              axi_arlen_reg, axi_arlen_next, axi_arlen_selected;
logic [2:0]              axi_arsize_reg, axi_arsize_next, axi_arsize_selected;
logic [1:0]              axi_arburst_reg, axi_arburst_next, axi_arburst_selected;
logic                    axi_arlock_reg, axi_arlock_next, axi_arlock_selected;
logic [3:0]              axi_arcache_reg, axi_arcache_next, axi_arcache_selected;
logic [2:0]              axi_arprot_reg, axi_arprot_next, axi_arprot_selected;
logic [3:0]              axi_arqos_reg, axi_arqos_next, axi_arqos_selected;
logic [3:0]              axi_arregion_reg, axi_arregion_next;
logic [C_USER_WIDTH-1:0] axi_aruser_reg, axi_aruser_next, axi_aruser_selected;
logic                    axi_arvalid_reg, axi_arvalid_next, axi_arvalid_selected;
logic                    axi_arready_reg, axi_arready_next;
logic [C_ID_WIDTH-1:0]   axi_rid_reg, axi_rid_next;
logic [C_DATA_WIDTH-1:0] axi_rdata_reg, axi_rdata_next;
logic [1:0]              axi_rresp_reg, axi_rresp_next;
logic                    axi_rlast_reg, axi_rlast_next;
logic [C_USER_WIDTH-1:0] axi_ruser_reg, axi_ruser_next;
logic                    axi_rvalid_reg, axi_rvalid_next;
logic                    axi_rready_reg, axi_rready_next, axi_rready_selected;

/*
	Slave-Side Mux
*/
assign axi_awid_selected = s_axi_awid [slave_select*C_ID_WIDTH +: C_ID_WIDTH];
assign axi_awaddr_selected = s_axi_awaddr [slave_select*C_ADDR_WIDTH +: C_ADDR_WIDTH];
assign axi_awlen_selected = s_axi_awlen [slave_select*8 +: 8];
assign axi_awsize_selected = s_axi_awsize [slave_select*3 +: 3];
assign axi_awburst_selected = s_axi_awburst [slave_select*2 +: 2];
assign axi_awlock_selected = s_axi_awlock [slave_select];
assign axi_awcache_selected = s_axi_awcache [slave_select*4 +: 4];
assign axi_awprot_selected = s_axi_awprot [slave_select*3 +: 3];
assign axi_awuser_selected = s_axi_awuser [slave_select*C_USER_WIDTH +: C_USER_WIDTH];
assign axi_awqos_selected = s_axi_awqos [slave_select*4 +: 4];
assign axi_awvalid_selected = s_axi_awvalid [slave_select];
assign axi_wdata_selected = s_axi_wdata [slave_select*C_DATA_WIDTH +: C_DATA_WIDTH];
assign axi_wstrb_selected = s_axi_wstrb [slave_select*C_STRB_WIDTH +: C_STRB_WIDTH];
assign axi_wlast_selected = s_axi_wlast [slave_select];
assign axi_wuser_selected = s_axi_wuser [slave_select*C_USER_WIDTH +: C_USER_WIDTH];
assign axi_wvalid_selected = s_axi_wvalid [slave_select];
assign axi_bready_selected = s_axi_bready [slave_select];
assign axi_arid_selected = s_axi_arid [slave_select*C_ID_WIDTH +: C_ID_WIDTH];
assign axi_araddr_selected = s_axi_araddr [slave_select*C_ADDR_WIDTH +: C_ADDR_WIDTH];
assign axi_arlen_selected = s_axi_arlen [slave_select*8 +: 8];
assign axi_arsize_selected = s_axi_arsize [slave_select*3 +: 3];
assign axi_arburst_selected = s_axi_arburst [slave_select*2 +: 2];
assign axi_arlock_selected = s_axi_arlock [slave_select];
assign axi_arcache_selected = s_axi_arcache [slave_select*4 +: 4];
assign axi_arprot_selected = s_axi_arprot [slave_select*3 +: 3];
assign axi_arqos_selected = s_axi_arqos [slave_select*4 +: 4];
assign axi_arvalid_selected = s_axi_arvalid [slave_select];
assign axi_aruser_selected = s_axi_aruser [slave_select*C_USER_WIDTH +: C_USER_WIDTH];
assign axi_rready_selected = s_axi_rready [slave_select];

/*
	Slave-Side Demux
*/
always_comb begin
	s_axi_awready = 0;
	s_axi_arready = 0;
	s_axi_wready = 0;
	s_axi_bid = 0;
	s_axi_bresp = 0;
	s_axi_buser = 0;
	s_axi_bvalid = 0;
	s_axi_rvalid = 0;
	s_axi_rid = 0;
	s_axi_rdata = 0;
	s_axi_rresp = 0;
	s_axi_rlast = 0;
	s_axi_ruser = 0;

	if (curr_state == ST_TRANSACTION) begin
		s_axi_awready[slave_select] = axi_awready_reg;
		s_axi_wready[slave_select] = axi_wready_reg;
		s_axi_bid[slave_select*C_ID_WIDTH +: C_ID_WIDTH] = axi_bid_reg;
		s_axi_bresp[slave_select*2 +: 2] = axi_bresp_reg;
		s_axi_buser[slave_select*C_USER_WIDTH +: C_USER_WIDTH] = axi_buser_reg;
		s_axi_bvalid[slave_select] = axi_bvalid_reg;
		s_axi_arready[slave_select] = axi_arready_reg;
		s_axi_rid[slave_select*C_ID_WIDTH +: C_ID_WIDTH] = axi_rid_reg;
		s_axi_rdata[slave_select*C_DATA_WIDTH +: C_DATA_WIDTH] = axi_rdata_reg;
		s_axi_rresp[slave_select*2 +: 2] = axi_rresp_reg;
		s_axi_rlast[slave_select] = axi_rlast_reg;
		s_axi_ruser[slave_select*C_USER_WIDTH +: C_USER_WIDTH] = axi_ruser_reg;
		s_axi_rvalid[slave_select] = axi_rvalid_reg;
	end
end

// Master-side direct assignment from regs
assign m_axi_awid = axi_awid_reg;
assign m_axi_awaddr = axi_awaddr_reg;
assign m_axi_awlen = axi_awlen_reg;
assign m_axi_awsize = axi_awsize_reg;
assign m_axi_awburst = axi_awburst_reg;
assign m_axi_awlock = axi_awlock_reg;
assign m_axi_awcache = axi_awcache_reg;
assign m_axi_awprot = axi_awprot_reg;
assign m_axi_awqos = axi_awqos_reg;
assign m_axi_awuser = axi_awuser_reg;
assign m_axi_awvalid = axi_awvalid_reg;
assign m_axi_wdata = axi_wdata_reg;
assign m_axi_wstrb = axi_wstrb_reg;
assign m_axi_wlast = axi_wlast_reg;
assign m_axi_wuser = axi_wuser_reg;
assign m_axi_wvalid = axi_wvalid_reg;
assign m_axi_bready = axi_bready_reg;
assign m_axi_arid = axi_arid_reg;
assign m_axi_araddr = axi_araddr_reg;
assign m_axi_arlen = axi_arlen_reg;
assign m_axi_arsize = axi_arsize_reg;
assign m_axi_arburst = axi_arburst_reg;
assign m_axi_arlock = axi_arlock_reg;
assign m_axi_arcache = axi_arcache_reg;
assign m_axi_arprot = axi_arprot_reg;
assign m_axi_arqos = axi_arqos_reg;
assign m_axi_arregion = axi_arregion_reg;
assign m_axi_aruser = axi_aruser_reg;
assign m_axi_arvalid = axi_arvalid_reg;
assign m_axi_rready = axi_rready_reg;

// Read transactions take priority, so we make a flag for them
logic is_read, is_read_next;

// Beat-ready-to-be-transmitted signals
logic s_awrite_beat_ready, s_write_beat_ready, s_write_resp_beat_ready, s_aread_beat_ready, s_read_beat_ready;
logic m_awrite_beat_ready, m_write_beat_ready, m_write_resp_beat_ready, m_aread_beat_ready, m_read_beat_ready;

assign s_awrite_beat_ready = axi_awvalid_selected && axi_awready_reg;
assign s_write_beat_ready = axi_wvalid_selected && axi_wready_reg;
assign s_write_resp_beat_ready = axi_bvalid_reg && axi_bready_selected;
assign s_aread_beat_ready = axi_arvalid_selected && axi_arready_reg;
assign s_read_beat_ready = axi_rvalid_reg && axi_rready_selected;

assign m_awrite_beat_ready = axi_awvalid_reg && m_axi_awready;
assign m_write_beat_ready = axi_wvalid_reg && m_axi_wready;
assign m_write_resp_beat_ready = m_axi_bvalid && axi_bready_reg;
assign m_aread_beat_ready = axi_arvalid_reg && m_axi_arready;
assign m_read_beat_ready = m_axi_rvalid && axi_rready_reg;

// Special signals depending on AXI ID usage logic
generate
	if (C_ID_MT_USE) begin
		// 5 bits for counters are supposed to be more than enough, with the proper ID usage
		logic [4:0] read_declared_transaction_counter, read_declared_transaction_counter_next;
		logic [4:0] write_declared_transaction_counter, write_declared_transaction_counter_next;
		logic [4:0] read_completed_transaction_counter, read_completed_transaction_counter_next;
		logic [4:0] write_completed_transaction_counter, write_completed_transaction_counter_next;
		logic [4:0] wlast_counter, wlast_counter_next;

		// Helper signals
		logic write_counters_equal, read_counters_equal;
		logic write_ids_equal, read_ids_equal;

		assign write_counters_equal = write_declared_transaction_counter == write_completed_transaction_counter;
		assign read_counters_equal = read_declared_transaction_counter == read_completed_transaction_counter;
		assign write_ids_equal = axi_awid_selected == axi_awid_reg;
		assign read_ids_equal = axi_arid_selected == axi_arid_reg;

		always_comb begin
			axi_awready_next = 1'b0;
			axi_wready_next = 1'b0;
			axi_arready_next = 1'b0;
			read_finish_flag_next = 1'b0;
			write_finish_flag_next = 1'b0;

			read_declared_transaction_counter_next = read_declared_transaction_counter;
			write_declared_transaction_counter_next = write_declared_transaction_counter;
			read_completed_transaction_counter_next = read_completed_transaction_counter;
			write_completed_transaction_counter_next = write_completed_transaction_counter;
			wlast_counter_next = wlast_counter;

			case (curr_state)
				ST_IDLE: begin
					if (grant_valid) begin
						axi_arready_next =  1'b1;
						axi_awready_next = 1'b1;

						read_declared_transaction_counter_next = 0;
						write_declared_transaction_counter_next = 0;

						read_completed_transaction_counter_next = 0;
						write_completed_transaction_counter_next = 0;

						wlast_counter_next = 0;
					end
				end

				ST_TRANSACTION: begin
					// Write Transaction
					if (s_awrite_beat_ready) begin
						axi_awready_next = 1'b0;
						write_declared_transaction_counter_next = write_declared_transaction_counter + 1;
					end else begin
						// leave the channel open for possible transactions with the same AXI ID
						if (is_read && !read_finish_flag) begin
							axi_awready_next = (axi_awvalid_selected && write_ids_equal) && (!axi_awvalid_reg || m_axi_awready);
						end else begin
							axi_awready_next = !write_counters_equal && (axi_awvalid_selected && write_ids_equal) && (!axi_awvalid_reg || m_axi_awready);
						end
					end
					// S_AXI_WREADY signal
					if (wlast_counter < write_declared_transaction_counter) begin
						axi_wready_next = s_write_beat_ready ? m_write_beat_ready : (!axi_wvalid_reg || m_axi_wready);
					end else begin
						axi_wready_next = 1'b0;
					end
					// write counters update
					if (s_write_resp_beat_ready) begin
						write_completed_transaction_counter_next = write_completed_transaction_counter + 1;
					end
					if (s_write_beat_ready && axi_wlast_selected) begin
						wlast_counter_next = wlast_counter + 1;
					end
					// write finish flag
					if (is_read && !read_finish_flag) begin
						write_finish_flag_next = 1'b0;
					end else begin
						write_finish_flag_next = write_finish_flag ? 1'b1 : write_counters_equal && !s_awrite_beat_ready;
					end

					// Read Transaction
					if (s_aread_beat_ready) begin
						axi_arready_next = 1'b0;
						read_declared_transaction_counter_next = read_declared_transaction_counter + 1;
					end else begin
						// leave the channel open for possible transactions with the same AXI ID
						if (!is_read && !write_finish_flag) begin
							axi_arready_next = (axi_arvalid_selected && read_ids_equal) && (!axi_arvalid_reg || m_axi_arready);
						end else begin
							axi_arready_next = !read_counters_equal && (axi_arvalid_selected && read_ids_equal) && (!axi_arvalid_reg || m_axi_arready);
						end
					end
					// read counters update
					if (s_read_beat_ready && axi_rlast_reg) begin
						read_completed_transaction_counter_next = read_completed_transaction_counter + 1;
					end
					// read finish flag
					if (!is_read && !write_finish_flag) begin
						read_finish_flag_next = 1'b0;
					end else begin
						read_finish_flag_next = read_finish_flag ? 1'b1 : read_counters_equal && !s_aread_beat_ready;
					end
				end

				ST_FINISH: begin
					read_finish_flag_next = 1'b0;
					write_finish_flag_next = 1'b0;
					wlast_counter_next = 1'b0;
					read_declared_transaction_counter_next = 0;
					write_declared_transaction_counter_next = 0;
					read_completed_transaction_counter_next = 0;
					write_completed_transaction_counter_next = 0;
				end
			endcase
		end

		always_ff @ (posedge clk or negedge resetn) begin
			if (~resetn) begin
				read_declared_transaction_counter <= 0;
				write_declared_transaction_counter <= 0;
				read_completed_transaction_counter <= 0;
				write_completed_transaction_counter <= 0;
				wlast_counter <= 0;
			end else begin
				read_declared_transaction_counter <= read_declared_transaction_counter_next;
				write_declared_transaction_counter <= write_declared_transaction_counter_next;
				read_completed_transaction_counter <= read_completed_transaction_counter_next;
				write_completed_transaction_counter <= write_completed_transaction_counter_next;
				wlast_counter <= wlast_counter_next;
			end
		end

	end else begin
		logic write_last_flag, write_last_flag_next;
		logic [3:0] wlast_counter, wlast_counter_next;
		logic [3:0] declared_transaction_counter, declared_transaction_counter_next;
		logic [3:0] completed_transaction_counter, completed_transaction_counter_next;

		logic counters_equal;

		assign counters_equal = declared_transaction_counter == completed_transaction_counter;

		always_comb begin
			axi_awready_next = 1'b0;
			axi_wready_next = 1'b0;
			axi_arready_next = 1'b0;
			read_finish_flag_next = 1'b0;
			write_finish_flag_next = 1'b0;
			declared_transaction_counter_next = declared_transaction_counter;
			completed_transaction_counter_next = completed_transaction_counter;
			wlast_counter_next = wlast_counter;
			case (curr_state)
				ST_IDLE: begin
					if (grant_valid) begin
						axi_arready_next = 1'b1;
						axi_awready_next = 1'b1;
						write_last_flag_next = 0;
						declared_transaction_counter_next = 0;
						completed_transaction_counter_next = 0;
						wlast_counter_next = 0;
					end
				end

				ST_TRANSACTION: begin
					// Write Transaction
					// S_AXI_AWREADY signal and write flags
					if (is_read && !read_finish_flag) begin
						axi_awready_next =  !s_awrite_beat_ready && (!axi_awvalid_reg || m_axi_awready);
						write_finish_flag_next = 1'b0;
					end else begin
						axi_awready_next = 1'b0;
						if (is_read) begin
							write_finish_flag_next = write_finish_flag ? 1'b1 : counters_equal && !s_awrite_beat_ready;
						end else begin
							write_finish_flag_next = write_finish_flag ? 1'b1 : s_write_resp_beat_ready;
						end
					end
					// S_AXI_WREADY signal
					if (is_read) begin
						if (wlast_counter < declared_transaction_counter) begin
							axi_wready_next = s_write_beat_ready ? m_write_beat_ready : !axi_wvalid_reg || m_axi_wready;
						end else begin
							axi_wready_next = 1'b0;
						end
					end else begin
						if (wlast_counter == 0) begin
							axi_wready_next = s_write_beat_ready ? m_write_beat_ready : !axi_wvalid_reg || m_axi_wready;
						end else begin
							axi_wready_next = 1'b0;
						end
					end

					// Read Transaction
					// S_AXI_ARREADY signal and read flags
					if (!is_read && !write_finish_flag) begin
						axi_arready_next = !s_aread_beat_ready && !axi_arvalid_reg || m_axi_arready;
						read_finish_flag_next = 1'b0;
					end else begin
						axi_arready_next = 1'b0;
						if (is_read) begin
							read_finish_flag_next = read_finish_flag ? 1'b1 : s_read_beat_ready && axi_rlast_reg;
						end else begin
							read_finish_flag_next = read_finish_flag ? 1'b1 : counters_equal && !s_aread_beat_ready;
						end
					end

					// declared_transaction_counter update
					if ((is_read && s_awrite_beat_ready) || (!is_read && s_aread_beat_ready)) begin
						declared_transaction_counter_next = declared_transaction_counter + 1;
					end
					// completed_transaction_counter update
					if ((is_read && s_write_resp_beat_ready) || (!is_read && s_read_beat_ready && axi_rlast_reg)) begin
						completed_transaction_counter_next = completed_transaction_counter + 1;
					end
					// wlast_counter update
					if (s_write_beat_ready && axi_wlast_selected) begin
						wlast_counter_next = wlast_counter + 1;
					end

				end

				ST_FINISH: begin
					write_last_flag_next = 1'b0;
					read_finish_flag_next = 1'b0;
					wlast_counter_next = 0;
					declared_transaction_counter_next = 1'b0;
					completed_transaction_counter_next = 1'b0;
				end
			endcase
		end

		always_ff @ (posedge clk or negedge resetn) begin
			if (~resetn) begin
				wlast_counter <= 0;
				declared_transaction_counter <= 0;
				completed_transaction_counter <= 0;
			end else begin
				wlast_counter <= wlast_counter_next;
				declared_transaction_counter <= declared_transaction_counter_next;
				completed_transaction_counter <= completed_transaction_counter_next;
			end
		end

	end
endgenerate

// Rest of the internal signals
always_comb begin
	axi_awvalid_next = 1'b0;
	axi_wvalid_next = 1'b0;
	axi_bready_next = 1'b0;
	axi_bvalid_next = 1'b0;
	axi_arvalid_next = 1'b0;
	axi_rvalid_next = 1'b0;
	axi_rready_next = 1'b0;
	is_read_next = is_read;
	case (curr_state)
		ST_IDLE: begin
			is_read_next = axi_arvalid_selected;
		end
		ST_TRANSACTION: begin
			// write address channel
			if (s_awrite_beat_ready) begin
				axi_awid_next = axi_awid_selected;
				axi_awaddr_next = axi_awaddr_selected;
				axi_awlen_next = axi_awlen_selected;
				axi_awsize_next = axi_awsize_selected;
				axi_awburst_next = axi_awburst_selected;
				axi_awlock_next = axi_awlock_selected;
				axi_awcache_next = axi_awcache_selected;
				axi_awprot_next = axi_awprot_selected;
				axi_awqos_next = axi_awqos_selected;
				axi_awuser_next = axi_awuser_selected;
				axi_awvalid_next = 1'b1;
			end else begin
				axi_awid_next = axi_awid_reg;
				axi_awaddr_next = axi_awaddr_reg;
				axi_awlen_next = axi_awlen_reg;
				axi_awsize_next = axi_awsize_reg;
				axi_awburst_next = axi_awburst_reg;
				axi_awlock_next = axi_awlock_reg;
				axi_awcache_next = axi_awcache_reg;
				axi_awprot_next = axi_awprot_reg;
				axi_awqos_next = axi_awqos_reg;
				axi_awuser_next = axi_awuser_reg;
				axi_awvalid_next = m_awrite_beat_ready? 1'b0 : axi_awvalid_reg;
			end
			// write data channel
			if (s_write_beat_ready) begin
				axi_wdata_next = axi_wdata_selected;
				axi_wstrb_next = axi_wstrb_selected;
				axi_wlast_next = axi_wlast_selected;
				axi_wuser_next = axi_wuser_selected;
				axi_wvalid_next = 1'b1;
			end else begin
				axi_wdata_next = axi_wdata_reg;
				axi_wstrb_next = axi_wstrb_reg;
				axi_wlast_next = axi_wlast_reg;
				axi_wuser_next = axi_wuser_reg;
				axi_wvalid_next = m_write_beat_ready ? 1'b0 : axi_wvalid_reg;
			end
			// write response channel
			axi_bready_next = !axi_bvalid_reg || axi_bready_selected;
			if (m_write_resp_beat_ready) begin
				axi_bid_next = m_axi_bid;
				axi_bresp_next = m_axi_bresp;
				axi_buser_next = m_axi_buser;
				axi_bvalid_next = 1'b1;
			end else begin
				axi_bid_next = axi_bid_reg;
				axi_bresp_next = axi_bresp_reg;
				axi_buser_next = axi_buser_reg;
				axi_bvalid_next = s_write_resp_beat_ready ? 1'b0 : axi_bvalid_reg;
			end
			// read address channel
			if (s_aread_beat_ready) begin
				axi_arid_next = axi_arid_selected;
				axi_araddr_next = axi_araddr_selected;
				axi_arlen_next = axi_arlen_selected;
				axi_arsize_next = axi_arsize_selected;
				axi_arburst_next = axi_arburst_selected;
				axi_arlock_next = axi_arlock_selected;
				axi_arcache_next = axi_arcache_selected;
				axi_arprot_next = axi_arprot_selected;
				axi_arqos_next = axi_arqos_selected;
				axi_aruser_next = axi_aruser_selected;
				axi_arvalid_next = 1'b1;
			end else begin
				axi_arid_next = axi_arid_reg;
				axi_araddr_next = axi_araddr_reg;
				axi_arlen_next = axi_arlen_reg;
				axi_arsize_next = axi_arsize_reg;
				axi_arburst_next = axi_arburst_reg;
				axi_arlock_next = axi_arlock_reg;
				axi_arcache_next = axi_arcache_reg;
				axi_arprot_next = axi_arprot_reg;
				axi_arqos_next = axi_arqos_reg;
				axi_aruser_next = axi_aruser_reg;
				axi_arvalid_next = m_aread_beat_ready ? 1'b0 : axi_arvalid_reg;
			end
			// read data channel
			// S_AXI_RREADY signal
			if (read_finish_flag) begin
				axi_rready_next = 0;
			end else begin
				axi_rready_next = m_read_beat_ready ? s_read_beat_ready : (!axi_rvalid_reg || axi_rready_selected);
			end
			if (m_read_beat_ready) begin
				axi_rid_next = m_axi_rid;
				axi_rdata_next = m_axi_rdata;
				axi_rresp_next = m_axi_rresp;
				axi_rlast_next = m_axi_rlast;
				axi_ruser_next = m_axi_ruser;
				axi_rvalid_next = 1'b1;
			end else begin
				axi_rid_next = axi_rid_reg;
				axi_rdata_next = axi_rdata_reg;
				axi_rresp_next = axi_rresp_reg;
				axi_rlast_next = axi_rlast_reg;
				axi_ruser_next = axi_ruser_reg;
				axi_rvalid_next = s_read_beat_ready ? 1'b0 : axi_rvalid_reg;
			end
		end
	endcase
end

// Regfile Assignment
always_ff @ (posedge clk or negedge resetn) begin
	if (~resetn) begin
		axi_awvalid_reg <= 0;
		axi_awready_reg <= 0;
		axi_wvalid_reg <= 0;
		axi_wready_reg <= 0;
		axi_bvalid_reg <= 0;
		axi_bready_reg <= 0;
		axi_arvalid_reg <= 0;
		axi_arready_reg <= 0;
		axi_rready_reg <= 0;
		axi_rvalid_reg <= 0;
		read_finish_flag <= 0;
		write_finish_flag <= 0;
		is_read <= 0;
	end else begin
		axi_awid_reg <= axi_awid_next;
		axi_awaddr_reg <= axi_awaddr_next;
		axi_awlen_reg <= axi_awlen_next;
		axi_awsize_reg <= axi_awsize_next;
		axi_awburst_reg <= axi_awburst_next;
		axi_awlock_reg <= axi_awlock_next;
		axi_awcache_reg <= axi_awcache_next;
		axi_awprot_reg <= axi_awprot_next;
		axi_awqos_reg <= axi_awqos_next;
		axi_awregion_reg <= axi_awregion_next;
		axi_awuser_reg <= axi_awuser_next;
		axi_awvalid_reg <= axi_awvalid_next;
		axi_awready_reg <= axi_awready_next;
		axi_wdata_reg <= axi_wdata_next;
		axi_wstrb_reg <= axi_wstrb_next;
		axi_wlast_reg <= axi_wlast_next;
		axi_wuser_reg <= axi_wuser_next;
		axi_wvalid_reg <= axi_wvalid_next;
		axi_wready_reg <= axi_wready_next;
		axi_bid_reg <= axi_bid_next;
		axi_bresp_reg <= axi_bresp_next;
		axi_buser_reg <= axi_buser_next;
		axi_bvalid_reg <= axi_bvalid_next;
		axi_bready_reg <= axi_bready_next;
		axi_arid_reg <= axi_arid_next;
		axi_araddr_reg <= axi_araddr_next;
		axi_arlen_reg <= axi_arlen_next;
		axi_arsize_reg <= axi_arsize_next;
		axi_arburst_reg <= axi_arburst_next;
		axi_arlock_reg <= axi_arlock_next;
		axi_arcache_reg <= axi_arcache_next;
		axi_arprot_reg <= axi_arprot_next;
		axi_arqos_reg <= axi_arqos_next;
		axi_arregion_reg <= axi_arregion_next;
		axi_aruser_reg <= axi_aruser_next;
		axi_arvalid_reg <= axi_arvalid_next;
		axi_arready_reg <= axi_arready_next;
		axi_rid_reg <= axi_rid_next;
		axi_rdata_reg <= axi_rdata_next;
		axi_rresp_reg <= axi_rresp_next;
		axi_rlast_reg <= axi_rlast_next;
		axi_ruser_reg <= axi_ruser_next;
		axi_rvalid_reg <= axi_rvalid_next;
		axi_rready_reg <= axi_rready_next;
		read_finish_flag <= read_finish_flag_next;
		write_finish_flag <= write_finish_flag_next;
		is_read <= is_read_next;
	end
end

endmodule

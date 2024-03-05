module axi_fifo # (
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
	// FIFO size (power of 2)
	parameter C_FIFO_SIZE = 128
)
(
    // Clock and Resetn
	input logic clk,
	input logic resetn,

	/*
		Slave Interface
	*/
	input  logic [C_ID_WIDTH-1:0]   s_axi_awid,
    input  logic [C_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  logic [7:0]              s_axi_awlen,
    input  logic [2:0]              s_axi_awsize,
    input  logic [1:0]              s_axi_awburst,
    input  logic                    s_axi_awlock,
    input  logic [3:0]              s_axi_awcache,
    input  logic [2:0]              s_axi_awprot,
    input  logic [3:0]              s_axi_awqos,
    input  logic [C_USER_WIDTH-1:0] s_axi_awuser,
    input  logic                    s_axi_awvalid,
    output logic                    s_axi_awready,
    input  logic [C_DATA_WIDTH-1:0] s_axi_wdata,
    input  logic [C_STRB_WIDTH-1:0] s_axi_wstrb,
    input  logic                    s_axi_wlast,
    input  logic [C_USER_WIDTH-1:0] s_axi_wuser,
    input  logic                    s_axi_wvalid,
    output logic                    s_axi_wready,
    output logic [C_ID_WIDTH-1:0]   s_axi_bid,
    output logic [1:0]              s_axi_bresp,
    output logic [C_USER_WIDTH-1:0] s_axi_buser,
    output logic                    s_axi_bvalid,
    input  logic                    s_axi_bready,
    input  logic [C_ID_WIDTH-1:0]   s_axi_arid,
    input  logic [C_ADDR_WIDTH-1:0] s_axi_araddr,
    input  logic [7:0]              s_axi_arlen,
    input  logic [2:0]              s_axi_arsize,
    input  logic [1:0]              s_axi_arburst,
    input  logic                    s_axi_arlock,
    input  logic [3:0]              s_axi_arcache,
    input  logic [2:0]              s_axi_arprot,
    input  logic [3:0]              s_axi_arqos,
    input  logic [C_USER_WIDTH-1:0] s_axi_aruser,
    input  logic                    s_axi_arvalid,
    output logic                    s_axi_arready,
    output logic [C_ID_WIDTH-1:0]   s_axi_rid,
    output logic [C_DATA_WIDTH-1:0] s_axi_rdata,
    output logic [1:0]              s_axi_rresp,
    output logic                    s_axi_rlast,
    output logic [C_USER_WIDTH-1:0] s_axi_ruser,
    output logic                    s_axi_rvalid,
    input  logic                    s_axi_rready,

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
    output logic                    m_axi_rready,

    /*
        FIFO signals
    */
    output reg waddr_empty,
    output reg waddr_full,
    output reg wdata_empty,
    output reg wdata_full,
    output reg wresp_empty,
    output reg wresp_full,
    output reg raddr_empty,
    output reg raddr_full,
    output reg rdata_empty,
    output reg rdata_full
)

localparam ADDR_BUS_WIDTH = C_ID_WIDTH + C_ADDR_WIDTH + 25 + C_USER_WIDTH;
localparam WDATA_BUS_WIDTH = C_DATA_WIDTH + C_STRB_WIDTH + 1 + C_USER_WIDTH;
localparam WRESP_BUS_WIDTH = C_ID_WIDTH + 2 + C_USER_WIDTH;
localparam RDATA_BUS_WIDTH = C_ID_WIDTH + C_DATA_WIDTH + 3 + C_USER_WIDTH;

localparam C_FIFO_SIZE_LOG = $clog2(C_FIFO_SIZE);

/*
    Write
*/

// Beat-ready-to-be-transmitted
logic s_awrite_beat_ready, s_write_beat_ready, s_write_resp_beat_ready;
logic m_awrite_beat_ready, m_write_beat_ready, m_write_resp_beat_ready;

assign s_awrite_beat_ready = s_axi_awvalid && s_axi_awready;
assign s_write_beat_ready = s_axi_wvalid && s_axi_wready;
assign s_write_resp_beat_ready = s_axi_bvalid && s_axi_bready;

assign m_awrite_beat_ready = m_axi_awvalid && m_axi_awready;
assign m_write_beat_ready = m_axi_wvalid && m_axi_wready;
assign m_write_resp_beat_ready = m_axi_bvalid && m_axi_bready;

// Auxiliary signals
logic waddr_write_update, wdata_write_update, wresp_write_update;
logic waddr_read_update, wdata_read_update, wresp_read_update;

assign waddr_write_update = s_awrite_beat_ready && !m_awrite_beat_ready;
assign wdata_write_update = s_write_beat_ready && !m_write_beat_ready;
assign wresp_write_update = m_write_resp_beat_ready && !s_write_resp_beat_ready;

assign waddr_read_update = !s_awrite_beat_ready && m_awrite_beat_ready;
assign wdata_read_update = !s_write_beat_ready && m_write_beat_ready;
assign wresp_read_update = !m_write_resp_beat_ready && s_write_resp_beat_ready;

// SRAM
reg [ADDR_BUS_WIDTH-1:0]  write_address_sram [C_FIFO_SIZE-1:0];
reg [WDATA_BUS_WIDTH-1:0] write_data_sram [C_FIFO_SIZE-1:0];
reg [WRESP_BUS_WIDTH-1:0] write_response_sram [C_FIFO_SIZE-1:0];

// Pointers
reg [C_FIFO_SIZE_LOG-1:0] waddr_read_ptr, waddr_write_ptr;
reg [C_FIFO_SIZE_LOG-1:0] wdata_read_ptr, wdata_write_ptr;
reg [C_FIFO_SIZE_LOG-1:0] wresp_read_ptr, wresp_write_ptr;

logic [C_FIFO_SIZE_LOG-1:0] waddr_read_ptr_next, waddr_write_ptr_next;
logic [C_FIFO_SIZE_LOG-1:0] wdata_read_ptr_next, wdata_write_ptr_next;
logic [C_FIFO_SIZE_LOG-1:0] wresp_read_ptr_next, wresp_write_ptr_next;

// Flags
logic waddr_empty_next, waddr_full_next;
logic wdata_empty_next, wdata_full_next;
logic wresp_empty_next, wresp_full_next;

// Difference counters
logic [C_FIFO_SIZE_LOG:0] diff_counter_waddr, diff_counter_waddr_next;
logic [C_FIFO_SIZE_LOG:0] diff_counter_wdata, diff_counter_wdata_next;
logic [C_FIFO_SIZE_LOG:0] diff_counter_wresp, diff_counter_wresp_next;

always_comb begin
    // Full flag
    waddr_full_next = waddr_full;
    wdata_full_next = wdata_full;
    wresp_full_next = wresp_full;

    if (waddr_full == 1'b1 && waddr_read_update) begin
        waddr_full_next = 1'b0;
    end else if (diff_counter_waddr == C_FIFO_SIZE-1 && waddr_write_update) begin
        waddr_full_next = 1'b1;
    end

    if (wdata_full == 1'b1 && wdata_read_update) begin
        wdata_full_next = 1'b0;
    end else if (diff_counter_wdata == C_FIFO_SIZE-1 && wdata_write_update) begin
        wdata_full_next = 1'b1;
    end

    if (wresp_full == 1'b1 && wresp_read_update) begin
        wresp_full_next = 1'b0;
    end else if (diff_counter_wresp == C_FIFO_SIZE-1 && wresp_write_update) begin
        wresp_full_next = 1'b1;
    end

    // Empty flag
    waddr_empty_next = waddr_empty;
    wdata_empty_next = wdata_empty;
    wresp_empty_next = wresp_empty;

    if (waddr_empty == 1'b1 && s_awrite_beat_ready) begin
        waddr_empty_next = 1'b0;
    end else if (diff_counter_waddr == 1 && waddr_read_update) begin
        waddr_empty_next = 1'b1;
    end

    if (wdata_empty == 1'b1 && s_write_beat_ready) begin
        wdata_empty_next = 1'b0;
    end else if (diff_counter_wdata == 1 && wdata_read_update) begin
        wdata_empty_next = 1'b1;
    end

    if (wresp_empty == 1'b1 && m_write_resp_beat_ready) begin
        wresp_empty_next = 1'b0;
    end else if (diff_counter_wresp == 1 && wresp_read_update) begin
        wresp_empty_next = 1'b1;
    end

    // Difference counters
    diff_counter_waddr_next = diff_counter_waddr;
    diff_counter_wdata_next = diff_counter_wdata;
    diff_counter_wresp_next = diff_counter_wresp;

    if (waddr_write_update) begin
        diff_counter_waddr_next = diff_counter_waddr + 1;
    end else if (waddr_read_update) begin
        diff_counter_waddr_next = diff_counter_waddr - 1;
    end

    if (wdata_write_update) begin
        diff_counter_wdata_next = diff_counter_wdata + 1;
    end else if (wdata_read_update) begin
        diff_counter_wdata_next = diff_counter_wdata - 1;
    end

    if (wresp_write_update) begin
        diff_counter_wresp_next = diff_counter_wresp + 1;
    end else if (wresp_read_update) begin
        diff_counter_wresp_next = diff_counter_wresp - 1;
    end

end

always_ff @ (posedge clk or negedge resetn) begin
    if (~resetn) begin
        // Slave-side
        waddr_read_ptr <= 0;
        waddr_write_ptr <= 0;
        wdata_read_ptr <= 0;
        wdata_write_ptr <= 0;
        waddr_full <= 1'b0;
        wdata_full <= 1'b0;
        wresp_empty <= 1'b0;
        s_axi_awready <= 1'b0;
        s_axi_wready <= 1'b0;
        s_axi_bvalid <= 1'b0;
        // Master-side
        wresp_read_ptr <= 0;
        wresp_write_ptr <= 0;
        waddr_empty <= 1'b0;
        wdata_empty <= 1'b0;
        wresp_full <= 1'b0;
        m_axi_awvalid <= 1'b0;
        m_axi_wvalid <= 1'b0;
        m_axi_bready <= 1'b0;
    end else begin
        // Full flag
        if ()
        // Empty flag
    end
end

/*
    Read
*/

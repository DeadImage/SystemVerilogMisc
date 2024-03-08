/*

Serves as an AXI-Lite - AXI-Stream converter, where AXI-Stream Data Width > AXI-Lite Data Width.
Converts data both ways.

*/
module gpc_axi_register # (
	// Address Bus width in AXI-Lite interface
	parameter AXIL_ADDR_WIDTH = 64,
	// Data Bus width in AXI-Lite interface
	parameter AXIL_DATA_WIDTH = 64,
	//Strobe Bus width in AXI-Lite
	parameter AXIL_STRB_WIDTH = AXIL_DATA_WIDTH / 8,
	// Data Bus width in AXI-Stream
	parameter AXIS_DATA_WIDTH = 512,
	// TKEEP width in AXI-Stream
	parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH / 8
)
(
	input wire                         clk,
	input wire                         rst,
	// AXI-Lite Read IF
	input  wire [AXIL_ADDR_WIDTH-1:0]  s_axil_araddr,
	input  wire [2:0]                  s_axil_arprot,
	input  wire                        s_axil_arvalid,
	output wire                        s_axil_arready,
	output wire [AXIL_DATA_WIDTH-1:0]  s_axil_rdata,
	output wire                        s_axil_rvalid,
	input  wire                        s_axil_rready,
	output wire [1:0]                  s_axil_rresp,
	// AXI-Lite Write IF
	input  wire [AXIL_ADDR_WIDTH-1:0]  s_axil_awaddr,
	input  wire [2:0]                  s_axil_awprot,
	input  wire                        s_axil_awvalid,
	output wire                        s_axil_awready,
	input  wire [AXIL_DATA_WIDTH-1:0]  s_axil_wdata,
	input  wire [AXIL_STRB_WIDTH-1:0]  s_axil_wstrb,
	input  wire                        s_axil_wvalid,
	output wire                        s_axil_wready,
	output wire [1:0]                  s_axil_bresp,
	output wire                        s_axil_bvalid,
	input  wire                        s_axil_bready,
	// AXI-Stream from CMAC
	input  wire [AXIS_DATA_WIDTH-1:0]  s_axis_tdata,
	input  wire [AXIS_KEEP_WIDTH-1:0] s_axis_tkeep,
	input  wire                        s_axis_tvalid,
	output wire                        s_axis_tready,
	input  wire                        s_axis_tlast,
	// AXI-Stream to CMAC
	output wire [AXIS_DATA_WIDTH-1:0]  m_axis_tdata,
	output wire [AXIS_KEEP_WIDTH-1:0] m_axis_tkeep,
	output wire                        m_axis_tvalid,
	input  wire                        m_axis_tready,
	output wire                        m_axis_tlast
);

localparam integer FRAME_BYTE_SIZE = 60;
localparam integer MEM_CELL_NUM = $floor(FRAME_BYTE_SIZE*8 / AXIL_DATA_WIDTH) + 2; // ceil doesn't work for whatever reason
localparam integer MEM_PTR_WIDTH = $clog2(8*(MEM_CELL_NUM-1));

// Memory cells for data
reg [AXIL_DATA_WIDTH*MEM_CELL_NUM*2-1:0] mem;

// Memory signals
reg [MEM_PTR_WIDTH-1:0] read_ptr;
reg read_mem_full;

reg [MEM_PTR_WIDTH-1:0] write_ptr;
reg write_mem_full;

// Beat-ready-to-be-transferred signals
wire axis_read_beat_ready = s_axis_tvalid & s_axis_tready;
wire axis_write_beat_ready = m_axis_tvalid & m_axis_tready;
wire axil_raddr_beat_ready = s_axil_arready & s_axil_arvalid;
wire axil_rdata_beat_ready = s_axil_rready & s_axil_rvalid;
wire axil_waddr_beat_ready = s_axil_awready & s_axil_awvalid;
wire axil_wdata_beat_ready = s_axil_wready & s_axil_wvalid;
wire axil_wresp_beat_ready = s_axil_bready & s_axil_bvalid;

// Reg to output
reg                       s_axil_arready_reg;
reg [AXIL_DATA_WIDTH-1:0] s_axil_rdata_reg;
reg                       s_axil_rvalid_reg;
reg [1:0]                 s_axil_rresp_reg;
reg                       s_axil_awready_reg;
reg                       s_axil_wready_reg;
reg [1:0]                 s_axil_bresp_reg;
reg                       s_axil_bvalid_reg;
reg                       s_axis_tready_reg;
reg [AXIS_DATA_WIDTH-1:0] m_axis_tdata_reg;
reg [AXIS_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
reg                       m_axis_tlast_reg;
reg                       m_axis_tvalid_reg;

assign s_axil_arready = s_axil_arready_reg;
assign s_axil_rdata = s_axil_rdata_reg;
assign s_axil_rvalid = s_axil_rvalid_reg;
assign s_axil_rresp = s_axil_rresp_reg;
assign s_axil_awready = s_axil_awready_reg;
assign s_axil_wready = s_axil_wready_reg;
assign s_axil_bresp = s_axil_bresp_reg;
assign s_axil_bvalid = s_axil_bvalid_reg;
assign s_axis_tready = s_axis_tready_reg;
assign m_axis_tdata = m_axis_tdata_reg;
assign m_axis_tkeep = m_axis_tkeep_reg;
assign m_axis_tlast = m_axis_tlast_reg;
assign m_axis_tvalid = m_axis_tvalid_reg;

// AXIL state registers
enum reg [1:0] {ST_READ_IDLE, ST_READ_DATA} axil_read_state;
enum reg [1:0] {ST_WRITE_IDLE, ST_WRITE_DATA, ST_WRITE_RESP} axil_write_state;

// AXI-Lite read and write address
reg [AXIL_ADDR_WIDTH-1:0] curr_read_addr, curr_write_addr;

/*
	AXI-Lite Behavior
*/

// Read
wire [AXIL_DATA_WIDTH-1:0] addressed_mem;
assign addressed_mem = mem[8*s_axil_araddr +: AXIL_DATA_WIDTH];

// Regions of memory above 511 (in bits) contain memory validity data or meant for
// write-only purposes, so an attempt to read from those must not increment read_ptr
wire validity_requested = curr_read_addr > AXIL_DATA_WIDTH * (MEM_CELL_NUM - 1) - 1;

always_ff @ (posedge clk or posedge rst) begin
	if (rst) begin
		s_axil_arready_reg <= 1'b0;
		s_axil_rvalid_reg <= 1'b0;
		axil_read_state <= ST_READ_IDLE;
		read_ptr <= 0;
		curr_read_addr <= 0;
	end else begin
		case (axil_read_state)
			ST_READ_IDLE: begin
				if (axil_raddr_beat_ready) begin
					s_axil_arready_reg <= 1'b0;
					curr_read_addr <= s_axil_araddr;
					s_axil_rdata_reg <= addressed_mem;
					s_axil_rresp_reg <= 2'b00;
					s_axil_rvalid_reg <= 1'b1;
					axil_read_state <= ST_READ_DATA;
				end else begin
					s_axil_arready_reg <= 1'b1;
					axil_read_state <= ST_READ_IDLE;
				end
			end
			ST_READ_DATA: begin
				if (axil_rdata_beat_ready) begin
					s_axil_rvalid_reg <= 1'b0;
					s_axil_arready_reg <= 1'b1;
					axil_read_state <= ST_READ_IDLE;
					read_ptr <= !validity_requested ? read_ptr + AXIL_STRB_WIDTH : read_ptr;
				end else begin
					s_axil_rvalid_reg <= 1'b1;
					s_axil_arready_reg <= 1'b0;
					axil_read_state <= ST_READ_DATA;
				end
			end
		endcase
	end
end

// Write
always_ff @ (posedge clk or posedge rst) begin
	if (rst) begin
		s_axil_awready_reg <= 1'b0;
		s_axil_wready_reg <= 1'b0;
		s_axil_bvalid_reg <= 1'b0;
		axil_write_state <= ST_WRITE_IDLE;
		write_ptr <= 0;
		curr_write_addr <= 0;
	end else begin
		case (axil_write_state)
			ST_WRITE_IDLE: begin
				s_axil_bvalid_reg <= 1'b0;
				if (axil_waddr_beat_ready) begin
					s_axil_awready_reg <= 1'b0;
					curr_write_addr <= s_axil_awaddr;
					s_axil_wready_reg <= 1'b1;
					axil_write_state <= ST_WRITE_DATA;
				end else begin
					s_axil_awready_reg <= !write_mem_full;
					s_axil_wready_reg <= 1'b0;
					axil_write_state <= ST_WRITE_IDLE;
				end
			end
			ST_WRITE_DATA: begin
				s_axil_awready_reg <= 1'b0;
				if (axil_wdata_beat_ready) begin
					s_axil_wready_reg <= 1'b0;
					mem[8*curr_write_addr +: AXIL_DATA_WIDTH] <= s_axil_wdata;
					m_axis_tkeep_reg[write_ptr +: 8] <= s_axil_wstrb;
					write_ptr <= write_ptr + AXIL_STRB_WIDTH;
					s_axil_bvalid_reg <= 1'b1;
					s_axil_bresp_reg <= 2'b00;
					axil_write_state <= ST_WRITE_RESP;
				end else begin
					s_axil_wready_reg <= 1'b1;
					s_axil_bvalid_reg <= 1'b0;
					axil_write_state <= ST_WRITE_DATA;
				end
			end
			ST_WRITE_RESP: begin
				s_axil_bresp_reg <= 2'b00;
				s_axil_wready_reg <= 1'b0;
				if (axil_wresp_beat_ready) begin
					s_axil_bvalid_reg <= 1'b0;
					s_axil_awready_reg <= !write_mem_full;
					axil_write_state <= ST_WRITE_IDLE;
				end else begin
					s_axil_bvalid_reg <= 1'b1;
					s_axil_awready_reg <= 1'b0;
					axil_write_state <= ST_WRITE_RESP;
				end
			end
		endcase
	end
end

// write validity logic (cuz it depends on both AXIL and AXIS)
always_ff @ (posedge clk or posedge rst) begin
	if (rst) begin
		write_mem_full <= 1'b0;
		mem[AXIL_DATA_WIDTH*MEM_CELL_NUM*2-1 -: AXIL_DATA_WIDTH] <= {AXIL_DATA_WIDTH{1'b1}};
	end else begin
		if (axis_write_beat_ready) begin
			write_mem_full <= 1'b0;
			mem[AXIL_DATA_WIDTH*MEM_CELL_NUM*2-1 -: AXIL_DATA_WIDTH] <= {AXIL_DATA_WIDTH{1'b1}};
		end else if (axil_wdata_beat_ready && write_ptr == (MEM_CELL_NUM-2) * AXIL_STRB_WIDTH) begin
			write_mem_full <= 1'b1;
			mem[AXIL_DATA_WIDTH*MEM_CELL_NUM*2-1 -: AXIL_DATA_WIDTH] <= {AXIL_DATA_WIDTH{1'b0}};
		end
	end
end

/*
	AXI-Stream behavior
*/

// Read
always_ff @ (posedge clk or posedge rst) begin
	if (rst) begin
		s_axis_tready_reg <= 1'b0;
		mem[AXIL_DATA_WIDTH*MEM_CELL_NUM-1 -: AXIL_DATA_WIDTH] <= {AXIL_DATA_WIDTH{1'b0}};
		read_mem_full <= 1'b0;
	end else begin
		if (!read_mem_full) begin
			if (axis_read_beat_ready) begin
				s_axis_tready_reg <= 1'b0;
				mem[AXIL_DATA_WIDTH*(MEM_CELL_NUM-1)-1 -: AXIS_DATA_WIDTH] <= s_axis_tdata;
                mem[AXIL_DATA_WIDTH*MEM_CELL_NUM-1 -: AXIL_DATA_WIDTH] <= {AXIL_DATA_WIDTH{1'b1}};
                read_mem_full <= 1'b1;
			end else begin
				s_axis_tready_reg <= 1'b1;
				read_mem_full <= 1'b0;
				mem[AXIL_DATA_WIDTH*MEM_CELL_NUM-1 -: AXIL_DATA_WIDTH] <= {AXIL_DATA_WIDTH{1'b0}};
			end
		end else begin
			if (read_ptr == (MEM_CELL_NUM-2) * AXIL_STRB_WIDTH && axil_rdata_beat_ready) begin
				read_mem_full <= 1'b0;
				mem[AXIL_DATA_WIDTH*MEM_CELL_NUM-1 -: AXIL_DATA_WIDTH] <= {AXIL_DATA_WIDTH{1'b0}};
				s_axis_tready_reg <= 1'b1;
			end else begin
				read_mem_full <= 1'b1;
				s_axis_tready_reg <= 1'b0;
			end
		end
	end
end

// Write
always_ff @ (posedge clk or posedge rst) begin
	if (rst) begin
		m_axis_tvalid_reg <= 1'b0;
	end else begin
		m_axis_tdata_reg <= mem[AXIL_DATA_WIDTH*(2*MEM_CELL_NUM-1)-1 -: AXIS_DATA_WIDTH];
		m_axis_tlast_reg <= 1'b1;
		if (write_mem_full) begin
			m_axis_tvalid_reg <= !axis_write_beat_ready;
		end else begin
			m_axis_tvalid_reg <= 1'b0;
		end
	end
end

endmodule

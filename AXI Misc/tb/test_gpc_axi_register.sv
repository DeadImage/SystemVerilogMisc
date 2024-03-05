`resetall
`timescale 1ns / 1ps
`default_nettype wire

module test_gpc_axi_register # (
	// Address Bus width in AXI-Lite interface
	parameter AXIL_ADDR_WIDTH = 64,
	// Data Bus width in both AXI-Lite interface
	parameter AXIL_DATA_WIDTH = 64,
	// Strobe Bus width in AXI-Lite
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
	input  wire [AXIS_KEEP_WIDTH-1:0]  s_axis_tkeep,
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

gpc_axi_register # (
    .AXIL_ADDR_WIDTH(AXIL_ADDR_WIDTH),
	.AXIL_DATA_WIDTH(AXIL_DATA_WIDTH),
	.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)
) gpc_axi_register_inst (
	.clk            (clk),
	.rst            (rst),
	.s_axil_araddr  (s_axil_araddr),
	.s_axil_arprot  (s_axil_arprot),
	.s_axil_arvalid (s_axil_arvalid),
	.s_axil_arready (s_axil_arready),
	.s_axil_rdata   (s_axil_rdata),
	.s_axil_rvalid  (s_axil_rvalid),
	.s_axil_rready  (s_axil_rready),
	.s_axil_rresp   (s_axil_rresp),
	.s_axis_tdata   (s_axis_tdata),
	.s_axis_tkeep   (s_axis_tkeep),
	.s_axis_tvalid  (s_axis_tvalid),
	.s_axis_tready  (s_axis_tready),
	.s_axis_tlast   (s_axis_tlast),
	.s_axil_awaddr  (s_axil_awaddr),
	.s_axil_awprot  (s_axil_awprot),
	.s_axil_awvalid (s_axil_awvalid),
	.s_axil_awready (s_axil_awready),
	.s_axil_wdata   (s_axil_wdata),
	.s_axil_wstrb   (s_axil_wstrb),
	.s_axil_wvalid  (s_axil_wvalid),
	.s_axil_wready  (s_axil_wready),
	.s_axil_bresp   (s_axil_bresp),
	.s_axil_bvalid  (s_axil_bvalid),
	.s_axil_bready  (s_axil_bready),
	.m_axis_tdata   (m_axis_tdata),
	.m_axis_tkeep   (m_axis_tkeep),
	.m_axis_tvalid  (m_axis_tvalid),
	.m_axis_tready  (m_axis_tready),
	.m_axis_tlast   (m_axis_tlast)
);

initial begin
    $dumpfile("waves.vcd");
    $dumpvars;
end

endmodule

`resetall

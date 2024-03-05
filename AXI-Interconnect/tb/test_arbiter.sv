`default_nettype wire
`resetall
`timescale 1ns / 1ps

/*
 * Arbiter testbench
 */

 module test_arbiter # (
	parameter PORTS = 6,
	// select round robin arbitration
	parameter ARB_TYPE_ROUND_ROBIN = 1,
	// blocking arbiter enable
	parameter ARB_BLOCK = 1,
	// block on acknowledge assert when nonzero, request deassert when 0
	parameter ARB_BLOCK_ACK = 1,
	// LSB priority selection
	parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
	input logic clk,
	input logic resetn,

	input logic [PORTS-1:0] request,
	input logic [PORTS-1:0] acknowledge,

	output logic [PORTS-1:0]         grant,
	output logic                     grant_valid,
	output logic [$clog2(PORTS)-1:0] grant_encoded
);

arbiter # (
    .PORTS(PORTS),
    .ARB_TYPE_ROUND_ROBIN(ARB_TYPE_ROUND_ROBIN),
    .ARB_BLOCK(ARB_BLOCK),
    .ARB_BLOCK_ACK(ARB_BLOCK_ACK),
    .ARB_LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
) arbiter_inst (
    .clk(clk),
    .resetn(resetn),
    .request(request),
    .acknowledge(acknowledge),
    .grant(grant),
    .grant_valid(grant_valid),
    .grant_encoded(grant_encoded)
);

initial begin
    $dumpfile("waves.vcd");
    $dumpvars;
end

endmodule

`resetall

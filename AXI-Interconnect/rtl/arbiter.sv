/*

Copyright (c) 2014-2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

module arbiter # (
	parameter PORTS = 4,
	// select round robin arbitration
	parameter ARB_TYPE_ROUND_ROBIN = 0,
	// blocking arbiter enable
	parameter ARB_BLOCK = 0,
	// block on acknowledge assert when nonzero, request deassert when 0
	parameter ARB_BLOCK_ACK = 1,
	// LSB priority selection
	parameter ARB_LSB_HIGH_PRIORITY = 0
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

logic [PORTS-1:0]         grant_reg = 0, grant_next;
logic                     grant_valid_reg = 0, grant_valid_next;
logic [$clog2(PORTS)-1:0] grant_encoded_reg = 0, grant_encoded_next;

assign grant_valid = grant_valid_reg;
assign grant = grant_reg;
assign grant_encoded = grant_encoded_reg;

logic                     request_valid;
logic [$clog2(PORTS)-1:0] request_index;
logic [PORTS-1:0]         request_mask;

// request encoder
priority_encoder #(
    .INPUT_WIDTH(PORTS),
    .LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
)
priority_encoder_request (
    .input_unencoded(request),
    .output_valid(request_valid),
    .output_encoded(request_index),
    .output_unencoded(request_mask)
);

logic [PORTS-1:0] mask_reg = 0, mask_next;

logic masked_request_valid;
logic [$clog2(PORTS)-1:0] masked_request_index;
logic [PORTS-1:0] masked_request_mask;

// masked request encoder
priority_encoder #(
    .INPUT_WIDTH(PORTS),
    .LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
)
priority_encoder_masked (
    .input_unencoded(request & mask_reg),
    .output_valid(masked_request_valid),
    .output_encoded(masked_request_index),
    .output_unencoded(masked_request_mask)
);

always_comb begin : proc_grant
	grant_next = 0;
	grant_valid_next = 0;
	grant_encoded_next = 0;
	mask_next = 0;

	if (ARB_BLOCK && !ARB_BLOCK_ACK && grant_reg & request) begin
		// blocking arbiter enabled; granted request still asserted; hold it
		grant_valid_next = grant_valid_reg;
		grant_next = grant_reg;
		grant_encoded_next = grant_encoded_reg;
	end else if (ARB_BLOCK && ARB_BLOCK_ACK && grant_valid && !(grant_reg & acknowledge)) begin
		// blocking arbiter enabled; granted request not yet acknowledged; hold it
		grant_valid_next = grant_valid_reg;
		grant_next = grant_reg;
		grant_encoded_next = grant_encoded_reg;
	end else if (request_valid) begin
		if (ARB_TYPE_ROUND_ROBIN) begin
			// round robin enabled; the requests are masked to restrict the priority encoder inputs
			// this way requests with the same priority won't be granted twice in one round robin cycle
			if (masked_request_valid) begin
				// input request fits the mask
				grant_valid_next = 1;
				grant_next = masked_request_mask;
				grant_encoded_next = masked_request_index;
				if (ARB_LSB_HIGH_PRIORITY) begin
					mask_next = {PORTS{1'b1}} << (masked_request_index + 1);
				end else begin
					mask_next = {PORTS{1'b1}} >> (PORTS - masked_request_index);
				end
			end else begin
				// input request does not fit the mask; start round robin cycle anew starting with
				// the input request
				grant_valid_next = 1;
				grant_next = request_mask;
				grant_encoded_next = request_index;
				if (ARB_LSB_HIGH_PRIORITY) begin
					mask_next = {PORTS{1'b1}} << (request_index + 1);
				end else begin
					mask_next = {PORTS{1'b1}} >> (PORTS - request_index);
				end
			end
		end else begin
			// default case; granted request is determined by the priority of the encoder
			grant_valid_next = 1;
			grant_next = request_mask;
			grant_encoded_next = request_index;
		end
	end	
end

always_ff @(posedge clk or negedge resetn) begin
	if (~resetn) begin
		grant_reg <= 0;
		grant_valid_reg <= 0;
		grant_encoded_reg <= 0;
		mask_reg <= 0;
	end else begin
		grant_reg <= grant_next;
		grant_valid_reg <= grant_valid_next;
		grant_encoded_reg <= grant_encoded_next;
		mask_reg <= mask_next;
	end
end

endmodule : arbiter

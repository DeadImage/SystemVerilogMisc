import essentials::*;

module cdf5_3(
input logic clk, resetn, en, dis,
input logic [7:0] in0, in1, in2,
output logic [7:0] out_s, out_d,
output logic result);

	// state register and next state value
	enum logic [1:0] {ST_IDLE, ST_PROC} state, next_state;

	logic signed [15:0] x0, x1, x2;
	logic signed [15:0] d_prev;
	logic signed [15:0] s, d;
	
	// state register
	always_ff @ (posedge clk or negedge resetn)
	begin
		if (~resetn) state <= ST_IDLE;
		else state <= next_state;
	end
	
	//next state logic
	always_comb
	begin
        next_state = state;
		case (state)
		ST_IDLE:
			if (en) next_state = ST_PROC;
			else next_state = ST_IDLE;
		ST_PROC:
			if (dis) next_state = ST_IDLE;
			else next_state = ST_PROC;
		default:
			next_state = ST_IDLE;
		endcase
	end
	
	always_ff @ (posedge clk or negedge resetn)
	begin
		if (!resetn)
		begin
			d_prev <= 0;
			result <= 0;
		end
		else	
		case (state)
		ST_IDLE:
			begin				
				result <= 0;
				if (en)
				begin
					x0 <= in0;
					x1 <= in1;
					x2 <= in2;
					d_prev <= 0;
				end
			end
		ST_PROC:
			begin				
				result <= 1;
				d_prev <= d;
				x0 <= in0;
				x1 <= in1;
				x2 <= in2;			
			end
		endcase
	end
	
	always_ff @ (posedge clk or negedge resetn)
	begin
	if (!resetn)
		begin
			out_s <= 0;
			out_d <= 0;
		end
		else
		begin
			out_s <= s;
			out_d <= d;
		end
	end
	
	always_comb
	begin
		d = x1 - ((x0 + x2) >>> 1);
		s = x0 + ((d + d_prev) >>> 2);
	end
	
endmodule
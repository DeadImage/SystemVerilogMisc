import essentials::*;

module row_to_cdf
(
input logic clk, resetn, en,
input logic [7:0] in [LENGTH],
output logic [7:0] out0, out1, out2,
output logic result);

	// state register and next state value
	enum logic {ST_IDLE, ST_PROC} state, next_state;	
	logic [7:0] counter;
	
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
			if (counter == LENGTH - 2) next_state = ST_IDLE;
			else next_state = ST_PROC;
		default:
			next_state = ST_IDLE;
		endcase
	end
	
	always_ff @ (posedge clk or negedge resetn)
	begin
		if (!resetn)
		begin
			result <= 0;
			counter <= 0;
		end
		else
		case (state)
		ST_IDLE:
			begin				
				if (en)
				begin
					result <= 1;
					counter <= counter + 2;
					out0 <= in[0];
					out1 <= in[1];
					out2 <= in[2];
				end
				else 
				begin
					counter <= 0;
					result <= 0;
				end
			end
		ST_PROC:
			begin
				result <= 1;
				counter <= counter + 2;
				out0 <= in[counter];
				out1 <= in[counter + 1];
				if (counter == LENGTH - 2) out2 <= in[counter + 1]; else out2 <= in[counter + 2];
			end
	    endcase		
	end
	
endmodule
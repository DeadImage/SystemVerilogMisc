import essentials::*;

module coefs_to_row(
input logic clk, en, resetn,
input logic [7:0] s, d,
output logic [7:0] out,
output logic result);	

	logic [7:0] counter;
	logic [7:0] d_bank [0:LENGTH/2-1];
	
	// state register and next state value
	enum logic [1:0] {ST_IDLE, ST_OUT_S, ST_OUT_D} state, next_state;
	
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
			if (en) next_state = ST_OUT_S;
			else next_state = ST_IDLE;
		ST_OUT_S:
			if (counter == LENGTH / 2) next_state = ST_OUT_D;
			else next_state = ST_OUT_S;
		ST_OUT_D:
			if (counter == LENGTH / 2) next_state = ST_IDLE;
			else next_state = ST_OUT_D;
		default:
			next_state = ST_IDLE;
		endcase
	end
	
	always_ff @ (posedge clk or negedge resetn)
	begin
		if (~resetn)
		begin
			counter <= 0;
		end
		else
		case (state)
		ST_IDLE:
		begin
			if (en)
			begin
				d_bank[0] <= d;
				out <= s;
				counter <= 1;
				result <= 1;
			end
			else
			begin
				result <= 0;
				counter <= 0;
			end		
		end
		ST_OUT_S:
			begin		
				if (counter == LENGTH / 2) counter <= 0; else counter <= counter + 1;
				d_bank[counter] <= d;
				out <= s;
				result <= 1;
			end
		ST_OUT_D:
			begin		
				if (counter == LENGTH / 2)
				begin
					counter <= 0;
					result <= 0;
				end
				else 
				begin
					counter <= counter + 1;
					result <= 1;
				end
				out <= d_bank[counter];
				
			end
		endcase		
	end

endmodule
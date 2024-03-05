import essentials::*;

module col_processor(
input logic clk, resetn, en,
input logic [7:0] row_0, row_1, row_2,
input logic row_bank_en,
input logic iter_var,
output logic [7:0] s, d,
output logic result);

	logic [7:0] r0_input;
	logic [7:0] bank_out;
	logic tf_en, tf_dis, tf_res;
	logic [8:0] counter;

	// state register and next state value
	enum logic [1:0] {ST_IDLE, ST_PROC} state, next_state;
	
	cdf5_3 transformer(clk, resetn, tf_en, tf_dis, r0_input, row_1, row_2, s, d, tf_res);	
	row_shift_bank bank(clk, row_bank_en, resetn, row_2, bank_out);
	
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
			if (counter == LENGTH) next_state = ST_IDLE;
			else next_state = ST_PROC;
		default:
			next_state = ST_IDLE;
		endcase
	end
	
	// data and status registers
	always_ff @ (posedge clk or negedge resetn)
	begin
		if (!resetn)
		begin
			counter <= 0;
		end
		else
		case (state)
		ST_IDLE:			
			counter <= 0;
		ST_PROC:
			counter <= counter + 1;		
	    endcase		
	end
	
	always_comb
	begin
		if (en) tf_en = 1; else tf_en = 0;
		if (counter == LENGTH - 1) tf_dis = 1; else tf_dis = 0;
		if (tf_res == 1) result = 1; else result = 0;
		if (iter_var)
			r0_input = bank_out;
		else
			r0_input = row_0;
	end

endmodule
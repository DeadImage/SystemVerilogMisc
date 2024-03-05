import essentials::*;

module block_processor(
input logic clk, en, resetn,
input logic [1:0] iter_flag,
input logic [7:0] in_row_0 [LENGTH], in_row_1 [LENGTH], in_row_2 [LENGTH],
output logic [7:0] s, d,
output logic result);

	logic [7:0] rp0_s, rp0_d;
	logic [7:0] rp1_s, rp1_d;
	logic [7:0] rp2_s, rp2_d;
	logic rp0_en, rp1_en, rp2_en, rp0_res, rp1_res, rp2_res;
	
	logic [7:0] cp_in2;
	logic cp_en, cp_res;
	logic cp_rb_en;
	logic iter_var;
	
	logic cr_en0, cr_en1, cr_en2;
	logic [7:0] cr0_out, cr1_out, cr2_out;
	logic cr_res0, cr_res1, cr_res2;	
	
	logic [9:0] counter;

	// state register and next state value
	enum logic [1:0] {ST_IDLE, ST_ROW_PROC, ST_COL_PROC} state, next_state;
	
	row_processor rp0(clk, resetn, rp0_en, in_row_0, rp0_s, rp0_d, rp0_res);
	row_processor rp1(clk, resetn, rp1_en, in_row_1, rp1_s, rp1_d, rp1_res);
	row_processor rp2(clk, resetn, rp2_en, in_row_2, rp2_s, rp2_d, rp2_res);
	
	coefs_to_row cr0(clk, cr_en0, resetn, rp0_s, rp0_d, cr0_out, cr_res0);
	coefs_to_row cr1(clk, cr_en1, resetn, rp1_s, rp1_d, cr1_out, cr_res1);
	coefs_to_row cr2(clk, cr_en2, resetn, rp2_s, rp2_d, cr2_out, cr_res2);
	
	col_processor cp(clk, resetn, cp_en, cr0_out, cr1_out, cp_in2, cr_res1, iter_var, s, d, cp_res);
	
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
			if (en) next_state = ST_ROW_PROC;
			else next_state = ST_IDLE;
		ST_ROW_PROC:
			if (rp1_res) next_state = ST_COL_PROC;
			else next_state = ST_ROW_PROC;
		ST_COL_PROC:
			if (counter == LENGTH) next_state = ST_IDLE;
			else next_state = ST_COL_PROC;
		default:
			next_state = ST_IDLE;
		endcase
	end
	
	
	always_ff @ (posedge clk or negedge resetn)
	begin
		if (!resetn)
			counter <= 0;
		else
		case (state)
		ST_ROW_PROC:				
				counter <= 0;
		ST_COL_PROC:
				counter <= counter + 1;
	    endcase		
	end
	
	always_comb
	begin
		if (en && iter_flag == 0) rp0_en = 1; else rp0_en = 0;
		if (en) rp1_en = 1; else rp1_en = 0;
		if (en && iter_flag != 2) rp2_en = 1; else rp2_en = 0;	
			
		if (state == ST_ROW_PROC && rp0_res) cr_en0 = 1; else cr_en0 = 0;
		if (state == ST_ROW_PROC && rp1_res) cr_en1 = 1; else cr_en1 = 0;
		if (state == ST_ROW_PROC && rp2_res) cr_en2 = 1; else cr_en2 = 0;
		
		if (state == ST_COL_PROC && counter == 0) 
			cp_en = 1; 
		else 
			cp_en = 0;
					 
		if (iter_flag == 0)
			iter_var = 0; 
		else 
			iter_var = 1;
		
		if (iter_flag == 2)
			cp_in2 = cr1_out;
		else
			cp_in2 = cr2_out;
		
		result = cp_res;
	end

endmodule
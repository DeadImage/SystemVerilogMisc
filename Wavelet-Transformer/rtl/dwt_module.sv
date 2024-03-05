import essentials::*;

module dwt_module(
input logic clk, en, resetn,
input logic [7:0] in,
output logic [7:0] s, d,
output logic result, rdy);
	
	logic [8:0] result_counter;
	logic [7:0] block_counter;
	
	logic ip_en, ip_full;
	logic [1:0] iter_flag;
	logic [7:0] ip_row_0 [0:LENGTH-1];
	logic [7:0] ip_row_1 [0:LENGTH-1];
	logic [7:0] ip_row_2 [0:LENGTH-1];
	
	logic [7:0] bp_row_0 [0:LENGTH-1];
	logic [7:0] bp_row_1 [0:LENGTH-1];
	logic [7:0] bp_row_2 [0:LENGTH-1];

	// state register and next state value
	enum logic [1:0] {ST_IDLE, ST_FIRST_BLOCK, ST_MAIN_BLOCK, ST_LAST_BLOCK} state, next_state;
	
	input_block ip(clk, ip_en, resetn, iter_flag, in, ip_row_0, ip_row_1, ip_row_2, ip_full);	
	block_processor bp(clk, ip_full, resetn, iter_flag, ip_row_0, ip_row_1, ip_row_2, s, d, result);
	
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
			if (en) next_state = ST_FIRST_BLOCK;
			else next_state = ST_IDLE;
		ST_FIRST_BLOCK:
			if (block_counter == 1) next_state = ST_MAIN_BLOCK;
			else next_state = ST_FIRST_BLOCK;
		ST_MAIN_BLOCK:
			if (block_counter == LENGTH/2-1) next_state = ST_LAST_BLOCK;
			else next_state = ST_MAIN_BLOCK;
		ST_LAST_BLOCK:
			if (block_counter == LENGTH/2) next_state = ST_IDLE;
			else next_state = ST_LAST_BLOCK;
		default:
			next_state = ST_IDLE;
		endcase
	end
	
	
	always_ff @ (posedge clk or negedge resetn)
	begin
		if (!resetn)
		begin
			iter_flag <= 0;
			rdy <= 0;
		end
		else
		case (state)
		ST_IDLE:
		begin
			iter_flag <= 0;
			if (en) 
			begin
				ip_en <= 1;				
				rdy <= 0;				
			end
			else 
			begin
				rdy <= 1;
				ip_en <= 0;
			end
		end
		ST_FIRST_BLOCK:
		begin
			ip_en <= 0;
			if (block_counter == 1)	rdy <= 1; else rdy <= 0;
		end
		ST_MAIN_BLOCK:
		begin
			iter_flag <= 1;
			if (en)
			begin
				ip_en <= 1;
				rdy <= 0;
			end
			else
			begin
				ip_en <= 0;
				if (result_counter == LENGTH) rdy <= 1; else rdy <= 0;
			end
		end
		ST_LAST_BLOCK:
		begin
			iter_flag <= 2;
			if (en)
			begin
				ip_en <= 1;
				rdy <= 0;
			end
			else
			begin
				ip_en <= 0;
				if (result_counter == LENGTH) rdy <= 1; else rdy <= 0;
			end
		end
	    endcase		
	end
	
	always_ff @ (posedge clk or negedge resetn)
	begin
		if (!resetn)
		begin
			result_counter <= 0;
			block_counter <= 0;
		end
		else
		begin
			if (block_counter == LENGTH/2)
				block_counter <= 0;
			else
			if (result_counter == LENGTH)
			begin
				result_counter <= 0;
				block_counter <= block_counter + 1;
			end
			else
			begin
				if (result) result_counter <= result_counter + 1;
			end
		end
	end

endmodule
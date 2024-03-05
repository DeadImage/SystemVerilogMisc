import essentials::*;

module row_processor(
input logic clk, resetn, en,
input logic [7:0] in [LENGTH],
output logic [7:0] s, d,
output logic result);

	logic [7:0] x0, x1, x2;
	logic tf_en, tf_dis;
	logic df_res;
	logic [9:0] counter;

	// state register and next state value
	enum logic [1:0] {ST_IDLE, ST_PROC} state, next_state;
	
	cdf5_3 transformer(clk, resetn, tf_en, tf_dis, x0, x1, x2, s, d, result);
	row_to_cdf data_former(clk, resetn, en, in, x0, x1, x2, df_res);
	
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
			if (counter == LENGTH / 2 + 1) next_state = ST_IDLE;
			else next_state = ST_PROC;
		default:
			next_state = ST_IDLE;
		endcase
	end
	
	always_ff @ (posedge clk or negedge resetn)
	begin
		if (!resetn)
		begin
			tf_en <= 0;	
			tf_dis <= 0;			
		end
		else
		case (state)
		ST_IDLE:
			begin				
				tf_en <= 0;
				tf_dis <= 0;
				counter <= 0;
				if (en) tf_en <= 1;
			end
		ST_PROC:
			begin
				tf_en <= 0;
				counter <= counter + 1;
				if (counter == LENGTH / 2 - 1) tf_dis <= 1; else tf_dis <= 0;
			end
	    endcase		
	end
endmodule
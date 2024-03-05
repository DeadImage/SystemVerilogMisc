import essentials::*;

module input_block(
input logic clk, en, resetn,
input logic [1:0] iter_flag,
input logic [7:0] in,
output logic [7:0] out_row_0 [0:LENGTH-1],
output logic [7:0] out_row_1 [0:LENGTH-1],
output logic [7:0] out_row_2 [0:LENGTH-1],
output logic full_flag);	

	logic [9:0] counter;
	logic [1:0] iter;
	logic [7:0] mem [0:(LENGTH*3)-1];
	
	// state register and next state value
	enum logic [1:0] {ST_IDLE, ST_INPUT, ST_OUTPUT} state, next_state;
	
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
			if (en) next_state = ST_INPUT;
			else next_state = ST_IDLE;
		ST_INPUT:
		begin
			if (iter == 0)
				if (counter == (LENGTH*3)-1)
					next_state = ST_OUTPUT;
				else
					next_state = ST_INPUT;
			if (iter == 1)
				if (counter == (LENGTH*2)-1)
					next_state = ST_OUTPUT;
				else
					next_state = ST_INPUT;
			if (iter == 2)
				if (counter == LENGTH-1)
					next_state = ST_OUTPUT;
				else
					next_state = ST_INPUT;
		end
		ST_OUTPUT:
			next_state = ST_IDLE;
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
			if (en)
			begin
				mem[0] <= in;
				iter <= iter_flag;
				counter <= 1;				
			end
		ST_INPUT:
		begin
			counter <= counter + 1;
			mem[counter] <= in;
		end	
		endcase
	end

	always_comb
	begin
		if (state == ST_OUTPUT)
		begin
			full_flag = 1;
			case (iter)
			0:
			begin
				out_row_0 = mem[0:LENGTH-1];
				out_row_1 = mem[LENGTH:(LENGTH*2)-1];
				out_row_2 = mem[LENGTH*2:(LENGTH*3)-1];
			end
			1:
			begin
				out_row_1 = mem[0:LENGTH-1];
				out_row_2 = mem[LENGTH:(LENGTH*2)-1];
			end
			2:
				out_row_1 = mem[0:LENGTH-1];
			endcase
		end
		else 
			full_flag = 0;
	end

endmodule
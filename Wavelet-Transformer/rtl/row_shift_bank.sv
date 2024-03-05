import essentials::*;

module row_shift_bank(
input logic clk, en, resetn,
input logic [7:0] in,
output logic [7:0] out);

	logic [7:0] data[0:LENGTH-1];
	
	always_ff @ (posedge clk or negedge resetn)
	begin
		if (!resetn)
			for (int i = 0; i < LENGTH; i=i+1)
				data[i] <= 0;
		else
		if (en)
		begin
			data[1:LENGTH-1] <= data[0:LENGTH-2];
			data[0] <= in;
			out <= data[LENGTH-1];
		end
	end

endmodule
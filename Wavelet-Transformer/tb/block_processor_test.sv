`timescale 1 ps/ 1 ps

import essentials::*;

module block_processor_test();
	// test vector input registers
	logic clk;
	logic resetn;
	logic en;
	logic result;
	logic [7:0] in_row_0 [LENGTH], in_row_1 [LENGTH], in_row_2 [LENGTH];
	logic [1:0] iter_flag;
	// module output connections
	logic [7:0] s, d;
	
	//input and output arrays
    logic [7:0] din[0:(LENGTH*LENGTH)-1]; //input
	integer fin;
		
	//device under test
	block_processor uut_inst (
		.clk(clk),
		.resetn(resetn),
		.en(en),
		.in_row_0(in_row_0), .in_row_1(in_row_1), .in_row_2(in_row_2),
		.s(s), .d(d),
		.iter_flag(iter_flag),
		.result(result)
	);
	
	// create clock
	initial                                                
	begin                                                  
		clk=0;
		forever #10 clk=~clk;
	end

	initial begin
		//Read data
		fin = $fopen("image.bin", "rb");
        $fread(din, fin);
		// reset
		resetn=0;
		@(negedge clk) resetn=1;
		en = 0;

		for (int i = 0; i < 4; i = i + 1)
		begin
			@(posedge clk);
			en = 1;
			
			if (i == 0)
			begin			 
				iter_flag = 0;
				in_row_0 = din[0:LENGTH-1];
				in_row_1 = din[LENGTH:(LENGTH*2)-1];
				in_row_2 = din[LENGTH*2:(LENGTH*3)-1];
			end
			if (i == 1)
			begin			 
				iter_flag = 1;
				in_row_1 = din[LENGTH*3:(LENGTH*4)-1];
				in_row_2 = din[LENGTH*4:(LENGTH*5)-1];
			end
			if (i == 2)
			begin			 
				iter_flag = 1;
				in_row_1 = din[LENGTH*5:(LENGTH*6)-1];
				in_row_2 = din[LENGTH*6:(LENGTH*7)-1];
			end
			if (i == 3)
			begin			 
				iter_flag = 2;
				in_row_1 = din[LENGTH*7:(LENGTH*8)-1];
			end
			
			
			@(posedge clk);
			en = 0;
			
			while (result == 0)
				@(posedge clk);
			while (result == 1)
				@(posedge clk);
		end
		
		$fclose(fin);
		//stop simulation
		$stop;
	end
	
endmodule
	

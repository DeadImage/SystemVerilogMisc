`timescale 1 ps/ 1 ps

import essentials::*;

module col_processor_test();
	// test vector input registers
	logic clk;
	logic resetn;
	logic en;
	logic result;
	logic [7:0] row_0, row_1, row_2;
	// module output connections
	logic [7:0] s, d;
	logic iter_var;
	logic row_bank_en;
	
	//input and output arrays
    logic [7:0] din[0:(LENGTH*3)-1]; //input	
	integer fin;
		
	//device under test
	col_processor uut_inst (
		.clk(clk),
		.resetn(resetn),
		.en(en),
		.row_0(row_0), .row_1(row_1), .row_2(row_2),
		.s(s), .d(d),
		.iter_var(iter_var),
		.row_bank_en(row_bank_en),
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
		row_bank_en	= 0;
		iter_var = 0;

		for (int i = 0; i < LENGTH; i = i + 1)
		begin
			@(posedge clk);
			row_bank_en	= 0;
			if (i == 0) en = 1; else en = 0;
			row_0 = din[i];
			row_1 = din[256 + i];
			row_2 = din[512 + i];
		end
		
		for (int i = 0; i < 15; i = i + 1)
			@(posedge clk);
		
		$fclose(fin);
		
		//stop simulation
		$stop;
	end
	
endmodule
	
